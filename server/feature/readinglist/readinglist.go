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

// SaveWebArticle appends the web article specified by the URL
// to the reading list. Reports nil if succeeds.
//
// Note that this function immediately returns after creating
// a placeholder reading list item. It then tries fetching
// the article itself asynchronously, and fills the placeholders
// with actual metadata.
func SaveWebArticle(ctx context.Context, db *sql.DB, u url.URL) error {
	// TODO: Cleanup URL
	// TODO: Validate URL (schema, host)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var id int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO reading_list_items (kind, title, saved_at)
		VALUES ('web_article', '', now())
		RETURNING id;
	`).Scan(&id)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO reading_list_item_web_article_details (reading_list_item_id, url)
		VALUES ($1, $2);
	`, id, u.String())
	if err != nil {
		return err
	}
	if err = tx.Commit(); err != nil {
		return err
	}

	go func() {
		err := tryFetchWebArticle(db, id, u)
		if err != nil {
			fmt.Println(err)
		}
	}()
	return nil
}

func tryFetchWebArticle(db *sql.DB, id int, u url.URL) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	err := fetchWebArticle(ctx, db, id, u)
	if err == nil {
		return nil
	}
	ctx, cancel = context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, dbErr := db.ExecContext(ctx, `
		UPDATE reading_list_item_web_article_details
		SET fetch_status = 'failed'
		WHERE reading_list_item_id = $1;
	`, id)
	if dbErr != nil {
		return errors.Join(err, dbErr)
	}
	return err
}

// TODO: DRY scraping logic
func fetchWebArticle(ctx context.Context, db *sql.DB, id int, u url.URL) error {
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
	_, err = tx.ExecContext(ctx, `
		UPDATE reading_list_items
		SET title = $1
		WHERE id = $2;
	`, article.Title(), id)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		UPDATE reading_list_item_web_article_details
		SET content = $1, fetch_status = 'done'
		WHERE reading_list_item_id = $2;
	`, content, id)
	if err != nil {
		return err
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
