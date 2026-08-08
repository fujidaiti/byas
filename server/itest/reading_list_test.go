//go:build integration

package itest

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/api"
	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
)

// seedUserToken creates a real user via user.Service.SignUp and returns both
// their ID and an encoded auth token usable in an Authorization header.
func seedUserToken(t *testing.T, email string, now time.Time) (user.UserID, string) {
	t.Helper()
	us := user.Service{DB: testenv.DB(), Now: func() time.Time { return now }}
	token := must(us.SignUp(
		t.Context(),
		must(user.ParseEmail(email)),
		must(user.ValidatePassword("test#password$1234")),
		"Pixel9a",
	))
	uid := scanValOrFatal[user.UserID](t, `SELECT id FROM users WHERE email = $1`, email)
	return uid, token.Encode()
}

// seedFeedEntry inserts a minimal feed and feed entry, returning the entry ID.
func seedFeedEntry(t *testing.T, seed, title string) int {
	t.Helper()
	feedID := scanValOrFatal[int](t, `
		INSERT INTO feeds (url, title) VALUES ($1, $2) RETURNING id
	`, fmt.Sprintf("http://%s.test/rss", seed), title+" Feed")
	return scanValOrFatal[int](t, `
		INSERT INTO feed_entries (dedup_key, feed_id, url, title, snapshot_at)
		VALUES ($1, $2, $3, $4, $5) RETURNING id
	`, seed, feedID, fmt.Sprintf("http://%s.test/entry", seed), title, time.Now())
}

// seedReadingListItem saves feedEntryID directly into uid's reading list,
// bypassing the API under test.
func seedReadingListItem(t *testing.T, uid user.UserID, feedEntryID int, archived bool) int {
	t.Helper()
	return scanValOrFatal[int](t, `
		INSERT INTO reading_list_items (kind, feed_entry_id, title, archived, user_id)
		VALUES ('feed_entry', $1, 'Test Entry', $2, $3)
		RETURNING id
	`, feedEntryID, archived, uid)
}

func doRequest(t *testing.T, h http.Handler, method, path, token string, body any) *httptest.ResponseRecorder {
	t.Helper()
	buf := new(bytes.Buffer)
	if body != nil {
		if err := json.NewEncoder(buf).Encode(body); err != nil {
			t.Fatalf("failed to marshal request body: %v", err)
		}
	}
	req := httptest.NewRequest(method, path, buf)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

type readingListItemBody struct {
	ID          int     `json:"id"`
	ResourceID  int     `json:"resource_id"`
	Kind        string  `json:"kind"`
	Title       string  `json:"title"`
	Description *string `json:"description,omitempty"`
	SavedAt     string  `json:"saved_at"`
}

type getReadingListBody struct {
	Items      []readingListItemBody `json:"items"`
	NextCursor *string               `json:"next_cursor,omitempty"`
}

type readLaterBody struct {
	ID       int  `json:"id"`
	Archived bool `json:"archived"`
}

type getFeedEntryBody struct {
	ID        int            `json:"id"`
	ReadLater *readLaterBody `json:"read_later,omitempty"`
}

func TestReadingList_GetScopedToOwner(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	_, aliceToken := seedUserToken(t, "alice@example.com", now)
	uidBob, bobToken := seedUserToken(t, "bob@example.com", now)

	entryID := seedFeedEntry(t, "shared", "Shared Entry")
	seedReadingListItem(t, uidBob, entryID, false)

	rec := doRequest(t, h, http.MethodGet, "/reading-list", aliceToken, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want %d", rec.Code, http.StatusOK)
	}
	var got getReadingListBody
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if len(got.Items) != 0 {
		t.Errorf("got %d items for alice, want 0 (bob's item must not leak)", len(got.Items))
	}

	rec = doRequest(t, h, http.MethodGet, "/reading-list", bobToken, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want %d", rec.Code, http.StatusOK)
	}
	got = getReadingListBody{}
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if len(got.Items) != 1 {
		t.Fatalf("got %d items for bob, want 1", len(got.Items))
	}
	if got.Items[0].ResourceID != entryID {
		t.Errorf("got resource id %d, want %d", got.Items[0].ResourceID, entryID)
	}
}

func TestReadingList_ArchivedScopedToOwner(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	uidAlice, aliceToken := seedUserToken(t, "alice@example.com", now)
	uidBob, _ := seedUserToken(t, "bob@example.com", now)

	aliceEntryID := seedFeedEntry(t, "alice-archived", "Alice Archived")
	bobEntryID := seedFeedEntry(t, "bob-archived", "Bob Archived")
	seedReadingListItem(t, uidAlice, aliceEntryID, true)
	seedReadingListItem(t, uidBob, bobEntryID, true)

	rec := doRequest(t, h, http.MethodGet, "/reading-list/archived", aliceToken, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want %d", rec.Code, http.StatusOK)
	}
	var got getReadingListBody
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if len(got.Items) != 1 {
		t.Fatalf("got %d archived items for alice, want 1", len(got.Items))
	}
	if got.Items[0].ResourceID != aliceEntryID {
		t.Errorf("got resource id %d, want alice's own entry %d", got.Items[0].ResourceID, aliceEntryID)
	}
}

func TestReadingList_SaveAssociatesWithCaller(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	uidAlice, aliceToken := seedUserToken(t, "alice@example.com", now)

	entryID := seedFeedEntry(t, "save-me", "Save Me")

	rec := doRequest(t, h, http.MethodPost, "/reading-list", aliceToken, map[string]any{
		"feed_entry_id": entryID,
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("got status %d, want %d, body: %s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var got readingListItemBody
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	gotUID := scanValOrFatal[user.UserID](t, `SELECT user_id FROM reading_list_items WHERE id = $1`, got.ID)
	if gotUID != uidAlice {
		t.Errorf("got user_id %d, want alice's id %d", gotUID, uidAlice)
	}
}

func TestReadingList_DeleteRequiresOwnership(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	uidAlice, aliceToken := seedUserToken(t, "alice@example.com", now)
	_, bobToken := seedUserToken(t, "bob@example.com", now)

	entryID := seedFeedEntry(t, "delete-me", "Delete Me")
	itemID := seedReadingListItem(t, uidAlice, entryID, false)

	rec := doRequest(t, h, http.MethodDelete, fmt.Sprintf("/reading-list/%d", itemID), bobToken, nil)
	if rec.Code != http.StatusNotFound {
		t.Errorf("got status %d, want %d (bob must not be able to delete alice's item)", rec.Code, http.StatusNotFound)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM reading_list_items WHERE id = $1`, itemID); n != 1 {
		t.Errorf("got %d rows, want the item to still exist", n)
	}

	rec = doRequest(t, h, http.MethodDelete, fmt.Sprintf("/reading-list/%d", itemID), aliceToken, nil)
	if rec.Code != http.StatusNoContent {
		t.Errorf("got status %d, want %d", rec.Code, http.StatusNoContent)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM reading_list_items WHERE id = $1`, itemID); n != 0 {
		t.Errorf("got %d rows, want the item to be gone", n)
	}
}

func TestReadingList_ArchiveRequiresOwnership(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	uidAlice, aliceToken := seedUserToken(t, "alice@example.com", now)
	_, bobToken := seedUserToken(t, "bob@example.com", now)

	entryID := seedFeedEntry(t, "archive-me", "Archive Me")
	itemID := seedReadingListItem(t, uidAlice, entryID, false)

	rec := doRequest(t, h, http.MethodPatch, fmt.Sprintf("/reading-list/%d", itemID), bobToken, map[string]any{
		"archived": true,
	})
	if rec.Code != http.StatusNotFound {
		t.Errorf("got status %d, want %d (bob must not be able to archive alice's item)", rec.Code, http.StatusNotFound)
	}
	if archived := scanValOrFatal[bool](t, `SELECT archived FROM reading_list_items WHERE id = $1`, itemID); archived {
		t.Error("item must remain unarchived after bob's request")
	}

	rec = doRequest(t, h, http.MethodPatch, fmt.Sprintf("/reading-list/%d", itemID), aliceToken, map[string]any{
		"archived": true,
	})
	if rec.Code != http.StatusNoContent {
		t.Errorf("got status %d, want %d", rec.Code, http.StatusNoContent)
	}
	if archived := scanValOrFatal[bool](t, `SELECT archived FROM reading_list_items WHERE id = $1`, itemID); !archived {
		t.Error("item must be archived after alice's request")
	}
}

func TestReadingList_ReadLaterScopedToOwner(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	h := api.NewServer(testenv.DB(), nil).Handler
	now := time.Now()
	_, aliceToken := seedUserToken(t, "alice@example.com", now)
	uidBob, bobToken := seedUserToken(t, "bob@example.com", now)

	entryID := seedFeedEntry(t, "read-later", "Read Later Entry")
	seedReadingListItem(t, uidBob, entryID, false)

	rec := doRequest(t, h, http.MethodGet, fmt.Sprintf("/feed-entries/%d", entryID), aliceToken, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want %d", rec.Code, http.StatusOK)
	}
	var gotAlice getFeedEntryBody
	if err := json.Unmarshal(rec.Body.Bytes(), &gotAlice); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if gotAlice.ReadLater != nil {
		t.Errorf("got read_later=%+v for alice, want nil (bob's saved state must not leak)", gotAlice.ReadLater)
	}

	rec = doRequest(t, h, http.MethodGet, fmt.Sprintf("/feed-entries/%d", entryID), bobToken, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want %d", rec.Code, http.StatusOK)
	}
	var gotBob getFeedEntryBody
	if err := json.Unmarshal(rec.Body.Bytes(), &gotBob); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if gotBob.ReadLater == nil {
		t.Fatal("got nil read_later for bob, want his saved item to be reflected")
	}
}
