# Set up dev environment. Run this command once after cloning.
.PHONY: setup
setup:
	git config core.hooksPath .githooks
	fvm use
	cd client && fvm flutter pub get
	cd server && go mod tidy
