//go:build integration

package itest

import (
	"context"
	"log"
	"os"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/itest/testenv"
)

func TestMain(m *testing.M) {
	code := func() int {
		ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
		defer cancel()

		err := testenv.SetUp(ctx, "127.0.0.1:8081")
		defer func() {
			ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			if err := testenv.ShutDown(ctx); err != nil {
				log.Println(err)
			}
			cancel()
		}()
		if err != nil {
			log.Println(err)
			return 1
		}

		return m.Run()
	}()

	os.Exit(code)
}
