//go:build integration

package integration_test

import (
	"os"
	"testing"

	"github.com/fujidaiti/paperdoll/server/integration_test/testenv"
)

func TestMain(m *testing.M) {
	os.Exit(testenv.RunTests(m))
}
