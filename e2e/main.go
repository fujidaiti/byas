package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
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
	sock, err := net.Listen("tcp", "127.0.0.1:9000")
	if err != nil {
		return fmt.Errorf("faild to open a socket: %w", err)
	}
	defer func() { _ = sock.Close() }()
	go func() {
		for {
			conn, err := sock.Accept()
			if err != nil {
				return
			}
			reqCtx, cancel := context.WithTimeout(ctx, 60*time.Second)
			// Expects exactly one request per session.
			handleRequest(reqCtx, conn)
			cancel()
		}
	}()

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

type request struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

const _delimitor = "\n"

func handleRequest(ctx context.Context, conn net.Conn) {
	defer func() { _ = conn.Close() }()
	if t, ok := ctx.Deadline(); ok {
		if err := conn.SetDeadline(t); err != nil {
			fmt.Fprintf(os.Stderr, "failed to set deadline: %v\n", err)
			return
		}
	}

	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		if err := scanner.Err(); err != nil {
			fmt.Fprintf(os.Stderr, "failed to read request: %v\n", err)
		}
		return
	}

	var req request
	if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
		fmt.Fprintf(os.Stderr, "malformed request: %v\n", err)
		return
	}

	if _, err := fmt.Fprintf(os.Stdout, "received: %+v\n", req); err != nil {
		fmt.Fprintf(os.Stderr, "failed to log request: %v\n", err)
	}
	time.Sleep(5 * time.Second)
	if _, err := conn.Write([]byte("ready" + _delimitor)); err != nil {
		fmt.Fprintf(os.Stderr, "failed to send a response: %v\n", err)
	}
}
