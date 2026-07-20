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
	// This channel has no buffer because:
	//  - we expect exactly one pair of request/response per connection
	//  - the connection is closed immediately after the response is sent
	//  - connections are processed one by one (not in parallel)
	msgCh := make(chan message)
	env, err := setUpTestEnv(ctx, msgCh)
	if err != nil {
		return err
	}
	subCtx, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup
	wg.Go(func() { env.startSessionManagement(subCtx) })
	wg.Go(func() { spawnMessageHandler(subCtx, msgCh) })
	err = runTests(ctx)
	cancel()
	wg.Wait()
	return err
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

type messageBody struct {
	DebugLabel string `json:"debug_label"`
	ScenarioID string `json:"scenario_id"`
}

type message struct {
	body   messageBody
	result chan<- string
}

func spawnMessageHandler(ctx context.Context, msgc chan<- message) {
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

	errc := make(chan error, 1)
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "message listener exited abnormally: %v", err)
			errc <- err
		} else {
			errc <- nil
		}
	}()

	select {
	case <-ctx.Done():
	case err := <-errc:
		if err != nil {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	}

	sctx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()
	if err := srv.Shutdown(sctx); err != nil {
		fmt.Fprintf(os.Stderr, "got error while closing server: %v\n", err)
	}
}

type testEnv struct {
	// TODO: TBD
	msgc            <-chan message
	tearDownSession func()
}

func setUpTestEnv(_ context.Context, msgc <-chan message) (*testEnv, error) {
	// TODO: spawn a test DB container and migrate the DB
	env := testEnv{msgc, func() { /*no-op */ }}
	return &env, nil
}

func (env *testEnv) tearDown() {
	env.tearDownSession()
	// TODO: shutdown test container
}

func (env *testEnv) startSessionManagement(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			env.tearDown()
			return

		case msg := <-env.msgc:
			env.tearDownSession()
			if session, err := setUpNewSession(msg.body); err != nil {
				fmt.Fprintf(os.Stderr, "failed to start a new session: %v\n", err)
				env.tearDownSession = func() { /* no-op */ }
				// TODO: return a cleaner response
				msg.result <- "failed to start a new session"
			} else {
				sctx, cancel := context.WithCancel(ctx)
				go session.start(sctx)
				env.tearDownSession = func() { cancel(); <-session.done }
				// TODO: return a cleaner response
				msg.result <- "ready"
			}
		}
	}
}

type testSession struct {
	// TODO: add session related resources here
	server *http.Server
	done   chan struct{}
}

func setUpNewSession(msg messageBody) (*testSession, error) {
	_, _ = fmt.Fprintf(os.Stdout, "received message: %+v\n", msg)
	s := testSession{}
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

func (s *testSession) start(ctx context.Context) {
	if s.done != nil {
		panic("start() has been called twice on the same session instance")
	}
	s.done = make(chan struct{})
	defer close(s.done)

	go func() {
		if err := s.server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	}()
	<-ctx.Done()

	sctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := s.server.Shutdown(sctx); err != nil {
		fmt.Fprintf(os.Stderr, "shutdown failed: %v\n", err)
	}
}
