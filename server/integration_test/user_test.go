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
		rawToken, err := base64.RawURLEncoding.DecodeString(got1.Token)
		if err != nil {
			t.Errorf("returned token must be a valid Base64URL with no padding,　but got: %s", got1.Token)
		}
		if l := len(rawToken); l != 32 {
			t.Errorf("raw token must be 32 bytes, but got %d bytes", l)
		}

		var got2 userRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, email, password_hash FROM users WHERE email = $1;
		`, rBody.Email).Scan(&got2.ID, &got2.Email, &got2.PasswordHash)
		if err != nil {
			t.Fatalf("failed to fetch created user: %v", err)
		}
		want2 := userRecord{
			ID:    1,
			Email: rBody.Email,
		}
		if d := cmp.Diff(want2, got2, cmpopts.IgnoreFields(userRecord{}, "PasswordHash")); d != "" {
			t.Errorf("unexpected user record:\n%s", d)
		}
		if err := bcrypt.CompareHashAndPassword(
			got2.PasswordHash,
			[]byte(rBody.Password),
		); err != nil {
			t.Errorf("a bcrypt hash should be saved instead of the real password, but it looks like not: %v", err)
		}

		var got3 authTokenRecord
		err = db.QueryRowContext(t.Context(), `
			SELECT id, user_id, device_kind, token_hash, expires_at FROM auth_tokens WHERE user_id = $1;
		`, want2.ID).Scan(&got3.ID, &got3.UserId, &got3.DeviceKind, &got3.TokenHash, &got3.ExpiresAt)
		if err != nil {
			t.Fatalf("failed to fetch issued token: %v", err)
		}
		want3 := authTokenRecord{ID: 1, UserId: 1, DeviceKind: rBody.DeviceKind}
		if d := cmp.Diff(want3, got3, cmpopts.IgnoreFields(authTokenRecord{}, "TokenHash", "ExpiresAt")); d != "" {
			t.Errorf("unexpected token record:\n%s", d)
		}
		if d := got3.ExpiresAt.Sub(now); d != 30*24*time.Hour {
			t.Errorf("token should expires in 30 days, but actual TTL is %g hour(s)", d.Hours())
		}
		if bytes.Equal(got3.TokenHash, rawToken) {
			t.Error("raw token must not be stored in DB")
		}
		if d := cmp.Diff(got3.TokenHash, new(sha256.Sum256(rawToken))[:]); d != "" {
			t.Errorf("token must be SHA256-hashed in DB; actual diff:\n%s", d)
		}
	})
}
