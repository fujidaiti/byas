package main

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/user"
)

type seeder = func(ctx context.Context, db *sql.DB) error

var seeders = map[string]seeder{
	"newspaper_today":     seedNewspaperSuit_Today,
	"auth_no_users":       seedAuthSuit_NoUsers,
	"auth_existing_user":  seedAuthSuit_ExistingUser,
	"auth_signed_in":      seedAuthSuit_SignedIn,
	"feed_bbc_news":       seedFeedSuit_BbcNews,
	"feed_nasa_candidate": seedFeedSuit_NasaCandidate,
}

// testAccountEmail and testAccountPassword identify the fixed E2E test
// account that "/signin" always signs in to (see main.go). Seeders whose test
// pumps the app via pumpAppWithAuth must call provisionTestAccount before
// seeding any data they want reachable by the signed-in session.
const (
	testAccountEmail    = "e2e-runner@example.com"
	testAccountPassword = "Police-Repurpose-Atypical-Gravel"
)

func provisionTestAccount(ctx context.Context, db *sql.DB) error {
	email := must(user.ParseEmail(testAccountEmail))
	pswd := must(user.ValidatePassword(testAccountPassword))
	svc := &user.Service{DB: db, Now: time.Now}
	_, err := svc.SignUp(ctx, email, pswd, "seeder")
	return err
}

func seedDB(ctx context.Context, db *sql.DB, seederID string) error {
	s, ok := seeders[seederID]
	if !ok {
		return fmt.Errorf("no seeder is registered for ID=%q", seederID)
	}
	return s(ctx, db)
}

// mustTimeUTC parses s into a [time.Time]. The accepted format is "yyyy-MM-dd hh:mm:ss".
func mustTimeUTC(s string) time.Time {
	t, err := time.ParseInLocation(time.DateTime, s, time.UTC)
	if err != nil {
		panic(err)
	}
	return t
}

func must[T any](val T, err error) T {
	if err != nil {
		panic(err)
	}
	return val
}
