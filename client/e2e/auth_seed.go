package main

import (
	"context"
	"database/sql"

	"golang.org/x/crypto/bcrypt"
)

// Credentials of the user seeded by [seedAuthSuit_ExistingUser]; keep these in
// sync with the Dart constants in helper.dart.
const (
	existingUserEmail    = "alice@example.com"
	existingUserPassword = "Police-Repurpose-Atypical-Gravel"
)

// seedAuthSuit_NoUsers leaves the users table empty. It exists so the runner
// still starts a clean API server for scenarios that begin signed-out with no
// pre-existing accounts (sign-up, navigation).
func seedAuthSuit_NoUsers(ctx context.Context, db *sql.DB) error {
	return nil
}

// seedAuthSuit_ExistingUser inserts a single account so sign-in and
// taken-email scenarios have something to authenticate against. The password
// is bcrypt-hashed the same way the server does on sign-up.
func seedAuthSuit_ExistingUser(ctx context.Context, db *sql.DB) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(existingUserPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	_, err = db.ExecContext(ctx, `
		INSERT INTO users (email, password_hash) VALUES ($1, $2)
	`, existingUserEmail, hash)
	return err
}
