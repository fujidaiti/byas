package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
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
	subCtx, tearDown := context.WithCancel(ctx)
	defer tearDown()
	serverErrCh := make(chan error, 1)
	go startServer(subCtx, serverErrCh)
	clientCh := make(chan error, 1)
	go startClient(subCtx, clientCh)

	select {
	case err := <-serverErrCh:
		tearDown()
		return err
	case err := <-clientCh:
		tearDown()
		return err
	case <-ctx.Done():
		return nil
	}
}

func startClient(ctx context.Context, c chan<- error) {
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
	if err := testCmd.Run(); err != nil {
		c <- fmt.Errorf("got an error while testing: %w", err)
	} else {
		c <- nil
	}
}

// TODO: spawn a test DB container and an API server
func startServer(ctx context.Context, errCh chan<- error) {
	sock, err := net.Listen("tcp", "127.0.0.1:9000")
	if err != nil {
		errCh <- fmt.Errorf("faild to open a socket: %w", err)
		return
	}
	defer func() {
		if err := sock.Close(); err != nil {
			errCh <- fmt.Errorf("got error while closing socket: %w", err)
		}
	}()

	// This channel has no buffer because:
	//   - we expect exactly one pair of request/response per session
	//   - the session is closed immediately after the response is sent
	//   - sessions are processed one by one (not in parallel)
	connCh := make(chan net.Conn)
	defer close(connCh)
	go func() {
		for {
			conn, err := sock.Accept()
			switch {
			case errors.Is(err, net.ErrClosed):
				return

			case err != nil:
				errCh <- err
				close(connCh)
				return

			default:
				connCh <- conn
			}
		}
	}()

	for {
		select {
		case <-ctx.Done():
			return

		case c, ok := <-connCh:
			if !ok {
				return
			}
			connCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
			err := handleConnection(connCtx, c)
			cancel()
			if err != nil {
				errCh <- err
				return
			}
		}
	}
}

type request struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

const _delimitor = "\n"

func handleConnection(ctx context.Context, conn net.Conn) error {
	// Expects exactly one pair of request/response per session.
	defer func() { _ = conn.Close() }()

	if t, ok := ctx.Deadline(); ok {
		if err := conn.SetDeadline(t); err != nil {
			return err
		}
	}

	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		if err := scanner.Err(); err != nil {
			return fmt.Errorf("failed to read request: %w", err)
		}
		return nil
	}

	var req request
	if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
		return fmt.Errorf("malformed request: %w", err)
	}

	if _, err := fmt.Fprintf(os.Stdout, "received: %+v\n", req); err != nil {
		return fmt.Errorf("failed to log request: %w", err)
	}
	// TODO: setup DB based on the request
	time.Sleep(5 * time.Second)
	if _, err := conn.Write([]byte("ready" + _delimitor)); err != nil {
		return fmt.Errorf("failed to send a response: %w", err)
	}
	return nil
}
