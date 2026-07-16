package integration_test

import (
	"context"
	"database/sql"
	"fmt"

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

func scanRows[T any](ctx context.Context, query string, args []any, scan func(*sql.Rows, *T) error) ([]T, error) {
	rows, err := testenv.DB.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed fetch rows: %w\nquery: %s", err, query)
	}
	defer func() {
		_ = rows.Close()
	}()
	var dsts []T
	for rows.Next() {
		dst := new(T)
		if err := scan(rows, dst); err != nil {
			return nil, fmt.Errorf("failed to scan a row: %w\nquery: %s", err, query)
		}
		dsts = append(dsts, *dst)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed to scan rows: %w\nquery: %s", err, query)
	}
	return dsts, nil
}
