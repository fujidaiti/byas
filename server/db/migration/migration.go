package migration

import (
	"context"
	"database/sql"
	"embed"

	"github.com/pressly/goose/v3"
)

//go:embed *sql
var embedMigrations embed.FS

// Run proxies the command and arguments to github.com/pressly/goose.
func Run(ctx context.Context, db *sql.DB, cmd string, args []string) error {
	goose.SetBaseFS(embedMigrations)
	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}
	return goose.RunContext(ctx, cmd, db, ".", args...)
}

// Up runs goose's up command.
func Up(ctx context.Context, db *sql.DB) error {
	return Run(ctx, db, "up", nil)
}
