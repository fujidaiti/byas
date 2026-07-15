package user

import (
	"database/sql"
	"io"
	"time"
)

type Service struct {
	DB         *sql.DB
	Now        func() time.Time
	SecureRand io.Reader
}
