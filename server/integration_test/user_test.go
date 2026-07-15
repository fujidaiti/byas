//go:build integration

package integration_test

import (
	"database/sql"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/feature/user"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
	"github.com/google/go-cmp/cmp"
)

type userRecord struct {
	ID           int64
	Email        string
	PasswordHash []byte
}

type authTokenRecord struct {
	ID         int64
	UserId     int64
	DeviceKind string
	TokenHash  []byte
	ExpiresAt  time.Time
}

func TestAuth_SignUp(t *testing.T) {
	testenv.Run(t, func(db *sql.DB) {
		gotT, err := user.SignUp(t.Context(), db, user.Credentials{
			Email:      "test@example.com",
			Password:   "Test$Password+123",
			DeviceKind: "TestDevice/1.0.0",
		})
		if err != nil {
			t.Fatalf("failed to sign-up: %v", err)
		}
		var gotU userRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, email, password_hash
			FROM users
			WHERE email = 'test@example.com';
		`).Scan(&gotU.ID, &gotU.Email, &gotU.PasswordHash)
		if err != nil {
			t.Fatalf("failed to fetch created user: %v", err)
		}
		wantU := userRecord{
			ID:           1,
			Email:        "test@example.com",
			PasswordHash: []byte("testhash"),
		}
		if diff := cmp.Diff(wantU, gotU); diff != "" {
			t.Errorf("unexpected user record (-want, +got):\n%s", diff)
		}

		var gotA authTokenRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, user_id, device_kind, token_hash, expires_at
			FROM auth_tokens
			WHERE user_id = 1;
		`).Scan(&gotA.ID, &gotA.UserId, &gotA.DeviceKind, &gotA.TokenHash, &gotA.ExpiresAt)
		if err != nil {
			t.Fatalf("failed to fetch issued token: %v", err)
		}
		wantA := authTokenRecord{
			ID:         1,
			UserId:     1,
			DeviceKind: "TestDevice/1.0.0",
			TokenHash:  []byte("testtokenhash"),
			ExpiresAt:  time.Now(),
		}
		if diff := cmp.Diff(wantA, gotA); diff != "" {
			t.Errorf("unexpected token record (-want, +got):\n%s", diff)
		}

		wantT := []byte("11111111111111111111111111111111")
		if got, want := len(gotT), len(wantT); got != want {
			t.Errorf("returned token should be %d bytes, but got %d bytes", want, got)
		}

	})
}
