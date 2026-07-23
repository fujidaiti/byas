package feed

import (
	"database/sql"

	"github.com/fujidaiti/paperdoll/server/feature/scraper"
)

// Service holds the dependencies shared by feed operations.
type Service struct {
	DB      *sql.DB
	scraper *scraper.Service
}

func NewService(db *sql.DB, scrp *scraper.Service) *Service {
	return &Service{db, scrp}
}
