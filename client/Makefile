export PATROL_FLUTTER_COMMAND = ../.fvm/versions/stable/bin/flutter

# Run integration tests. Specify a target device as D=<device-id>.
.PHONY: integration-test
integration-test:
	patrol test -v -t integration_test/ -d $(D)

# Run the app in debug mode on the target specified by D=<device-id>.
.PHONY: dev
dev:
	fvm flutter run --dart-define-from-file=.env -d $(D)
