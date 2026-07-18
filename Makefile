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

.PHONY: dev-server
dev-server:
	go run ./server/cmd/app/main.go serve

.PHONY: build-server-linux-amd64
build-server-linux-amd64:
	GOOS=linux GOARCH=amd64 go build -o build/paperdoll-server-linux-amd64 ./server/cmd/app/main.go
