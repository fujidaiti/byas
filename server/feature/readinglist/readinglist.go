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
// TODO: Garbage-collect orphaned web articles in the background. Deleting the
// join row here leaves the backing web_articles row unreachable (it can only be
// reached via a reading_list_items row), so a background job should periodically
// delete web_articles that have no referencing reading_list_items.
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

func SaveFeedEntry(ctx context.Context, db *sql.DB, id int) error {
	err := db.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, feed_entry_id, title, description)
		SELECT 'feed_entry', id, title, description
		FROM feed_entries
		WHERE id = $1
		RETURNING id;
	`, id).Scan(new(int))
	// TODO: Return a dedicated error for the case where the id doesn't exist
	return err
}

// SaveWebArticleByID re-saves an existing web article to the reading list by its
// id, re-attaching its row without re-fetching. Used when re-saving an article
// that was just unsaved from the reader (the web_articles row survives an
// unsave, since DeleteItem removes only the join row).
func SaveWebArticleByID(ctx context.Context, db *sql.DB, id int) error {
	// reading_list_items.title is NOT NULL but web_articles.title is nullable,
	// so coalesce to keep the placeholder well-formed.
	err := db.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, web_article_id, title, description)
		SELECT 'web_article', id, COALESCE(title, ''), description
		FROM web_articles
		WHERE id = $1
		RETURNING id;
	`, id).Scan(new(int))
	// TODO: Return a dedicated error for the case where the id doesn't exist
	return err
}

// SaveWebArticle appends the web article specified by the URL to the reading list.
// Reports nil if succeeds.
//
// Note that this function immediately returns after creating a placeholder reading list item.
// It then tries fetching the article itself asynchronously, and fills the placeholders with actual metadata.
func SaveWebArticle(ctx context.Context, db *sql.DB, u url.URL, title string) error {
	// TODO: Cleanup URL
	// TODO: Validate URL (schema, host)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var aID int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO web_articles (url)
		VALUES ($1)
		RETURNING id;
	`, u.String()).Scan(&aID)
	if err != nil {
		return err
	}
	var rID int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, web_article_id, title)
		VALUES ('web_article', $1, $2)
		RETURNING id;
	`, aID, title).Scan(&rID)
	if err != nil {
		return err
	}
	if err = tx.Commit(); err != nil {
		return err
	}

	go func() {
		// TODO: Recover from panic
		err := tryFetchWebArticle(db, rID, aID, u)
		if err != nil {
			fmt.Println(err)
		}
	}()
	return nil
}

func tryFetchWebArticle(db *sql.DB, rID, aID int, u url.URL) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	err := fetchWebArticle(ctx, db, rID, aID, u)
	if err == nil {
		return nil
	}
	ctx, cancel = context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, dbErr := db.ExecContext(ctx, `
		UPDATE web_articles
		SET fetch_status = 'failed'
		WHERE id = $1;
	`, aID)
	if dbErr != nil {
		return errors.Join(err, dbErr)
	}
	return err
}

// TODO: DRY scraping logic
func fetchWebArticle(ctx context.Context, db *sql.DB, rID, aID int, u url.URL) error {
	fmt.Printf("Fetching reading list article from %s\n", u.String())
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return err
	}
	// TODO: Use a custom client
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP GET failed with status code %d", res.StatusCode)
	}

	buf := bluemonday.UGCPolicy().AllowElements("head", "title").SanitizeReader(res.Body)
	if buf.Len() == 0 {
		return fmt.Errorf("The body is empty.")
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
		return fmt.Errorf("Failed to extract content.")
	}
	content := fmt.Sprintf(contentTemplate, buf)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
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
			UPDATE web_articles
			SET title = $1, content = $2, fetch_status = 'done'
			WHERE id = $3;
		`, t, content, aID)
		if err != nil {
			return err
		}
	} else {
		_, err = tx.ExecContext(ctx, `
			UPDATE web_articles
			SET content = $1, fetch_status = 'done'
			WHERE id = $2;
		`, content, aID)
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
