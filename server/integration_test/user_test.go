//go:build integration

package integration_test

import (
	"bytes"
	"database/sql"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/feature/user"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	"golang.org/x/crypto/bcrypt"
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
	// Random 32 bytes
	wantRawToken := []byte{
		0xDA, 0x6B, 0x94, 0xF1, 0x7F, 0x4C, 0xD8, 0xD4,
		0xEB, 0xED, 0xE8, 0x4A, 0x6F, 0xFB, 0x3E, 0x5B,
		0x37, 0xDF, 0xEE, 0x3F, 0xD9, 0x9E, 0x32, 0xC5,
		0x26, 0x48, 0xE6, 0x31, 0xCB, 0x1C, 0x20, 0x6A,
	}
	// SHA256-hashed wantRawToken
	wantTokenHash := []byte{
		0x2E, 0x6E, 0x42, 0x73, 0x93, 0x9C, 0xF3, 0xB2,
		0xF2, 0xF1, 0x64, 0x3A, 0xCF, 0x49, 0xE8, 0x4F,
		0xC8, 0xF8, 0xF7, 0xAB, 0x00, 0x65, 0xB4, 0xC4,
		0x18, 0x73, 0x94, 0xF7, 0xA6, 0x33, 0x7B, 0x51,
	}
	// Base64URL-encoded wantRawToken without padding
	wantToken := "2muU8X9M2NTr7ehKb_s-Wzff7j_ZnjLFJkjmMcscIGo"

	testenv.Run(t, func(db *sql.DB) {
		s := user.Service{
			DB:         db,
			Now:        func() time.Time { return time.Now() },
			SecureRand: bytes.NewReader(wantRawToken),
		}

		got1, err := s.SignUp(t.Context(), user.Credentials{
			Email:      "test@example.com",
			Password:   "Test$Password+123",
			DeviceKind: "TestDevice/1.0.0",
		})
		if err != nil {
			t.Fatalf("failed to sign-up: %v", err)
		}
		if diff := cmp.Diff(wantToken, got1); diff != "" {
			t.Errorf("unexpected returned token (-want, +got):\n%s", diff)
		}

		var got2 userRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, email, password_hash
			FROM users
			WHERE email = 'test@example.com';
		`).Scan(&got2.ID, &got2.Email, &got2.PasswordHash)
		if err != nil {
			t.Fatalf("failed to fetch created user: %v", err)
		}
		want2 := userRecord{
			ID:    1,
			Email: "test@example.com",
		}
		if diff := cmp.Diff(
			want2,
			got2,
			cmpopts.IgnoreFields(userRecord{}, "PasswordHash"),
		); diff != "" {
			t.Errorf("unexpected user record (-want, +got):\n%s", diff)
		}
		if err := bcrypt.CompareHashAndPassword(
			got2.PasswordHash,
			[]byte("Test$Password+123"),
		); err != nil {
			t.Errorf(
				"a bcrypt hash should be saved instead of the real password, but it looks like not: %v",
				err,
			)
		}

		var got3 authTokenRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, user_id, device_kind, token_hash, expires_at
			FROM auth_tokens
			WHERE user_id = 1;
		`).Scan(&got3.ID, &got3.UserId, &got3.DeviceKind, &got3.TokenHash, &got3.ExpiresAt)
		if err != nil {
			t.Fatalf("failed to fetch issued token: %v", err)
		}
		want3 := authTokenRecord{
			ID:         1,
			UserId:     1,
			DeviceKind: "TestDevice/1.0.0",
			TokenHash:  wantTokenHash,
			ExpiresAt:  time.Now(),
		}
		if diff := cmp.Diff(want3, got3); diff != "" {
			t.Errorf("unexpected token record (-want, +got):\n%s", diff)
		}
	})
}
