# paperdoll

The Paperdoll mobile client — a daily-newspaper RSS reader.

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

Find the target device's ID using `fvm flutter devices`, then:

```sh
fvm flutter run -d [device-id] --dart-define-from-file=.env
```

## Testing

Integration tests drive the real app against a
[Prism](https://stoplight.io/open-source/prism) mock server backed by the
OpenAPI spec. Start the mock first (from the repo root):

```sh
prism mock api/api.yaml          # serves http://127.0.0.1:4010
```

The test harness points the app at Prism by overriding the config provider, so
no `--dart-define` is needed:

```sh
fvm flutter test integration_test/app_test.dart -d [device-id]
```

## Sharing to the reading list (Android)

Users can save a web page to the reading list directly from a browser's share
sheet, without opening the full app. The flow:

1. The user shares a page from a browser and picks "Save to Reading List".
2. The activity extracts the first `http(s)` URL from the shared text.
3. It fires a request to `POST /reading-list`.

See also:

- [Set up the Compose Compiler Gradle plugin](https://developer.android.com/develop/ui/compose/setup-compose-dependencies-and-compiler#setup-compose-compiler-without-version-catalog)
