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
	ID int
	FeedAttrs
}

type FeedAttrs struct {
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
	// TODO: Check if the f already exists first
	// TODO: Validate and cleanup the url (check schema, remove tracking params, etc.)
	var f Feed
	if a, err := fetchFeed(ctx, fu); err != nil {
		fmt.Println(err)
		return Feed{}, err
	} else {
		f = Feed{FeedAttrs: a}
	}
	var su, iu, desc sql.NullString
	if u := f.IconURL; u != nil {
		su = sql.NullString{String: u.String(), Valid: true}
	}
	if u := f.IconURL; u != nil {
		su = sql.NullString{String: u.String(), Valid: true}
	}
	if d := f.Description; d != nil {
		desc = sql.NullString{String: *d, Valid: true}
	}
	err := db.QueryRowContext(ctx, `
		INSERT INTO feeds (url, site_url, icon_url, title, description)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (url) DO UPDATE SET url = EXCLUDED.url
		RETURNING id;
	`, f.URL.String(), su, iu, f.Title, desc).Scan(&f.ID)
	if err != nil {
		return Feed{}, err
	}
	return f, nil
}

// SearchFeeds searchs subscriptable feeds by the given query.
func SearchFeeds(ctx context.Context, query string) ([]FeedAttrs, error) {
	// TODO: Accept arbitrary keywards as a query
	// TODO: Validate and cleanup the url (check schema, remove tracking params, etc.)
	u, err := url.Parse(query)
	if err != nil {
		return []FeedAttrs{}, nil
	}
	a, err := fetchFeed(ctx, *u)
	if err != nil {
		return nil, err
	}
	return []FeedAttrs{a}, nil
}

func fetchFeed(ctx context.Context, fu url.URL) (FeedAttrs, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fu.String(), nil)
	if err != nil {
		return FeedAttrs{}, err
	}
	// TODO: Use a custom client to mitigate SSRF attacks (+ timeout)
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return FeedAttrs{}, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return FeedAttrs{}, fmt.Errorf("Failed to fetch feed: %s", fu.String())
	}
	// TODO: Limit body size
	raw, err := gofeed.NewParser().Parse(res.Body)
	if err != nil {
		return FeedAttrs{}, err
	}

	a := FeedAttrs{URL: fu, Title: raw.Title}
	if raw.Link != "" {
		if u, err := url.Parse(raw.Link); err == nil {
			a.SiteURL = u
		}
	}
	if raw.Image != nil && raw.Image.URL != "" {
		if u, err := url.Parse(raw.Image.URL); err == nil {
			a.IconURL = u
		}
	}
	if raw.Description != "" {
		a.Description = &raw.Description
	}
	return a, nil
}
