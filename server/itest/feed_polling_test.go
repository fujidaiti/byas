//go:build integration

package itest

import (
	"database/sql"
	"slices"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/feed"
	"github.com/fujidaiti/paperdoll/server/feature/newspaper"
	"github.com/fujidaiti/paperdoll/server/feature/scraper"
	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

const pollingArticleFixture = "./testdata/polling_article.html"

// pollingInterval is the fixed editorial interval every Do-behavior test hands
// to its [feed.Job] directly, without deriving it from seeded
// newspaper_schedules rows. Feed fixtures use literal pubDates chosen to sit
// inside or outside this window.
var pollingInterval = newspaper.EditorialInterval{
	Last: time.Date(2026, 7, 15, 9, 55, 0, 0, time.UTC),
	Next: time.Date(2026, 7, 15, 10, 5, 0, 0, time.UTC),
}

// pollingSignupTime is an arbitrary fixed clock for seeding subscribers; it
// has no relationship to pollingInterval.
var pollingSignupTime = time.Date(2026, 7, 15, 10, 0, 0, 0, time.UTC)

func seedFeed(t *testing.T, url, title string) int {
	t.Helper()
	var id int
	scanRowOrFatal(t, `INSERT INTO feeds (url, title) VALUES ($1, $2) RETURNING id`, []any{url, title}, &id)
	return id
}

func seedSubscriber(t *testing.T, email string, feedID int) user.UserID {
	t.Helper()
	us := user.Service{DB: testenv.DB(), Now: func() time.Time { return pollingSignupTime }}
	_ = must(
		us.SignUp(
			t.Context(),
			must(user.ParseEmail(email)),
			must(user.ValidatePassword("test#password$1234")),
			"Pixel9a",
		),
	)
	var uid user.UserID
	scanRowOrFatal(t, `SELECT id FROM users WHERE email = $1`, []any{email}, &uid)
	execOrFatal(t, `INSERT INTO feed_subscriptions (user_id, feed_id) VALUES ($1, $2)`, uid, feedID)
	return uid
}

func execOrFatal(t *testing.T, query string, args ...any) {
	t.Helper()
	if _, err := testenv.DB().ExecContext(t.Context(), query, args...); err != nil {
		t.Fatalf("failed to exec: %v\nquery: %s", err, query)
	}
}

// collectJobsNow is the fixed clock every CollectJobs test hands to
// [feed.CollectJobs].
var collectJobsNow = time.Date(2026, 7, 15, 10, 0, 0, 0, time.Local)

// seedSchedule seeds one newspaper_schedules row at the given minute-of-day.
func seedSchedule(t *testing.T, label string, minuteOfDay int) {
	t.Helper()
	execOrFatal(t, `INSERT INTO newspaper_schedules (label, minute_of_date) VALUES ($1, $2)`, label, minuteOfDay)
}

func collectJobs(t *testing.T, now time.Time) ([]feed.Job, error) {
	t.Helper()
	return feed.CollectJobs(
		t.Context(),
		testenv.DB(),
		&newspaper.Service{DB: testenv.DB()},
		scraper.NewService(stubServerAddr),
		now,
	)
}

func TestCollectJobs_OneJobPerFeed(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedAID := seedFeed(t, "http://feed-a.test/rss", "Feed A")
	feedBID := seedFeed(t, "http://feed-b.test/rss", "Feed B")

	jobs, err := collectJobs(t, collectJobsNow)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 2 {
		t.Fatalf("got %d jobs, want 2", len(jobs))
	}

	got := []feed.FeedRecord{jobs[0].Feed, jobs[1].Feed}
	slices.SortFunc(got, func(a, b feed.FeedRecord) int { return a.ID - b.ID })
	want := []feed.FeedRecord{
		{ID: feedAID, URL: "http://feed-a.test/rss", Title: "Feed A"},
		{ID: feedBID, URL: "http://feed-b.test/rss", Title: "Feed B"},
	}
	if d := cmp.Diff(want, got); d != "" {
		t.Errorf("job feeds mismatch:\n%s", d)
	}
}

func TestCollectJobs_NoFeeds(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	jobs, err := collectJobs(t, collectJobsNow)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 0 {
		t.Errorf("got %d jobs, want 0", len(jobs))
	}
}

func TestCollectJobs_IntervalFromSchedule(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	seedFeed(t, "http://feed.test/rss", "Test Feed")
	midnight := time.Date(collectJobsNow.Year(), collectJobsNow.Month(), collectJobsNow.Day(), 0, 0, 0, 0, time.Local)
	minuteOfDay := func(t time.Time) int { return int(t.Sub(midnight).Minutes()) }
	seedSchedule(t, "before", minuteOfDay(collectJobsNow.Add(-5*time.Minute)))
	seedSchedule(t, "after", minuteOfDay(collectJobsNow.Add(5*time.Minute)))

	jobs, err := collectJobs(t, collectJobsNow)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 1 {
		t.Fatalf("got %d jobs, want 1", len(jobs))
	}

	wantInterval, err := newspaper.FindEditorialInterval(t.Context(), testenv.DB(), collectJobsNow)
	if err != nil {
		t.Fatalf("FindEditorialInterval returned an unexpected error: %v", err)
	}
	if d := cmp.Diff(wantInterval, jobs[0].Interval); d != "" {
		t.Errorf("job interval mismatch:\n%s", d)
	}
}

func TestCollectJobs_FailSoftWithoutSchedule(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	seedFeed(t, "http://feed.test/rss", "Test Feed")
	// No newspaper_schedules rows seeded.

	jobs, err := collectJobs(t, collectJobsNow)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 1 {
		t.Fatalf("got %d jobs, want 1", len(jobs))
	}
	if jobs[0].Interval.Valid() {
		t.Errorf("got a valid interval %+v, want the zero value since no schedule is registered", jobs[0].Interval)
	}
}

// newPollingJob builds a [feed.Job] directly, bypassing [feed.CollectJobs]
// entirely, with pollingInterval as its editorial interval.
func newPollingJob(feedID int, feedURL, feedTitle string) *feed.Job {
	return &feed.Job{
		DB:           testenv.DB(),
		Feed:         feed.FeedRecord{ID: feedID, URL: feedURL, Title: feedTitle},
		Interval:     pollingInterval,
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
}

type feedEntryRow struct {
	DedupKey    string
	FeedID      int
	URL         string
	Title       string
	Description sql.NullString
	Content     sql.NullString
	PublishedAt sql.NullTime
}

type storyRow struct {
	FeedEntryID int
	UserID      user.UserID
	Title       string
	Description sql.NullString
	Source      sql.NullString
}

func storyEntryID(t *testing.T, dedupKey string) int {
	t.Helper()
	var id int
	scanRowOrFatal(t, `SELECT id FROM feed_entries WHERE dedup_key = $1`, []any{dedupKey}, &id)
	return id
}

func TestFeedPolling_HappyPath(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	uid := seedSubscriber(t, "alice@example.com", feedID)

	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_happy_path.xml")
	testenv.StubHTTP("articles.test", "/happy-in", pollingArticleFixture)

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	entries := scanRowsOrFatal(t, `
		SELECT dedup_key, feed_id, url, title, description, content, published_at
		FROM feed_entries ORDER BY dedup_key
	`, nil, func(rows *sql.Rows, e *feedEntryRow) error {
		return rows.Scan(&e.DedupKey, &e.FeedID, &e.URL, &e.Title, &e.Description, &e.Content, &e.PublishedAt)
	})
	if len(entries) != 2 {
		t.Fatalf("got %d feed_entries, want 2", len(entries))
	}

	inEntry, outEntry := entries[0], entries[1] // "happy-in" < "happy-out"
	ignoreContent := cmpopts.IgnoreFields(feedEntryRow{}, "Content")
	wantIn := feedEntryRow{
		DedupKey:    "happy-in",
		FeedID:      feedID,
		URL:         "http://articles.test/happy-in",
		Title:       "In interval",
		Description: sql.NullString{String: "In desc", Valid: true},
		PublishedAt: sql.NullTime{Time: time.Date(2026, 7, 15, 10, 0, 0, 0, time.UTC), Valid: true},
	}
	wantOut := feedEntryRow{
		DedupKey:    "happy-out",
		FeedID:      feedID,
		URL:         "http://articles.test/happy-out",
		Title:       "Out of interval",
		Description: sql.NullString{String: "Out desc", Valid: true},
		PublishedAt: sql.NullTime{Time: time.Date(2026, 7, 15, 7, 0, 0, 0, time.UTC), Valid: true},
	}
	if d := cmp.Diff(wantIn, inEntry, ignoreContent); d != "" {
		t.Errorf("in-interval entry mismatch:\n%s", d)
	}
	if d := cmp.Diff(wantOut, outEntry, ignoreContent); d != "" {
		t.Errorf("out-of-interval entry mismatch:\n%s", d)
	}
	if !inEntry.Content.Valid || inEntry.Content.String == "" {
		t.Errorf("in-interval entry: want content to be populated, got %+v", inEntry.Content)
	}
	if outEntry.Content.Valid {
		t.Errorf("out-of-interval entry: want content to stay NULL, got %q", outEntry.Content.String)
	}

	stories := scanRowsOrFatal(t, `
		SELECT feed_entry_id, user_id, title, description, source FROM stories
	`, nil, func(rows *sql.Rows, s *storyRow) error {
		return rows.Scan(&s.FeedEntryID, &s.UserID, &s.Title, &s.Description, &s.Source)
	})
	if len(stories) != 1 {
		t.Fatalf("got %d stories, want exactly 1", len(stories))
	}
	want := storyRow{
		FeedEntryID: storyEntryID(t, "happy-in"),
		UserID:      uid,
		Title:       "In interval",
		Description: sql.NullString{String: "In desc", Valid: true},
		Source:      sql.NullString{String: "Test Feed", Valid: true},
	}
	if d := cmp.Diff(want, stories[0]); d != "" {
		t.Errorf("story mismatch:\n%s", d)
	}
}

func TestFeedPolling_RePoll(t *testing.T) {
	tests := []struct {
		name                           string
		firstFixture, secondFixture    string
		wantEntryCount, wantStoryCount int
	}{
		{
			name:           "no duplicates",
			firstFixture:   "./testdata/polling_repoll_nodup.xml",
			secondFixture:  "./testdata/polling_repoll_nodup.xml",
			wantEntryCount: 1,
			wantStoryCount: 1,
		},
		{
			name:           "new item added",
			firstFixture:   "./testdata/polling_repoll_new_item_before.xml",
			secondFixture:  "./testdata/polling_repoll_new_item_after.xml",
			wantEntryCount: 2,
			wantStoryCount: 2,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Cleanup(testenv.TearDown)
			feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
			seedSubscriber(t, "alice@example.com", feedID)
			j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")

			testenv.StubHTTP("feed.test", "/rss", tt.firstFixture)
			if err := j.Do(t.Context()); err != nil {
				t.Fatalf("first poll: job.Do returned an unexpected error: %v", err)
			}

			testenv.StubHTTP("feed.test", "/rss", tt.secondFixture)
			if err := j.Do(t.Context()); err != nil {
				t.Fatalf("second poll: job.Do returned an unexpected error: %v", err)
			}

			var entryCount, storyCount int
			scanRowOrFatal(t, `SELECT count(*) FROM feed_entries`, nil, &entryCount)
			scanRowOrFatal(t, `SELECT count(*) FROM stories`, nil, &storyCount)
			if entryCount != tt.wantEntryCount {
				t.Errorf("got %d feed_entries after re-poll, want %d", entryCount, tt.wantEntryCount)
			}
			if storyCount != tt.wantStoryCount {
				t.Errorf("got %d stories after re-poll, want %d", storyCount, tt.wantStoryCount)
			}
		})
	}
}

func TestFeedPolling_NoSubscribers(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_no_subscribers.xml")

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	var entryCount, storyCount int
	scanRowOrFatal(t, `SELECT count(*) FROM feed_entries`, nil, &entryCount)
	scanRowOrFatal(t, `SELECT count(*) FROM stories`, nil, &storyCount)
	if entryCount != 1 {
		t.Errorf("got %d feed_entries, want 1", entryCount)
	}
	if storyCount != 0 {
		t.Errorf("got %d stories, want 0", storyCount)
	}
}

func TestFeedPolling_ArticleFetchFails(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	seedSubscriber(t, "alice@example.com", feedID)
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_article_fetch_fails.xml")
	// No StubHTTP rule registered for /missing, so the stub server 404s it.

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err != nil {
		t.Errorf("job.Do returned %v, want nil (article fetch failures are fail-soft)", err)
	}

	var content sql.NullString
	scanRowOrFatal(t, `SELECT content FROM feed_entries WHERE dedup_key = 'fetch-fail'`, nil, &content)
	if content.Valid {
		t.Errorf("want content to stay NULL after a failed article fetch, got %q", content.String)
	}
	var storyCount int
	scanRowOrFatal(t, `SELECT count(*) FROM stories`, nil, &storyCount)
	if storyCount != 1 {
		t.Errorf("got %d stories, want 1 (story is queued before the article fetch runs)", storyCount)
	}
}

func TestFeedPolling_FeedFetchFailure(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	// No StubHTTP rule registered for /rss, so the fetch 404s.

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err == nil {
		t.Error("want an error when the feed itself fails to fetch, got nil")
	}

	var entryCount int
	scanRowOrFatal(t, `SELECT count(*) FROM feed_entries`, nil, &entryCount)
	if entryCount != 0 {
		t.Errorf("got %d feed_entries, want 0", entryCount)
	}
}

func TestFeedPolling_EmptyFeed(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_empty_feed.xml")

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err == nil {
		t.Error("want an error for a feed with zero items, got nil")
	}

	var entryCount int
	scanRowOrFatal(t, `SELECT count(*) FROM feed_entries`, nil, &entryCount)
	if entryCount != 0 {
		t.Errorf("got %d feed_entries, want 0", entryCount)
	}
}

func TestFeedPolling_MultipleSubscribers(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	uidAlice := seedSubscriber(t, "alice@example.com", feedID)
	uidBob := seedSubscriber(t, "bob@example.com", feedID)
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_multiple_subscribers.xml")

	j := newPollingJob(feedID, "http://feed.test/rss", "Test Feed")
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	stories := scanRowsOrFatal(
		t,
		`SELECT user_id FROM stories ORDER BY user_id`,
		nil,
		func(rows *sql.Rows, uid *user.UserID) error {
			return rows.Scan(uid)
		},
	)
	// alice signs up before bob, and users.id is an ascending identity column,
	// so uidAlice < uidBob and this matches the ORDER BY above.
	want := []user.UserID{uidAlice, uidBob}
	if d := cmp.Diff(want, stories); d != "" {
		t.Errorf("subscriber user IDs mismatch:\n%s", d)
	}
}
