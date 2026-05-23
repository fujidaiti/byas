package main

import (
	"database/sql"
	"os"
	"os/signal"

	"github.com/fujidaiti/paperdoll/feature/feed"
	"github.com/fujidaiti/paperdoll/worker"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
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

	pool := worker.NewPool(16)
	defer pool.Shutdown()
	feed.FlushRefreshJobs(pool, db)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit
}
