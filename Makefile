-include server/.env
export

# Set up dev environment. Run this command once after cloning.
.PHONY: setup
setup:
	git config core.hooksPath .githooks
	fvm use
	cd client && fvm flutter pub get
	go mod tidy

.PHONY: db-migrate
db-migrate:
	go run ./server/cmd/app/main.go migrate up

.PHONY: dev-poll
dev-poll:
	go run ./server/cmd/dev/main.go poll

.PHONY: dev-serve
dev-serve:
	go run ./server/cmd/app/main.go serve

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o server/build/paperdoll-linux-amd64 ./server/cmd/app/main.go
