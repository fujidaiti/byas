package newspaper_test

import (
	"context"
	"database/sql"
	"fmt"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/db/migration"
	"github.com/fujidaiti/paperdoll/feature/newspaper"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

func TestSubmitStories(t *testing.T) {
	ctx := context.Background()
	pg, err := postgres.Run(ctx,
		"postgres:18-alpine",
		postgres.WithDatabase("test_db"),
		postgres.WithUsername("postgres"),
		postgres.WithPassword("postgres"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).WithStartupTimeout(5*time.Second),
		),
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := pg.Terminate(ctx); err != nil {
			t.Fatalf("Ffailed to terminate Postgres container: %s", err)
		}
	})
	dsn, err := pg.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatal(err)
	}
	db, err := setUpDB(dsn)
	if err != nil {
		t.Fatal(err)
	}
	err = migration.Up(ctx, db)
	if err != nil {
		t.Fatal(err)
	}

	var feedID int
	err = db.QueryRowContext(ctx, `
		INSERT INTO feeds (url, title)
		VALUES ('https://example.com', 'Example Feed')
		RETURNING id;
	`).Scan(&feedID)
	if err != nil {
		t.Fatal(err)
	}
	var entryID int
	err = db.QueryRowContext(ctx, `
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
	err = newspaper.SubmitStories(ctx, []newspaper.Story{story}, db)
	if err != nil {
		t.Fatal(err)
	}
	var id, feID, npID *int
	var title, desc, src *string
	var pubDate *time.Time
	rows, err := db.QueryContext(ctx, `
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
}

func setUpDB(dsn string) (*sql.DB, error) {
	if len(dsn) == 0 {
		return nil, fmt.Errorf("DB_DSN is requried")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		if err2 := db.Close(); err2 != nil {
			fmt.Println(err2)
		}
		return nil, err
	}
	return db, nil
}
