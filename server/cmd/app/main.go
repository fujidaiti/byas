package main

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"os"
	"os/signal"

	"github.com/fujidaiti/paperdoll/api"
	"github.com/fujidaiti/paperdoll/worker"
	_ "github.com/jackc/pgx/v5/stdlib"
)

//go:embed db/migration/*.sql
var embedMigrations embed.FS

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Specify a sub-command.")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "serve":
		serve()

	case "schedule":
		schedule()

	case "migrate":
		migrate()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}

func serve() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	api.StartServer(ctx)
}

func schedule() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	worker.StartScheduler(ctx)
}

func migrate() {
	db, err := setUpDB()
	if err != nil {
		panic(err)
	}
	defer db.Close()
}

func setUpDB() (*sql.DB, error) {
	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		return nil, fmt.Errorf("DB_DSN is requried")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		if err2 := db.Close(); err2 != nil {
			fmt.Println(err2)
		}
		return nil, err
	}
	return db, nil
}
