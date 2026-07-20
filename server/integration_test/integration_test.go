//go:build integration

package integration_test

import (
	"context"
	"log"
	"os"
	"testing"
	"time"

	"github.com/fujidaiti/paperdoll/server/integration_test/testenv"
)

func TestMain(m *testing.M) {
	code := func() int {
		ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
		defer cancel()

		err := testenv.SetUp(ctx)
		defer func() {
			ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			if err := testenv.TearDown(ctx); err != nil {
				log.Println(err)
			}
			cancel()
		}()
		if err != nil {
			log.Println(err)
		}
		return m.Run()
	}()

	os.Exit(code)
}
