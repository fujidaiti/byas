//go:build integration

package integration_test

import (
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/feature/newspaper"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

type storyRow struct {
	ID          int64
	FeedEntryID int64
	NewspaperID *int64
	Title       string
	Description *string
	PublishedAt *time.Time
	Source      string
}

func TestSubmitStories(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	var feedID int
	scanRowOrFatal(t, `
		INSERT INTO feeds (url, title)
		VALUES ('https://example.com', 'Example Feed')
		RETURNING id;
	`, nil, &feedID)

	var entryID int
	scanRowOrFatal(t, `
		INSERT INTO feed_entries (dedup_key, feed_id, url, title, snapshot_at)
		VALUES ('https://example.com', $1, 'https://example.com', 'Example Entry', now())
		RETURNING id;
	`, []any{feedID}, &entryID)

	story := newspaper.Story{
		FeedEntryID: entryID,
		Title:       "Example Entry",
		Source:      "Example Feed",
	}
	err := newspaper.SubmitStories(t.Context(), []newspaper.Story{story}, testenv.DB)
	if err != nil {
		t.Fatal(err)
	}

	var got storyRow
	scanRowOrFatal(t, `
		SELECT id, feed_entry_id, newspaper_id, title, description, source, published_at FROM stories LIMIT 1
	`, nil, &got.ID, &got.FeedEntryID, &got.NewspaperID, &got.Title, &got.Description, &got.Source, &got.PublishedAt,
	)

	want := storyRow{
		FeedEntryID: int64(entryID),
		Title:       story.Title,
		Source:      story.Source,
	}
	if diff := cmp.Diff(want, got, cmpopts.IgnoreFields(storyRow{}, "ID")); diff != "" {
		t.Errorf("unexpected story (-want +got):\n%s", diff)
	}
	if got.ID == 0 {
		t.Error("expected a non-zero ID")
	}
}
