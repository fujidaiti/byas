package itest

import (
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"strings"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
	"golang.org/x/crypto/bcrypt"
)

// isDistinct checks if all comparable elements in v are uniqueue.
func isDistinct[T comparable](v []T) bool {
	seen := make(map[T]struct{}, len(v))
	for _, x := range v {
		if _, exists := seen[x]; exists {
			return false
		}
		seen[x] = struct{}{}
	}
	return true
}

func must[T any](val T, err error) T {
	if err != nil {
		panic(err)
	}
	return val
}

// mustTimeUTC parses s into a [time.Time]. The accepted format is "yyyy-MM-dd hh:mm:ss".
func mustTimeUTC(s string) time.Time {
	t, err := time.ParseInLocation(time.DateTime, s, time.UTC)
	if err != nil {
		panic(err)
	}
	return t
}

func scanRowOrFatal(t *testing.T, query string, args []any, dest ...any) {
	t.Helper()
	err := testenv.DB().QueryRowContext(t.Context(), query, args...).Scan(dest...)
	if err != nil {
		t.Fatalf("failed to scan a row: %v\nquery: %s", err, query)
	}
}

func scanValOrFatal[T any](t *testing.T, query string, args ...any) T {
	t.Helper()
	var val T
	scanRowOrFatal(t, query, args, &val)
	return val
}

func scanRowsOrFatal[T any](t *testing.T, query string, args []any, scan func(*sql.Rows, *T) error) []T {
	t.Helper()
	rows, err := testenv.DB().QueryContext(t.Context(), query, args...)
	if err != nil {
		t.Fatalf("failed to scan rows: %v\nquery: %s", err, query)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			t.Errorf("failed to close DB: %v", err)
		}
	}()
	var dests []T
	for rows.Next() {
		dest := new(T)
		if err := scan(rows, dest); err != nil {
			t.Fatalf("failed to scan a row: %v\nquery: %s", err, query)
		}
		dests = append(dests, *dest)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("failed to scan rows: %v\nquery: %s", err, query)
	}
	return dests
}

func execOrFatal(t *testing.T, query string, args ...any) {
	t.Helper()
	if _, err := testenv.DB().ExecContext(t.Context(), query, args...); err != nil {
		t.Fatalf("failed to exec: %v\nquery: %s", err, query)
	}
}

// provisionTestAccount creates a usable test account at the given time and
// returns the new user ID along with the auth token issued for device.
func provisionTestAccount(
	t *testing.T, email, password, device string, at time.Time,
) (user.UserID, user.AuthToken) {
	t.Helper()
	s := user.Service{DB: testenv.DB(), Now: func() time.Time { return at }}
	token, err := s.SignUp(
		t.Context(),
		must(user.ParseEmail(email)),
		must(user.ValidatePassword(password)),
		device,
	)
	if err != nil {
		t.Fatalf("failed to provision a test account (%s): %v", email, err)
	}
	// TODO: Remove this workaround when CannonicalEmail is refactored to be a named type.
	// SignUp stores the canonicalized (lower-cased) address.
	uid := scanValOrFatal[user.UserID](t,
		`SELECT id FROM users WHERE email = $1`, strings.ToLower(email))
	return uid, token
}

// provisionDefaultTestAccount creates a test account at the given time with a
// fixed email address and password, and returns the new user ID. Use it when
// the email address and password do not matter for the test. Note that it can
// only be called once per test, since the address is always the same.
func provisionDefaultTestAccount(t *testing.T, at time.Time) user.UserID {
	t.Helper()
	uid, _ := provisionTestAccount(
		t, "test-account@example.com", "test#password$1234", "Pixel9a", at)
	return uid
}

// seedPendingSignUpAttempt inserts a pending sign-up attempt directly into the
// DB and returns its row ID. The ticket must be a base64url-encoded 32-byte
// value, matching what user.AuthToken.Encode produces.
//
// TODO: Replace this with the real sign-up-request function once it exists.
func seedPendingSignUpAttempt(
	t *testing.T, ticket, email, password, code string, expiresAt time.Time,
) int {
	t.Helper()
	// Mirrors user.AuthToken.Hash, whose internals this package cannot reach.
	raw, err := base64.RawURLEncoding.DecodeString(ticket)
	if err != nil {
		t.Fatalf("ticket %q is not base64url: %v", ticket, err)
	}
	if len(raw) != 32 {
		t.Fatalf("ticket %q decodes to %d bytes, want 32", ticket, len(raw))
	}
	ticketHash := sha256.Sum256(raw)

	// MinCost keeps the suite fast; CompareHashAndPassword accepts any cost.
	pswdHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("failed to hash the password: %v", err)
	}
	codeHash, err := bcrypt.GenerateFromPassword([]byte(code), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("failed to hash the verification code: %v", err)
	}

	return scanValOrFatal[int](t, `
		INSERT INTO pending_signup_attempts
			(email, password_hash, verification_code_hash, ticket_hash, expires_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`, strings.ToLower(email), pswdHash, codeHash, ticketHash[:], expiresAt)
}
