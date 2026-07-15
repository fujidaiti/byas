package testenv

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/db/migration"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

var container *postgres.PostgresContainer
var db *sql.DB

// Run is a wrapper around the body of top-level test functions that requires a sql.DB handle.
// The database is automatically cleanued up after the test finishes.
func Run(t *testing.T, f func(db *sql.DB)) {
	t.Helper()
	t.Cleanup(func() {
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
	})
	f(db)
}

// RunTests runs all top-level test functions and returns an exit code.
// Intended to be used in TestMain, only once.
func RunTests(m *testing.M) int {
	if container != nil || db != nil {
		return exitAs("Do not call RunTests twice")
	}
	ctx := context.Background()
	defer func() {
		if db != nil {
			err := db.Close()
			if err != nil {
				log.Printf("Failed to close DB: %v\n", err)
			}
		}
		if container != nil {
			err := container.Terminate(ctx)
			if err != nil {
				log.Printf("Failed to terminate test container: %v\n", err)
			}
		}
	}()

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
		return exitAs("Failed to launch test container: %v\n", err)
	}
	err = openDB(ctx)
	if err != nil {
		return exitAs("Failed to open the DB for migration: %v\n", err)
	}
	err = migration.Run(ctx, db, "up", nil)
	if err != nil {
		return exitAs("Failed to migrate DB: %v\n", err)
	}
	// container.Snapshot requires all DB connections to be closed.
	if err := db.Close(); err != nil {
		return exitAs("Failed to close DB before taking a snapshot: %v\n", err)
	}
	err = container.Snapshot(ctx)
	if err != nil {
		return exitAs("Failed to take a DB snapshot: %v\n", err)
	}
	err = openDB(ctx)
	if err != nil {
		return exitAs("Failed to reopen the DB: %v\n", err)
	}
	return m.Run()
}

func exitAs(format string, v ...any) int {
	log.Printf(format, v...)
	return 1
}

// openDB modifies the global db variable. Errors should be handled on the call site.
func openDB(ctx context.Context) error {
	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		return fmt.Errorf("failed to construct the DSN: %w", err)
	}
	db, err = sql.Open("pgx", dsn)
	if err != nil {
		return fmt.Errorf("failed to connect to %s: %w", dsn, err)
	}
	err = db.Ping()
	if err != nil {
		return fmt.Errorf("failed to ping: %w", err)
	}
	return nil
}
