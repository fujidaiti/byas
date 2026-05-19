include .env

.PHONY: db-seed
db-seed:
	psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME) -f seed.sql

.PHONY: db-reset
db-reset:
	dropdb -h $(DB_HOST) -p $(DB_PORT) --if-exists $(DB_NAME)
	createdb -h $(DB_HOST) -p $(DB_PORT) $(DB_NAME)
	$(MAKE) db-seed

.PHONY: dev-poll
dev-poll:
	go run ./cmd/poll/*.go

.PHONY: dev-scheduler
dev-scheduler:
	go run ./cmd/scheduler/*.go
