package newspaper

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

func CollectJobs(ctx context.Context, db *sql.DB) ([]job, error) {
	now := time.Now()
	ei, err := FindEditorialInterval(ctx, db, now)
	pubDate := ei.Next
	if err != nil {
		return nil, err
	}
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
	defer func() {
		if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
			fmt.Println(err)
		}
	}()

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
