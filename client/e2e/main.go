package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"github.com/fujidaiti/paperdoll/server/api"
	"github.com/fujidaiti/paperdoll/server/itest/testenv"
	"golang.org/x/sync/errgroup"
)

// This is an E2E testing runner, which consists of these four components:
//
//   - [testenv], which manages a test DB container that is shared across all test cases.
//   - client, which is the Dart-side testing code that is driven by the Patrol framework.
//   - [messageHandler], which is a tiny HTTP server that listens to [message]s from the client.
//   - [sessionManager], which launches test [session]s based on the received messages and manages their lifecycle.
//
// At the beginning of each test case, the client sends a message to the messageHandler
// to initiates a test session. The lifecycle of a session consists of the following steps:
//
//  1. seeds the DB based on the requested scenario ID.
//  2. spawns a new API server instance.
//  3. tells the client that the server and DB are ready.
//  4. after that, the Flutter app can communicate with the server via HTTP.
//
// There is no specific message something like "tear down this session".
// All resources for the previous session is wiped out before starting a new session,
// including the seeded data and server instance.
//
// The client is supposed to run tests in sequence. Sending multiple messages is not illegal,
// but testing sessions never run in parallel as sessionManager handles messages one by one.
//
// The sessionManager never stops even if errors occur while handling messages or during a test session.
// This is a design decision so that non-fatal errors don't terminate the entire testing process.
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	defer func() {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		if err := testenv.ShutDown(ctx); err != nil {
			fmt.Fprintln(os.Stderr, err)
		}
		cancel()
	}()
	// TODO: make the stub server address configurable
	if err := testenv.SetUp(ctx, "127.0.0.1:8081"); err != nil {
		return err
	}

	// This channel is unbuffered because:
	//  - the receiver (the sessionManager) processes messages one by one, and
	//  - senders (the messageHandler's handler functions) must wait for it to finish
	// 	  to tell the client if test sessions are successfully launched.
	msgc := make(chan message)
	g, ctx := errgroup.WithContext(ctx)
	g.Go(func() error { return messageHandler(ctx, msgc) })
	g.Go(func() error { sessionManager(ctx, msgc); return nil })
	// In serve-only mode the runner just keeps the seeding/API backend up (until
	// SIGINT/SIGTERM) so `patrol develop` can drive the tests interactively; it
	// does not shell out to `patrol test` itself.
	if os.Getenv("E2E_SERVE_ONLY") == "" {
		g.Go(func() error {
			// stop() must be called here, otherwise a deadlock occurs in a happy path:
			//   1. all tests pass, runTests returns with no error.
			//   2. if messageHandler doesn't get any error, it doesn't return unless ctx is canceled.
			//   3. sessionManager never returns unless ctx is canceled.
			//   4. ctx is never canceled, as no goroutine returns an error.
			//   5. g.Wait() can't return until those two goroutines finish.
			defer stop()
			return runTests(ctx)
		})
	}
	return g.Wait()
}

func runTests(ctx context.Context) error {
	cmd := exec.CommandContext(ctx,
		"patrol",
		"test",
		"-v",
		"--flutter-command",
		// TODO: make flutter command path configurable
		"/Users/fujidaiti/.fvm/versions/stable/bin/flutter",
		"-d",
		// TODO: make the target device configurable
		"emulator-5554",
		// Run only the E2E scenarios (client/e2e/), built as part of the real
		// client app. They live outside integration_test/ (the mock suite) but
		// still compile into the app via the patrol test bundle.
		"-t",
		"e2e/",
		// The API server (session()) listens on the host's :8080; from the
		// Android emulator the host is reached via 10.0.2.2, so localhost would
		// silently point back at the emulator.
		// TODO: make the API base URL configurable.
		"--dart-define",
		"API_BASE_URL=http://10.0.2.2:8080",
	)
	// patrol builds and drives the client app (which carries the full native
	// plugin configuration), not a separate throwaway Flutter package. The
	// runner lives in client/e2e/, so the client package root is one level up.
	cmd.Dir = ".."
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("testing failed with an error: %w", err)
	}
	return nil
}

type message struct {
	body    messageBody
	resultc chan<- string
}

type messageBody struct {
	SeederID string `json:"seeder_id"`
}

const (
	// apiBaseURL is where the runner reaches the session's API server. The
	// server binds :8080; the emulator reaches it via 10.0.2.2:8080, but the
	// runner itself runs on the host, so it uses localhost.
	// TODO: make the API base URL configurable (see runTests' dart-define).
	apiBaseURL = "http://127.0.0.1:8080"
	// Pre-defined credentials the /signin endpoint provisions. The password is
	// reused from the auth seeder's existingUserPassword; the email is distinct
	// so it doesn't collide with the auth scenarios' seeded account.
	testAccountEmail  = "e2e-runner@example.com"
	testAccountDevice = "e2e-runner"
)

type authReqBody struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Device   string `json:"device"`
}

type authResBody struct {
	Token string `json:"token"`
}

// createTestAccountToken provisions the pre-defined test account on the running
// API server and returns its bearer token. It signs the account up; if the
// account already exists (a seeder may have inserted it), it signs in instead.
func createTestAccountToken(ctx context.Context) (string, error) {
	token, status, err := postAuth(ctx, "/signup")
	if err != nil {
		return "", err
	}
	if status == http.StatusConflict {
		token, status, err = postAuth(ctx, "/signin")
		if err != nil {
			return "", err
		}
	}
	if status != http.StatusOK && status != http.StatusCreated {
		return "", fmt.Errorf("auth request to %q failed with status %d", apiBaseURL, status)
	}
	return token, nil
}

// postAuth POSTs the pre-defined credentials to path (/signup or /signin) on the
// API server. It returns the issued token on a 2xx response, or an empty token
// with the response status (e.g. 409) so the caller can fall back.
func postAuth(ctx context.Context, path string) (token string, status int, err error) {
	body, err := json.Marshal(authReqBody{
		Email:    testAccountEmail,
		Password: existingUserPassword,
		Device:   testAccountDevice,
	})
	if err != nil {
		return "", 0, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiBaseURL+path, bytes.NewReader(body))
	if err != nil {
		return "", 0, err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", 0, err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return "", resp.StatusCode, nil
	}
	var res authResBody
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return "", resp.StatusCode, err
	}
	return res.Token, resp.StatusCode, nil
}

func messageHandler(ctx context.Context, msgc chan<- message) error {
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
			return
		}
		// Wait for the result to be returned.
		select {
		case res := <-resc:
			_, _ = fmt.Fprint(w, res)
		case <-r.Context().Done():
			_, _ = fmt.Fprint(w, "request canceled")
		}
	})

	// /signin provisions the pre-defined test account on the already-running
	// session API server and returns its bearer token, so gated feature tests
	// (e.g. newspaper) can boot already authenticated without driving the
	// sign-up UI. It talks to the API server directly rather than going through
	// the sessionManager: the client only calls /signin after /setup has
	// returned "ready", by which point the server is listening on :8080.
	mux.HandleFunc("POST /signin", func(w http.ResponseWriter, r *http.Request) {
		token, err := createTestAccountToken(r.Context())
		if err != nil {
			http.Error(w, fmt.Sprintf("failed to provision test account: %v", err), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"token": token})
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

	ln, err := net.Listen("tcp", srv.Addr)
	if err != nil {
		return err
	}
	errc := make(chan error, 1)
	go func() { errc <- srv.Serve(ln) }()

	select {
	case err := <-errc:
		if !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}
	case <-ctx.Done():
	}
	return nil
}

func sessionManager(ctx context.Context, msgc <-chan message) {
	tearDown := func() { /* no-op */ }
	for {
		select {
		case msg := <-msgc:
			tearDown()
			done := make(chan struct{})
			sctx, cancel := context.WithCancel(ctx)
			tearDown = func() { cancel(); <-done }
			go session(sctx, done, msg)

		case <-ctx.Done():
			tearDown()
			return
		}
	}
}

func session(ctx context.Context, done chan struct{}, msg message) {
	defer close(done)
	defer testenv.TearDown()
	if err := seedDB(ctx, testenv.DB(), msg.body.SeederID); err != nil {
		fmt.Fprintf(os.Stderr, "failed to seed DB for scenario %q: %v", msg.body.SeederID, err)
		// TODO: return a better response message
		msg.resultc <- "failed to seed DB"
		return
	}

	// TODO: make stub HTTP server address configurable
	proxyURL, _ := url.Parse("http://127.0.0.1:8081")
	srv := api.NewServer(testenv.DB(), proxyURL)
	defer func() {
		sctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := srv.Shutdown(sctx); err != nil {
			fmt.Fprintf(os.Stderr, "shutdown failed: %v\n", err)
		}
	}()

	ln, err := net.Listen("tcp", srv.Addr)
	if err != nil {
		msg.resultc <- fmt.Sprintf("failed to start server: %v", err)
		return
	}
	errc := make(chan error, 1)
	go func() { errc <- srv.Serve(ln) }()
	// TODO: return a cleaner response
	msg.resultc <- "ready"

	select {
	case err := <-errc:
		if !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintf(os.Stderr, "server exited abnormally: %v\n", err)
		}

	case <-ctx.Done():
	}
}
