package testenv

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/fujidaiti/paperdoll/server/db/migration"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

var container *postgres.PostgresContainer

// SetUp initializes a test container and migrate the database.
// Make sure to always call [ShutDown] even if this returns a non-nil error.
func SetUp(ctx context.Context, stubAddr string) error {
	if container != nil || db != nil || stubServer != nil {
		panic("do not call SetUp twice")
	}
	var err error
	container, err = postgres.Run(ctx,
		"postgres:18-alpine",
		postgres.WithSQLDriver("pgx"),
		postgres.WithDatabase("test_db"),
		postgres.WithUsername("postgres"),
		postgres.WithPassword("postgres"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).WithStartupTimeout(5*time.Second),
		),
	)
	if err != nil {
		return fmt.Errorf("failed to launch test container: %w", err)
	}
	if err := openDB(ctx); err != nil {
		return fmt.Errorf("failed to open the DB for migration: %w", err)
	}
	if err := migration.Run(ctx, db, "up", nil); err != nil {
		return fmt.Errorf("failed to migrate DB: %w", err)
	}
	// container.Snapshot requires all DB connections to be closed.
	if err := db.Close(); err != nil {
		return fmt.Errorf("failed to close DB before taking a snapshot: %w", err)
	}
	if err := container.Snapshot(ctx); err != nil {
		return fmt.Errorf("failed to take a DB snapshot: %w", err)
	}
	if err := openDB(ctx); err != nil {
		return fmt.Errorf("failed to reopen the DB: %w", err)
	}

	ln, err := net.Listen("tcp", stubAddr)
	if err != nil {
		return fmt.Errorf("failed to open a socket for stub HTTP server: %w", err)
	}
	go startStubServer(ln)

	return nil
}

func ShutDown(ctx context.Context) error {
	var err1, err2, err3 error
	if db != nil {
		err1 = db.Close()
		db = nil
	}
	if container != nil {
		err2 = container.Terminate(ctx)
		container = nil
	}
	if stubServer != nil {
		err3 = stubServer.Shutdown(ctx)
		stubServer = nil
	}
	return errors.Join(err1, err2, err3)
}

// TODO: return an error if any
func TearDown() {
	// container.Restore force-kills open connections to the db, so a later
	// test could be handed a dead pooled connection and fail. Close/reopen
	// the pool around it so every test starts with a known-good connection.
	if err := db.Close(); err != nil {
		log.Printf("Failed to close DB before restore: %v\n", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	if err := container.Restore(ctx); err != nil {
		log.Printf("Failed to restore DB snapshot: %v\n", err)
	}
	if err := openDB(ctx); err != nil {
		log.Printf("Failed to reopen DB after restore: %v\n", err)
	}

	clear(stubHTTPRules)
}

var db *sql.DB

// DB returns the test database handle. It is only valid between [SetUp] and [ShutDown].
func DB() *sql.DB {
	return db
}

// openDB modifies the global db variable. Errors should be handled on the call site.
func openDB(ctx context.Context) error {
	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		return fmt.Errorf("failed to construct the DSN: %w", err)
	}
	if db, err = sql.Open("pgx", dsn); err != nil {
		return fmt.Errorf("failed to connect to %s: %w", dsn, err)
	}
	if err = db.Ping(); err != nil {
		return fmt.Errorf("failed to ping: %w", err)
	}
	return nil
}

var stubServer *http.Server

func startStubServer(ln net.Listener) {
	if stubServer != nil {
		panic("stub HTTP server is already running")
	}
	stubServer = &http.Server{
		Addr:    ln.Addr().String(),
		Handler: http.HandlerFunc(handleHTTPRequest),
	}
	if err := stubServer.Serve(ln); !errors.Is(err, http.ErrServerClosed) {
		panic(fmt.Sprintf("stub HTTP server exited abnormally: %v", err))
	}
}

var stubHTTPRules = map[string]string{}

func StubHTTP(host, path, fp string) {
	stubHTTPRules[host+path] = fp
}

func handleHTTPRequest(w http.ResponseWriter, r *http.Request) {
	key := r.URL.Host + r.URL.Path
	fp, ok := stubHTTPRules[key]
	if !ok {
		http.Error(w, fmt.Sprintf("no stub rule found for %q", key), http.StatusNotFound)
		return
	}

	var mime string
	switch ext := filepath.Ext(fp); ext {
	case ".html":
		mime = "text/html; charset=utf-8"
	case ".json":
		mime = "application/json"
	case ".xml":
		mime = "application/xml; charset=utf-8"
	default:
		panic(fmt.Sprintf("unsupported stub file extension: %q", ext))
	}

	data, err := os.ReadFile(fp)
	if err != nil {
		http.Error(w, fmt.Sprintf("request matched rule %q, but fixture not found in %q", key, fp), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", mime)
	if _, err := w.Write(data); err != nil {
		log.Printf("failed to write stub response for %q: %v", key, err)
	}
}
