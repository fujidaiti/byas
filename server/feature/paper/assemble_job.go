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

	slices.SortFunc(schedules, time.Time.Compare)
	last, next := findScheduleSegment(now, schedules)
	if next.Sub(now) > 10*time.Minute {
		fmt.Printf("Not yet close enough to the next schedule %s. Skipping.\n", next)
		return []job{}, nil
	}
	fmt.Printf("Prepare for next schedule: %s\n", next)

	var lastIssue int
	var lastPubDate time.Time
	err = db.QueryRowContext(ctx, `
		SELECT issue, published_at
		FROM papers
		ORDER BY published_at DESC
		LIMIT 1;
	`).Scan(&lastIssue, &lastPubDate)
	if errors.Is(err, sql.ErrNoRows) {
		// Falls back to the last schedule datetime if no paper is published yet.
		lastPubDate = last
	} else if err != nil {
		return nil, err
	}

	j := job{
		db:      db,
		issue:   lastIssue + 1,
		pubDate: next,
		cutoff:  lastPubDate,
	}

	return []job{j}, nil
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
	issue   int
	pubDate time.Time
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
	fmt.Printf("Assembling a paper #%d (cutoff=%s)\n", j.issue, j.cutoff)
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
		fmt.Println("No articles. Skipping issue #", j.issue)
		return nil
	}

	tx, err := j.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	// TODO: Handle rollback error
	defer tx.Rollback()

	var paperID int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO papers (issue, published_at)
		VALUES ($1, $2)
		RETURNING id;
	`, j.issue, j.pubDate).Scan(&paperID)
	if err != nil {
		return err
	}

	fmt.Printf("New articles: %d\n", len(entries))

	var vals []string
	var args []any
	for i, entry := range entries {
		j := i * 5
		vals = append(vals, fmt.Sprintf("($%d, $%d, $%d, $%d, $%d)", j+1, j+2, j+3, j+4, j+5))
		args = append(args, paperID, entry.id, entry.title, entry.description, entry.publishedAt)
	}
	_, err = tx.ExecContext(ctx, fmt.Sprintf(`
			INSERT INTO articles (paper_id, entry_id, title, description, published_at)
			VALUES %s;
		`, strings.Join(vals, ",")), args...)
	if err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}
	return nil
}
