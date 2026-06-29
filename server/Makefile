include .env
export

.PHONY: db-seed
db-seed:
	psql -d $(DB_NAME) -f db/seed.sql

.PHONY: db-reset
db-reset:
	dropdb --if-exists $(DB_NAME)
	createdb $(DB_NAME)
	$(MAKE) db-seed

.PHONY: dev-poll
dev-poll:
	go run ./cmd/dev/main.go poll

.PHONY: dev-serve
dev-serve:
	go run ./cmd/app/main.go serve

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o build/paperdoll-linux-amd64 ./cmd/app/main.go
