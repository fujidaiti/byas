package newspaper

import (
	"context"
	"database/sql"
	"errors"
	"slices"
	"time"
)

// TODO: rename Schedule to PublicationSchedule
func getSchedules(ctx context.Context, db *sql.DB, t time.Time) ([]time.Time, error) {
	rows, err := db.QueryContext(ctx, `SELECT minute_of_date FROM newspaper_schedules;`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	year, month, day := t.Date()
	midnight := time.Date(year, month, day, 0, 0, 0, 0, time.Local)
	var schedules []time.Time
	for rows.Next() {
		var dt int
		err := rows.Scan(&dt)
		if err != nil {
			return nil, err
		}
		schedules = append(schedules, midnight.Add(time.Duration(dt)*time.Minute))
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return schedules, nil
}

func FindEditorialInterval(ctx context.Context, db *sql.DB, t time.Time) (time.Time, time.Time, error) {
	ss, err := getSchedules(ctx, db, t)
	if err != nil {
		return time.Time{}, time.Time{}, err
	}
	if len(ss) == 0 {
		return time.Time{}, time.Time{}, errors.New("No schedule is registered.")
	}
	slices.SortFunc(ss, time.Time.Compare)
	last, next := findEditorialInterval(t, ss)
	return last, next, nil
}

// findEditorialInterval returns the nearest consecutive pair of datetime points
// surrounding the given time t on the given daily publishing schedule timeline ss.
// The returned datetimes may be from yesterday or tomorrow if the t falls before
// the first or after the last datetime in the timeline.
//
// If a datetime in ss equals t, it is returned as the left (last) point.
//
// The day of t and the Time instances in ss must be the same, and ss must
// be sorted in ascending order.
func findEditorialInterval(t time.Time, ss []time.Time) (last, next time.Time) {
	idx := -1
	for i, s := range ss {
		if s.After(t) {
			idx = i
			break
		}
	}

	switch {
	case idx == 0:
		// Yesterday's last schedule
		last = ss[len(ss)-1].AddDate(0, 0, -1)
		next = ss[0]

	case idx-1 >= 0:
		last = ss[idx-1]
		next = ss[idx]

	case idx < 0:
		last = ss[len(ss)-1]
		// Tomorrow's first schedule
		next = ss[0].AddDate(0, 0, 1)
	}
	return
}
