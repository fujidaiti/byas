package main

import (
	"database/sql"
	"fmt"
	"os"
	"os/signal"
	"time"

	"github.com/fujidaiti/paperdoll/feature/feed"
	"github.com/go-co-op/gocron/v2"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
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
			err := feed.RefreshFeeds(db)
			if err != nil {
				fmt.Println(err)
			}
		}),
		gocron.WithSingletonMode(gocron.LimitModeReschedule),
	)
	if err != nil {
		panic(err)
	}

	scheduler.Start()
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit
}
