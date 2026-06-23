package feed

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"codeberg.org/readeck/go-readability/v2"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/microcosm-cc/bluemonday"
	"github.com/mmcdole/gofeed"
)

type feedRecord struct {
	id  int
	url string
}

type entryRecord struct {
	id          int
	dedupKey    string
	feedId      int
	url         string
	title       string
	description sql.NullString
	publishedAt sql.NullTime
}

type job struct {
	db   *sql.DB
	feed feedRecord
}

func (j *job) Timeout() time.Duration {
	return 30 * time.Second
}

func (j *job) Do(ctx context.Context) error {
	feed, db := j.feed, j.db
	fmt.Println("Fetching feed: ", feed.url)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, feed.url, nil)
	if err != nil {
		return err
	}
	// TODO: Use a custom client
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("Couldn't fetch feed (id=%d)\n", feed.id)
	}
	defer res.Body.Close()

	fp := gofeed.NewParser()
	raw, err := fp.Parse(res.Body)
	if err != nil {
		return err
	}
	if len(raw.Items) == 0 {
		return fmt.Errorf("Feed %d has no items.\n", feed.id)
	}

	fmt.Printf("Got %d entries from %s\n", len(raw.Items), feed.url)

	// TODO: Batch insertions if the feed is too large
	ncols := 7
	vals := make([]string, 0, len(raw.Items))
	args := make([]any, 0, len(raw.Items)*ncols)
	snapshotAt := time.Now()
	for i, item := range raw.Items {
		j := i * ncols
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d, $%d, $%d, $%d)", j+1, j+2, j+3, j+4, j+5, j+6, j+7))
		e := normalizeEntry(item, feed.id)
		args = append(args, e.dedupKey, e.feedId, e.url, e.title, e.description, snapshotAt, e.publishedAt)
	}
	sql := fmt.Sprintf(`
		INSERT INTO entries (dedup_key, feed_id, url, title, description, snapshot_at, published_at)
		VALUES %s
		ON CONFLICT (dedup_key) DO NOTHING
		RETURNING id, dedup_key, feed_id, url, title, description, published_at;
	`, strings.Join(vals, ","))
	rows, err := db.QueryContext(ctx, sql, args...)
	if err != nil {
		return err
	}
	defer rows.Close()

	var newEntries []entryRecord
	for rows.Next() {
		e := entryRecord{}
		err := rows.Scan(&e.id, &e.dedupKey, &e.feedId, &e.url, &e.title, &e.description, &e.publishedAt)
		if err != nil {
			return err
		}
		newEntries = append(newEntries, e)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if len(newEntries) == 0 {
		fmt.Printf("No new entry from %s, skipping.\n", feed.url)
		return nil
	}

	err = writeStories(ctx, newEntries, j.db)
	if err != nil {
		return err
	}

	// TODO: Mark the entry as queued in DB to avoid duplicate jobs for the same entry
	for _, e := range newEntries {
		fmt.Printf("Fetching content for %s\n", e.url)
		st := time.Now()
		err := fetchContent(ctx, e, db)
		if err != nil {
			return err
		}
		// TODO: Respect Crawl-delay in robot.txt
		if dt := time.Since(st); dt < 2*time.Second {
			time.Sleep(time.Second - dt)
		}
	}

	return nil
}

func CollectJobs(ctx context.Context, db *sql.DB) ([]job, error) {
	// TODO: Create an index for next_poll_at column
	rows, err := db.QueryContext(ctx, `
		SELECT id, url
		FROM feeds;
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var jobs []job
	for rows.Next() {
		feed := feedRecord{}
		err := rows.Scan(&feed.id, &feed.url)
		if err != nil {
			return nil, err
		}
		jobs = append(jobs, job{db, feed})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return jobs, nil
}

func normalizeEntry(entry *gofeed.Item, feedId int) entryRecord {
	e := entryRecord{
		feedId: feedId,
		// TODO: Cleanup the link
		url:   entry.Link,
		title: entry.Title,
	}

	// TODO: Sanitize the description
	if desc := entry.Description; len(desc) > 0 {
		e.description.String = desc
		e.description.Valid = true
	}
	if date := entry.PublishedParsed; date != nil {
		e.publishedAt.Time = *date
		e.publishedAt.Valid = true
	}
	if guid := entry.GUID; len(guid) > 0 {
		e.dedupKey = guid
	} else {
		// TODO: Synthesize a guid for this entry
		e.dedupKey = entry.Link
	}

	return e
}

func writeStories(ctx context.Context, entries []entryRecord, db *sql.DB) error {
	var vals []string
	var args []any
	for i, entry := range entries {
		k := i * 4
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d)", k+1, k+2, k+3, k+4))
		args = append(args, entry.id, entry.title, entry.description, entry.publishedAt)
	}
	_, err := db.ExecContext(ctx, fmt.Sprintf(`
			INSERT INTO stories (entry_id, title, description, published_at)
			VALUES %s;
		`, strings.Join(vals, ",")), args...)
	if err != nil {
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

func fetchContent(ctx context.Context, entry entryRecord, db *sql.DB) error {
	entryUrl, err := url.Parse(entry.url)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, entry.url, nil)
	if err != nil {
		return err
	}
	// TODO: Use a custom client
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP GET failed with status code %d", res.StatusCode)
	}
	defer res.Body.Close()

	buf := bluemonday.UGCPolicy().SanitizeReader(res.Body)
	if buf.Len() == 0 {
		return fmt.Errorf("The body is empty.")
	}

	baseUrl := new(*entryUrl)
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

	_, err = db.ExecContext(ctx, `
		UPDATE entries
		SET content = $1, snapshot_at = $2
		WHERE id = $3;
	`, content, time.Now(), entry.id)
	if err != nil {
		return fmt.Errorf("Failed to fetch content.")
	}

	return nil
}
