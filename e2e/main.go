package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

// main is the entry point for the E2E testing.
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
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(
		context.Background(), syscall.SIGTERM, syscall.SIGINT,
	)
	defer stop()

	// This channel has no buffer because:
	//  - we expect exactly one pair of request/response per connection
	//  - the connection is closed immediately after the response is sent
	//  - connections are processed one by one (not in parallel)
	msgc := make(chan message)
	env, err := setUpTestEnv(ctx, msgc)
	if err != nil {
		return err
	}
	defer env.tearDown()

	var wg sync.WaitGroup
	wg.Go(func() { messageHandler(ctx, msgc) })
	wg.Go(func() { sessionManager(ctx, env) })
	err = runTests(ctx)

	stop()
	wg.Wait()
	return err
}

type testEnv struct {
	// TODO: TBD
	msgc <-chan message
}

func setUpTestEnv(_ context.Context, msgc <-chan message) (*testEnv, error) {
	// TODO: spawn a test DB container and migrate the DB
	env := testEnv{msgc}
	return &env, nil
}

func (env *testEnv) tearDown() {
	// TODO: shutdown the test container
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

type message struct {
	body    messageBody
	resultc chan<- string
}

type messageBody struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

func messageHandler(ctx context.Context, msgc chan<- message) {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /setup", func(w http.ResponseWriter, r *http.Request) {
		var body messageBody
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			_, _ = fmt.Fprintf(w, "malformed message body: %v", err)
			return
		}
		resc := make(chan string, 1)
		select {
		case msgc <- message{body, resc}:
		case <-r.Context().Done():
			_, _ = fmt.Fprint(w, "request canceled")
		}
		// Wait for the result to be returned.
		select {
		case res := <-resc:
			_, _ = fmt.Fprint(w, res)
		case <-r.Context().Done():
			_, _ = fmt.Fprint(w, "request canceled")
		}
	})

	srv := http.Server{
		// TODO: make the host ip and port number configurable
		Addr:         ":9000",
		Handler:      mux,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 120 * time.Second,
	}
	defer func() {
		sctx, cancel := context.WithTimeout(ctx, 60*time.Second)
		defer cancel()
		if err := srv.Shutdown(sctx); err != nil {
			fmt.Fprintf(os.Stderr, "got error while closing server: %v\n", err)
		}
	}()

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	select {
	case <-ctx.Done():
	case err := <-errc:
		if !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	}
}

func sessionManager(ctx context.Context, env *testEnv) {
	tearDown := func() { /* no-op */ }
	for {
		select {
		case <-ctx.Done():
			tearDown()
			return

		case msg := <-env.msgc:
			tearDown()
			done := make(chan struct{})
			sctx, cancel := context.WithCancel(ctx)
			tearDown = func() { cancel(); <-done }
			go session(sctx, done, msg)
		}
	}
}

func session(ctx context.Context, done chan struct{}, msg message) {
	defer close(done)
	// TODO: Open and setup DB based on the request
	time.Sleep(5 * time.Second) // a fake delay

	// TODO: replace this with the real server
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello E2E!"))
	})
	srv := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}
	defer func() {
		sctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := srv.Shutdown(sctx); err != nil {
			fmt.Fprintf(os.Stderr, "shutdown failed: %v\n", err)
		}
	}()

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	// TODO: return a cleaner response
	msg.resultc <- "ready"

	select {
	case <-ctx.Done():
	case err := <-errc:
		if !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	}

}
