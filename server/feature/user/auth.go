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
	"unicode"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrDeviceKindEmpty = errors.New("device kind is empty")
	ErrEmailInvalid    = errors.New("email has invalid format")
	ErrEmailTaken      = errors.New("email already exists")
	ErrPswdInvalid     = errors.New("password has invalid format")
	ErrAuthFailed      = errors.New("email or password is incorrect")
	ErrTokenInvalid    = errors.New("token is invalid or has been expired")
)

type UserID = int

type ValidPassword struct{ value string }

// Printable ASCII characters only; 15-64 characters
var pswdRegex = regexp.MustCompile(`^[\x20-\x7E]{15,64}$`)

func ValidatePassword(p string) (ValidPassword, error) {
	if !pswdRegex.MatchString(p) {
		return ValidPassword{}, ErrPswdInvalid
	}
	return ValidPassword{p}, nil
}

type ValidEmail struct{ value string }

func ValidateEmail(addr string) (ValidEmail, error) {
	for i := 0; i < len(addr); i++ {
		if addr[i] > unicode.MaxASCII {
			return ValidEmail{}, ErrEmailInvalid
		}
	}
	r, err := mail.ParseAddress(addr)
	if err != nil || r.Address != addr {
		return ValidEmail{}, ErrEmailInvalid
	}
	return ValidEmail{r.Address}, nil
}

// SignUp creates a fresh user account for the given email and issue a new authentication token.
func (s *Service) SignUp(ctx context.Context, email ValidEmail, pswd ValidPassword, device string) (string, error) {
	if device == "" {
		return "", ErrDeviceKindEmpty
	}
	id, err := s.CreateUserAccount(ctx, email, pswd)
	if err != nil {
		return "", err
	}
	return s.IssueAuthToken(ctx, id, device)
}

func (s *Service) SignIn(ctx context.Context, email ValidEmail, pswd string, device string) (string, error) {
	if device == "" {
		return "", ErrDeviceKindEmpty
	}
	var dbHash []byte
	var id int
	err := s.DB.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1;
	`, email.value).Scan(&id, &dbHash)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return "", ErrAuthFailed
	case err != nil:
		return "", err
	}
	if bcrypt.CompareHashAndPassword(dbHash, []byte(pswd)) != nil {
		return "", ErrAuthFailed
	}
	return s.IssueAuthToken(ctx, id, device)
}

// TODO: Tweak the bcrypt cost
const bcryptCost = 12

func (s *Service) CreateUserAccount(ctx context.Context, email ValidEmail, pswd ValidPassword) (UserID, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(pswd.value), bcryptCost)
	if err != nil {
		return 0, err
	}
	var id int
	err = s.DB.QueryRowContext(ctx, `
		INSERT INTO users (email, password_hash)
		VALUES ($1, $2)
		ON CONFLICT (email) DO NOTHING
		RETURNING id;
	`, email.value, hash).Scan(&id)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return 0, ErrEmailTaken
	case err != nil:
		return 0, err
	}
	return id, nil
}

const tokenExpiresInDays = 30

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
