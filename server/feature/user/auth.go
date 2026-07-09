// TODO: Garbage-collect expired tokens
package user

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"errors"
	"net/mail"
	"regexp"
	"time"

	"golang.org/x/crypto/bcrypt"
)

const tokenExpiresInDays = 30

var (
	ErrDeviceKindEmpty = errors.New("device kind is empty")
	ErrEmailInvalid    = errors.New("email has invalid format")
	ErrEmailTaken      = errors.New("email already exists")
	ErrAuthFailed      = errors.New("email or password is incorrect")
	ErrTokenInvalid    = errors.New("token is invalid or has been expired")
)

type Credentials struct {
	Email      string
	Password   Password
	DeviceKind string
}

type Password struct{ value string }

// Printable ASCII characters only; 15-64 characters
var pswdRegex = regexp.MustCompile(`^[\x20-\x7E]{15,64}$`)

func ValidatePassword(p string) *Password {
	if !pswdRegex.MatchString(p) {
		return nil
	}
	return &Password{p}
}

// TODO: Tweak the bcrypt cost
const bcryptCost = 12

func (p *Password) hash() ([]byte, error) {
	return bcrypt.GenerateFromPassword([]byte(p.value), bcryptCost)
}

func (p *Password) equals(hash []byte) bool {
	return bcrypt.CompareHashAndPassword(hash, []byte(p.value)) == nil
}

func SignUp(ctx context.Context, db *sql.DB, crd Credentials) ([]byte, error) {
	if crd.DeviceKind == "" {
		return nil, ErrDeviceKindEmpty
	}
	email, err := mail.ParseAddress(crd.Email)
	if err != nil || email.Address != crd.Email {
		return nil, ErrEmailInvalid
	}
	hash, err := crd.Password.hash()
	if err != nil {
		return nil, err
	}
	var id int
	err = db.QueryRowContext(ctx, `
		INSERT INTO users (email, password_hash)
		VALUES ($1, $2)
		ON CONFLICT (email) DO NOTHING
		RETURNING id;
	`, email.Address, hash).Scan(&id)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return nil, ErrEmailTaken
	case err != nil:
		return nil, err
	}
	return issueToken(ctx, db, id, crd.DeviceKind)
}

func SignIn(ctx context.Context, db *sql.DB, crd Credentials) ([]byte, error) {
	if crd.DeviceKind == "" {
		return nil, ErrDeviceKindEmpty
	}
	var dbHash []byte
	var id int
	err := db.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1;
	`, crd.Email).Scan(&id, &dbHash)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return nil, ErrAuthFailed
	case err != nil:
		return nil, err
	}
	if !crd.Password.equals(dbHash) {
		return nil, ErrAuthFailed
	}
	return issueToken(ctx, db, id, crd.DeviceKind)
}

func issueToken(ctx context.Context, db *sql.DB, id int, device string) ([]byte, error) {
	token := make([]byte, 32)
	if _, err := rand.Read(token); err != nil {
		return nil, err
	}
	hashed := hashToken(token)
	expr := time.Now().AddDate(0, 0, tokenExpiresInDays)
	_, err := db.ExecContext(ctx, `
		INSERT INTO auth_tokens (user_id, device_kind, token_hash, expires_at)
		VALUES ($1, $2, $3, $4);
	`, id, device, hashed, expr)
	if err != nil {
		return nil, err
	}
	return token, nil
}

func hashToken(raw []byte) []byte {
	h := sha256.Sum256(raw)
	return h[:]
}
