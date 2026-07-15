# Integration tests

These tests run against a real Postgres database managed by [testcontainers-go].
Make sure Docker is installed and running before running them.

[testcontainers-go]: https://golang.testcontainers.org/

Every test file must start with the following build directive so these tests are
excluded from the normal unit test suite:

```go
//go:build integration
```

Run all integration tests with:

```sh
go test -tags="integration" ./integration_test/...
```

or filter by name with `-run`:

```sh
go test -tags="integration" ./integration_test/... -run TestSubmitStories
```
