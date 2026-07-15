// TODO: Garbage-collect expired tokens
package user

import (
	"context"
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
	ErrPswdInvalid     = errors.New("password has invalid format")
	ErrAuthFailed      = errors.New("email or password is incorrect")
	ErrTokenInvalid    = errors.New("token is invalid or has been expired")
)

type Credentials struct {
	Email      string
	Password   string
	DeviceKind string
}

// Printable ASCII characters only; 15-64 characters
var pswdRegex = regexp.MustCompile(`^[\x20-\x7E]{15,64}$`)

// TODO: Tweak the bcrypt cost
const bcryptCost = 12

// SignUp creates a fresh user account for the given email and issue a new authentication token.
func (s *Service) SignUp(ctx context.Context, crd Credentials) ([]byte, error) {
	if crd.DeviceKind == "" {
		return nil, ErrDeviceKindEmpty
	}
	email, err := mail.ParseAddress(crd.Email)
	if err != nil || email.Address != crd.Email {
		return nil, ErrEmailInvalid
	}
	if !pswdRegex.MatchString(crd.Password) {
		return nil, ErrPswdInvalid
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(crd.Password), bcryptCost)
	if err != nil {
		return nil, err
	}
	var id int
	err = s.DB.QueryRowContext(ctx, `
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
	return s.issueToken(ctx, id, crd.DeviceKind)
}

func (s *Service) SignIn(ctx context.Context, crd Credentials) ([]byte, error) {
	if crd.DeviceKind == "" {
		return nil, ErrDeviceKindEmpty
	}
	var dbHash []byte
	var id int
	err := s.DB.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1;
	`, crd.Email).Scan(&id, &dbHash)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return nil, ErrAuthFailed
	case err != nil:
		return nil, err
	}
	if bcrypt.CompareHashAndPassword(dbHash, []byte(crd.Password)) != nil {
		return nil, ErrAuthFailed
	}
	return s.issueToken(ctx, id, crd.DeviceKind)
}

func (s *Service) issueToken(ctx context.Context, id int, device string) ([]byte, error) {
	token := make([]byte, 32)
	if _, err := s.ReadSecureRand(token); err != nil {
		return nil, err
	}
	hashed := hashToken(token)
	expr := time.Now().AddDate(0, 0, tokenExpiresInDays)
	_, err := s.DB.ExecContext(ctx, `
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
