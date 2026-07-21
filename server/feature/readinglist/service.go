package readinglist

import "database/sql"

// Service holds the dependencies shared by reading-list operations.
type Service struct {
	DB *sql.DB
}
