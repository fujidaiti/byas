package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
)

// main is the entry point for the E2E testing.
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
	// TODO: make the host ip and port configurable
	sock, err := net.Listen("tcp", "127.0.0.1:9000")
	if err != nil {
		return fmt.Errorf("failed open a socket: %w", err)
	}

	lisCtx, tearDown := context.WithCancel(ctx)
	defer tearDown()
	go listenToRequests(lisCtx, sock)

	return runTests(ctx)
}

func runTests(ctx context.Context) error {
	testCmd := exec.CommandContext(ctx,
		"patrol",
		"test",
		"-v",
		"--flutter-command",
		// TODO: make flutter command path configurable
		"/Users/fujidaiti/.fvm/versions/stable/bin/flutter",
		"-d",
		// TODO: make the target device configurable
		"emulator-5554",
	)
	testCmd.Stdout = os.Stdout
	testCmd.Stderr = os.Stderr
	if err := testCmd.Run(); err != nil {
		return fmt.Errorf("testing failed with an error: %w", err)
	}
	return nil
}

// listenToRequests listens to requests from the client (Dart-side testing code)
// and manages the lifecycle of test sessions.
//
// A request message initiates a test session, which corresponds to a single e2e test case
// and its lifecycle consists of the following steps:
//
//  1. seeds the DB based on the requested scenario ID
//  2. spawn a new API server instance
//  3. tell the client that the server and DB are ready, by sending a response message
//  4. while testing, the Flutter app and the server communicates via HTTP (not the socket)
//
// There is no request message something like "tear down the previous session",
// since all resources for the previous session is wiped out before starting a new session,
// including the seeded data and server instance.
//
// The client is supposed to run tests in sequence. Sending multiple requests is not illegal,
// but test sessions never run in parallel as TCP connections are processed one by one.
//
// This continues to listen to the socket even if errors occur while handling TCP connections
// or during a test session. This is a design decision so that non-fatal errors don't terminate
// the entire testing process.
func listenToRequests(ctx context.Context, socket net.Listener) {
	defer func() {
		if err := socket.Close(); err != nil {
			fmt.Fprintf(os.Stderr, "got error while closing socket: %v\n", err)
		}
	}()

	// This channel has no buffer because:
	//  - we expect exactly one pair of request/response per connection
	//  - the connection is closed immediately after the response is sent
	//  - connections are processed one by one (not in parallel)
	ch := make(chan net.Conn)
	go func() {
		for {
			conn, err := socket.Accept()
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

	tearDown := func() { /*no-op */ }
	for {
		select {
		case <-ctx.Done():
			tearDown()
			return

		case conn := <-ch:
			tearDown()
			if s, err := prepareForNewSession(ctx, conn); err != nil {
				fmt.Fprintf(os.Stderr, "failed while preparing for a new test session: %v\n", err)
				tearDown = func() { /* no-op */ }
			} else {
				sctx, cancel := context.WithCancel(ctx)
				tearDown = func() { cancel(); <-s.done }
				go s.start(sctx)
			}
		}
	}
}

type request struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

type session struct {
	// TODO: add session related resources here
	server *http.Server
	conn   net.Conn
	done   chan struct{}
}

func (s *session) start(ctx context.Context) {
	if s.done != nil {
		panic("start() has been called twice on the same session instance")
	}
	s.done = make(chan struct{})
	defer close(s.done)

	defer func() {
		if err := s.conn.Close(); err != nil {
			fmt.Fprintf(os.Stderr, "got an error while closing a connection: %v", err)
		}
	}()

	if s.server == nil {
		return
	}

	go func() {
		if err := s.server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			s.sendResponse("server error")
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	}()
	s.sendResponse("ready")
	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := s.server.Shutdown(shutdownCtx); err != nil {
		fmt.Fprintf(os.Stderr, "shutdown failed: %v\n", err)
	}
}

func (s *session) sendResponse(msg string) {
	// The newline character is important; it's used as the delimiter for the message stream.
	if _, err := s.conn.Write([]byte(msg + "\n")); err != nil {
		fmt.Fprintf(os.Stderr, "got an error while sending a response: %v\n", err)
	}
}

func prepareForNewSession(ctx context.Context, conn net.Conn) (*session, error) {
	s := session{conn: conn}
	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		s.sendResponse("server error")
		if err := scanner.Err(); err != nil {
			return nil, err
		}
		return nil, errors.New("EOF, nothing to read")
	}
	var req request
	if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
		sendResponse(conn, "invalid request")
		return nil, fmt.Errorf("malformed request: %w", err)
	}

	_, _ = fmt.Fprintf(os.Stdout, "receivced: %+v\n", req)

	// TODO: Open and setup DB based on the request
	time.Sleep(5 * time.Second) // a fake delay

	// TODO: replace this with the real server
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello E2E!"))
	})
	s.server = &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	return &s, nil
}
