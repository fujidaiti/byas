# E2E tests

The real-backend E2E suite, run with Patrol on a real device/emulator. Unlike
the widget tests in `client/test/`, these drive the actual Flutter app against a
real API server and DB (see the doc comment at the top of `main.go` for how the
runner, client, and test DB fit together).

## Requirements

Before running, check that:

- An Android emulator is running (`emulator-5554` by default):
  ```sh
  fvm flutter devices
  ```
- Docker is running (the test DB is spun up in a container via testcontainers):
  ```sh
  docker info > /dev/null 2>&1 && echo "docker is running"
  ```

## Running

```sh
cd e2e && go run ./...
```

This requires a running emulator/device (`emulator-5554` by default) and the
Flutter SDK managed by FVM.

## Running specific test cases

Everything after a literal `--` is forwarded to the underlying `patrol test`
invocation, so you can use Patrol's own `--tags` and `--target` options to
narrow down which tests run instead of executing the whole suite:

```sh
go run ./... -- --tags smoke
go run ./... -- --target e2e/auth_test.dart
go run ./... -- --target e2e/auth_test.dart --tags smoke
```

See
[patrol's tag docs](https://github.com/leancodepl/patrol/blob/master/docs/documentation/other/patrol-tags.mdx)
for the full syntax (tag expressions support `&&`, `||`, and `!`).
