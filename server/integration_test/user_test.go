//go:build integration

package integration_test

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/api"
	"github.com/fujidaiti/paperdoll/feature/user"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	"golang.org/x/crypto/bcrypt"
)

type userRecord struct {
	ID           int
	Email        string
	PasswordHash []byte
}

type authTokenRecord struct {
	ID         int
	UserId     int
	DeviceKind string
	TokenHash  []byte
	ExpiresAt  time.Time
}

func TestAuth_CreateUserAccount(t *testing.T) {
	type Test struct {
		email      string
		password   string
		wantRecord userRecord
	}
	test := map[string]Test{
		"happy": {
			email:      "alice@gmail.com",
			password:   "Test$Password+123",
			wantRecord: userRecord{ID: 1, Email: "alice@gmail.com"},
		},
		"same password": {
			email:      "bob@exchange.com",
			password:   "Test$Password+123",
			wantRecord: userRecord{ID: 2, Email: "bob@exchange.com"},
		},
	}

	var passwordHashes []string
	testenv.RunTT(t, test, true, func(db *sql.DB, tt Test) {
		s := user.Service{
			DB:  db,
			Now: func() time.Time { return time.Now() },
		}

		got1, err := s.CreateUserAccount(t.Context(), tt.email, tt.password)
		if err != nil {
			t.Fatalf("failed to create user account: %v", err)
		}

		var got2 userRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, email, password_hash FROM users WHERE email = $1;
		`, tt.email).Scan(&got2.ID, &got2.Email, &got2.PasswordHash)
		if err != nil {
			t.Fatalf("a new user record must be created: %v", err)
		}

		if got1 != got2.ID {
			t.Errorf("returned ID(=%d) must be same as stored ID(=%d)", got1, got2.ID)
		}

		if d := cmp.Diff(tt.wantRecord, got2, cmpopts.IgnoreFields(userRecord{}, "PasswordHash")); d != "" {
			t.Errorf("created user recored is malformed:\n%s", d)
		}

		if bytes.Equal(got2.PasswordHash, []byte(tt.password)) {
			t.Error("raw password must not be stored in DB")
		}

		if err := bcrypt.CompareHashAndPassword(
			got2.PasswordHash,
			[]byte(tt.password),
		); err != nil {
			t.Errorf("a bcrypt hash should be stored instead of the real password: %v", err)
		}

		passwordHashes = append(passwordHashes, string(got2.PasswordHash))
	})

	if len(passwordHashes) != len(test) {
		t.Fatal("some of subtests have failed")
	}
	if !testenv.IsDistinct(passwordHashes) {
		t.Errorf("")
	}
}

func TestAuth_IssueAuthToken(t *testing.T) {
	now := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)
	want3 := authTokenRecord{ID: 1, UserId: 1, DeviceKind: "Pixel9a/Android17"}
	testenv.Run(t, func(db *sql.DB) {
		s := user.Service{
			DB:  db,
			Now: func() time.Time { return now },
		}
		uID, err := s.CreateUserAccount(t.Context(), "test@gmail.com", "Test$Password")
		if err != nil {
			t.Fatalf("failed to seed user: %v", err)
		}

		got1, err := s.IssueAuthToken(t.Context(), uID, "Pixel9a/Android17")
		if err != nil {
			t.Fatalf("failed to issue a new auth token: %v", err)
		}

		rawToken, err := base64.RawURLEncoding.DecodeString(got1)
		if err != nil {
			t.Errorf("returned token must be a valid Base64URL with no padding, but got: %s\n%v", got1, err)
		}
		if l := len(rawToken); l != 32 {
			t.Errorf("raw token must be 32 bytes, but got %d bytes", l)
		}

		var got2 authTokenRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, user_id, device_kind, token_hash, expires_at FROM auth_tokens WHERE user_id = $1;
		`, uID).Scan(&got2.ID, &got2.UserId, &got2.DeviceKind, &got2.TokenHash, &got2.ExpiresAt)
		if err != nil {
			t.Fatalf("new token record must be created: %v", err)
		}

		if d := cmp.Diff(want3, got2, cmpopts.IgnoreFields(authTokenRecord{}, "TokenHash", "ExpiresAt")); d != "" {
			t.Errorf("created token record is malformed:\n%s", d)
		}

		if d := got2.ExpiresAt.Sub(now); d != 30*24*time.Hour {
			t.Errorf("token should expires in 30 days, but actual TTL is %g hour(s)", d.Hours())
		}

		if bytes.Equal(got2.TokenHash, rawToken) {
			t.Error("raw token must not be stored in DB")
		}

		if d := cmp.Diff(got2.TokenHash, new(sha256.Sum256(rawToken))[:]); d != "" {
			t.Errorf("token must be SHA256-hashed in DB; actual diff:\n%s", d)
		}
	})
}

func TestAuth_SignUp(t *testing.T) {
	now := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)

	testenv.Run(t, func(db *sql.DB) {
		h := api.Handler{
			DB: db,
			UserService: user.Service{
				DB:  db,
				Now: func() time.Time { return now },
			},
		}
		rBody := api.SignUpReqBody{
			Email:      "test@example.com",
			Password:   "Test$Password+123",
			DeviceKind: "Pixel9a/Android16",
		}
		jBody, _ := json.Marshal(rBody)
		req := httptest.NewRequest("POST", "/signup", bytes.NewReader(jBody))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		api.NewRouter(&h).ServeHTTP(rec, req)

		var got1 api.SignUpResBody
		if err := json.NewDecoder(rec.Body).Decode(&got1); err != nil {
			t.Fatalf("failed to decode response body: %v", err)
		}
	})
}
