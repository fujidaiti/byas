include .env
export

.PHONY: db-migrate
db-migrate:
	go run ./cmd/app/main.go migrate up

.PHONY: dev-poll
dev-poll:
	go run ./cmd/dev/main.go poll

.PHONY: dev-serve
dev-serve:
	go run ./cmd/app/main.go serve

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o build/paperdoll-linux-amd64 ./cmd/app/main.go
