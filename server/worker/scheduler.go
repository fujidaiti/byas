package worker

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	"github.com/fujidaiti/paperdoll/feature/feed"
	"github.com/fujidaiti/paperdoll/feature/paper"
	"github.com/go-co-op/gocron/v2"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func StartScheduler(ctx context.Context) {
	dsn := os.Getenv("DB_DSN")
	if len(dsn) == 0 {
		panic("DB_DSN is requried.")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		panic(err)
	}
	defer func() {
		fmt.Println("Closing DB...")
		if err := db.Close(); err != nil {
			fmt.Println(err)
		}
	}()
	if err := db.Ping(); err != nil {
		panic(err)
	}

	p := &pool{}
	p.start(ctx, 16)
	defer func() {
		fmt.Println("Shutting down workers...")
		p.shutdown()
	}()

	scheduler, err := gocron.NewScheduler()
	if err != nil {
		panic(err)
	}
	defer func() {
		fmt.Println("Shutting down scheduler...")
		if err := scheduler.Shutdown(); err != nil {
			fmt.Println(err)
		}
	}()
	_, err = scheduler.NewJob(
		gocron.DurationJob(time.Hour),
		gocron.NewTask(func() {
			fmt.Println("--------------------------")
			fmt.Println("Rfreshing feeds...")
			jobs, err := feed.CollectJobs(ctx, db)
			if err != nil {
				fmt.Println(err)
				return
			}
			if len(jobs) == 0 {
				fmt.Println("No polling is scheduled.")
				return
			}
			for _, job := range jobs {
				err := p.push(ctx, &job)
				if err != nil {
					fmt.Println(err)
					return
				}
			}
		}),
	)
	if err != nil {
		panic(err)
	}

	_, err = scheduler.NewJob(
		gocron.DurationJob(5*time.Minute),
		gocron.NewTask(func() {
			jobs, err := paper.CollectJobs(ctx, db)
			if err != nil {
				fmt.Println(err)
			}
			for _, job := range jobs {
				err := p.push(ctx, &job)
				if err != nil {
					fmt.Println(err)
					return
				}
			}
		}),
	)
	if err != nil {
		panic(err)
	}
	scheduler.Start()
	<-ctx.Done()
}
