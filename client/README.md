# paperdoll

The Paperdoll mobile client — a daily-newspaper RSS reader. See
[`docs/design.md`](docs/design.md) for the architecture and screen design.

## Setup

Uses [FVM](https://fvm.app/); run all tooling through `fvm flutter` /
`fvm dart`.

```sh
fvm flutter pub get
fvm dart run build_runner build          # generate *.freezed.dart / *.g.dart
```

Configuration (API base URL) is read from `.env` via `--dart-define-from-file`.
Copy the template and adjust if needed:

```sh
cp .env.example .env
```

## Running

```sh
fvm flutter run -d macos --dart-define-from-file=.env
```

`API_BASE_URL` in `.env` must point at a running Paperdoll API.

## Testing

Integration tests drive the real app against a
[Prism](https://stoplight.io/open-source/prism) mock server backed by the
OpenAPI spec. Start the mock first (from the repo root):

```sh
prism mock api/api.yaml          # serves http://127.0.0.1:4010
```

The test harness points the app at Prism by overriding the config provider, so
no `--dart-define` is needed. Run each suite in its own invocation — macOS
cannot relaunch multiple integration-test apps within one `flutter test` call:

```sh
fvm flutter test integration_test/today_to_story_test.dart -d macos
fvm flutter test integration_test/feeds_to_entry_test.dart -d macos
fvm flutter test integration_test/search_subscribe_test.dart -d macos
```
