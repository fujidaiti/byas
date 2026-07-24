export PATROL_FLUTTER_COMMAND = ../.fvm/versions/stable/bin/flutter

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
