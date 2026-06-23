package newspaper

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"slices"
	"time"
)

func CollectJobs(ctx context.Context, db *sql.DB) ([]job, error) {
	rows, err := db.QueryContext(ctx, `SELECT minute_of_date FROM newspaper_schedules;`)
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
	_, pubDate := findScheduleSegment(now, schedules)
	if pubDate.Sub(now) > 10*time.Minute {
		fmt.Printf("Not yet close enough to the next schedule %s. Skipping.\n", pubDate)
		return []job{}, nil
	}
	fmt.Printf("Prepare for next schedule: %s\n", pubDate)

	var newspaperID int
	err = db.QueryRowContext(ctx, `
		INSERT INTO newspapers (draft, published_at)
		VALUES (TRUE, $1)
		ON CONFLICT (published_at) DO NOTHING
		RETURNING id;
	`, pubDate).Scan(&newspaperID)
	if errors.Is(err, sql.ErrNoRows) {
		// TODO: Handle the case where a record exists but the newspaper was not assembled due to a server outage.
		fmt.Printf("The newspaper for %s already exists or is being assembled. Skipping.\n", pubDate)
		return []job{}, nil
	} else if err != nil {
		return nil, err
	}

	return []job{{db, newspaperID}}, nil
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
	db          *sql.DB
	newspaperID int
}

func (j *job) Timeout() time.Duration {
	return time.Minute
}

func (j *job) Do(ctx context.Context) error {
	fmt.Printf("Assembling newspaper (ID=%d)\n", j.newspaperID)
	n, err := j.assembleAndPublish(ctx)
	if err != nil {
		fmt.Println("Something went wrong while assembling. Deleting.")
	} else if n == 0 {
		fmt.Println("No stories found to publish. Skipping.")
	} else {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, dErr := j.db.ExecContext(ctx, `DELETE FROM newspapers WHERE id = $1;`, j.newspaperID)
	if dErr != nil {
		return fmt.Errorf("%w; cleanup failed: %w", err, dErr)
	}
	return err
}

func (j *job) assembleAndPublish(ctx context.Context) (int64, error) {
	tx, err := j.db.BeginTx(ctx, nil)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()

	res, err := tx.ExecContext(ctx, `
		UPDATE stories
		SET newspaper_id = $1
		WHERE newspaper_id IS NULL;
	`, j.newspaperID)
	if err != nil {
		return 0, err
	}
	n, err := res.RowsAffected()
	if err != nil || n <= 0 {
		return n, err
	}

	_, err = tx.ExecContext(ctx, `
		UPDATE newspapers
		SET draft = FALSE
		WHERE id = $1;
	`, j.newspaperID)
	if err != nil {
		return n, err
	}
	err = tx.Commit()
	return n, err
}
