//go:build integration

package integration_test

import (
	"bytes"
	"crypto/sha256"
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
	t.Cleanup(testenv.ResetDB)

	test := []struct {
		name       string
		email      string
		password   string
		wantRecord userRecord
	}{
		{
			name:       "success",
			email:      "alice@gmail.com",
			password:   "Test$Password+123",
			wantRecord: userRecord{ID: 1, Email: "alice@gmail.com"},
		},
		{
			name:       "same password",
			email:      "bob@exchange.com",
			password:   "Test$Password+123",
			wantRecord: userRecord{ID: 2, Email: "bob@exchange.com"},
		},
	}

	var passwordHashes []string
	for _, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			s := user.Service{
				DB:  testenv.DB,
				Now: func() time.Time { return time.Now() },
			}

			gotID, err := s.CreateUserAccount(t.Context(), tt.email, tt.password)
			if err != nil {
				t.Fatalf("failed to create user account: %v", err)
			}

			var gotUser userRecord
			err = testenv.DB.QueryRowContext(t.Context(), `
				SELECT id, email, password_hash FROM users WHERE email = $1;
			`, tt.email).Scan(&gotUser.ID, &gotUser.Email, &gotUser.PasswordHash)
			if err != nil {
				t.Fatalf("a new user record must be created: %v", err)
			}

			if gotID != gotUser.ID {
				t.Errorf("returned ID(=%d) must be same as stored ID(=%d)", gotID, gotUser.ID)
			}

			if d := cmp.Diff(tt.wantRecord, gotUser, cmpopts.IgnoreFields(userRecord{}, "PasswordHash")); d != "" {
				t.Errorf("created user recored is malformed:\n%s", d)
			}

			if bytes.Equal(gotUser.PasswordHash, []byte(tt.password)) {
				t.Error("raw password must not be stored in DB")
			}

			if err := bcrypt.CompareHashAndPassword(gotUser.PasswordHash, []byte(tt.password)); err != nil {
				t.Errorf("a bcrypt hash should be stored instead of the real password: %v", err)
			}

			passwordHashes = append(passwordHashes, string(gotUser.PasswordHash))
		})
	}

	if len(passwordHashes) != len(test) {
		t.Fatal("some of subtests have failed")
	}
	if !isDistinct(passwordHashes) {
		t.Errorf("password hashes must be uniqueue for each user even if raw passwords are identical")
	}
}

func TestAuth_CreateUserAccount_EmailUniquness(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	test := []struct {
		name     string
		email    string
		password string
		wantErr  error
		wantID   int
	}{
		{
			name: "success", email: "testUser@gmail.com", password: "testPassword1",
			wantErr: nil, wantID: 1,
		},
		{
			name: "same email", email: "testUser@gmail.com", password: "testPassword2",
			wantErr: user.ErrEmailTaken, wantID: 0,
		},
		{
			name: "same email and password", email: "testUser@gmail.com", password: "testPassword1",
			wantErr: user.ErrEmailTaken, wantID: 0,
		},
	}

	for _, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			s := user.Service{
				DB:  testenv.DB,
				Now: func() time.Time { return time.Now() },
			}
			gotID, gotErr := s.CreateUserAccount(t.Context(), tt.email, tt.password)
			if gotID != tt.wantID {
				t.Errorf("want ID=%d, got ID=%d", tt.wantID, gotID)
			}
			if gotErr != tt.wantErr {
				t.Errorf("want an error '%v', got '%v'", tt.wantErr, gotErr)
			}

			var gotUsers []userRecord
			rows, err := testenv.DB.QueryContext(t.Context(), `
				SELECT id, email, password_hash FROM users where;
			`)
			if err != nil {
				t.Fatalf("failed to fetch users: %v", err)
			}
			defer rows.Close()
			for rows.Next() {
				got := userRecord{}
				if err := rows.Scan(&got.ID, &got.Email, &got.PasswordHash); err != nil {
					t.Fatalf("failed to fetch user record: %v", err)
				}
				gotUsers = append(gotUsers, got)
			}
			if err := rows.Err(); err != nil {
				t.Fatalf("failed to fetch user records: %v", err)
			}
			if n := len(gotUsers); n != 1 {
				t.Fatalf("exactly one user must be registered, got %d users", n)
			}
			if got := gotUsers[0]; got.ID != gotID || got.Email != tt.email ||
				bcrypt.CompareHashAndPassword(got.PasswordHash, []byte(tt.password)) != nil {
				t.Errorf("only the first user must be registered, got=%v", got)
			}
		})
	}
}

func TestAuth_IssueAuthToken(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	now := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)
	want3 := authTokenRecord{ID: 1, UserId: 1, DeviceKind: "Pixel9a/Android17"}

	s := user.Service{
		DB:  testenv.DB,
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
	err = testenv.DB.QueryRowContext(t.Context(), `
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
}

func TestAuth_SignUp(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	now := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)
	h := api.Handler{
		DB: testenv.DB,
		UserService: user.Service{
			DB:  testenv.DB,
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
}
