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

`.env` also feeds the native Android side. The share-sheet activity (see
[Sharing to the reading list](#sharing-to-the-reading-list-android)) runs as
plain Kotlin and cannot read Dart `--dart-define` values, so
`android/app/build.gradle.kts` reads the same `.env` at configure time (via
`java.util.Properties`) and bakes `API_BASE_URL` into
`BuildConfig.API_BASE_URL`. The `.env` stays the single source of truth for both
Dart and native. When `.env` is absent (e.g. CI), it falls back to
`http://10.0.2.2:4010` (the emulator's host loopback). Because it is parsed as a
Java properties file, keep comments on their own `#` lines — a trailing
`# comment` after a value would be swallowed into the value.

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
sheet, without opening the full app. `SaveWebArticleActivity`
(`android/app/src/main/kotlin/dev/norelease/paperdoll/`) is a lightweight,
dialog-styled `ComponentActivity` (Jetpack Compose UI) registered for
`ACTION_SEND` + `text/plain`. It does **not** boot the Flutter engine. The flow:

1. The user shares a page from a browser and picks "Save to Reading List".
2. The activity extracts the first `http(s)` URL from the shared text (browsers
   often share `"Title https://…"`), then `POST`s `{ "url": … }` to
   `/reading-list` using `HttpURLConnection`. Non-URL shares are ignored and the
   activity closes silently.
3. It shows progress, then a success or error message with a Close button.

The user can tap Close at any time, even mid-request: the POST runs on a
process-lifetime coroutine (`SaveScope`) so it completes even after the dialog
is dismissed. It is only lost if the OS kills the app process before the request
finishes (no `WorkManager` is used). The endpoint host comes from
`BuildConfig.API_BASE_URL` (see [Setup](#setup)). This is Android-only; iOS
support will land later.

Debug builds permit cleartext HTTP (via
`android/app/src/debug/res/xml/network_security_config.xml`) so the activity can
reach a local dev server at any address — `10.0.2.2` on the emulator, a LAN IP
on a physical device (e.g. `192.168.x.x`), or a Prism mock. Release builds keep
HTTPS-only enforcement.

See also:

- [Set up the Compose Compiler Gradle plugin](https://developer.android.com/develop/ui/compose/setup-compose-dependencies-and-compiler)

