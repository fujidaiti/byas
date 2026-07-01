package newspaper

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"
)

type Story struct {
	ID          int
	FeedEntryID int
	NewspaperID int
	Title       string
	Description string

	// Source is optional display text indicating where the content of this story comes from;
	// e.g., the feed name for feed-entry-based stories.
	Source string

	// PublishedAt is the optional user-facing date when the associated entry
	// was published. This is not the date when this story was created.
	PublishedAt time.Time
}

func DraftStory(title, description, source string, feedEntryID int, publishedAt time.Time) (Story, error) {
	if title == "" {
		return Story{}, fmt.Errorf("title cannot be empty")
	}
	if feedEntryID <= 0 {
		return Story{}, fmt.Errorf("invalid feed entry ID: %d", feedEntryID)
	}
	s := Story{
		FeedEntryID: feedEntryID,
		Title:       title,
		Description: description,
		PublishedAt: publishedAt,
		Source:      source,
	}
	return s, nil
}

// SubmitStories queues the stories that will be published in the next issue.
// The stories should have valid fields except the ID and NewspaperID.
func SubmitStories(ctx context.Context, ss []Story, db *sql.DB) error {
	if len(ss) == 0 {
		return nil
	}
	var vals []string
	var args []any
	for i, s := range ss {
		desc := sql.NullString{String: s.Description, Valid: s.Description != ""}
		src := sql.NullString{String: s.Source, Valid: s.Source != ""}
		pubDate := sql.NullTime{Time: s.PublishedAt, Valid: !s.PublishedAt.IsZero()}
		k := i * 5
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d, $%d)", k+1, k+2, k+3, k+4, k+5))
		args = append(args, s.Title, desc, src, s.FeedEntryID, pubDate)
	}
	_, err := db.ExecContext(ctx, fmt.Sprintf(`
			INSERT INTO stories (title, description, source, feed_entry_id, published_at)
			VALUES %s;
		`, strings.Join(vals, ",")), args...)
	if err != nil {
		return err
	}
	return nil
}
