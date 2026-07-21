package newspaper

import "database/sql"

// Service holds the dependencies shared by newspaper operations.
type Service struct {
	DB *sql.DB
}
