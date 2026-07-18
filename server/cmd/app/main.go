package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"os/signal"

	"github.com/fujidaiti/paperdoll/server/api"
	"github.com/fujidaiti/paperdoll/server/db/migration"
	"github.com/fujidaiti/paperdoll/server/worker"
	_ "github.com/jackc/pgx/v5/stdlib"
)

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
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Specify a goose command (e.g., up).")
			os.Exit(1)
		}
		migrate(os.Args[2], os.Args[3:])

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

func migrate(cmd string, args []string) {
	db, err := setUpDB()
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			fmt.Println(err)
		}
	}()
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	err = migration.Run(ctx, db, cmd, args)
	if err != nil {
		panic(err)
	}
}

func setUpDB() (*sql.DB, error) {
	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		return nil, fmt.Errorf("DB_DSN is required")
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
