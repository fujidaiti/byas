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

.PHONY: dev-poll
dev-poll:
	go run ./cmd/poll/*.go

.PHONY: dev-scheduler
dev-scheduler:
	go run ./cmd/scheduler/*.go

.PHONY: dev-assemble
dev-assemble:
	go run ./cmd/assemble/*.go

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o build/paperdoll-linux-amd64 ./cmd/scheduler/*.go
