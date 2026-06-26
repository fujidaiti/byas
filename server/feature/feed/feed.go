package feed

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"net/url"

	"github.com/mmcdole/gofeed"
)

type Feed struct {
	ID          int
	URL         url.URL
	SiteURL     *url.URL
	IconURL     *url.URL
	Title       string
	Description *string
}

// Subscribe registers a web feed by its URL.
// Feeds are identified by URL and this operation is idempotent;
// subscribing to the same feed (URL) twice has no additional effect.
func Subscribe(ctx context.Context, db *sql.DB, fu url.URL) (Feed, error) {
	// TODO: Validate and cleanup the url (check schema, remove tracking params, etc.)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fu.String(), nil)
	if err != nil {
		return Feed{}, err
	}
	// TODO: Use a custom client to mitigate SSRF attacks (+ timeout)
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return Feed{}, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return Feed{}, fmt.Errorf("Failed to fetch feed: %s", fu.String())
	}
	// TODO: Limit body size
	raw, err := gofeed.NewParser().Parse(res.Body)
	if err != nil {
		return Feed{}, err
	}

	// TODO: Check if the feed already exists first
	feed := Feed{URL: fu, Title: raw.Title}
	var su, iu, desc sql.NullString
	if raw.Link != "" {
		u, err := url.Parse(raw.Link)
		if err == nil {
			feed.SiteURL = u
			su = sql.NullString{String: raw.Link, Valid: true}
		}
	}
	if raw.Image != nil && raw.Image.URL != "" {
		u, err := url.Parse(raw.Image.URL)
		if err == nil {
			feed.IconURL = u
			iu = sql.NullString{String: raw.Image.URL, Valid: true}
		}
	}
	if raw.Description != "" {
		feed.Description = &raw.Description
		desc = sql.NullString{String: raw.Description, Valid: true}
	}
	err = db.QueryRowContext(ctx, `
		INSERT INTO feeds (url, site_url, icon_url, title, description)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (url) DO UPDATE SET url = EXCLUDED.url
		RETURNING id;
	`, feed.URL.String(), su, iu, feed.Title, desc).Scan(&feed.ID)
	if err != nil {
		return Feed{}, err
	}
	return feed, nil
}
