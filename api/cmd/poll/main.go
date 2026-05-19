package main

import (
	"database/sql"
	"os"

	"github.com/fujidaiti/paperdoll/feature/feed"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/joho/godotenv"
)

func main() {
	if f := os.Getenv("ENV_FILE"); len(f) > 0 {
		godotenv.Load(f)
	} else {
		godotenv.Load()
	}

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
