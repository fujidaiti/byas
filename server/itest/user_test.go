//go:build integration

package itest

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/feature/user"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
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

type pendingSignUpAttemptRecord struct {
	ID                   int
	Email                string
	PasswordHash         []byte
	VerificationCodeHash []byte
	TicketHash           []byte
	ExpiresAt            time.Time
}

func TestAuth_SignUp_Success(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	test := []struct {
		name, email, password string
		signUpAt              time.Time
	}{
		{
			name:     "alice",
			email:    "alice@gmail.com",
			password: "Test$Password+123",
			signUpAt: mustTimeUTC("2026-07-01 09:15:00"),
		},
		{
			name:     "alice (the second attempt)",
			email:    "alice@gmail.com",
			password: "New$Password+456",
			signUpAt: mustTimeUTC("2026-07-01 09:20:00"),
		},
		{
			name:     "bob (same password as alice)",
			email:    "bob@exchange.com",
			password: "Test$Password+123",
			signUpAt: mustTimeUTC("2027-08-20 14:00:59"),
		},
	}

	// Extract a verification code from the email body.
	codeRe := regexp.MustCompile(`\b(\d{6})\b`)
	s := user.Service{DB: testenv.DB()}
	var gotPswdHashes []string
	var gotTickets []user.AuthToken
	for _, tt := range test {
		s.Now = func() time.Time { return tt.signUpAt }

		var gotCode string
		s.SendEmail = func(_, _, body string) error {
			if m := codeRe.FindStringSubmatch(gotCode); len(m) > 0 {
				gotCode = m[0]
			}
			return nil
		}

		t.Run(tt.name, func(t *testing.T) {
			gotTicket, err := s.SignUp(
				t.Context(),
				must(user.ParseEmail(tt.email)),
				must(user.ValidatePassword(tt.password)),
				"remove this later",
			)
			if err != nil {
				t.Fatalf("got %v, want nil error", err)
			}
			gotTickets = append(gotTickets, gotTicket)

			var gotAtmpt pendingSignUpAttemptRecord
			scanRowOrFatal(t, `
				SELECT id, email, password_hash, verification_code_hash, ticket_hash, expires_at
				FROM pending_signup_attempts WHERE email = $1
			`, []any{tt.email}, &gotAtmpt.ID, &gotAtmpt.Email, &gotAtmpt.PasswordHash,
				&gotAtmpt.VerificationCodeHash, &gotAtmpt.TicketHash, &gotAtmpt.ExpiresAt,
			)
			gotPswdHashes = append(gotPswdHashes, string(gotAtmpt.PasswordHash))

			if gotAtmpt.Email != tt.email {
				t.Errorf("got %q, want %q", gotAtmpt.Email, tt.email)
			}
			if bytes.Equal(gotAtmpt.PasswordHash, []byte(tt.password)) {
				t.Error("raw password must not be stored")
			}
			if !bytes.Equal(gotAtmpt.TicketHash, gotTicket.Hash()) {
				t.Errorf("raw ticket must not be stored")
			}
			if gotCode == "" {
				t.Errorf("email must contain a 6-digits verification code")
			} else if bytes.Equal(gotAtmpt.VerificationCodeHash, []byte(gotCode)) {
				t.Errorf("raw verification code must no be stored")
			}
			if d := gotAtmpt.ExpiresAt.Sub(tt.signUpAt); d != 10*time.Minute {
				t.Errorf("got TTL %g min, want 10 min", d.Minutes())
			}
		})
	}

	if !isDistinct(gotPswdHashes) {
		t.Errorf("password hashes must be uniqueue even if raw passwords are identical")
	}
	if !isDistinct(gotTickets) {
		t.Errorf("tickets must be uniqueue")
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

func TestAuth_SignUp_PerEmailAddressThrottle(t *testing.T) {
	test := []struct {
		signUpAt time.Time
		wantErr  error
	}{
		{mustTimeUTC("2026-09-03 12:00:00"), nil},
		{mustTimeUTC("2026-09-03 12:10:56"), nil},
		{mustTimeUTC("2026-09-03 12:30:00"), nil},
		{mustTimeUTC("2026-09-03 12:30:01"), user.ErrTooManyAttempts},
		{mustTimeUTC("2026-09-03 12:59:59"), user.ErrTooManyAttempts},
		{mustTimeUTC("2026-09-03 13:00:00"), user.ErrTooManyAttempts},
		{mustTimeUTC("2026-09-03 13:00:01"), nil},
		{mustTimeUTC("2026-09-03 13:10:56"), user.ErrTooManyAttempts},
		{mustTimeUTC("2026-09-03 14:30:00"), nil},
	}

	s := user.Service{DB: testenv.DB()}
	for i, tt := range test {
		s.Now = func() time.Time { return tt.signUpAt }
		t.Run(fmt.Sprintf("attempt %d", i+1), func(t *testing.T) {
			_, got := s.SignUp(
				t.Context(), must(user.ParseEmail("alice@example.com")),
				must(user.ValidatePassword("Test$Password#1234")),
				"delete this later",
			)
			if !errors.Is(got, tt.wantErr) {
				t.Errorf("got %q, want %q", got, tt.wantErr)
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
		provisionTestAccount(t, u.email, u.password, u.signUpDevice, u.signUpAt)
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
	s := user.Service{DB: testenv.DB()}
	provisionTestAccount(t, alice.email, alice.password, alice.signUpDevice, alice.signUpAt)

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
	// Sign up
	addr, pswd := "alice@example.com", "alice#password$123"
	_, token1 := provisionTestAccount(t,
		addr, pswd, "Pixel9a", mustTimeUTC("2026-07-01 13:30:00"))

	// Sign in from other devices
	email := must(user.ParseEmail(addr))
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

func TestAuth_VerifyAuthToken(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	s := user.Service{DB: testenv.DB()}
	aEmail, aPswd := "alice@example.com", "alice#password$123"
	bEmail, bPswd := "bob@example.com", "bob#password$789"
	// Alice signs up
	aID, token1 := provisionTestAccount(t,
		aEmail, aPswd, "Pixel9a", mustTimeUTC("2026-07-01 13:30:00"))
	// Alice signs in from another device
	s.Now = func() time.Time { return mustTimeUTC("2026-07-02 09:00:00") }
	token2, err := s.SignIn(t.Context(), must(user.ParseEmail(aEmail)), aPswd, "iPad")
	if err != nil {
		t.Fatalf("failed to sign in: %v", err)
	}
	// Bob signs up
	bID, token3 := provisionTestAccount(t,
		bEmail, bPswd, "iPhone17", mustTimeUTC("2026-07-02 23:18:45"))
	// Bob signs in from another device
	s.Now = func() time.Time { return mustTimeUTC("2026-07-04 19:30:00") }
	token4, err := s.SignIn(t.Context(), must(user.ParseEmail(bEmail)), bPswd, "macbookAir 2020")
	if err != nil {
		t.Fatalf("failed to sign in: %v", err)
	}

	test := []struct {
		name    string
		token   user.AuthToken
		checkAt time.Time
		want    user.UserID
		wantErr error
	}{
		{
			name:    "alice's sign-up token",
			token:   token1,
			checkAt: mustTimeUTC("2026-07-01 13:30:30"),
			want:    aID,
		},
		{
			name:    "alice's sign-in token",
			token:   token2,
			checkAt: mustTimeUTC("2026-07-02 09:12:32"),
			want:    aID,
		},
		{
			name:    "bob's sign-up token",
			token:   token3,
			checkAt: mustTimeUTC("2026-07-12 02:10:00"),
			want:    bID,
		},
		{
			name:    "bob's expired sign-in token",
			token:   token4,
			checkAt: mustTimeUTC("2026-11-04 12:00:00"),
			want:    0,
			wantErr: user.ErrTokenInvalid,
		},
		{
			name:    "unknown token",
			token:   user.AuthToken{},
			checkAt: mustTimeUTC("2026-08-01 09:00:00"),
			want:    0,
			wantErr: user.ErrTokenInvalid,
		},
	}

	for _, tt := range test {
		s.Now = func() time.Time { return tt.checkAt }
		t.Run(tt.name, func(t *testing.T) {
			gotID, gotErr := s.VerifyAuthToken(t.Context(), tt.token.Encode())
			if gotID != tt.want {
				t.Errorf("got ID=%d, want %d", gotID, tt.want)
			}
			if !errors.Is(gotErr, tt.wantErr) {
				t.Errorf("got %q, want %q", gotErr, tt.wantErr)
			}
		})
	}
}

// Ticket fixtures: 32 random bytes, base64url-encoded — the same wire format
// that user.AuthToken.Encode produces. Fixed so tests are reproducible.
const (
	ticketAlice = "vaMr9K5HEEV9kldJoix-n4rLggBXWj6QrGrs59VlZD8"
	ticketBob   = "Ljpw4JKJAC6ylb8PblpQ890dstgAPTvmtXzmTJAhRKg"
	ticketCarol = "aNEzrkBC996ne6HafDO8q7K9XWPffYjTFnrkkxfy0lM"
)

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

func TestAuth_VerifySignUpEmailAddress_Success(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	test := []struct {
		name, ticket, email, password, code, device string
		signUpAt, expiresAt, verifiedAt             time.Time
	}{
		{
			name:       "alice",
			ticket:     ticketAlice,
			email:      "alice@gmail.com",
			password:   "Test$Password+123",
			code:       "123456",
			device:     "Pixel9a/Android16",
			signUpAt:   mustTimeUTC("2026-07-01 09:20:00"),
			expiresAt:  mustTimeUTC("2026-07-01 09:30:00"),
			verifiedAt: mustTimeUTC("2026-07-01 09:15:00"),
		},
		{
			name:       "bob (same password and code as alice)",
			ticket:     ticketBob,
			email:      "bob@exchange.com",
			password:   "Test$Password+123",
			code:       "123456",
			device:     "iPhone17/iOS26",
			expiresAt:  mustTimeUTC("2027-08-20 14:15:00"),
			verifiedAt: mustTimeUTC("2027-08-20 14:00:59"),
		},
	}

	s := user.Service{DB: testenv.DB()}
	var gotTokens []user.AuthToken
	for i, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			aID := seedPendingSignUpAttempt(
				t, tt.ticket, tt.email, tt.password, tt.code, tt.expiresAt,
			)
			wantPswdHash := scanValOrFatal[[]byte](t, `
				SELECT password_hash FROM pending_signup_attempts WHERE id = $1
			`, aID)

			s.Now = func() time.Time { return tt.verifiedAt }
			gotToken, err := s.VerifySignUpEmailAddress(
				t.Context(), tt.ticket, tt.code, tt.device)
			if err != nil {
				t.Fatalf("failed to verify the email address: %v", err)
			}
			if gotToken.Encode() == "" {
				t.Fatal("an auth token must be issued on success")
			}
			gotTokens = append(gotTokens, gotToken)

			var gotUser userRecord
			scanRowOrFatal(t, `
				SELECT id, email, password_hash FROM users WHERE email = $1;
			`, []any{tt.email}, &gotUser.ID, &gotUser.Email, &gotUser.PasswordHash)

			if gotUser.Email != tt.email {
				t.Errorf("created user has a malformed email %q, want %q", gotUser.Email, tt.email)
			}

			// The pending password hash must be carried over as-is, not recomputed.
			if d := cmp.Diff(gotUser.PasswordHash, wantPswdHash); d != "" {
				t.Errorf("password hash must be carried over from the attempt, diff:\n%s", d)
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

			if d := gotRec.ExpiresAt.Sub(tt.verifiedAt); d != 30*24*time.Hour {
				t.Errorf("token should expires in 30 days, got TTL = %g day(s)", d.Hours()/24)
			}

			if d := cmp.Diff(gotRec.TokenHash, gotToken.Hash()); d != "" {
				t.Errorf("token must be hashed in DB, diff:\n%s", d)
			}
		})
	}

	if !isDistinct(gotTokens) {
		t.Errorf("auth tokens must be uniqueue")
	}
}

func TestAuth_VerifySignUpEmailAddress_Failure(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	alice := struct {
		email, password, device string
		ticket, code            string
		expiresAt               time.Time
	}{
		"alice@example.com", "alice#password$123", "Pixel9a/Android16",
		ticketAlice, "123456",
		mustTimeUTC("2026-07-01 09:30:00"),
	}

	test := []struct {
		name, ticket, code, device string
		signUpAt, verifiedAt       time.Time
		wantErr                    error
	}{
		{
			name:       "wrong code",
			ticket:     alice.ticket,
			code:       "654321",
			device:     alice.device,
			signUpAt:   mustTimeUTC("2026-07-01 09:15:00"),
			verifiedAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrEmailVerifyFailed,
		},
		{
			name:       "unknown ticket",
			ticket:     ticketCarol,
			code:       alice.code,
			device:     alice.device,
			signUpAt:   mustTimeUTC("2026-07-01 09:15:00"),
			verifiedAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrEmailVerifyFailed,
		},
		{
			// TODO: This branch should report a sentinel error so callers can
			// distinguish a malformed ticket. Only non-nil is asserted for now.
			name:       "malformed ticket",
			ticket:     "not-a-ticket",
			code:       alice.code,
			device:     alice.device,
			signUpAt:   mustTimeUTC("2026-07-01 09:15:00"),
			verifiedAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    nil,
		},
		{
			name:       "no device info",
			ticket:     alice.ticket,
			code:       alice.code,
			device:     "",
			signUpAt:   mustTimeUTC("2026-07-01 09:15:00"),
			verifiedAt: mustTimeUTC("2026-07-01 09:16:00"),
			wantErr:    user.ErrDeviceEmpty,
		},
	}

	s := user.Service{DB: testenv.DB()}
	aID := seedPendingSignUpAttempt(
		t, alice.ticket, alice.email, alice.password, alice.code, alice.expiresAt,
	)

	for _, tt := range test {
		t.Run(tt.name, func(t *testing.T) {
			s.Now = func() time.Time { return tt.verifiedAt }
			gotToken, gotErr := s.VerifySignUpEmailAddress(
				t.Context(), tt.ticket, tt.code, tt.device)

			if gotErr == nil {
				t.Fatalf("want an error, got nil")
			}
			if tt.wantErr != nil && !errors.Is(gotErr, tt.wantErr) {
				t.Errorf("got %q, want %q", gotErr, tt.wantErr)
			}
			if got := gotToken.Encode(); got != "" {
				t.Errorf("must be an empty token, got %v", got)
			}

			var nUsers int
			scanRowOrFatal(t, `SELECT COUNT(*) FROM users`, nil, &nUsers)
			if nUsers != 0 {
				t.Errorf("no user must be created, got %d rows", nUsers)
			}

			var nTokens int
			scanRowOrFatal(t, `SELECT COUNT(*) FROM auth_tokens`, nil, &nTokens)
			if nTokens != 0 {
				t.Errorf("no token must be issued, got %d rows", nTokens)
			}

			// Only the expiry and success paths delete the attempt.
			var nAttempts int
			scanRowOrFatal(t, `
				SELECT COUNT(*) FROM pending_signup_attempts WHERE id = $1
			`, []any{aID}, &nAttempts)
			if nAttempts != 1 {
				t.Errorf("the attempt must be retained, got %d rows", nAttempts)
			}
		})
	}
}

func TestAuth_VerifySignUpEmailAddress_DuplicateVerifications(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	const (
		email  = "alice@example.com"
		code   = "123456"
		device = "Pixel9a/Android"
	)
	seedPendingSignUpAttempt(
		t, ticketAlice, email, "Test#Password$1234", code,
		mustTimeUTC("2026-09-03 12:00:00"),
	)

	s := user.Service{
		DB:  testenv.DB(),
		Now: func() time.Time { return mustTimeUTC("2026-09-03 11:52:00") },
	}
	_, gotErr := s.VerifySignUpEmailAddress(t.Context(), ticketAlice, code, device)
	if gotErr != nil {
		t.Fatal("new account must be created")
	}

	// Duplicate verifications must fail even the attempt isn't expired and the code is correct.
	s.Now = func() time.Time { return mustTimeUTC("2026-09-03 11:58:00") }
	_, gotErr = s.VerifySignUpEmailAddress(t.Context(), ticketAlice, code, device)
	if want := user.ErrEmailTaken; !errors.Is(gotErr, want) {
		t.Errorf("got %q, want %q", gotErr, want)
	}

	var n int
	scanRowOrFatal(t, `SELECT COUNT(*) FROM users`, []any{}, &n)
	if n != 1 {
		t.Errorf("got %d user rows, want exactly one", n)
	}
	scanRowOrFatal(t, `SELECT COUNT(*) FROM auth_tokens`, []any{}, &n)
	if n != 1 {
		t.Errorf("got %d token rows, want exactly one", n)
	}
}

func TestAuth_VerifySignUpEmailAddress_Expired(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	expiresAt := mustTimeUTC("2026-07-01 09:30:00")
	test := []struct {
		name          string
		email, ticket string
		verifyAt      time.Time
		wantErr       error
		wantAccount   bool
	}{
		{
			name:        "before the expiry",
			email:       "alice@example.com",
			ticket:      ticketAlice,
			verifyAt:    expiresAt.Add(-time.Second),
			wantErr:     nil,
			wantAccount: true,
		},
		{
			name:        "exactly at the expiry",
			email:       "bob@example.com",
			ticket:      ticketBob,
			verifyAt:    expiresAt,
			wantErr:     nil,
			wantAccount: true,
		},
		{
			name:        "after the expiry",
			email:       "carol@example.com",
			ticket:      ticketCarol,
			verifyAt:    expiresAt.Add(time.Second),
			wantErr:     user.ErrEmailVerifyCodeExpired,
			wantAccount: false,
		},
	}

	s := user.Service{DB: testenv.DB()}
	for _, tt := range test {
		seedPendingSignUpAttempt(
			t, tt.ticket, tt.email, "test#password$123", "123456", expiresAt,
		)
		s.Now = func() time.Time { return tt.verifyAt }
		t.Run(tt.name, func(t *testing.T) {
			gotToken, gotErr := s.VerifySignUpEmailAddress(
				t.Context(), tt.ticket, "123456", "Pixel9a/Android",
			)
			var nUsers int
			scanRowOrFatal(t, `
				SELECT COUNT(*) FROM users WHERE email = $1
			`, []any{tt.email}, &nUsers)

			if !errors.Is(gotErr, tt.wantErr) {
				t.Errorf("got %q, want %q", gotErr, tt.wantErr)
			}
			switch tkn := gotToken.Encode(); {
			case tt.wantAccount && tkn == "":
				t.Errorf("got empty token, want valid one")
			case !tt.wantAccount && tkn != "":
				t.Errorf("got %v, want empty token", gotToken)
			}
			switch {
			case tt.wantAccount && nUsers != 1:
				t.Errorf("exactly one user must be created, got %d rows", nUsers)
			case !tt.wantAccount && nUsers != 0:
				t.Errorf("no user must be created, got %d rows", nUsers)
			}
		})
	}
}

func TestAuth_VerifySignUpEmailAddress_EmailAlreadyRegistered(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	const (
		email          = "alice@example.com"
		signUpPassword = "alice#password$123"
		signUpDevice   = "Pixel9a/Android16"
		// The pending attempt was started before the address got registered.
		pendingPassword = "alice#password$987"
		pendingCode     = "123456"
		pendingDevice   = "iPhone17/iOS26"
	)

	// The address is registered through the regular sign-up path first.
	provisionTestAccount(
		t, email, signUpPassword, signUpDevice, mustTimeUTC("2026-07-01 09:00:00"),
	)
	var wantUser userRecord
	scanRowOrFatal(t, `
		SELECT id, email, password_hash FROM users WHERE email = $1
	`, []any{email}, &wantUser.ID, &wantUser.Email, &wantUser.PasswordHash)

	seedPendingSignUpAttempt(
		t, ticketAlice, email, pendingPassword, pendingCode,
		mustTimeUTC("2026-07-01 09:30:00"),
	)

	s := user.Service{
		DB:  testenv.DB(),
		Now: func() time.Time { return mustTimeUTC("2026-07-01 09:15:00") },
	}
	gotToken, gotErr := s.VerifySignUpEmailAddress(
		t.Context(), ticketAlice, pendingCode, pendingDevice)

	if gotErr == nil {
		t.Fatal("want an error, got nil")
	}
	if got := gotToken.Encode(); got != "" {
		t.Errorf("must be an empty token, got %v", got)
	}

	gotUsers := scanRowsOrFatal(t, `
		SELECT id, email, password_hash FROM users
	`, nil, func(r *sql.Rows, d *userRecord) error {
		return r.Scan(&d.ID, &d.Email, &d.PasswordHash)
	})
	if n := len(gotUsers); n != 1 {
		t.Fatalf("exactly one user must be registered, got %d users", n)
	}
	if d := cmp.Diff(gotUsers[0], wantUser); d != "" {
		t.Errorf("already registered user must never be touched, diff:\n%s", d)
	}

	var nTokens int
	scanRowOrFatal(t, `
		SELECT COUNT(*) FROM auth_tokens WHERE device = $1
	`, []any{pendingDevice}, &nTokens)
	if nTokens != 0 {
		t.Errorf("no token must be issued for the pending device, got %d rows", nTokens)
	}
}

func TestAuth_VerifySignUpEmailAddress_FailCountCap(t *testing.T) {
	t.Cleanup(testenv.TearDown)

	_ = seedPendingSignUpAttempt(
		t, ticketAlice, "alice@example.com", "alice#password$123", "123456",
		mustTimeUTC("2026-07-01 09:30:00"),
	)

	test := []struct {
		code     string
		wantErr  error
		verifyAt time.Time
	}{
		{"000000", user.ErrEmailVerifyFailed, mustTimeUTC("2026-07-01 09:20:00")},
		{"111111", user.ErrEmailVerifyFailed, mustTimeUTC("2026-07-01 09:20:20")},
		{"222222", user.ErrEmailVerifyFailed, mustTimeUTC("2026-07-01 09:20:40")},
		{"333333", user.ErrEmailVerifyFailed, mustTimeUTC("2026-07-01 09:21:00")},
		{"444444", user.ErrEmailVerifyFailed, mustTimeUTC("2026-07-01 09:21:30")},
		// The last wrong code reached the cap (5 times), so the ticket is dead:
		// even the correct code must not verify it.
		{"123456", user.ErrEmailVerifyCodeExpired, mustTimeUTC("2026-07-01 09:22:00")},
	}

	s := user.Service{DB: testenv.DB()}
	for i, tt := range test {
		attempt := i + 1
		s.Now = func() time.Time { return tt.verifyAt }
		t.Run(fmt.Sprintf("attempt %d", attempt), func(t *testing.T) {
			gotToken, gotErr := s.VerifySignUpEmailAddress(
				t.Context(), ticketAlice, tt.code, "Pixel9a/Android",
			)
			if !errors.Is(gotErr, tt.wantErr) {
				t.Fatalf("attempt %d: got %q, want %q", attempt, gotErr, tt.wantErr)
			}
			if got := gotToken.Encode(); got != "" {
				t.Errorf("attempt %d: got %v, want an empty token", attempt, got)
			}
		})
	}

	var n int
	scanRowOrFatal(t, `SELECT COUNT(*) FROM users`, nil, &n)
	if n != 0 {
		t.Errorf("no user must be created, got %d rows", n)
	}
	scanRowOrFatal(t, `SELECT COUNT(*) FROM auth_tokens`, nil, &n)
	if n != 0 {
		t.Errorf("no token must be issued, got %d rows", n)
	}
}
