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
	"strings"
	"unicode"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrDeviceEmpty  = errors.New("device is empty")
	ErrEmailInvalid = errors.New("email has invalid format")
	ErrEmailTaken   = errors.New("email already exists")
	ErrPswdInvalid  = errors.New("password has invalid format")
	ErrAuthFailed   = errors.New("email or password is incorrect")
	ErrTokenInvalid = errors.New("token is invalid or has been expired")
)

type UserID = int

type ValidPassword struct{ value string }

// Printable ASCII characters only; 15-64 characters
var passwordRegex = regexp.MustCompile(`^[\x20-\x7E]{15,64}$`)

func ValidatePassword(p string) (ValidPassword, error) {
	if !passwordRegex.MatchString(p) {
		return ValidPassword{}, ErrPswdInvalid
	}
	return ValidPassword{p}, nil
}

type CanonicalEmail struct{ value string }

func ParseEmail(addr string) (CanonicalEmail, error) {
	for i := 0; i < len(addr); i++ {
		if addr[i] > unicode.MaxASCII {
			return CanonicalEmail{}, ErrEmailInvalid
		}
	}
	a, err := mail.ParseAddress(addr)
	if err != nil || a.Address != addr {
		return CanonicalEmail{}, ErrEmailInvalid
	}
	return CanonicalEmail{strings.ToLower(a.Address)}, nil
}

type AuthToken struct{ value [32]byte }

func generateAuthToken() (AuthToken, error) {
	t := AuthToken{}
	_, err := rand.Read(t.value[:])
	return t, err
}

func decodeAuthToken(t string) (AuthToken, error) {
	b, err := base64.RawURLEncoding.DecodeString(t)
	if err != nil || len(b) != 32 {
		return AuthToken{}, ErrTokenInvalid
	}
	return AuthToken{[32]byte(b)}, nil
}

func (t AuthToken) Encode() string {
	if t == (AuthToken{}) {
		return ""
	}
	return base64.RawURLEncoding.EncodeToString(t.value[:])
}

func (t AuthToken) Hash() []byte {
	if t == (AuthToken{}) {
		return nil
	}
	h := sha256.Sum256(t.value[:])
	return h[:]
}

// TODO: Tweak the bcrypt cost
const bcryptCost = 12

func (s *Service) SignUp(
	ctx context.Context, email CanonicalEmail, pswd ValidPassword, device string,
) (AuthToken, error) {
	if device == "" {
		return AuthToken{}, ErrDeviceEmpty
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
		RETURNING id
	`, email.value, hash).Scan(&id)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return AuthToken{}, ErrEmailTaken
	case err != nil:
		return AuthToken{}, err
	}
	return s.issueAuthToken(ctx, id, device)
}

func (s *Service) SignIn(
	ctx context.Context, email CanonicalEmail, pswd, device string,
) (AuthToken, error) {
	if device == "" {
		return AuthToken{}, ErrDeviceEmpty
	}
	var dbHash []byte
	var id int
	err := s.DB.QueryRowContext(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1
	`, email.value).Scan(&id, &dbHash)
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

func (s *Service) issueAuthToken(
	ctx context.Context, id UserID, device string,
) (AuthToken, error) {
	token, err := generateAuthToken()
	if err != nil {
		return AuthToken{}, err
	}
	expr := s.Now().AddDate(0, 0, tokenExpiresInDays)
	_, err = s.DB.ExecContext(ctx, `
		INSERT INTO auth_tokens (user_id, device, token_hash, expires_at)
		VALUES ($1, $2, $3, $4)
	`, id, device, token.Hash(), expr)
	if err != nil {
		return AuthToken{}, err
	}
	return token, nil
}

// SignOut revokes the encoded token t. The user who owns that token remains
// authorized as long as their other tokens are valid.
//
// This operation does not fail even if the token is invalid, but it may report
// an unknown error due to infrastructure issues.
func (s *Service) SignOut(ctx context.Context, t string) error {
	token, err := decodeAuthToken(t)
	if err != nil {
		return nil
	}
	_, err = s.DB.ExecContext(ctx, `
		DELETE FROM auth_tokens WHERE token_hash = $1
	`, token.Hash())
	return err
}

// VerifyAuthToken checks if the encoded token t is valid and finds the user who
// owns that token. Reports an [ErrTokenInvalid] if the token is malformed or expired.
// TODO: Garbage-collect expired tokens
func (s *Service) VerifyAuthToken(ctx context.Context, t string) (UserID, error) {
	token, err := decodeAuthToken(t)
	if err != nil {
		return 0, err
	}
	var id UserID
	err = s.DB.QueryRowContext(ctx, `
		SELECT user_id FROM auth_tokens WHERE expires_at > $1 AND token_hash = $2
	`, s.Now(), token.Hash()).Scan(&id)
	if err != nil {
		return 0, ErrTokenInvalid
	}
	return id, nil
}
