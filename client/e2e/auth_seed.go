package main

import (
	"context"
	"database/sql"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/user"
)

// seedAuthSuit_NoUsers leaves the users table empty. It exists so the runner
// still starts a clean API server for scenarios that begin signed-out with no
// pre-existing accounts (sign-up, navigation).
func seedAuthSuit_NoUsers(ctx context.Context, db *sql.DB) error {
	return nil
}

// seedAuthSuit_ExistingUser inserts a single account so sign-in and
// taken-email scenarios have something to authenticate against. It goes through
// the real [user.Service.SignUp] so the password is hashed exactly as the
// server does, rather than duplicating the persistence logic here.
func seedAuthSuit_ExistingUser(ctx context.Context, db *sql.DB) error {
	email := must(user.ParseEmail("alice@example.com"))
	pswd := must(user.ValidatePassword("Police-Repurpose-Atypical-Gravel"))
	svc := &user.Service{DB: db, Now: time.Now}
	_, err := svc.SignUp(ctx, email, pswd, "seeder")
	return err
}
