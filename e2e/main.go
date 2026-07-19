package main

import (
	"context"
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
	ctx, stop := signal.NotifyContext(
		context.Background(), syscall.SIGTERM, syscall.SIGINT,
	)
	defer stop()
	if err := run(ctx); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	// TODO: spawn a test DB container and migrate the DB
	servCtx, tearDownServ := context.WithCancel(ctx)
	defer tearDownServ()
	sock, err := net.Listen("tcp", "127.0.0.1:9000")
	if err != nil {
		return fmt.Errorf("faild to open a socket: %w", err)
	}
	defer func() {
		if err := sock.Close(); err != nil {
			fmt.Fprintf(os.Stderr, "got error while closing socket: %v\n", err)
		}
	}()
	go listenToRequests(servCtx, sock)

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
		return fmt.Errorf("testing failed with an error: %w", err)
	}
	return nil
}

// listenToRequests listens to requests from the client (Dart-sdie testing code)
// and manages lifecycle of test sessions.
//
// A request message initiates a test session, which corresponds to a single e2e test case
// and its lifecycle consists of the following steps:
//
//  1. seeds the DB based on the requested scenario ID
//  2. spawn a new API server instance
//  3. tell the client that the server and DB are ready, by sending a response message
//  4. while testing, the Flutter app and the server communicates via HTTP (not the sock)
//
// There is no request message something like "tear down the previous session",
// since all resources for the previous session is wiped out before starting a new session,
// including the seeded data and server instance.
//
// The client is supposed to run tests in sequence. Sending multiple requests is not illegal,
// but test sessions never run in parallel as TCP connections are processed one by one.
func listenToRequests(ctx context.Context, sock net.Listener) {
	// This channel has no buffer because:
	//  - we expect exactly one pair of request/response per connection
	//  - the connection is closed immediately after the response is sent
	//  - connections are processed one by one (not in parallel)
	ch := make(chan net.Conn)
	defer close(ch)
	go func() {
		for {
			conn, err := sock.Accept()
			switch {
			case errors.Is(err, net.ErrClosed):
				return
			case err != nil:
				fmt.Fprintln(os.Stderr, err)
			default:
				ch <- conn
			}
		}
	}()

	var tearDown context.CancelFunc
	for {
		select {
		case <-ctx.Done():
			tearDown()
			return

		case conn := <-ch:
			tearDown()
			var ctx2 context.Context
			ctx2, tearDown = context.WithTimeout(ctx, 60*time.Second)
			go startNewTestSession(ctx2, conn)
		}
	}
}

type request struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

const _delimitor = "\n"

// startNewTestSession sets up the testing DB based on the request
// and spawn a new API server instance for the new test session.
func startNewTestSession(ctx context.Context, conn net.Conn) {
	defer func() {
		if err := conn.Close(); err != nil {
			fmt.Fprintf(os.Stderr, "got an error while closing a connection: %v", err)
		}
	}()
	// TODO: Open and setup DB based on the request, spawn a new API server
	time.Sleep(5 * time.Second) // a fake delay
	if _, err := conn.Write([]byte("ready" + _delimitor)); err != nil {
		fmt.Fprintf(os.Stderr, "failed to send a response: %v\n", err)
		return
	}
}

// func readRequest(ctx context.Context, conn net.Conn) error {
// 	if t, ok := ctx.Deadline(); ok {
// 		if err := conn.SetDeadline(t); err != nil {
// 			fmt.Fprintln(os.Stderr, err)
// 			return
// 		}
// 	}

// 	scanner := bufio.NewScanner(conn)
// 	if !scanner.Scan() {
// 		if err := scanner.Err(); err != nil {
// 			fmt.Fprintln(os.Stderr, err)
// 		}
// 		return
// 	}
// 	var req request
// 	if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
// 		fmt.Fprintf(os.Stderr, "malformed request: %v\n", err)
// 		return
// 	}
// 	_, _ = fmt.Fprintf(os.Stdout, "received: %+v\n", req)

// }
