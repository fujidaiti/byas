package test

import (
	"database/sql"
	"fmt"
)

type seeder = func(*sql.DB) error

var seeders = map[string]seeder{
	"reading_list": seedReadingListSuit_,
}

func Seed(seederID string, db *sql.DB) error {
	s, ok := seeders[seederID]
	if !ok {
		return fmt.Errorf("no seeder is registered for ID=%q", seederID)
	}
	return s(db)
}
