// TODO: unify distributed web-scraping-related logics and DB tables into this package and single table
package scraper

import (
	"context"
	"net/http"
	"net/url"
)

type Service struct {
	client *httpClient
}

func NewService(httpProxy *url.URL) *Service {
	return &Service{newHttpClient(httpProxy)}
}

func (s *Service) Fetch(ctx context.Context, link url.URL) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, link.String(), nil)
	if err != nil {
		return nil, err
	}
	return s.client.Do(req)
}
