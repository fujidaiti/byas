//go:build integration

package integration_test

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"

	"github.com/fujidaiti/paperdoll/integration_test/testenv"
)

func TestMain(m *testing.M) {
	os.Exit(testenv.RunTests(m))
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
