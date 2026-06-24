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
	EntryID     int
	NewspaperID int
	Title       string
	Description string

	// PublishedAt is an optional user-facing date when the associated entry
	// was published. This is not the date when this story is created.
	PublishedAt time.Time
}

func DraftStory(title, description string, entryID int, publishedAt time.Time) (Story, error) {
	if title == "" {
		return Story{}, fmt.Errorf("title cannot be empty")
	}
	if entryID <= 0 {
		return Story{}, fmt.Errorf("invalid entry ID: %d", entryID)
	}
	s := Story{
		EntryID:     entryID,
		Title:       title,
		Description: description,
		PublishedAt: publishedAt,
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
		pubDate := sql.NullTime{Time: s.PublishedAt, Valid: !s.PublishedAt.IsZero()}
		k := i * 4
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d)", k+1, k+2, k+3, k+4))
		args = append(args, s.Title, desc, s.EntryID, pubDate)
	}
	_, err := db.ExecContext(ctx, fmt.Sprintf(`
			INSERT INTO stories (title, description, entry_id, published_at)
			VALUES %s;
		`, strings.Join(vals, ",")), args...)
	if err != nil {
		return err
	}
	return nil
}
