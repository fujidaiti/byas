// TODO: Garbage-collect expired tokens
package user

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"net/mail"
	"regexp"

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

type UserID = int

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
func (s *Service) SignUp(ctx context.Context, crd Credentials) (string, error) {
	if crd.DeviceKind == "" {
		return "", ErrDeviceKindEmpty
	}
	email, err := mail.ParseAddress(crd.Email)
	if err != nil || email.Address != crd.Email {
		return "", ErrEmailInvalid
	}
	if !pswdRegex.MatchString(crd.Password) {
		return "", ErrPswdInvalid
	}
	id, err := s.CreateUserAccount(ctx, email.Address, crd.Password)
	if err != nil {
		return "", err
	}
	return s.IssueAuthToken(ctx, id, crd.DeviceKind)
}

func (s *Service) SignIn(ctx context.Context, crd Credentials) (string, error) {
	if crd.DeviceKind == "" {
		return "", ErrDeviceKindEmpty
	}
	var dbHash []byte
	var id int
	err := s.DB.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1;
	`, crd.Email).Scan(&id, &dbHash)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return "", ErrAuthFailed
	case err != nil:
		return "", err
	}
	if bcrypt.CompareHashAndPassword(dbHash, []byte(crd.Password)) != nil {
		return "", ErrAuthFailed
	}
	return s.IssueAuthToken(ctx, id, crd.DeviceKind)
}

func (s *Service) CreateUserAccount(ctx context.Context, email, password string) (UserID, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return 0, err
	}
	var id int
	err = s.DB.QueryRowContext(ctx, `
		INSERT INTO users (email, password_hash)
		VALUES ($1, $2)
		ON CONFLICT (email) DO NOTHING
		RETURNING id;
	`, email, hash).Scan(&id)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return 0, ErrEmailTaken
	case err != nil:
		return 0, err
	}
	return id, nil
}

func (s *Service) IssueAuthToken(ctx context.Context, id UserID, device string) (string, error) {
	token := make([]byte, 32)
	_, err := rand.Read(token)
	if err != nil {
		return "", err
	}
	hashed := hashToken(token)
	expr := s.Now().AddDate(0, 0, tokenExpiresInDays)
	_, err = s.DB.ExecContext(ctx, `
		INSERT INTO auth_tokens (user_id, device_kind, token_hash, expires_at)
		VALUES ($1, $2, $3, $4);
	`, id, device, hashed, expr)
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(token), nil
}

func hashToken(raw []byte) []byte {
	h := sha256.Sum256(raw)
	return h[:]
}
