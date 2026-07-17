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

type AuthToken struct{ value [32]byte }

func generateAuthToken() (AuthToken, error) {
	t := AuthToken{}
	_, err := rand.Read(t.value[:])
	return t, err
}

func (t AuthToken) Hash() []byte {
	h := sha256.Sum256(t.value[:])
	return h[:]
}

func (t AuthToken) Encode() string {
	return base64.RawURLEncoding.EncodeToString(t.value[:])
}

// TODO: Tweak the bcrypt cost
const bcryptCost = 12

// SignUp creates a fresh user account for the given email and issue a new authentication token.
func (s *Service) SignUp(ctx context.Context, email ValidEmail, pswd ValidPassword, device string) (AuthToken, error) {
	if device == "" {
		return AuthToken{}, ErrDeviceKindEmpty
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(pswd.value), bcryptCost)
	if err != nil {
		return AuthToken{}, err
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
		return AuthToken{}, ErrEmailTaken
	case err != nil:
		return AuthToken{}, err
	}
	return s.issueAuthToken(ctx, id, device)
}

func (s *Service) SignIn(ctx context.Context, email, pswd, device string) (AuthToken, error) {
	if device == "" {
		return AuthToken{}, ErrDeviceKindEmpty
	}
	var dbHash []byte
	var id int
	err := s.DB.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1;
	`, email).Scan(&id, &dbHash)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return AuthToken{}, ErrAuthFailed
	case err != nil:
		return AuthToken{}, err
	}
	if bcrypt.CompareHashAndPassword(dbHash, []byte(pswd)) != nil {
		return AuthToken{}, ErrAuthFailed
	}
	return s.issueAuthToken(ctx, id, device)
}

const tokenExpiresInDays = 30

func (s *Service) issueAuthToken(ctx context.Context, id UserID, device string) (AuthToken, error) {
	token, err := generateAuthToken()
	if err != nil {
		return AuthToken{}, err
	}
	expr := s.Now().AddDate(0, 0, tokenExpiresInDays)
	_, err = s.DB.ExecContext(ctx, `
		INSERT INTO auth_tokens (user_id, device_kind, token_hash, expires_at)
		VALUES ($1, $2, $3, $4);
	`, id, device, token.Hash(), expr)
	if err != nil {
		return AuthToken{}, err
	}
	return token, nil
}
