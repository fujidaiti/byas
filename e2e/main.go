package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	if err := run(ctx); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	testCmd := exec.CommandContext(ctx,
		"patrol",
		"test",
		"-v",
		"--flutter-command",
		"/Users/fujidaiti/.fvm/versions/stable/bin/flutter",
		"-d emulator-5554",
	)
	testCmd.Stdout = os.Stdout
	testCmd.Stderr = os.Stderr
	if err := testCmd.Start(); err != nil {
		return fmt.Errorf("failed to spawn %q: %w", testCmd.String(), err)
	}
	testDone := make(chan error, 1)
	go func() {
		err := testCmd.Wait()
		if err != nil {
			testDone <- fmt.Errorf("testing has finished with an error: %w", err)
		} else {
			testDone <- nil
		}
	}()

	select {
	case err := <-testDone:
		return err
	case <-ctx.Done():
		// Wait for the test command to finish
		return <-testDone
	}
}
