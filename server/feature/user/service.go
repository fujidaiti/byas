package user

import (
	"database/sql"
	"time"
)

type Service struct {
	DB  *sql.DB
	Now func() time.Time
}
