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

func seedFeed(t *testing.T, url, title string) int {
	t.Helper()
	return scanValOrFatal[int](t, `INSERT INTO feeds (url, title) VALUES ($1, $2) RETURNING id`, url, title)
}

func seedSubscriber(t *testing.T, email string, feedID int, now time.Time) user.UserID {
	t.Helper()
	us := user.Service{DB: testenv.DB(), Now: func() time.Time { return now }}
	_ = must(us.SignUp(
		t.Context(),
		must(user.ParseEmail(email)),
		must(user.ValidatePassword("test#password$1234")),
		"Pixel9a",
	))
	uid := scanValOrFatal[user.UserID](t, `SELECT id FROM users WHERE email = $1`, email)
	execOrFatal(t, `INSERT INTO feed_subscriptions (user_id, feed_id) VALUES ($1, $2)`, uid, feedID)
	return uid
}

// CollectJobs returns exactly one job per feed row, regardless of how many
// feeds exist.
func TestCollectJobs_OneJobPerFeed(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedAID := seedFeed(t, "http://feed-a.test/rss", "Feed A")
	feedBID := seedFeed(t, "http://feed-b.test/rss", "Feed B")

	jobs, err := feed.CollectJobs(
		t.Context(),
		testenv.DB(),
		&newspaper.Service{DB: testenv.DB()},
		scraper.NewService(stubServerAddr),
		time.Date(2026, 7, 15, 10, 0, 0, 0, time.Local),
	)
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

// CollectJobs returns no jobs when there are no feeds to poll.
func TestCollectJobs_NoFeeds(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	jobs, err := feed.CollectJobs(
		t.Context(),
		testenv.DB(),
		&newspaper.Service{DB: testenv.DB()},
		scraper.NewService(stubServerAddr),
		time.Date(2026, 7, 15, 10, 0, 0, 0, time.Local),
	)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 0 {
		t.Errorf("got %d jobs, want 0", len(jobs))
	}
}

// A job's editorial interval is derived from the newspaper schedules
// immediately surrounding now, given two seeded schedule points that
// straddle it.
func TestCollectJobs_IntervalFromSchedule(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	seedFeed(t, "http://feed.test/rss", "Test Feed")
	// Seed schedules
	// TODO: add a domain function for adding a publishing schedule and
	// refactor this test to use it instead of inserting into newspaper_schedules directly.
	now := time.Date(2026, 7, 15, 10, 0, 0, 0, time.Local)
	before := now.Add(-5 * time.Minute)
	after := now.Add(5 * time.Minute)
	midnight := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
	minuteOfDay := func(t time.Time) int { return int(t.Sub(midnight).Minutes()) }
	execOrFatal(t, `
		INSERT INTO newspaper_schedules (label, minute_of_date) VALUES ($1, $2)
	`, "before", minuteOfDay(before))
	execOrFatal(t, `
		INSERT INTO newspaper_schedules (label, minute_of_date) VALUES ($1, $2)
	`, "after", minuteOfDay(after))

	jobs, err := feed.CollectJobs(
		t.Context(),
		testenv.DB(),
		&newspaper.Service{DB: testenv.DB()},
		scraper.NewService(stubServerAddr),
		now,
	)
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if n := len(jobs); n != 1 {
		t.Fatalf("got %d jobs, want 1", n)
	}

	wantInterval := newspaper.EditorialInterval{Last: before, Next: after}
	if d := cmp.Diff(wantInterval, jobs[0].Interval); d != "" {
		t.Errorf("job interval mismatch:\n%s", d)
	}
}

// A feed with no newspaper schedules registered still yields a job, just
// with a zero (invalid) editorial interval instead of an error.
func TestCollectJobs_FailSoftWithoutSchedule(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	seedFeed(t, "http://feed.test/rss", "Test Feed")
	// No newspaper_schedules rows seeded.

	jobs, err := feed.CollectJobs(
		t.Context(),
		testenv.DB(),
		&newspaper.Service{DB: testenv.DB()},
		scraper.NewService(stubServerAddr),
		time.Date(2026, 7, 15, 10, 0, 0, 0, time.Local),
	)
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

// A full polling job end-to-end: an in-interval item is stored with its
// fetched article content and drafted into a story for the subscriber,
// while an out-of-interval item is stored but skipped for both content
// fetching and story drafting.
func TestFeedPolling_HappyPath(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	uid := seedSubscriber(t, "alice@example.com", feedID, mustTimeUTC("2026-07-15 10:00:00"))

	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_happy_path.xml")
	testenv.StubHTTP("articles.test", "/happy-in", "./testdata/polling_article.html")

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
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
		PublishedAt: sql.NullTime{Time: mustTimeUTC("2026-07-15 10:00:00"), Valid: true},
	}
	wantOut := feedEntryRow{
		DedupKey:    "happy-out",
		FeedID:      feedID,
		URL:         "http://articles.test/happy-out",
		Title:       "Out of interval",
		Description: sql.NullString{String: "Out desc", Valid: true},
		PublishedAt: sql.NullTime{Time: mustTimeUTC("2026-07-15 07:00:00"), Valid: true},
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

	type storyRow struct {
		FeedEntryID int
		UserID      user.UserID
		Title       string
		Description sql.NullString
		Source      sql.NullString
	}
	stories := scanRowsOrFatal(t, `
		SELECT feed_entry_id, user_id, title, description, source FROM stories
	`, nil, func(rows *sql.Rows, s *storyRow) error {
		return rows.Scan(&s.FeedEntryID, &s.UserID, &s.Title, &s.Description, &s.Source)
	})
	if len(stories) != 1 {
		t.Fatalf("got %d stories, want exactly 1", len(stories))
	}
	inEntryID := scanValOrFatal[int](t, `SELECT id FROM feed_entries WHERE dedup_key = 'happy-in'`)
	want := storyRow{
		FeedEntryID: inEntryID,
		UserID:      uid,
		Title:       "In interval",
		Description: sql.NullString{String: "In desc", Valid: true},
		Source:      sql.NullString{String: "Test Feed", Valid: true},
	}
	if d := cmp.Diff(want, stories[0]); d != "" {
		t.Errorf("story mismatch:\n%s", d)
	}
}

// Polling the same feed twice does not duplicate entries or stories for
// items already seen, but does add a new entry and story when a second poll
// picks up a genuinely new item.
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
			seedSubscriber(t, "alice@example.com", feedID, mustTimeUTC("2026-07-15 10:00:00"))
			j := &feed.Job{
				DB:   testenv.DB(),
				Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
				Interval: newspaper.EditorialInterval{
					Last: mustTimeUTC("2026-07-15 09:55:00"),
					Next: mustTimeUTC("2026-07-15 10:05:00"),
				},
				NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
				ScrpSvc:      scraper.NewService(stubServerAddr),
			}

			testenv.StubHTTP("feed.test", "/rss", tt.firstFixture)
			if err := j.Do(t.Context()); err != nil {
				t.Fatalf("first poll: job.Do returned an unexpected error: %v", err)
			}

			testenv.StubHTTP("feed.test", "/rss", tt.secondFixture)
			if err := j.Do(t.Context()); err != nil {
				t.Fatalf("second poll: job.Do returned an unexpected error: %v", err)
			}

			if n := scanValOrFatal[int](t, `SELECT count(*) FROM feed_entries`); n != tt.wantEntryCount {
				t.Errorf("got %d feed_entries after re-poll, want %d", n, tt.wantEntryCount)
			}
			if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories`); n != tt.wantStoryCount {
				t.Errorf("got %d stories after re-poll, want %d", n, tt.wantStoryCount)
			}
		})
	}
}

// A feed with no subscribers still gets its item stored as a feed_entry,
// but no story is drafted since there's no one to draft it for.
func TestFeedPolling_NoSubscribers(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_no_subscribers.xml")

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	if n := scanValOrFatal[int](t, `SELECT count(*) FROM feed_entries`); n != 1 {
		t.Errorf("got %d feed_entries, want 1", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories`); n != 0 {
		t.Errorf("got %d stories, want 0", n)
	}
}

// A failure to fetch an item's article page is fail-soft: the entry is
// stored with NULL content and the story is still drafted, and job.Do
// itself returns no error.
func TestFeedPolling_ArticleFetchFails(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	seedSubscriber(t, "alice@example.com", feedID, mustTimeUTC("2026-07-15 10:00:00"))
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_article_fetch_fails.xml")
	// No StubHTTP rule registered for /missing, so the stub server 404s it.

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err != nil {
		t.Errorf("job.Do returned %v, want nil (article fetch failures are fail-soft)", err)
	}

	content := scanValOrFatal[sql.NullString](t, `SELECT content FROM feed_entries WHERE dedup_key = 'fetch-fail'`)
	if content.Valid {
		t.Errorf("want content to stay NULL after a failed article fetch, got %q", content.String)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories`); n != 1 {
		t.Errorf("got %d stories, want 1 (story is queued before the article fetch runs)", n)
	}
}

// A failure to fetch the feed itself (no stub registered, so it 404s) is a
// hard error: job.Do returns an error and nothing is written to
// feed_entries.
func TestFeedPolling_FeedFetchFailure(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	// No StubHTTP rule registered for /rss, so the fetch 404s.

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err == nil {
		t.Error("want an error when the feed itself fails to fetch, got nil")
	}

	if n := scanValOrFatal[int](t, `SELECT count(*) FROM feed_entries`); n != 0 {
		t.Errorf("got %d feed_entries, want 0", n)
	}
}

// A feed with zero items is treated as an error rather than a successful
// no-op poll, and nothing is written to feed_entries.
func TestFeedPolling_EmptyFeed(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_empty_feed.xml")

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err == nil {
		t.Error("want an error for a feed with zero items, got nil")
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM feed_entries`); n != 0 {
		t.Errorf("got %d feed_entries, want 0", n)
	}
}

// A single in-interval item on a feed with multiple subscribers is drafted
// into one story per subscriber.
func TestFeedPolling_MultipleSubscribers(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	feedID := seedFeed(t, "http://feed.test/rss", "Test Feed")
	uidAlice := seedSubscriber(t, "alice@example.com", feedID, mustTimeUTC("2026-07-15 10:00:00"))
	uidBob := seedSubscriber(t, "bob@example.com", feedID, mustTimeUTC("2026-07-15 10:00:00"))
	testenv.StubHTTP("feed.test", "/rss", "./testdata/polling_multiple_subscribers.xml")

	j := &feed.Job{
		DB:   testenv.DB(),
		Feed: feed.FeedRecord{ID: feedID, URL: "http://feed.test/rss", Title: "Test Feed"},
		Interval: newspaper.EditorialInterval{
			Last: mustTimeUTC("2026-07-15 09:55:00"),
			Next: mustTimeUTC("2026-07-15 10:05:00"),
		},
		NewspaperSvc: &newspaper.Service{DB: testenv.DB()},
		ScrpSvc:      scraper.NewService(stubServerAddr),
	}
	if err := j.Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories WHERE user_id = $1`, uidAlice); n != 1 {
		t.Errorf("got %d stories for alice, want 1", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories WHERE user_id = $1`, uidBob); n != 1 {
		t.Errorf("got %d stories for bob, want 1", n)
	}
}
