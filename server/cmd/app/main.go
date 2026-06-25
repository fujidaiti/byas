package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"

	"github.com/fujidaiti/paperdoll/api"
	"github.com/fujidaiti/paperdoll/worker"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Specify a sub-command.")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "serve":
		serve()

	case "schedule":
		schedule()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}

func serve() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	api.StartServer(ctx)
}

func schedule() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	worker.StartScheduler(ctx)
}
