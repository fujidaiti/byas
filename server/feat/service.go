package feat

import (
	"database/sql"
	"time"
)

// Service holds the dependencies shared by feat operations.
type Service struct {
	DB  *sql.DB
	Now func() time.Time
}

// NewService constructs a Service with sane defaults.
func NewService(db *sql.DB) *Service {
	return &Service{DB: db, Now: func() time.Time { return time.Now() }}
}
