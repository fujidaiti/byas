package api

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"

	"github.com/fujidaiti/paperdoll/feature/feed"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func StartServer(ctx context.Context) {
	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		panic("DB_DSN is requried.")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		panic(err)
	}
	defer func() {
		fmt.Println("Closing DB...")
		if err := db.Close(); err != nil {
			fmt.Println(err)
		}
	}()
	if err := db.Ping(); err != nil {
		panic(err)
	}

	h := &handler{db}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", h.getHealth)
	mux.HandleFunc("GET /newspapers/today", h.getTodaysNewspaper)
	mux.HandleFunc("GET /newspapers/stories/{id}", h.getStory)
	mux.HandleFunc("GET /feeds", h.getFeeds)
	mux.HandleFunc("PUT /feeds", h.subscribeToFeed)
	mux.HandleFunc("GET /feeds/entries/{id}", h.getFeedEntry)

	srv := http.Server{
		Addr:    ":8080",
		Handler: mux,
		// Slowloris attack prevention
		ReadHeaderTimeout: 5 * time.Second,
		BaseContext:       func(_ net.Listener) context.Context { return ctx },
	}
	defer func() {
		fmt.Println("Shutting down API server...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := srv.Shutdown(ctx); err != nil {
			fmt.Println("Graceful shutdown failed:")
			fmt.Println(err)
		}
	}()

	c := make(chan error, 1)
	go func() {
		fmt.Printf("API server started on %s\n", srv.Addr)
		err := srv.ListenAndServe()
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			c <- err
		}
	}()

	select {
	case <-ctx.Done():
	case err := <-c:
		fmt.Println(err)
	}
}

type handler struct {
	db *sql.DB
}

func (h *handler) getHealth(w http.ResponseWriter, _ *http.Request) {
	w.Write([]byte("Feeling good!"))
}

type getTodaysNewspaperResponse struct {
	ID          int       `json:"id"`
	PublishedAt time.Time `json:"published_at"`
	Stories     []stories `json:"stories"`
}

type stories struct {
	ID          int        `json:"id"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	PublishedAt *time.Time `json:"published_at,omitempty"`
}

func (h *handler) getTodaysNewspaper(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	res := getTodaysNewspaperResponse{}
	err := h.db.QueryRowContext(ctx, `
		SELECT id, published_at
		FROM newspapers
		ORDER BY published_at DESC
		LIMIT 1;
	`).Scan(&res.ID, &res.PublishedAt)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to fetch today's newspaper.")
		return
	}

	rows, err := h.db.QueryContext(ctx, `
		SELECT id, title, description, published_at
		FROM stories
		WHERE newspaper_id = $1
		ORDER BY published_at DESC;
	`, res.ID)
	if err != nil {
		serverError(
			w, http.StatusInternalServerError,
			fmt.Sprintf("Failed to fetch stories for the newspaper (ID=%d).", res.ID),
		)
		return
	}
	for rows.Next() {
		a := stories{}
		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.PublishedAt)
		if err != nil {
			serverError(w, http.StatusInternalServerError, "Failed to parse a story.")
			return
		}
		res.Stories = append(res.Stories, a)
	}
	if err := rows.Err(); err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to parse stories.")
		return
	}

	jres, err := json.Marshal(res)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to construct a JSON response.")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

type getStoryResponse struct {
	Type string    `json:"type"`
	Data feedEntry `json:"data"`
}

func (h *handler) getStory(w http.ResponseWriter, r *http.Request) {
	rawId := r.PathValue("id")
	id, err := strconv.Atoi(rawId)
	if err != nil {
		serverError(w, http.StatusBadRequest, fmt.Sprintf("Invalid story ID: %s", rawId))
		return
	}

	ctx := r.Context()
	res := getStoryResponse{Type: "entry"}
	d := &res.Data
	err = h.db.QueryRowContext(ctx, `
		SELECT e.id, e.feed_id, e.url, e.title, e.description, e.content, e.snapshot_at, e.published_at
		FROM entries e JOIN stories s ON e.id = s.entry_id
		WHERE s.id = $1;
	`, id).Scan(&d.ID, &d.FeedID, &d.URL, &d.Title, &d.Description, &d.Content, &d.SnapshotAt, &d.PublishedAt)
	if errors.Is(err, sql.ErrNoRows) {
		serverError(w, http.StatusNotFound, "Story not found.")
		return
	} else if err != nil {
		serverError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to fetch story by ID: %s", rawId))
		return
	}

	jres, err := json.Marshal(res)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to construct the response.")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

type feedEntry struct {
	ID          int        `json:"id"`
	URL         string     `json:"url"`
	FeedID      int        `json:"feed_id"`
	Title       string     `json:"title"`
	Description *string    `json:"description"`
	Content     *string    `json:"content"`
	PublishedAt *time.Time `json:"published_at"`
	SnapshotAt  *time.Time `json:"snapshot_at"`
}

type getFeedEntryResponse struct {
	feedEntry
}

func (h *handler) getFeedEntry(w http.ResponseWriter, r *http.Request) {
	rawId := r.PathValue("id")
	id, err := strconv.Atoi(rawId)
	if err != nil {
		serverError(w, http.StatusBadRequest, fmt.Sprintf("Invalid entry ID: %s", rawId))
		return
	}

	ctx := r.Context()
	res := getFeedEntryResponse{}
	err = h.db.QueryRowContext(ctx, `
		SELECT id, feed_id, url, title, description, content, snapshot_at, published_at
		FROM entries
		WHERE id = $1;
	`, id).Scan(&res.ID, &res.FeedID, &res.URL, &res.Title, &res.Description, &res.Content, &res.SnapshotAt, &res.PublishedAt)
	if errors.Is(err, sql.ErrNoRows) {
		serverError(w, http.StatusNotFound, "Entry not found.")
		return
	} else if err != nil {
		serverError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to fetch entry by ID=%d", id))
		return
	}

	jres, err := json.Marshal(res)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to construct a JSON response.")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

type feedSchema struct {
	ID          int    `json:"id"`
	URL         string `json:"url"`
	SiteURL     string `json:"site_url,omitempty"`
	IconURL     string `json:"icon_url,omitempty"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
}

type getFeedsResBody struct {
	Feeds []feedSchema `json:"feeds"`
}

func (h *handler) getFeeds(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var res getFeedsResBody
	// TODO: Support pagination
	rows, err := h.db.QueryContext(ctx, `SELECT id, url, site_url, icon_url, title, description FROM feeds;`)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch feeds")
		return
	}
	for rows.Next() {
		var f feedSchema
		var su, iu, desc sql.NullString
		err := rows.Scan(&f.ID, &f.URL, &su, &iu, &f.Title, &desc)
		if err != nil {
			fmt.Print(err)
			serverError(w, http.StatusInternalServerError, "Failed to fetch feeds")
			return
		}
		if su.Valid {
			f.SiteURL = su.String
		}
		if iu.Valid {
			f.IconURL = iu.String
		}
		if desc.Valid {
			f.Description = desc.String
		}
		res.Feeds = append(res.Feeds, f)
	}
	if rows.Err() != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch feeds")
		return
	}

	jres, err := json.Marshal(res)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

type subscribeToFeedReqBody struct {
	URL string `json:"url"`
}

type subscribeToFeedResBody struct {
	feedSchema
}

func (h *handler) subscribeToFeed(w http.ResponseWriter, r *http.Request) {
	var b subscribeToFeedReqBody
	// TODO: Limit request body size (http.MaxBytesReader)
	err := json.NewDecoder(r.Body).Decode(&b)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusBadRequest, "Failed to parse request body")
		return
	}
	u, err := url.Parse(b.URL)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusBadRequest, "Failed to parse URL")
		return
	}
	ctx := r.Context()
	fd, err := feed.Subscribe(ctx, h.db, *u)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to subscribe to feed")
		return
	}
	res := subscribeToFeedResBody{}
	res.ID = fd.ID
	res.URL = fd.URL.String()
	res.Title = fd.Title
	if u := fd.SiteURL; u != nil {
		res.SiteURL = u.String()
	}
	if u := fd.IconURL; u != nil {
		res.IconURL = u.String()
	}
	if d := fd.Description; d != nil {
		res.Description = *d
	}
	jres, err := json.Marshal(res)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to construct a JSON")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

func serverError(w http.ResponseWriter, statusCode int, msg string) {
	res, err := json.Marshal(map[string]any{
		"message": msg,
	})
	if err != nil {
		http.Error(w, msg, http.StatusInternalServerError)
	} else {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(statusCode)
		w.Write(res)
	}
}
