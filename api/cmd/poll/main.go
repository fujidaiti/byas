package main

import (
	"database/sql"
	"os"

	"github.com/fujidaiti/paperdoll/feature/feed"
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

	feed.RefreshFeeds(db)
}
