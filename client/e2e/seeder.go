package main

import (
	"context"
	"database/sql"
	"fmt"
)

type seeder = func(ctx context.Context, db *sql.DB) error

var seeders = map[string]seeder{
	"newspaper_today":    seedNewspaperSuit_Today,
	"auth_no_users":      seedAuthSuit_NoUsers,
	"auth_existing_user": seedAuthSuit_ExistingUser,
}

func seedDB(ctx context.Context, db *sql.DB, seederID string) error {
	s, ok := seeders[seederID]
	if !ok {
		return fmt.Errorf("no seeder is registered for ID=%q", seederID)
	}
	return s(ctx, db)
}
