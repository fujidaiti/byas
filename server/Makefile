include .env
export

.PHONY: db-seed
db-seed:
	psql -d $(DB_NAME) -f seed.sql

.PHONY: db-reset
db-reset:
	dropdb --if-exists $(DB_NAME)
	createdb $(DB_NAME)
	$(MAKE) db-seed

.PHONY: dev-schedule
dev-schedule:
	go run ./cmd/main.go schedule

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o build/paperdoll-linux-amd64 ./cmd/scheduler/*.go
