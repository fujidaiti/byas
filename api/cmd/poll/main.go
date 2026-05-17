package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/mmcdole/gofeed"
)

type Feed struct {
	id  int
	url string
}

func main() {
	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		panic("DB_DSN is required.")
	}

	db, err := sql.Open("pgx", dsn)
	if err != nil {
		panic(err)
	}
	defer db.Close()
	if err := db.Ping(); err != nil {
		panic(err)
	}

	// TODO: Create an index for next_poll_at column
	rows, err := db.Query(`
		SELECT id, url
		FROM feeds;
	`)
	if err != nil {
		panic(err)
	}
	defer rows.Close()

	var feeds []Feed
	for rows.Next() {
		feed := Feed{}
		err := rows.Scan(&feed.id, &feed.url)
		if err != nil {
			panic(err)
		}
		feeds = append(feeds, feed)
	}
	if err := rows.Err(); err != nil {
		panic(err)
	}

	if len(feeds) == 0 {
		fmt.Println("No polling is scheduled.")
		return
	}

	// TODO: Should i limit the number of go routines?
	wg := sync.WaitGroup{}
	for _, feed := range feeds {
		wg.Add(1)
		go poll(feed, db, &wg)
	}
	wg.Wait()
}

func poll(feed Feed, db *sql.DB, wg *sync.WaitGroup) {
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
}

type entryRecord struct {
	dedupKey    string
	feedId      int
	url         string
	title       string
	description sql.NullString
	publishedAt sql.NullTime
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
