package paper

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"slices"
	"strings"
	"time"
)

func CollectJobs(ctx context.Context, db *sql.DB) ([]job, error) {
	rows, err := db.QueryContext(ctx, `SELECT minute_of_date FROM paper_schedules;`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	now := time.Now()
	year, month, day := now.Date()
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
	if len(schedules) == 0 {
		return nil, errors.New("No schedule is registered.")
	}

	slices.SortFunc(schedules, time.Time.Compare)
	lastSch, nextSch := findScheduleSegment(now, schedules)
	if nextSch.Sub(now) > 10*time.Minute {
		fmt.Printf("Not yet close enough to the next schedule %s. Skipping.\n", nextSch)
		return []job{}, nil
	}
	fmt.Printf("Prepare for next schedule: %s\n", nextSch)

	var paperID int
	err = db.QueryRowContext(ctx, `
		INSERT INTO papers (published_at, cutoff)
		VALUES ($1, $2)
		ON CONFLICT (published_at) DO NOTHING
		RETURNING id;
	`, nextSch, lastSch).Scan(&paperID)
	if errors.Is(err, sql.ErrNoRows) {
		// TODO: Handle the case where a record exists but the paper was not assembled due to a server outage.
		fmt.Printf("The paper for %s already exists or is being assembled. Skipping.\n", nextSch)
		return []job{}, nil
	} else if err != nil {
		return nil, err
	}

	return []job{{db, paperID, lastSch}}, nil
}

// findScheduleSegment returns the nearest consecutive pair of datetime points
// surrounding now on the given daily publishing schedule timeline ss.
// The returned datetimes may be from yesterday or tomorrow if now falls before
// the first or after the last datetime in the timeline.
//
// If a datetime in ss equals now, it is returned as the left (last) point.
//
// The day of now and the Time instances in ss must be the same, and ss must
// be sorted in ascending order.
func findScheduleSegment(now time.Time, ss []time.Time) (last, next time.Time) {
	idx := -1
	for i, s := range ss {
		if s.After(now) {
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

type job struct {
	db      *sql.DB
	paperID int
	cutoff  time.Time
}

func (j *job) Timeout() time.Duration {
	return time.Minute
}

type entryRecord struct {
	id          int
	title       string
	description sql.NullString
	publishedAt sql.NullTime
}

func (j *job) Do(ctx context.Context) error {
	fmt.Printf("Assembling a paper (ID=%d, cutoff=%s)\n", j.paperID, j.cutoff)
	err := writeArticles(ctx, j)
	if err == nil {
		return nil
	}
	fmt.Printf("Something went wrong while assembling a paper (ID=%d). Deleting.\n", j.paperID)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, dErr := j.db.ExecContext(ctx, `DELETE FROM papers WHERE id = $1;`, j.paperID)
	if dErr != nil {
		return fmt.Errorf("%w; cleanup failed: %w", err, dErr)
	}
	return err
}

func writeArticles(ctx context.Context, j *job) error {
	// Ignore entries without publish dates.
	rows, err := j.db.QueryContext(ctx, `
		SELECT id, title, description, published_at
		FROM entries
		WHERE published_at > $1
		ORDER BY published_at;
	`, j.cutoff)
	if err != nil {
		return err
	}
	defer rows.Close()

	var entries []entryRecord
	for rows.Next() {
		e := entryRecord{}
		err := rows.Scan(&e.id, &e.title, &e.description, &e.publishedAt)
		if err != nil {
			return err
		}
		entries = append(entries, e)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if len(entries) == 0 {
		return fmt.Errorf("No articles for the paper ID=%d. Skipping.", j.paperID)
	}
	fmt.Printf("New articles: %d\n", len(entries))

	var vals []string
	var args []any
	for i, entry := range entries {
		k := i * 5
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d, $%d)", k+1, k+2, k+3, k+4, k+5))
		args = append(args, j.paperID, entry.id, entry.title, entry.description, entry.publishedAt)
	}
	_, err = j.db.ExecContext(ctx, fmt.Sprintf(`
			INSERT INTO articles (paper_id, entry_id, title, description, published_at)
			VALUES %s;
		`, strings.Join(vals, ",")), args...)
	if err != nil {
		return err
	}

	return nil

}
