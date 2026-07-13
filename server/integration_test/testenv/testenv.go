package testenv

import (
	"context"
	"database/sql"
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

func Run(t *testing.T, f func(db *sql.DB)) {
	t.Helper()
	t.Cleanup(func() { container.Restore(t.Context()) })
	f(db)
}

func RunTests(m *testing.M) int {
	if container != nil || db != nil {
		panic("Do not call RunTests twice")
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
		postgres.WithDatabase("test_db"),
		postgres.WithUsername("postgres"),
		postgres.WithPassword("postgres"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).WithStartupTimeout(5*time.Second),
		),
	)
	if err != nil {
		log.Printf("Failed to launch test container: %v\n", err)
		return 1
	}
	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		log.Printf("Failed to construct the DSN: %v\n", err)
		return 1
	}
	db, err = sql.Open("pgx", dsn)
	if err != nil {
		log.Printf("Failed to connect to %s: %v\n", dsn, err)
		return 1
	}
	err = db.Ping()
	if err != nil {
		log.Printf("Failed to ping: %v\n", err)
		return 1
	}
	err = migration.Up(ctx, db)
	if err != nil {
		log.Printf("Failed to migrate DB: %v\n", err)
		return 1
	}
	err = container.Snapshot(ctx)
	if err != nil {
		log.Printf("Failed to take a snaphost of DB: %v\n", err)
	}
	return m.Run()
}
