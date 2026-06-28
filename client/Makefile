export PATROL_FLUTTER_COMMAND = ../.fvm/versions/stable/bin/flutter

# Run integration tests. Specify a target device as D=<device-id>.
.PHONY: integration-test
integration-test:
	patrol test -v -t integration_test/app_test.dart -d $(D)
