export PATROL_FLUTTER_COMMAND = ../.fvm/versions/stable/bin/flutter

# Run the widget tests. No device needed: they run the whole app on the
# Flutter test framework, with stubbed HTTP and in-memory platform storage.
.PHONY: test
test:
	fvm flutter test

# Run the mocked integration tests. Specify a target device as D=<device-id>.
# The real-backend E2E suite lives in client/e2e/ (run via the Go runner in
# ../e2e), separate from integration_test/, so nothing to exclude here.
.PHONY: integration-test
integration-test:
	patrol test -v -t integration_test/ -d $(D)

.PHONY: e2e
e2e:
	cd e2e && go run ./...

# Run the app in debug mode on the target specified by D=<device-id>.
.PHONY: dev
dev:
	fvm flutter run --dart-define-from-file=.env -d $(D)
