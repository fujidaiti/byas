//go:build integration

package itest

import (
	"bytes"
	"database/sql"
	"errors"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
	"github.com/google/go-cmp/cmp"
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

func TestAuth_SignUp_Success(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	test := []struct {
		name, email, password, device string
		signUpAt                      time.Time
	}{
		{
			name:     "alice",
			email:    "alice@gmail.com",
			password: "Test$Password+123",
			device:   "Pixel9a/Android16",
			signUpAt: mustTimeUTC("2026-07-01 09:15:00"),
		},
		{
			name:     "bob (same password as alice)",
			email:    "bob@exchange.com",
			password: "Test$Password+123",
			device:   "iPhone17/iOS26",
			signUpAt: mustTimeUTC("2027-08-20 14:00:59"),
		},
	}

	s := user.Service{DB: testenv.DB()}
	var gotPswdHashes []string
	var gotTokens []user.AuthToken
	for i, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			s.Now = func() time.Time { return tt.signUpAt }
			gotToken, err := s.SignUp(
				t.Context(),
				must(user.ParseEmail(tt.email)),
				must(user.ValidatePassword(tt.password)),
				tt.device,
			)
			if err != nil {
				t.Fatalf("failed to create user account: %v", err)
			}
			gotTokens = append(gotTokens, gotToken)

			var gotUser userRecord
			scanRowOrFatal(t, `
				SELECT id, email, password_hash FROM users WHERE email = $1;
			`, []any{tt.email}, &gotUser.ID, &gotUser.Email, &gotUser.PasswordHash)
			gotPswdHashes = append(gotPswdHashes, string(gotUser.PasswordHash))

			if gotUser.Email != tt.email {
				t.Errorf("created user has a malformed email %q, want %q", gotUser.Email, tt.email)
			}

			if bytes.Equal(gotUser.PasswordHash, []byte(tt.password)) {
				t.Error("raw password must not be stored in DB")
			}

			var n int
			scanRowOrFatal(t, `SELECT COUNT(*) from auth_tokens`, nil, &n)
			if want := i + 1; n != want {
				t.Errorf("only one token record must be added, got +%d rows", n-want)
			}

			var gotRec authTokenRecord
			scanRowOrFatal(t, `
				SELECT user_id, device, token_hash, expires_at FROM auth_tokens
				ORDER BY created_at DESC LIMIT 1
			`, nil, &gotRec.UserId, &gotRec.Device, &gotRec.TokenHash, &gotRec.ExpiresAt)
			if got, want := gotRec.UserId, gotUser.ID; got != want {
				t.Errorf("token was issued for wrong user Id=%d, want Id=%d", got, want)
			}

			if gotRec.Device != tt.device {
				t.Errorf("got device %q, want %q", gotRec.Device, tt.device)
			}

			if d := gotRec.ExpiresAt.Sub(tt.signUpAt); d != 30*24*time.Hour {
				t.Errorf("token should expires in 30 days, got TTL = %g day(s)", d.Hours()/24)
			}

			if d := cmp.Diff(gotRec.TokenHash, gotToken.Hash()); d != "" {
				t.Errorf("token must be hashed in DB, diff:\n%s", d)
			}
		})
	}

	if !isDistinct(gotPswdHashes) {
		t.Errorf("password hashes must be uniqueue for each user even if raw passwords are identical")
	}
	if !isDistinct(gotTokens) {
		t.Errorf("auth tokens must be uniqueue")
	}
}

func TestAuth_SignUp_EmailUniqueness(t *testing.T) {
	t.Cleanup(testenv.TearDown)

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
		{
			name:     "same but capitalized email",
			email:    "ALICE@GMAIL.COM",
			password: "test$Password123",
			device:   "Pixel9a/Android16",
			wantErr:  user.ErrEmailTaken,
		},
	}

	s := user.Service{
		DB:  testenv.DB(),
		Now: func() time.Time { return time.Now() },
	}
	var firstUser *userRecord
	for _, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			_, gotErr := s.SignUp(
				t.Context(),
				must(user.ParseEmail(tt.email)),
				must(user.ValidatePassword(tt.password)),
				tt.device,
			)
			if !errors.Is(gotErr, tt.wantErr) {
				t.Errorf("got '%v', want '%v'", gotErr, tt.wantErr)
			}

			gotUsers := scanRowsOrFatal(t, `
				SELECT id, email, password_hash FROM users
			`, nil, func(r *sql.Rows, d *userRecord) error {
				return r.Scan(&d.ID, &d.Email, &d.PasswordHash)
			})

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

func TestAuth_SignIn_Success(t *testing.T) {
	t.Cleanup(testenv.TearDown)
	type User struct {
		email, password, signUpDevice string
		signUpAt                      time.Time
	}
	users := map[string]*User{
		"alice": {
			email:        "alice@example.com",
			password:     "alice#password$123",
			signUpDevice: "Pixel9a/Android17",
			signUpAt:     mustTimeUTC("2026-07-01 09:15:00"),
		},
		"bob": {
			email:        "bob@forest.com",
			password:     "bob#password$123",
			signUpDevice: "GalaxyS26/Android16",
			signUpAt:     mustTimeUTC("2026-07-10 14:40:05"),
		},
	}
	test := []struct {
		name, device string
		user         *User
		signInAt     time.Time
	}{
		{
			name:     "alice's first session",
			device:   "Pixel9a/Android17",
			user:     users["alice"],
			signInAt: mustTimeUTC("2026-07-01 09:15:30"),
		},
		{
			name:     "bob's first session",
			device:   "GalaxyS26/Android16",
			user:     users["bob"],
			signInAt: mustTimeUTC("2026-07-10 14:45:18"),
		},
		{
			name:     "alice's second session",
			device:   "Pixel9a/Android17",
			user:     users["alice"],
			signInAt: mustTimeUTC("2026-07-08 07:45:00"),
		},
		{
			name:     "alice's third session from different device",
			device:   "iPhone17/iOS26",
			user:     users["alice"],
			signInAt: mustTimeUTC("2026-07-14 21:05:40"),
		},
		{
			name:   "bob's second session but email capitalized",
			device: "GalaxyS26/Android16",
			user: &User{
				email:        "BOB@FOREST.COM",
				password:     users["bob"].password,
				signUpDevice: users["bob"].signUpDevice,
				signUpAt:     users["bob"].signUpAt,
			},
			signInAt: mustTimeUTC("2026-07-10 14:45:18"),
		},
	}

	s := user.Service{DB: testenv.DB()}
	// Seed users
	for _, u := range users {
		s.Now = func() time.Time { return u.signUpAt }
		var err error
		_, err = s.SignUp(
			t.Context(),
			must(user.ParseEmail(u.email)),
			must(user.ValidatePassword(u.password)),
			u.signUpDevice,
		)
		if err != nil {
			t.Fatalf("failed to seed user (%s): %v", u.email, err)
		}
	}

	var gotTokens []user.AuthToken
	for i, tt := range test {
		s.Now = func() time.Time { return tt.signInAt }
		t.Run(tt.name, func(t *testing.T) {
			email := must(user.ParseEmail(tt.user.email))
			gotToken, err := s.SignIn(t.Context(), email, tt.user.password, tt.device)
			if err != nil {
				t.Fatalf("failed to sign-in: %v", err)
			}
			gotTokens = append(gotTokens, gotToken)

			var n int
			scanRowOrFatal(t, `SELECT COUNT(*) from auth_tokens`, nil, &n)
			if want := len(users) + i + 1; want != n {
				t.Errorf("only one token record must be added, got %d extra rows", n-want)
			}

			var gotRec authTokenRecord
			scanRowOrFatal(t, `
				SELECT user_id, device, token_hash, expires_at FROM auth_tokens
				ORDER BY created_at DESC LIMIT 1
			`, nil, &gotRec.UserId, &gotRec.Device, &gotRec.TokenHash, &gotRec.ExpiresAt)

			var gotEmail string
			scanRowOrFatal(t, `
				SELECT email FROM users WHERE id = $1
			`, []any{gotRec.UserId}, &gotEmail)
			if got, err := user.ParseEmail(gotEmail); err != nil {
				t.Errorf("saved email %q is malformed, want %v", gotEmail, email)
			} else if got != email {
				t.Errorf("token was issued for wrong user %v, want %v", got, email)
			}

			if gotRec.Device != tt.device {
				t.Errorf("got device %q, want %q", gotRec.Device, tt.device)
			}

			if d := gotRec.ExpiresAt.Sub(tt.signInAt); d != 30*24*time.Hour {
				t.Errorf("token should expires in 30 days, actual TTL is %g day(s)", d.Hours()/24)
			}

			if d := cmp.Diff(gotRec.TokenHash, gotToken.Hash()); d != "" {
				t.Errorf("token must be hashed in DB, diff:\n%s", d)
			}
		})
	}

	if !isDistinct(gotTokens) {
		t.Errorf("tokens must be uniqueue across all sessions")
	}
}

func TestAuth_SignIn_Failure(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	alice := struct {
		email, password, signUpDevice string
		signUpAt                      time.Time
	}{
		"alice@example.com", "alice#password$123", "Pixel9a/Android16",
		mustTimeUTC("2026-07-01 09:15:00"),
	}
	test := []struct {
		name, email, password, device string
		signedInAt                    time.Time
		wantErr                       error
	}{
		{
			name:       "wrong password",
			email:      alice.email,
			password:   "wrong#" + alice.password,
			device:     alice.signUpDevice,
			signedInAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrAuthFailed,
		},
		{
			name:       "unregistered user",
			email:      "unregistered." + alice.email,
			password:   alice.password,
			device:     alice.signUpDevice,
			signedInAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrAuthFailed,
		},
		{
			name:       "no device info",
			email:      alice.email,
			password:   alice.password,
			device:     "",
			signedInAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrDeviceEmpty,
		},
	}

	// Seed user
	s := user.Service{DB: testenv.DB(), Now: func() time.Time { return alice.signUpAt }}
	var err error
	_, err = s.SignUp(
		t.Context(),
		must(user.ParseEmail(alice.email)),
		must(user.ValidatePassword(alice.password)),
		alice.signUpDevice,
	)
	if err != nil {
		t.Fatalf("failed to seed user: %v", err)
	}

	for _, tt := range test {
		s.Now = func() time.Time { return tt.signedInAt }
		t.Run(tt.name, func(t *testing.T) {
			got1, got2 := s.SignIn(
				t.Context(), must(user.ParseEmail(tt.email)),
				tt.password, tt.device,
			)
			if !errors.Is(got2, tt.wantErr) {
				t.Errorf("got %v, want %v", got2, tt.wantErr)
			}
			if got := got1.Encode(); got != "" {
				t.Errorf("must be an empty token, got %v", got)
			}

			var n int
			scanRowOrFatal(t, `SELECT COUNT(*) from auth_tokens`, nil, &n)
			if got := n - 1; got != 0 {
				t.Errorf("no extra token must be issued, got %d extra rows", got)
			}
		})
	}
}

func TestAuth_SignOut(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	s := user.Service{DB: testenv.DB()}
	email := must(user.ParseEmail("alice@example.com"))
	pswd := "alice#password$123"
	// Sign up
	s.Now = func() time.Time { return mustTimeUTC("2026-07-01 13:30:00") }
	token1, err := s.SignUp(t.Context(), email, must(user.ValidatePassword(pswd)), "Pixel9a")
	if err != nil {
		t.Fatalf("failed to sign up: %v", err)
	}
	// Sign in from other devices
	s.Now = func() time.Time { return mustTimeUTC("2026-07-02 23:18:45") }
	token2, err := s.SignIn(t.Context(), email, pswd, "iPhone17")
	if err != nil {
		t.Fatalf("failed to sign in: %v", err)
	}
	s.Now = func() time.Time { return mustTimeUTC("2026-07-04 19:30:00") }
	token3, err := s.SignIn(t.Context(), email, pswd, "macbookAir2020")
	if err != nil {
		t.Fatalf("failed to sign in: %v", err)
	}

	test := []struct {
		name        string
		token       user.AuthToken
		signedOutAt time.Time
	}{
		{
			name:        "from signed-up device",
			token:       token1,
			signedOutAt: mustTimeUTC("2026-07-08 12:33:33"),
		},
		{
			name:        "from signed-in device",
			token:       token2,
			signedOutAt: mustTimeUTC("2026-07-12 02:10:00"),
		},
		{
			name:        "already signed out",
			token:       token2,
			signedOutAt: mustTimeUTC("2026-07-12 02:11:00"),
		},
		{
			name:        "unregistered user",
			token:       user.AuthToken{},
			signedOutAt: mustTimeUTC("2026-08-01 09:00:00"),
		},
		{
			name:        "outdated",
			token:       token3,
			signedOutAt: mustTimeUTC("2029-11-04 12:00:00"),
		},
	}

	for _, tt := range test {
		s.Now = func() time.Time { return tt.signedOutAt }
		t.Run(tt.name, func(t *testing.T) {
			if got := s.SignOut(t.Context(), tt.token.Encode()); got != nil {
				t.Errorf("got %v, want a nil error", got)
			}

			var n int
			scanRowOrFatal(t, `
				SELECT COUNT(*) FROM auth_tokens WHERE token_hash = $1
			`, []any{tt.token.Hash()}, &n)
			if n != 0 {
				t.Errorf("got %d rows: token still exists", n)
			}
		})
	}
}
