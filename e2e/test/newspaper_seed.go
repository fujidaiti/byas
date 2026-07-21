package test

import (
	"context"
	"database/sql"
)

func seedNewspaperSuit_Today(ctx context.Context, db *sql.DB) error {
	var feedID int
	err := db.QueryRowContext(ctx, `
		INSERT INTO feeds (url, site_url, icon_url, title, description)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (url) DO UPDATE SET url = EXCLUDED.url
		RETURNING id;
	`, "https://example.com/feed", "https://example.com", nil, "Example Feed",
		"This is an example feed. Have fun.").Scan(&feedID)
	if err != nil {
		return err
	}

	var entryID int
	err = db.QueryRowContext(ctx, `
		INSERT INTO feed_entries (dedup_key, feed_id, url, title, description, snapshot_at, published_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id
	`, "https://example.com/blog/greeting", feedID, "https://example.com/blog/hello",
		"Hello there", "This is the first blog post on example.com",
		mustTimeUTC("2026-06-30 12:34:30"), mustTimeUTC("2026-07-01 15:30:12")).Scan(&entryID)
	if err != nil {
		return err
	}

	var paperID int
	err = db.QueryRowContext(ctx, `
		INSERT INTO newspapers (published_at) VALUES ($1) RETURNING id
	`, mustTimeUTC("2026-07-01 13:00:00")).Scan(&paperID)
	if err != nil {
		return err
	}

	_, err = db.ExecContext(ctx, `
		INSERT INTO stories (feed_entry_id, newspaper_id, title, description, published_at, source)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, entryID, paperID, "Hello there", "This is the first blog post on example.com",
		mustTimeUTC("2026-07-01 15:30:12"), "example.com")
	if err != nil {
		return err
	}

	return nil
}
