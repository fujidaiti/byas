package feed

import (
	"database/sql"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
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

func RefreshFeeds(db *sql.DB) error {
	// TODO: Create an index for next_poll_at column
	rows, err := db.Query(`
		SELECT id, url
		FROM feeds;
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	var feeds []feedRecord
	for rows.Next() {
		feed := feedRecord{}
		err := rows.Scan(&feed.id, &feed.url)
		if err != nil {
			return err
		}
		feeds = append(feeds, feed)
	}
	if err := rows.Err(); err != nil {
		return err
	}

	if len(feeds) == 0 {
		fmt.Println("No polling is scheduled.")
		return nil
	}

	// TODO: Should i limit the number of go routines?
	wg := sync.WaitGroup{}
	for _, feed := range feeds {
		wg.Add(1)
		go poll(feed, db, &wg)
	}
	wg.Wait()
	return nil
}

func poll(feed feedRecord, db *sql.DB, wg *sync.WaitGroup) {
	defer wg.Done()
	fmt.Println("Fetching feed: ", feed.url)
	// TODO: Use a custom client
	res, err := http.Get(feed.url)
	if err != nil {
		fmt.Println(err)
		return
	}
	if res.StatusCode != http.StatusOK {
		fmt.Printf("Couldn't fetch feed (id=%d)\n", feed.id)
		return
	}
	defer res.Body.Close()

	fp := gofeed.NewParser()
	raw, err := fp.Parse(res.Body)
	if err != nil {
		fmt.Println(err)
		return
	}
	if len(raw.Items) == 0 {
		fmt.Printf("Feed %d has no items.\n", feed.id)
		return
	}

	fmt.Printf("Got %d entries from %s\n", len(raw.Items), feed.url)

	// TODO: Batch insertions if the feed is too large
	ncols := 6
	vals := make([]string, 0, len(raw.Items))
	args := make([]any, 0, len(raw.Items)*ncols)
	for i, item := range raw.Items {
		j := i * ncols
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d, $%d, $%d)", j+1, j+2, j+3, j+4, j+5, j+6))
		e := normalizeEntry(item, feed.id)
		args = append(args, e.dedupKey, e.feedId, e.url, e.title, e.description, e.publishedAt)
	}
	sql := fmt.Sprintf(`
		INSERT INTO entries (dedup_key, feed_id, url, title, description, published_at)
		VALUES %s
		ON CONFLICT (dedup_key) DO NOTHING;
	`, strings.Join(vals, ","))
	_, err = db.Exec(sql, args...)
	if err != nil {
		fmt.Print(err)
	}

	err = refreshEntryContent(feed, db)
	if err != nil {
		fmt.Print(err)
	}
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

func refreshEntryContent(feed feedRecord, db *sql.DB) error {
	rows, err := db.Query(`
		SELECT id, url
		FROM entries
		WHERE feed_id = $1 AND content IS NULL;
	`, feed.id)
	if err != nil {
		return err
	}
	defer rows.Close()

	var entries []entryRecord
	for rows.Next() {
		entry := entryRecord{}
		rows.Scan(&entry.id, &entry.url)
		entries = append(entries, entry)
	}
	if err := rows.Err(); err != nil {
		return err
	}

	for _, entry := range entries {
		fmt.Printf("Fetching content for %s\n", entry.url)
		st := time.Now()
		err := fetchContent(entry, db)
		if err != nil {
			return err
		}
		// TODO: Respect Crawl-delay in robot.txt
		if dt := time.Since(st); dt < time.Second {
			time.Sleep(time.Second - dt)
		}
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

func fetchContent(entry entryRecord, db *sql.DB) error {
	entryUrl, err := url.Parse(entry.url)
	if err != nil {
		return err
	}

	res, err := http.Get(entry.url)
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

	_, err = db.Exec(`
		UPDATE entries
		SET content = $1
		WHERE id = $2;
	`, content, entry.id)
	if err != nil {
		return fmt.Errorf("Failed to fetch content.")
	}

	return nil
}
