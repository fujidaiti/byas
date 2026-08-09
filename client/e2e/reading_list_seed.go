package main

import (
	"context"
	"database/sql"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/readinglist"
	"github.com/fujidaiti/paperdoll/server/feature/scraper"
	"github.com/fujidaiti/paperdoll/server/feature/user"
)

func seedReadingListSuit_Item(ctx context.Context, db *sql.DB) error {
	token, err := provisionTestAccount(ctx, db)
	if err != nil {
		return err
	}

	svc := &user.Service{DB: db, Now: time.Now}
	uid, err := svc.VerifyAuthToken(ctx, token.Encode())
	if err != nil {
		return err
	}

	var feedID int
	err = db.QueryRowContext(ctx, `
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

	_, err = db.ExecContext(ctx, `
		INSERT INTO reading_list_items (kind, feed_entry_id, title, description, saved_at, user_id)
		VALUES ('feed_entry', $1, $2, $3, $4, $5)
	`, entryID, "Hello there", "This is the first blog post on example.com",
		mustTimeUTC("2026-07-01 15:31:00"), uid)
	if err != nil {
		return err
	}

	return nil
}

// seedReadingListSuit_WebClip saves a single, already fetched web clip to the
// reading list. The clip row is inserted directly because no service creates a
// bare clip: [readinglist.Service.SaveWebClip] fetches the page in a background
// goroutine, so seeding through it would have to poll for the fetch to finish.
// The list item itself goes through the real service, which copies the clip's
// title and description onto it.
func seedReadingListSuit_WebClip(ctx context.Context, db *sql.DB) error {
	token, err := provisionTestAccount(ctx, db)
	if err != nil {
		return err
	}

	svc := &user.Service{DB: db, Now: time.Now}
	uid, err := svc.VerifyAuthToken(ctx, token.Encode())
	if err != nil {
		return err
	}

	clipID, err := insertWebClip(ctx, db)
	if err != nil {
		return err
	}

	rl := readinglist.NewService(db, scraper.NewService(stubServerAddr))
	_, err = rl.SaveWebClipByID(ctx, uid, clipID)
	return err
}

// seedReadingListSuit_Archived archives one item of each kind, so the reading
// list is empty and the archived list holds both a feed entry and a web clip.
func seedReadingListSuit_Archived(ctx context.Context, db *sql.DB) error {
	token, err := provisionTestAccount(ctx, db)
	if err != nil {
		return err
	}

	svc := &user.Service{DB: db, Now: time.Now}
	uid, err := svc.VerifyAuthToken(ctx, token.Encode())
	if err != nil {
		return err
	}

	var feedID int
	err = db.QueryRowContext(ctx, `
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

	clipID, err := insertWebClip(ctx, db)
	if err != nil {
		return err
	}

	rl := readinglist.NewService(db, scraper.NewService(stubServerAddr))
	entryItem, err := rl.SaveFeedEntry(ctx, uid, entryID)
	if err != nil {
		return err
	}
	clipItem, err := rl.SaveWebClipByID(ctx, uid, clipID)
	if err != nil {
		return err
	}
	if err := rl.ArchiveItem(ctx, uid, entryItem.ID); err != nil {
		return err
	}
	return rl.ArchiveItem(ctx, uid, clipItem.ID)
}

// insertWebClip inserts a clip that has already been fetched, and returns its
// ID. fetch_status must be 'done' together with a non-NULL content to satisfy
// the chk_content_when_done constraint.
func insertWebClip(ctx context.Context, db *sql.DB) (int, error) {
	var id int
	err := db.QueryRowContext(ctx, `
		INSERT INTO web_clips (url, title, description, content, fetch_status)
		VALUES ($1, $2, $3, $4, 'done')
		RETURNING id;
	`, "https://example.com/clips/agents", "Building effective agents",
		"Patterns that hold up outside a demo.",
		`<article><p>The most successful agents aren't built on complex frameworks. `+
			`They're built on simple, composable patterns.</p></article>`).Scan(&id)
	return id, err
}
