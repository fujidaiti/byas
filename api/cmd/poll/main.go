package main

import (
	"context"
	"database/sql"
	"os"
	"os/signal"

	"github.com/fujidaiti/paperdoll/feature/feed"
	"github.com/fujidaiti/paperdoll/worker"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		panic("DB_DSN is required.")
	}

	db, err := sql.Open("pgx", dsn)
	if err != nil {
		panic(err)
	}
	defer db.Close()
	if err := db.Ping(); err != nil {
		panic(err)
	}

	pool := &worker.Pool{}
	defer pool.Shutdown()
	pool.Start(ctx, 16)

	feed.FlushRefreshJobs(ctx, pool, db)
	<-ctx.Done()
}
