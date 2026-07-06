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
	"github.com/fujidaiti/paperdoll/feature/readinglist"
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
	mux.HandleFunc("GET /feeds", h.getFeeds)
	mux.HandleFunc("PUT /feeds", h.subscribeToFeed)
	mux.HandleFunc("GET /feeds/search", h.searchFeeds)
	mux.HandleFunc("GET /feeds/{id}", h.getFeed)
	mux.HandleFunc("GET /feeds/{id}/timeline", h.getFeedTimeline)
	mux.HandleFunc("GET /feed-entries/{id}", h.getFeedEntry)
	mux.HandleFunc("GET /web-articles/{id}", h.getWebArticle)
	mux.HandleFunc("POST /reading-list", h.saveToReadingList)
	mux.HandleFunc("GET /reading-list", h.getReadingList)
	mux.HandleFunc("DELETE /reading-list/{id}", h.deleteReadingListItem)
	mux.HandleFunc("PATCH /reading-list/{id}", h.setReadingListItemArchivedStatus)

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
	ResourceID  int        `json:"resource_id"`
	Kind        string     `json:"kind"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	Source      *string    `json:"source,omitempty"`
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
	if errors.Is(err, sql.ErrNoRows) {
		serverError(w, http.StatusNotFound, "No newspaper found.")
		return
	} else if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to fetch today's newspaper.")
		return
	}

	rows, err := h.db.QueryContext(ctx, `
		SELECT id, feed_entry_id, title, description, source, published_at
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
		a := stories{Kind: "feed_entry"}
		err := rows.Scan(&a.ID, &a.ResourceID, &a.Title, &a.Description, &a.Source, &a.PublishedAt)
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

type feedEntry struct {
	ID          int        `json:"id"`
	URL         string     `json:"url"`
	FeedID      int        `json:"feed_id"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	Content     *string    `json:"content,omitempty"`
	PublishedAt *time.Time `json:"published_at,omitempty"`
	SnapshotAt  *time.Time `json:"snapshot_at,omitempty"`
}

type getFeedEntryResponse struct {
	feedEntry

	// ReadingListItemID is the id of the reading list item backing this entry,
	// if it is saved in the reading list (regardless of archive status). Nil
	// when the entry is not saved.
	ReadingListItemID *int `json:"reading_list_item_id,omitempty"`
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
		SELECT id, feed_id, url, title, description, content, snapshot_at, published_at,
			(SELECT id FROM reading_list_items
				WHERE feed_entry_id = feed_entries.id
				LIMIT 1)
		FROM feed_entries
		WHERE id = $1;
	`, id).Scan(&res.ID, &res.FeedID, &res.URL, &res.Title, &res.Description, &res.Content, &res.SnapshotAt, &res.PublishedAt, &res.ReadingListItemID)
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

type feedAttrsSchema struct {
	URL         string `json:"url"`
	SiteURL     string `json:"site_url,omitempty"`
	IconURL     string `json:"icon_url,omitempty"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
}

type feedSchema struct {
	ID int `json:"id"`
	feedAttrsSchema
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

type getFeedResBody struct {
	feedSchema
}

func (h *handler) getFeed(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusBadRequest, "Invalid feed id")
		return
	}

	ctx := r.Context()
	var res getFeedResBody
	var su, iu, desc sql.NullString
	err = h.db.QueryRowContext(ctx, `
		SELECT id, url, site_url, icon_url, title, description
		FROM feeds
		WHERE id = $1;
	`, id).Scan(&res.ID, &res.URL, &su, &iu, &res.Title, &desc)
	if errors.Is(err, sql.ErrNoRows) {
		fmt.Print(err)
		serverError(w, http.StatusNotFound, "No feed found")
		return
	} else if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch feed")
		return
	}
	if su.Valid {
		res.SiteURL = su.String
	}
	if iu.Valid {
		res.IconURL = iu.String
	}
	if desc.Valid {
		res.Description = desc.String
	}

	jres, err := json.Marshal(res)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jres)
}

type getFeedTimelineResBody struct {
	Entries []feedEntry `json:"entries"`
}

func (h *handler) getFeedTimeline(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusBadRequest, "Invalid feed id")
		return
	}

	ctx := r.Context()
	// TODO: Support pagination
	rows, err := h.db.QueryContext(ctx, `
		SELECT id, feed_id, url, title, description, published_at, snapshot_at
		FROM feed_entries
		WHERE feed_id = $1;
	`, id)
	if err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch entries")
		return
	}
	res := getFeedTimelineResBody{Entries: []feedEntry{}}
	for rows.Next() {
		var e feedEntry
		err := rows.Scan(&e.ID, &e.FeedID, &e.URL, &e.Title, &e.Description, &e.PublishedAt, &e.SnapshotAt)
		if err != nil {
			fmt.Print(err)
			serverError(w, http.StatusInternalServerError, "Failed to fetch entry")
			return
		}
		res.Entries = append(res.Entries, e)
	}
	if err := rows.Err(); err != nil {
		fmt.Print(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch entries")
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

type searchFeedsResBody struct {
	Feeds []feedAttrsSchema `json:"feeds"`
}

func (h *handler) searchFeeds(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	fs, err := feed.SearchFeeds(r.Context(), q)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusNotFound, "Failed to search feeds")
		return
	}

	res := searchFeedsResBody{Feeds: []feedAttrsSchema{}}
	for _, f := range fs {
		a := feedAttrsSchema{URL: f.URL.String(), Title: f.Title}
		if u := f.SiteURL; u != nil {
			a.SiteURL = u.String()
		}
		if u := f.IconURL; u != nil {
			a.IconURL = u.String()
		}
		if d := f.Description; d != nil {
			a.Description = *d
		}
		res.Feeds = append(res.Feeds, a)
	}

	jres, err := json.Marshal(res)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON")
		return
	}
	w.Header().Set("Content-Type", "application/json")
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

type saveToReadingListReqBody struct {
	URL *string `json:"url"`

	// Title is the optional placeholder, e.g. the page title shared by the browser.
	// This is only honored on the URL path; it is ignored for feed entries.
	Title *string `json:"title"`

	FeedEntryID *int `json:"feed_entry_id"`

	// WebArticleID re-saves an already-existing web article (e.g. one just
	// unsaved from the reader), re-attaching its row without re-fetching.
	WebArticleID *int `json:"web_article_id"`
}

func (h *handler) saveToReadingList(w http.ResponseWriter, r *http.Request) {
	var b saveToReadingListReqBody
	// TODO: Limit request body size (http.MaxBytesReader)
	err := json.NewDecoder(r.Body).Decode(&b)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusBadRequest, "Invalid request body")
		return
	}
	argn := 0
	if b.URL != nil {
		argn++
	}
	if b.FeedEntryID != nil {
		argn++
	}
	if b.WebArticleID != nil {
		argn++
	}
	if argn != 1 {
		serverError(w, http.StatusBadRequest, "Specify exactly one item to save")
		return
	}

	ctx := r.Context()
	var saved readinglist.SavedItem
	switch {
	case b.URL != nil:
		// TODO: Validate URL (schema and host)
		u, err := url.Parse(*b.URL)
		if err != nil || *b.URL == "" {
			serverError(w, http.StatusBadRequest, "Invalid URL")
			return
		}
		// TODO: trim and length-cap the client-supplied title
		var title string
		if b.Title != nil {
			title = *b.Title
		}
		saved, err = readinglist.SaveWebArticle(ctx, h.db, *u, title)
		if err != nil {
			fmt.Println(err)
			serverError(w, http.StatusInternalServerError, "Failed to save article")
			return
		}

	case b.FeedEntryID != nil:
		// TODO: Return 404 instead of 500 when the given ID doesn't exist
		var err error
		saved, err = readinglist.SaveFeedEntry(ctx, h.db, *b.FeedEntryID)
		if err != nil {
			fmt.Println(err)
			serverError(w, http.StatusInternalServerError, "Failed to save feed entry")
			return
		}

	case b.WebArticleID != nil:
		// TODO: Return 404 instead of 500 when the given ID doesn't exist
		var err error
		saved, err = readinglist.SaveWebArticleByID(ctx, h.db, *b.WebArticleID)
		if err != nil {
			fmt.Println(err)
			serverError(w, http.StatusInternalServerError, "Failed to save web article")
			return
		}
	}

	jres, err := json.Marshal(readingListItem{
		ID:          saved.ID,
		ResourceID:  saved.ResourceID,
		Kind:        saved.Kind,
		Title:       saved.Title,
		Description: saved.Description,
		SavedAt:     saved.SavedAt,
	})
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON response")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	w.Write(jres)
}

type getReadingListResBody struct {
	Items []readingListItem `json:"items"`
}

type readingListItem struct {
	ID          int       `json:"id"`
	ResourceID  int       `json:"resource_id"`
	Kind        string    `json:"kind"`
	Title       string    `json:"title"` // Make this optional
	Description *string   `json:"description,omitempty"`
	SavedAt     time.Time `json:"saved_at"`
}

// TODO: Support pagination; add a tiebreaker to ORDER BY in case saved_at timestamps are the same
// TODO: Report pending/failed articles separately from the Items, if any
func (h *handler) getReadingList(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	rows, err := h.db.QueryContext(ctx, `
		SELECT id, kind, title, description, saved_at, web_article_id, feed_entry_id
		FROM reading_list_items
		WHERE archived = false
		ORDER BY saved_at DESC;
	`)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch reading list")
		return
	}
	defer rows.Close()
	res := getReadingListResBody{Items: []readingListItem{}}
	for rows.Next() {
		var li readingListItem
		var waID, feID *int
		err := rows.Scan(&li.ID, &li.Kind, &li.Title, &li.Description, &li.SavedAt, &waID, &feID)
		if err != nil {
			fmt.Println(err)
			serverError(w, http.StatusInternalServerError, "Failed to fetch reading list item")
			return
		}
		switch li.Kind {
		case "web_article":
			if waID == nil {
				fmt.Println("Malformed data: a reading list item of kind 'web_article' is expected to have a web article ID, but it doesn't.")
				serverError(w, http.StatusInternalServerError, "Failed to fetch reading list item")
				return
			}
			li.ResourceID = *waID

		case "feed_entry":
			if feID == nil {
				fmt.Println("Malformed data: a reading list item of kind 'feed_entry' is expected to have a feed entry ID, but it doesn't.")
				serverError(w, http.StatusInternalServerError, "Failed to fetch reading list item")
				return
			}
			li.ResourceID = *feID

		default:
			fmt.Printf("Unknown reading list item kind: %s\n", li.Kind)
			serverError(w, http.StatusInternalServerError, "Failed to fetch reading list item")
			return
		}
		res.Items = append(res.Items, li)
	}
	if err := rows.Err(); err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Failed to fetch reading list")
		return
	}

	jres, err := json.Marshal(res)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON response")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jres)
}

type getWebArticleResBody struct {
	ID          int     `json:"id"`
	URL         string  `json:"url"`
	Title       *string `json:"title,omitempty"`
	Description *string `json:"description,omitempty"`
	Content     *string `json:"content,omitempty"`

	// ReadingListItemID is the id of the reading list item backing this article,
	// if it is saved in the reading list (regardless of archive status). Nil
	// when the article is not saved.
	ReadingListItemID *int `json:"reading_list_item_id,omitempty"`
}

func (h *handler) getWebArticle(w http.ResponseWriter, r *http.Request) {
	rawId := r.PathValue("id")
	id, err := strconv.Atoi(rawId)
	if err != nil {
		serverError(w, http.StatusBadRequest, fmt.Sprintf("Invalid web article ID: %s", rawId))
		return
	}

	ctx := r.Context()
	var res getWebArticleResBody
	err = h.db.QueryRowContext(ctx, `
		SELECT id, url, title, description, content,
			(SELECT id FROM reading_list_items
				WHERE web_article_id = web_articles.id
				LIMIT 1)
		FROM web_articles
		WHERE id = $1;
	`, id).Scan(&res.ID, &res.URL, &res.Title, &res.Description, &res.Content, &res.ReadingListItemID)
	if errors.Is(err, sql.ErrNoRows) {
		serverError(w, http.StatusNotFound, "Web article not found.")
		return
	} else if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to fetch web article by ID=%d", id))
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

func (h *handler) deleteReadingListItem(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		serverError(w, http.StatusBadRequest, "Malformed ID")
		return
	}
	ok, err := readinglist.DeleteItem(r.Context(), h.db, id)
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Something went wrong.")
		return
	}
	if !ok {
		serverError(w, http.StatusNotFound, "Item not found")
		return
	}
	// TODO: DRY JSON response creation
	jres, err := json.Marshal(map[string]string{})
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to construct JSON response")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent)
	w.Write(jres)
}

type setReadingListItemArchivedStatusReqBody struct {
	Archived *bool `json:"archived"`
}

func (h *handler) setReadingListItemArchivedStatus(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		serverError(w, http.StatusBadRequest, "Invalid ID")
		return
	}
	var b setReadingListItemArchivedStatusReqBody
	err = json.NewDecoder(r.Body).Decode(&b)
	if err != nil || b.Archived == nil {
		serverError(w, http.StatusBadRequest, "Malformed request body")
		return
	}
	if *b.Archived {
		err = readinglist.ArchiveItem(r.Context(), h.db, id)
	} else {
		err = readinglist.UnarchiveItem(r.Context(), h.db, id)
	}
	if err != nil {
		fmt.Println(err)
		serverError(w, http.StatusInternalServerError, "Something went wrong")
		return
	}
	// TODO: DRY JSON response creation
	jres, _ := json.Marshal(map[string]string{})
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent)
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
