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
	"github.com/fujidaiti/paperdoll/server/feature/newspaper"
	"github.com/fujidaiti/paperdoll/server/feature/scraper"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/microcosm-cc/bluemonday"
	"github.com/mmcdole/gofeed"
)

type feedRecord struct {
	id    int
	url   string
	title string
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
	db           *sql.DB
	feed         feedRecord
	interval     newspaper.EditorialInterval
	newspaperSvc *newspaper.Service
	scrpSvc      *scraper.Service
}

func (j *job) Timeout() time.Duration {
	return 30 * time.Second
}

func (j *job) Do(ctx context.Context) error {
	feed, db := j.feed, j.db
	fmt.Println("Fetching feed: ", feed.url)

	link, err := url.Parse(feed.url)
	if err != nil {
		return err
	}
	res, err := j.scrpSvc.Fetch(ctx, *link)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("couldn't fetch feed (id=%d)", feed.id)
	}
	defer func() {
		if err := res.Body.Close(); err != nil {
			fmt.Println(err)
		}
	}()

	fp := gofeed.NewParser()
	raw, err := fp.Parse(res.Body)
	if err != nil {
		return err
	}
	if len(raw.Items) == 0 {
		return fmt.Errorf("feed %d has no items", feed.id)
	}

	fmt.Printf("Got %d entries from %s\n", len(raw.Items), feed.url)

	// TODO: Batch insertions if the feed is too large
	ncols := 7
	vals := make([]string, 0, len(raw.Items))
	args := make([]any, 0, len(raw.Items)*ncols)
	snapshotAt := time.Now()
	for i, item := range raw.Items {
		j := i * ncols
		vals = append(
			vals,
			fmt.Sprintf("($%d, $%d, $%d, $%d, $%d, $%d, $%d)", j+1, j+2, j+3, j+4, j+5, j+6, j+7),
		)
		e := normalizeEntry(item, feed.id)
		args = append(
			args, e.dedupKey, e.feedId, e.url, e.title, e.description, snapshotAt, e.publishedAt,
		)
	}
	sql := fmt.Sprintf(`
		INSERT INTO feed_entries (dedup_key, feed_id, url, title, description, snapshot_at, published_at)
		VALUES %s
		ON CONFLICT (dedup_key) DO NOTHING
		RETURNING id, dedup_key, feed_id, url, title, description, published_at;
	`, strings.Join(vals, ","))
	rows, err := db.QueryContext(ctx, sql, args...)
	if err != nil {
		return err
	}
	defer func() {
		if err := rows.Close(); err != nil {
			fmt.Println(err)
		}
	}()

	var newEntries []entryRecord
	for rows.Next() {
		e := entryRecord{}
		err := rows.Scan(
			&e.id,
			&e.dedupKey,
			&e.feedId,
			&e.url,
			&e.title,
			&e.description,
			&e.publishedAt,
		)
		if err != nil {
			// TODO: Make this case fail-soft instead of exiting.
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

	var entriesToBeStories []entryRecord
	// TODO: Mark the entry as queued in DB to avoid duplicate jobs for the same entry
	for _, e := range newEntries {
		if e.publishedAt.Valid && j.interval.Contains(e.publishedAt.Time) {
			entriesToBeStories = append(entriesToBeStories, e)
			fmt.Printf("Fetching content for %s\n", e.url)
			st := time.Now()
			err := fetchContent(ctx, j.scrpSvc, e, db)
			if err != nil {
				fmt.Print(err)
			}
			// TODO: Respect Crawl-delay in robot.txt
			if dt := time.Since(st); dt < 2*time.Second {
				time.Sleep(time.Second - dt)
			}
		}
	}

	err = writeStories(ctx, j.newspaperSvc, feed, entriesToBeStories)
	if err != nil {
		fmt.Printf("Something went wrong while writing stories: %s\n", err)
	}

	return nil
}

func CollectJobs(
	ctx context.Context,
	db *sql.DB,
	newspaperSvc *newspaper.Service,
	scrpSvc *scraper.Service,
) ([]job, error) {
	ei, err := newspaper.FindEditorialInterval(ctx, db, time.Now())
	if err != nil {
		fmt.Print(err)
		// Fail-soft: we don't exit here.
	}
	// TODO: Create an index for next_poll_at column
	rows, err := db.QueryContext(ctx, `
		SELECT id, url, title
		FROM feeds;
	`)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err := rows.Close(); err != nil {
			fmt.Println(err)
		}
	}()

	var jobs []job
	for rows.Next() {
		feed := feedRecord{}
		err := rows.Scan(&feed.id, &feed.url, &feed.title)
		if err != nil {
			return nil, err
		}
		jobs = append(jobs, job{db, feed, ei, newspaperSvc, scrpSvc})
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

func writeStories(ctx context.Context, svc *newspaper.Service, f feedRecord, es []entryRecord) error {
	var ss []newspaper.Story
	for _, e := range es {
		var pubDate time.Time
		if e.publishedAt.Valid {
			pubDate = e.publishedAt.Time
		}
		var desc string
		if e.description.Valid {
			desc = e.description.String
		}
		s, err := newspaper.DraftStory(e.title, desc, f.title, e.id, pubDate)
		if err != nil {
			fmt.Printf("Cannot write a story from this entry ID=%d. Skipping.\n", e.id)
		} else {
			ss = append(ss, s)
		}
	}
	if len(ss) == 0 {
		return nil
	}
	return svc.SubmitStories(ctx, ss)
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

func fetchContent(ctx context.Context, scrp *scraper.Service, entry entryRecord, db *sql.DB) error {
	entryUrl, err := url.Parse(entry.url)
	if err != nil {
		return err
	}

	res, err := scrp.Fetch(ctx, *entryUrl)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP GET failed with status code %d", res.StatusCode)
	}
	defer func() {
		if err := res.Body.Close(); err != nil {
			fmt.Println(err)
		}
	}()

	buf := bluemonday.UGCPolicy().SanitizeReader(res.Body)
	if buf.Len() == 0 {
		return fmt.Errorf("the body is empty")
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
		return fmt.Errorf("failed to extract content")
	}
	content := fmt.Sprintf(contentTemplate, buf)

	_, err = db.ExecContext(ctx, `
		UPDATE feed_entries
		SET content = $1, snapshot_at = $2
		WHERE id = $3;
	`, content, time.Now(), entry.id)
	if err != nil {
		return fmt.Errorf("failed to fetch content")
	}

	return nil
}
