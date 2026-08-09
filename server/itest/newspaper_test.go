//go:build integration

package itest

import (
	"fmt"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/newspaper"
	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
)

// seedSchedule registers a newspaper_schedules row at the given local
// clock time (only the time-of-day component matters; minute_of_date is
// relative to at's own local midnight, matching schedule.go's own calc).
//
// TODO: refactor to use a domain function once per-user schedule is supported
func seedSchedule(t *testing.T, label string, at time.Time) {
	t.Helper()
	local := at.Local()
	midnight := time.Date(local.Year(), local.Month(), local.Day(), 0, 0, 0, 0, time.Local)
	execOrFatal(t, `
		INSERT INTO newspaper_schedules (label, minute_of_date) VALUES ($1, $2)
	`, label, int(local.Sub(midnight).Minutes()))
}

// seedClaimableStory inserts a minimal feed and feed entry, bypassing feed
// polling since these tests only care about story claiming during newspaper
// assembly, then drafts and submits an unclaimed story (newspaper_id IS
// NULL) owned by uid through the real domain functions in story.go.
func seedClaimableStory(t *testing.T, uid user.UserID) {
	t.Helper()
	feedID := scanValOrFatal[int](t, `
		INSERT INTO feeds (url, title) VALUES ($1, $2) RETURNING id
	`, fmt.Sprintf("http://feed-%d.test/rss", uid), "Test Feed")
	entryID := scanValOrFatal[int](t, `
		INSERT INTO feed_entries (dedup_key, feed_id, url, title, snapshot_at)
		VALUES ($1, $2, $3, $4, $5) RETURNING id
	`, fmt.Sprintf("story-seed-%d", uid), feedID, fmt.Sprintf("http://feed-%d.test/entry", uid), "Test Entry", time.Now())

	s := must(newspaper.DraftStory(uid, "Test Story", "", "Test Feed", entryID, time.Time{}))
	svc := newspaper.Service{DB: testenv.DB()}
	if err := svc.SubmitStories(t.Context(), []newspaper.Story{s}); err != nil {
		t.Fatalf("SubmitStories returned an unexpected error: %v", err)
	}
}

// CollectJobs creates exactly one newspaper (and job) per registered user,
// all at the same shared schedule time, since per-user schedules don't
// exist yet.
func TestNewspaperCollectJobs_OneJobPerUser(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	now := time.Now()
	uidAlice := seedUser(t, "alice@example.com", now)
	uidBob := seedUser(t, "bob@example.com", now)
	seedSchedule(t, "before", now.Add(-2*time.Minute))
	seedSchedule(t, "after", now.Add(3*time.Minute))

	jobs, err := newspaper.CollectJobs(t.Context(), testenv.DB())
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 2 {
		t.Fatalf("got %d jobs, want 2", len(jobs))
	}

	for _, uid := range []user.UserID{uidAlice, uidBob} {
		if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers WHERE user_id = $1`, uid); n != 1 {
			t.Errorf("got %d newspapers for user %d, want 1", n, uid)
		}
	}
}

// CollectJobs returns no jobs when there are no users to issue newspapers for.
func TestNewspaperCollectJobs_NoUsers(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	now := time.Now()
	seedSchedule(t, "before", now.Add(-2*time.Minute))
	seedSchedule(t, "after", now.Add(3*time.Minute))

	jobs, err := newspaper.CollectJobs(t.Context(), testenv.DB())
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 0 {
		t.Errorf("got %d jobs, want 0", len(jobs))
	}
}

// A user who already has a newspaper for the current schedule tick is
// skipped, without blocking newspaper creation for other users.
func TestNewspaperCollectJobs_SkipsUserWithExistingNewspaper(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	now := time.Now()
	seedSchedule(t, "before", now.Add(-2*time.Minute))
	seedSchedule(t, "after", now.Add(3*time.Minute))

	// Alice already has a newspaper for the upcoming schedule tick: run
	// CollectJobs for her alone first, before bob is registered.
	uidAlice := seedUser(t, "alice@example.com", now)
	if _, err := newspaper.CollectJobs(t.Context(), testenv.DB()); err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}

	uidBob := seedUser(t, "bob@example.com", now)
	jobs, err := newspaper.CollectJobs(t.Context(), testenv.DB())
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 1 {
		t.Fatalf("got %d jobs, want 1 (only bob's)", len(jobs))
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers WHERE user_id = $1`, uidBob); n != 1 {
		t.Errorf("got %d newspapers for bob, want 1", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers WHERE user_id = $1`, uidAlice); n != 1 {
		t.Errorf("got %d newspapers for alice, want still 1 (no duplicate)", n)
	}
}

// Running one user's job claims only that user's unclaimed stories, leaving
// the other user's stories and newspaper untouched.
func TestNewspaperAssemble_ScopesStoriesByUser(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	now := time.Now()
	uidAlice := seedUser(t, "alice@example.com", now)
	uidBob := seedUser(t, "bob@example.com", now)
	seedSchedule(t, "before", now.Add(-2*time.Minute))
	seedSchedule(t, "after", now.Add(3*time.Minute))
	seedClaimableStory(t, uidAlice)
	seedClaimableStory(t, uidBob)

	jobs, err := newspaper.CollectJobs(t.Context(), testenv.DB())
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 2 {
		t.Fatalf("got %d jobs, want 2", len(jobs))
	}

	// Run only one of the two jobs. Which user it belongs to doesn't matter:
	// the assertions below only rely on exactly one user's data changing.
	if err := jobs[0].Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories WHERE newspaper_id IS NOT NULL`); n != 1 {
		t.Errorf("got %d claimed stories, want exactly 1 (only the processed user's story)", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM stories WHERE newspaper_id IS NULL`); n != 1 {
		t.Errorf("got %d unclaimed stories, want exactly 1 (the other user's story untouched)", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers WHERE draft = FALSE`); n != 1 {
		t.Errorf("got %d published newspapers, want exactly 1", n)
	}
	if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers WHERE draft = TRUE`); n != 1 {
		t.Errorf("got %d draft newspapers, want exactly 1 (the other user's newspaper untouched)", n)
	}
}

// A user with no unclaimed stories at assembly time gets their draft
// newspaper row cleaned up rather than published empty.
func TestNewspaperAssemble_NoStoriesCleansUpNewspaper(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	now := time.Now()
	seedUser(t, "alice@example.com", now)
	seedSchedule(t, "before", now.Add(-2*time.Minute))
	seedSchedule(t, "after", now.Add(3*time.Minute))

	jobs, err := newspaper.CollectJobs(t.Context(), testenv.DB())
	if err != nil {
		t.Fatalf("CollectJobs returned an unexpected error: %v", err)
	}
	if len(jobs) != 1 {
		t.Fatalf("got %d jobs, want 1", len(jobs))
	}

	if err := jobs[0].Do(t.Context()); err != nil {
		t.Fatalf("job.Do returned an unexpected error: %v", err)
	}

	if n := scanValOrFatal[int](t, `SELECT count(*) FROM newspapers`); n != 0 {
		t.Errorf("got %d newspapers, want 0 (cleaned up after finding no stories)", n)
	}
}
