package api

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"time"

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
	mux.HandleFunc("GET /papers/today", h.getTodaysPaper)

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

type getTodaysPaperResponse struct {
	ID          int        `json:"id"`
	PublishedAt time.Time  `json:"published_at"`
	Articles    []articles `json:"articles"`
}

type articles struct {
	ID          int        `json:"id"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	PublishedAt *time.Time `json:"published_at,omitempty"`
}

func (h *handler) getTodaysPaper(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	res := getTodaysPaperResponse{}
	err := h.db.QueryRowContext(ctx, `
		SELECT id, published_at
		FROM papers
		ORDER BY published_at DESC
		LIMIT 1;
	`).Scan(&res.ID, &res.PublishedAt)
	if err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to fetch today's paper.")
		return
	}

	rows, err := h.db.QueryContext(ctx, `
		SELECT id, title, description, published_at
		FROM articles
		WHERE paper_id = $1
		ORDER BY published_at DESC;
	`, res.ID)
	if err != nil {
		serverError(
			w, http.StatusInternalServerError,
			fmt.Sprintf("Failed to fetch articles for the paper (ID=%d).", res.ID),
		)
		return
	}
	for rows.Next() {
		a := articles{}
		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.PublishedAt)
		if err != nil {
			serverError(w, http.StatusInternalServerError, "Failed to parse an article.")
			return
		}
		res.Articles = append(res.Articles, a)
	}
	if err := rows.Err(); err != nil {
		serverError(w, http.StatusInternalServerError, "Failed to parse articles.")
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
