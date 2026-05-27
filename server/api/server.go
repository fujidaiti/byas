package api

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"time"
)

func StartServer(ctx context.Context) {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", getHealth)

	srv := http.Server{
		Addr:    ":8080",
		Handler: mux,
		// Slowloris attack prevention
		ReadHeaderTimeout: 5 * time.Second,
		BaseContext: func(_ net.Listener) context.Context {
			return ctx
		},
	}
	defer func() {
		fmt.Println("Shutting down API server...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := srv.Shutdown(ctx); err != nil {
			fmt.Println("Graceful shutdown failed:")
			fmt.Println(err)
		}
	}()

	c := make(chan error, 1)
	go func() {
		fmt.Printf("API server started on %s\n", srv.Addr)
		err := srv.ListenAndServe()
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			c <- err
		}
	}()

	select {
	case <-ctx.Done():
	case err := <-c:
		fmt.Println(err)
	}
}

func getHealth(w http.ResponseWriter, _ *http.Request) {
	w.Write([]byte("Feeling good!"))
}
