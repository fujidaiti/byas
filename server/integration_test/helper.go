package integration_test

import (
	"database/sql"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/integration_test/testenv"
)

// isDistinct checks if all comparable elements in v are uniqueue.
func isDistinct[T comparable](v []T) bool {
	seen := make(map[T]struct{}, len(v))
	for _, x := range v {
		if _, exists := seen[x]; exists {
			return false
		}
		seen[x] = struct{}{}
	}
	return true
}

func must[T any](val T, err error) T {
	if err != nil {
		panic(err)
	}
	return val
}

// mustTimeUTC parses s into a [time.Time]. The accepted format is "yyyy-MM-dd hh:mm:ss".
func mustTimeUTC(s string) time.Time {
	t, err := time.ParseInLocation(time.DateTime, s, time.UTC)
	if err != nil {
		panic(err)
	}
	return t
}

func scanRowOrFatal(t *testing.T, query string, args []any, dest ...any) {
	t.Helper()
	err := testenv.DB.QueryRowContext(t.Context(), query, args...).Scan(dest...)
	if err != nil {
		t.Fatalf("failed to scan a row: %v\nquery: %s", err, query)
	}
}

func scanRowsOrFatal[T any](t *testing.T, query string, args []any, scan func(*sql.Rows, *T) error) []T {
	rows, err := testenv.DB.QueryContext(t.Context(), query, args...)
	if err != nil {
		t.Fatalf("failed to scan rows: %v\nquery: %s", err, query)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			t.Errorf("failed to close DB: %v", err)
		}
	}()
	var dests []T
	for rows.Next() {
		dest := new(T)
		if err := scan(rows, dest); err != nil {
			t.Fatalf("failed to scan a row: %v\nquery: %s", err, query)
		}
		dests = append(dests, *dest)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("failed to scan rows: %v\nquery: %s", err, query)
	}
	return dests
}
