// TODO: Garbage-collect expired tokens
package user

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"errors"
	"net/mail"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// TODO: Tweak the bcrypt cost
const bcryptCost = 12
const tokenExpiresInDays = 30

var (
	ErrDeviceKindEmpty = errors.New("device kind is empty")
	ErrEmailInvalid    = errors.New("email has invalid format")
	ErrEmailTaken      = errors.New("email already exists")
	ErrPasswordTooLong = errors.New("password length exceeds 72 bytes")
	ErrAuthFailed      = errors.New("email or password is incorrect")
	ErrTokenInvalid    = errors.New("token is invalid or has been expired")
)

type Credentials struct {
	Email      string
	Password   string
	DeviceKind string
}

func SignUp(ctx context.Context, db *sql.DB, crd Credentials) ([]byte, error) {
	if crd.DeviceKind == "" {
		return nil, ErrDeviceKindEmpty
	}
	email, err := mail.ParseAddress(crd.Email)
	if err != nil || email.Address != crd.Email {
		return nil, ErrEmailInvalid
	}
	// TODO: Validate email and return an error if invalid
	hash, err := bcrypt.GenerateFromPassword([]byte(crd.Password), bcryptCost)
	if err != nil {
		return nil, ErrPasswordTooLong
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
	if err := bcrypt.CompareHashAndPassword(dbHash, []byte(crd.Password)); err != nil {
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
