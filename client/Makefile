export PATROL_FLUTTER_COMMAND = ../.fvm/versions/stable/bin/flutter

# Run the widget tests. No device needed: they run the whole app on the
# Flutter test framework, with stubbed HTTP and in-memory platform storage.
.PHONY: test
test:
	fvm flutter test

# Run the real-backend E2E suite (Patrol on a device, driven by the Go runner
# in client/e2e/).
.PHONY: e2e
e2e:
	cd e2e && go run ./...

# Run the app in debug mode on the target specified by D=<device-id>.
.PHONY: dev
dev:
	fvm flutter run --dart-define-from-file=.env -d $(D)
