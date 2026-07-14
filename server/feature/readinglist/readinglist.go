package readinglist

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"codeberg.org/readeck/go-readability/v2"
	"github.com/microcosm-cc/bluemonday"
)

// DeleteItem removes an item from the list.
// Reports false with no error if the id does not exist, true otherwise.
//
// TODO: Garbage-collect orphaned web clips in the background. Deleting the
// join row here leaves the backing web_clips row unreachable (it can only be
// reached via a reading_list_items row), so a background job should periodically
// delete web_clips that have no referencing reading_list_items.
func DeleteItem(ctx context.Context, db *sql.DB, id int) (bool, error) {
	res, err := db.ExecContext(ctx, `
		DELETE FROM reading_list_items
		WHERE id = $1;
	`, id)
	if err != nil {
		return false, err
	}
	if n, err := res.RowsAffected(); err != nil {
		return false, err
	} else {
		return n != 0, nil
	}
}

func ArchiveItem(ctx context.Context, db *sql.DB, id int) error {
	return setItemArchivedStatus(ctx, db, id, true)
}

func UnarchiveItem(ctx context.Context, db *sql.DB, id int) error {
	return setItemArchivedStatus(ctx, db, id, false)
}

func setItemArchivedStatus(ctx context.Context, db *sql.DB, id int, s bool) error {
	res, err := db.ExecContext(ctx, `
		UPDATE reading_list_items
		SET archived = $1
		WHERE id = $2;
	`, s, id)
	if err != nil {
		return err
	}
	if n, err := res.RowsAffected(); err != nil {
		return nil
	} else if n == 0 {
		return errors.New("item not found")
	}
	return nil
}

// SavedItem is the reading list item created by a save operation.
type SavedItem struct {
	ID          int
	ResourceID  int
	Kind        string
	Title       string
	Description *string
	SavedAt     time.Time
}

func SaveFeedEntry(ctx context.Context, db *sql.DB, id int) (SavedItem, error) {
	var it SavedItem
	err := db.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, feed_entry_id, title, description)
		SELECT 'feed_entry', id, title, description
		FROM feed_entries
		WHERE id = $1
		RETURNING id, feed_entry_id, kind, title, description, saved_at;
	`, id).Scan(&it.ID, &it.ResourceID, &it.Kind, &it.Title, &it.Description, &it.SavedAt)
	// TODO: Return a dedicated error for the case where the id doesn't exist
	return it, err
}

func SaveWebClipByID(ctx context.Context, db *sql.DB, id int) (SavedItem, error) {
	// reading_list_items.title is NOT NULL but web_clips.title is nullable,
	// so coalesce to keep the placeholder well-formed.
	var it SavedItem
	err := db.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, web_clip_id, title, description)
		SELECT 'web_clip', id, COALESCE(title, ''), description
		FROM web_clips
		WHERE id = $1
		RETURNING id, web_clip_id, kind, title, description, saved_at;
	`, id).Scan(&it.ID, &it.ResourceID, &it.Kind, &it.Title, &it.Description, &it.SavedAt)
	// TODO: Return a dedicated error for the case where the id doesn't exist
	return it, err
}

// SaveWebClip adds a web clip specified by the URL to the reading list.
// Reports nil if succeeds.
//
// Note that this function immediately returns after creating a placeholder reading list item.
// It then tries fetching the clip itself asynchronously, and fills the placeholders with actual metadata.
func SaveWebClip(ctx context.Context, db *sql.DB, u url.URL, title string) (SavedItem, error) {
	// TODO: Cleanup URL
	// TODO: Validate URL (schema, host)
	var it SavedItem
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return it, err
	}
	defer func() {
		if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
			fmt.Println(err)
		}
	}()
	var clipID int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO web_clips (url)
		VALUES ($1)
		RETURNING id;
	`, u.String()).Scan(&clipID)
	if err != nil {
		return it, err
	}
	err = tx.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, web_clip_id, title)
		VALUES ('web_clip', $1, $2)
		RETURNING id, web_clip_id, kind, title, description, saved_at;
	`, clipID, title).Scan(&it.ID, &it.ResourceID, &it.Kind, &it.Title, &it.Description, &it.SavedAt)
	if err != nil {
		return it, err
	}
	if err = tx.Commit(); err != nil {
		return it, err
	}
	go func() {
		// TODO: Recover from panic
		err := tryFetchWebClip(db, it.ID, clipID, u)
		if err != nil {
			fmt.Println(err)
		}
	}()
	return it, nil
}

func tryFetchWebClip(db *sql.DB, rID, clipID int, u url.URL) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	err := fetchWebClip(ctx, db, rID, clipID, u)
	if err == nil {
		return nil
	}
	ctx, cancel = context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, dbErr := db.ExecContext(ctx, `
		UPDATE web_clips
		SET fetch_status = 'failed'
		WHERE id = $1;
	`, clipID)
	if dbErr != nil {
		return errors.Join(err, dbErr)
	}
	return err
}

// TODO: DRY scraping logic
func fetchWebClip(ctx context.Context, db *sql.DB, rID, clipID int, u url.URL) error {
	fmt.Printf("Fetching reading list clip from %s\n", u.String())
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return err
	}
	// TODO: Use a custom client
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer func() {
		if err := res.Body.Close(); err != nil {
			fmt.Println(err)
		}
	}()
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP GET failed with status code %d", res.StatusCode)
	}

	buf := bluemonday.UGCPolicy().AllowElements("head", "title").SanitizeReader(res.Body)
	if buf.Len() == 0 {
		return fmt.Errorf("the body is empty")
	}

	baseUrl := new(u)
	baseUrl.Path = ""
	baseUrl.RawPath = ""
	baseUrl.Fragment = ""
	baseUrl.RawFragment = ""
	baseUrl.RawQuery = ""
	baseUrl.User = nil

	article, err := readability.FromReader(buf, baseUrl)
	if err != nil {
		return err
	}

	buf.Reset()
	err = article.RenderHTML(buf)
	if err != nil {
		return err
	}
	if buf.Len() == 0 {
		return fmt.Errorf("failed to extract content")
	}
	content := fmt.Sprintf(contentTemplate, buf)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() {
		if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
			fmt.Println(err)
		}
	}()
	// Only overwrite the title when the fetch actually extracted one; otherwise
	// keep the existing (placeholder) title rather than clobbering it with ''.
	if t := article.Title(); t != "" {
		_, err = tx.ExecContext(ctx, `
			UPDATE reading_list_items
			SET title = $1
			WHERE id = $2;
		`, t, rID)
		if err != nil {
			return err
		}
		_, err = tx.ExecContext(ctx, `
			UPDATE web_clips
			SET title = $1, content = $2, fetch_status = 'done'
			WHERE id = $3;
		`, t, content, clipID)
		if err != nil {
			return err
		}
	} else {
		_, err = tx.ExecContext(ctx, `
			UPDATE web_clips
			SET content = $1, fetch_status = 'done'
			WHERE id = $2;
		`, content, clipID)
		if err != nil {
			return err
		}
	}
	if err := tx.Commit(); err != nil {
		return err
	}

	return nil
}

const contentTemplate = `
<!DOCTYPE html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
%s
</body>
</html>
`
