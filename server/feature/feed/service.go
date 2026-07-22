package feed

import "database/sql"

// Service holds the dependencies shared by feed operations.
type Service struct {
	DB *sql.DB
}
