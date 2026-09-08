package user

import (
	"database/sql"
	"time"
)

type Service struct {
	DB  *sql.DB
	Now func() time.Time
}

func NewService(db *sql.DB) *Service {
	return &Service{
		DB:  db,
		Now: func() time.Time { return time.Now() },
	}
}
