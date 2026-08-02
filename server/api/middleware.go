package api

import (
	"context"
	"net/http"
	"strings"

	"github.com/fujidaiti/paperdoll/server/feature/user"
)

type contextKey int

const userIDKey contextKey = 0

func AuthMiddleware(next http.Handler, s *user.Service) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok {
			serverError(w, http.StatusUnauthorized, "invalid token")
			return
		}
		uid, err := s.VerifyAuthToken(r.Context(), token)
		if err != nil {
			serverError(w, http.StatusUnauthorized, "invalid token")
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), userIDKey, uid)))
	})
}

func UserIDFromContext(ctx context.Context) (user.UserID, bool) {
	id, ok := ctx.Value(userIDKey).(user.UserID)
	return id, ok
}
