//go:build integration

package integration_test

import (
	"database/sql"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/feature/newspaper"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
)

func TestSubmitStories(t *testing.T) {
	testenv.Run(t, func(db *sql.DB) {
		var feedID int
		err := db.QueryRowContext(t.Context(), `
			INSERT INTO feeds (url, title)
			VALUES ('https://example.com', 'Example Feed')
			RETURNING id;
		`).Scan(&feedID)
		if err != nil {
			t.Fatal(err)
		}
		var entryID int
		err = db.QueryRowContext(t.Context(), `
			INSERT INTO feed_entries (dedup_key, feed_id, url, title, snapshot_at)
			VALUES ('https://example.com', $1, 'https://example.com', 'Example Entry', now())
			RETURNING id;
		`, feedID).Scan(&entryID)
		if err != nil {
			t.Fatal(err)
		}

		story := newspaper.Story{
			FeedEntryID: entryID,
			Title:       "Example Entry",
			Source:      "Example Feed",
		}
		err = newspaper.SubmitStories(t.Context(), []newspaper.Story{story}, db)
		if err != nil {
			t.Fatal(err)
		}
		var id, feID, npID *int
		var title, desc, src *string
		var pubDate *time.Time
		rows, err := db.QueryContext(t.Context(), `
			SELECT id, feed_entry_id, newspaper_id, title, description, source, published_at
			FROM stories;
		`)
		if err != nil {
			t.Fatal(err)
		}
		defer rows.Close()
		if !rows.Next() {
			t.Fatal("no story is saved")
		}
		err = rows.Scan(&id, &feID, &npID, &title, &desc, &src, &pubDate)
		if err != nil {
			t.Fatal(err)
		}
		if id == nil {
			t.Error("Expected a non-nil ID, but got nil")
		}
		if feID == nil {
			t.Errorf("Expected to have a feed_entry_id of %d, but got nil", entryID)
		} else if *feID != entryID {
			t.Errorf("Expected to have a feed_entry_id of %d, but got %d", entryID, *feID)
		}
		if npID != nil {
			t.Errorf("Expected a nil newspaper_id, but got %d", *npID)
		}
		if title == nil {
			t.Errorf("Expected a title of %q, but got nil", story.Title)
		} else if *title != story.Title {
			t.Errorf("Expected a title of %q, but got %q", story.Title, *title)
		}
		if desc != nil {
			t.Errorf("Expected a nil description, but got %q", *desc)
		}
		if src == nil {
			t.Errorf("Expected a source of %q, but got nil", story.Source)
		} else if *src != story.Source {
			t.Errorf("Expected a source of %q, but got %q", story.Source, *src)
		}
		if pubDate != nil {
			t.Errorf("Expected a nil published_at, but got %v", *pubDate)
		}
	})
}
