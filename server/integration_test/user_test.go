//go:build integration

package integration_test

import (
	"bytes"
	"database/sql"
	"errors"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/feature/user"
	"github.com/fujidaiti/paperdoll/integration_test/testenv"
	"github.com/google/go-cmp/cmp"
	"golang.org/x/crypto/bcrypt"
)

type userRecord struct {
	ID           int
	Email        string
	PasswordHash []byte
}

type authTokenRecord struct {
	ID        int
	UserId    int
	Device    string
	TokenHash []byte
	ExpiresAt time.Time
}

func TestAuth_SignUp(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	test := []struct {
		name, email, password, device string
		signedUpAt                    time.Time
	}{
		{
			name:       "alice",
			email:      "alice@gmail.com",
			password:   "Test$Password+123",
			device:     "Pixel9a/Android16",
			signedUpAt: mustTimeUTC("2026-07-01 09:15:00"),
		},
		{
			name:       "bob (same password as alice)",
			email:      "bob@exchange.com",
			password:   "Test$Password+123",
			device:     "iPhone17/iOS26",
			signedUpAt: mustTimeUTC("2027-08-20 14:00:59"),
		},
	}

	s := user.Service{DB: testenv.DB}
	var pswdHashes []string
	var gotTokens []user.AuthToken
	for i, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			s.Now = func() time.Time { return tt.signedUpAt }
			gotToken, err := s.SignUp(
				t.Context(),
				must(user.ValidateEmail(tt.email)),
				must(user.ValidatePassword(tt.password)),
				tt.device,
			)
			if err != nil {
				t.Fatalf("failed to create user account: %v", err)
			}
			gotTokens = append(gotTokens, gotToken)

			var gotUser userRecord
			err = testenv.DB.QueryRowContext(t.Context(), `
				SELECT id, email, password_hash FROM users WHERE email = $1;
			`, tt.email).Scan(&gotUser.ID, &gotUser.Email, &gotUser.PasswordHash)
			if err != nil {
				t.Fatalf("a new user record must be created: %v", err)
			}
			pswdHashes = append(pswdHashes, string(gotUser.PasswordHash))

			if got, want := gotUser.Email, tt.email; got != want {
				t.Errorf("created user has a malformed email address: got %s, want %s", got, want)
			}

			if bytes.Equal(gotUser.PasswordHash, []byte(tt.password)) {
				t.Error("raw password must not be stored in DB")
			}

			if err := bcrypt.CompareHashAndPassword(gotUser.PasswordHash, []byte(tt.password)); err != nil {
				t.Errorf("a bcrypt hash should be stored instead of the real password: %v", err)
			}

			var n int
			err = testenv.DB.QueryRowContext(t.Context(), `SELECT COUNT(*) from auth_tokens`).Scan(&n)
			if err != nil {
				t.Fatalf("failed to count rows: %v", err)
			}
			if want := i + 1; n != want {
				t.Errorf("only one token record must be added, got +%d rows", n-want)
			}

			var gotRec authTokenRecord
			err = testenv.DB.QueryRowContext(t.Context(), `
				SELECT user_id, device, token_hash, expires_at FROM auth_tokens
				ORDER BY created_at DESC LIMIT 1
			`).Scan(&gotRec.UserId, &gotRec.Device, &gotRec.TokenHash, &gotRec.ExpiresAt)
			if err != nil {
				t.Fatalf("token record not found: %v", err)
			}

			if got, want := gotRec.UserId, gotUser.ID; got != want {
				t.Errorf("token was issued for wrong user Id=%d, want Id=%d", got, want)
			}

			if got, want := gotRec.Device, tt.device; got != want {
				t.Errorf("got device '%s', want '%s'", gotRec.Device, tt.device)
			}

			if d := gotRec.ExpiresAt.Sub(tt.signedUpAt); d != 30*24*time.Hour {
				t.Errorf("token should expires in 30 days, actual TTL is %g day(s)", d.Hours()/24)
			}

			if d := cmp.Diff(gotRec.TokenHash, gotToken.Hash()); d != "" {
				t.Errorf("token must be hashed in DB, diff:\n%s", d)
			}
		})
	}

	if len(pswdHashes) != len(test) || !isDistinct(pswdHashes) {
		t.Errorf("password hashes must be uniqueue for each user even if raw passwords are identical")
	}
	if len(gotTokens) != len(test) || !isDistinct(gotTokens) {
		t.Errorf("auth tokens must be uniqueue")
	}
}

func TestAuth_SignUp_EmailUniquness(t *testing.T) {
	t.Cleanup(testenv.ResetDB)

	test := []struct {
		name, email, password, device string
		wantErr                       error
	}{
		{
			name:     "baseline",
			email:    "alice@gmail.com",
			password: "test$Password123",
			device:   "Pixel9a/Android16",
			wantErr:  nil,
		},
		{
			name:     "same email and different password",
			email:    "alice@gmail.com",
			password: "test$Password987",
			device:   "Pixel9a/Android16",
			wantErr:  user.ErrEmailTaken,
		},
		{
			name:     "same email and same password",
			email:    "alice@gmail.com",
			password: "test$Password123",
			device:   "Pixel9a/Android16",
			wantErr:  user.ErrEmailTaken,
		},
	}

	s := user.Service{
		DB:  testenv.DB,
		Now: func() time.Time { return time.Now() },
	}
	var firstUser *userRecord
	for _, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			_, gotErr := s.SignUp(
				t.Context(),
				must(user.ValidateEmail(tt.email)),
				must(user.ValidatePassword(tt.password)),
				tt.device,
			)
			if !errors.Is(gotErr, tt.wantErr) {
				t.Errorf("got '%v', want '%v'", gotErr, tt.wantErr)
			}

			gotUsers, err := scanRows(t.Context(),
				`SELECT id, email, password_hash FROM users;`, nil,
				func(r *sql.Rows, d *userRecord) error {
					return r.Scan(&d.ID, &d.Email, &d.PasswordHash)
				},
			)
			if err != nil {
				t.Fatal(err)
			}

			if n := len(gotUsers); n != 1 {
				t.Fatalf("exactly one user must be registered, got %d users", n)
			}
			if firstUser == nil {
				firstUser = &gotUsers[0]
			}

			if d := cmp.Diff(gotUsers[0], *firstUser); d != "" {
				t.Errorf("already registered user must never be touched, diff:\n%s", d)
			}
		})
	}
}

func TestAuth_SignIn(t *testing.T) {
	t.Cleanup(testenv.ResetDB)
	type User struct {
		email, password string
		signedUpAt      time.Time
		signInDevice    string
	}
	users := map[string]*User{
		"alice": {
			email:        "alice@example.com",
			password:     "alice#password$123",
			signedUpAt:   mustTimeUTC("2026-07-01 09:15:00"),
			signInDevice: "Pixel9a/Android17",
		},
		"bob": {
			email:        "bob@forest.com",
			password:     "bob#password$123",
			signedUpAt:   mustTimeUTC("2026-07-10 14:40:05"),
			signInDevice: "GalaxyS26/Android16",
		},
	}
	test := []struct {
		name       string
		user       *User
		device     string
		signedInAt time.Time
	}{
		{
			name:       "alice's first session",
			user:       users["alice"],
			device:     "Pixel9a/Android17",
			signedInAt: mustTimeUTC("2026-07-01 09:15:30"),
		},
		{
			name:       "bob's first session",
			user:       users["bob"],
			device:     "GalaxyS26/Android16",
			signedInAt: mustTimeUTC("2026-07-10 14:45:18"),
		},
		{
			name:       "alice's second session",
			user:       users["alice"],
			device:     "Pixel9a/Android17",
			signedInAt: mustTimeUTC("2026-07-08 07:45:00"),
		},
		{
			name:       "alice's third session from different device",
			user:       users["alice"],
			device:     "iPhone17/iOS26",
			signedInAt: mustTimeUTC("2026-07-14 21:05:40"),
		},
	}

	s := user.Service{DB: testenv.DB}
	// Seed users
	for _, u := range users {
		s.Now = func() time.Time { return u.signedUpAt }
		var err error
		_, err = s.SignUp(
			t.Context(),
			must(user.ValidateEmail(u.email)),
			must(user.ValidatePassword(u.password)),
			u.signInDevice,
		)
		if err != nil {
			t.Fatalf("failed to seed user (%s): %v", u.email, err)
		}
	}

	var gotTokens []user.AuthToken
	for i, tt := range test {
		s.Now = func() time.Time { return tt.signedInAt }
		t.Run(tt.name, func(t *testing.T) {
			gotToken, err := s.SignIn(t.Context(), tt.user.email, tt.user.password, tt.device)
			if err != nil {
				t.Fatalf("failed to sign-in: %v", err)
			}
			gotTokens = append(gotTokens, gotToken)

			var n int
			err = testenv.DB.QueryRowContext(t.Context(), `SELECT COUNT(*) from auth_tokens`).Scan(&n)
			if err != nil {
				t.Fatalf("failed to count rows: %v", err)
			}
			if want := len(users) + i + 1; want != n {
				t.Errorf("only one token record must be added, got +%d rows", n-want)
			}

			var gotRec authTokenRecord
			err = testenv.DB.QueryRowContext(t.Context(), `
				SELECT user_id, device, token_hash, expires_at FROM auth_tokens
				ORDER BY created_at DESC LIMIT 1
			`).Scan(&gotRec.UserId, &gotRec.Device, &gotRec.TokenHash, &gotRec.ExpiresAt)
			if err != nil {
				t.Fatalf("token record not found: %v", err)
			}

			var gotEmail string
			err = testenv.DB.QueryRowContext(t.Context(), `
				SELECT email FROM users WHERE id = $1
			`, gotRec.UserId).Scan(&gotEmail)
			if err != nil {
				t.Errorf("token must be issued for an existing user: %v", err)
			}
			if got, want := gotEmail, tt.user.email; got != want {
				t.Errorf("token was issued for wrong user %s, want %s", got, want)
			}

			if got, want := gotRec.Device, tt.device; got != want {
				t.Errorf("got device '%s', want '%s'", got, want)
			}

			if d := gotRec.ExpiresAt.Sub(tt.signedInAt); d != 30*24*time.Hour {
				t.Errorf("token should expires in 30 days, actual TTL is %g day(s)", d.Hours()/24)
			}

			if d := cmp.Diff(gotRec.TokenHash, gotToken.Hash()); d != "" {
				t.Errorf("token must be hashed in DB, diff:\n%s", d)
			}
		})
	}

	if len(gotTokens) != len(test) || !isDistinct(gotTokens) {
		t.Errorf("tokens must be uniqueue across all sessions")
	}
}

// func TestAuth_SignUp(t *testing.T) {
// 	t.Cleanup(testenv.ResetDB)

// 	now := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)
// 	h := api.Handler{
// 		DB: testenv.DB,
// 		UserService: user.Service{
// 			DB:  testenv.DB,
// 			Now: func() time.Time { return now },
// 		},
// 	}
// 	rBody := api.SignUpReqBody{
// 		Email:    "test@example.com",
// 		Password: "Test$Password+123",
// 		Device:   "Pixel9a/Android16",
// 	}
// 	jBody, _ := json.Marshal(rBody)
// 	req := httptest.NewRequest("POST", "/signup", bytes.NewReader(jBody))
// 	req.Header.Set("Content-Type", "application/json")
// 	rec := httptest.NewRecorder()
// 	api.NewRouter(&h).ServeHTTP(rec, req)

// 	var got1 api.SignUpResBody
// 	if err := json.NewDecoder(rec.Body).Decode(&got1); err != nil {
// 		t.Fatalf("failed to decode response body: %v", err)
// 	}
// }
