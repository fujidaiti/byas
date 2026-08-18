# iOS

Two shipping targets live in `Runner.xcodeproj`:

| Target           | Product                                                          | What it is                                                                              |
| ---------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `Runner`         | `Runner.app`, `dev.norelease.paperdoll`                          | The Flutter app.                                                                        |
| `ShareExtension` | `ShareExtension.appex`, `dev.norelease.paperdoll.ShareExtension` | Share-sheet entry point for saving a URL to the reading list. Pure SwiftUI, no Flutter. |

`RunnerTests` is the stock Flutter unit-test target and is not part of any of
this.

## The app and the share extension

The extension is the iOS counterpart of Android's `SaveWebClipActivity` (see
`android/app/src/main/kotlin/dev/norelease/paperdoll/`), and it is deliberately
a straight port: same states, same copy, same fire-and-forget semantics. What
differs is only the platform mechanism — Android exports an activity behind an
`ACTION_SEND` intent filter, iOS embeds an app extension.

Three things are worth knowing before touching it.

**It is a separate process, and it does not embed Flutter.** The extension never
starts a Flutter engine and links nothing from the Flutter framework — its
`Frameworks` build phase is empty and must stay empty, or the `.appex` bloats
and App Store validation flags a non-extension-safe framework. Everything the
extension needs it either compiles in (see `APIConfig.xcconfig` below) or reads
out of shared storage.

**The POST outlives the extension.** iOS tears the extension process down the
moment it calls `completeRequest`, so the upload is handed to `nsurlsessiond`
instead of being run in-process: a background `URLSession` upload task, with the
request body written to a file in the app group container (background tasks are
file-based — no in-memory bodies). This is what Android gets from its
process-lifetime `SaveScope`, and it is why "Close" is tappable from the first
frame and never cancels anything.

The consequence is that the _app_ has to clean up after the _extension_:

```
ShareExtension                        nsurlsessiond                    Runner
  writes body to app group   ──▶
  starts background task     ──▶      transfers (may outlive
  user taps Close                     the extension by hours)
  process dies                                  │
                                                ▼
                                        app relaunched ──▶  handleEventsForBackgroundURLSession
                                                            deletes the body file, silently
```

`AppDelegate` reconnects to whatever session identifier the system hands it and
deletes the body file named by the task's `taskDescription`. It also sweeps the
app group container on launch for files older than a day, to catch bodies
orphaned by a crash before any delegate callback fired. Success and failure are
both silent — once the dialog is gone, a save either lands or it quietly
doesn't, matching Android exactly.

Background sessions created from an app extension need a _unique_ identifier per
session, so the extension uses `<its bundle id>.<UUID>`.

**Capabilities.** Both targets carry the same two entitlements
(`Config/Runner.entitlements`, `Config/ShareExtension.entitlements`):

- **App Groups** — `group.dev.norelease.paperdoll`, the container the upload
  body is written to.
- **Keychain Sharing** — `$(AppIdentifierPrefix)dev.norelease.paperdoll.shared`,
  so both targets see one physical auth-token item.

Both must be registered on both App IDs in the Apple Developer portal before an
archive will sign.

## Shared storage, and why the keys are duplicated

The extension is useful only when the user is already logged in: it reads the
auth token Flutter wrote, and shows the "Log in to Paperdoll first" state when
there isn't one. That means Flutter and native code have to agree on one
physical Keychain item.

Flutter's `SecureStorage` (`lib/core/platform/secure_storage.dart`) routes iOS
and Android through a `MethodChannel` to native code — `AppDelegate` +
`SecureStorage.swift` here, `MainActivity` + `SecureStorage.kt` there. macOS
still uses the `flutter_secure_storage` plugin. On iOS the backing store is a
`kSecClassGenericPassword` item; the Keychain does the encryption Android had to
hand-roll over Keystore.

The item is identified by three attributes, and **they are written out
independently in four places**:

| Where                                                                      | Declares                             |
| -------------------------------------------------------------------------- | ------------------------------------ |
| `lib/features/auth/data/auth_repository_impl.dart`                         | `authTokenStorageKey` — the origin   |
| `android/app/src/main/kotlin/dev/norelease/paperdoll/SaveWebClipScreen.kt` | `AUTH_TOKEN_KEY`                     |
| `ios/Runner/SecureStorage.swift`                                           | service + account, read/write/delete |
| `ios/ShareExtension/ReadingListUploader.swift`                             | service + account, read only         |

This duplication is deliberate, not an oversight. There is no cross-language
mechanism that would let one declaration reach Dart, Kotlin and two Swift
targets, and sharing the Swift file between `Runner` and `ShareExtension` would
buy one shared string at the cost of an `ios/Shared/` group plus explicit
build-file entries straddling the extension's synchronized-folder boundary — for
a target that needs a single read, not the whole read/write/delete surface.
Android already accepts exactly this duplication. Each copy carries a comment
naming the others.

**When you change any of these strings, change all four.** Nothing breaks at
compile time. The failure mode is that the extension silently reads `nil` and
shows "Log in to Paperdoll first, then try sharing again." forever, which is
indistinguishable from a legitimately logged-out user.

One attribute is _not_ duplicated: the Keychain access group.
`SecureStorage.swift` pins it on writes only; the extension's read omits it,
because a query without an access group searches every group the process can
reach, and the entitlement already scopes that. So the group string exists in
exactly one Swift file, and a read can never land in the wrong place.

## `Config/APIConfig.xcconfig`

The extension talks to the API directly, so it needs `API_BASE_URL` compiled in
— the same value Flutter gets from `--dart-define-from-file=.env` and Android
gets from `BuildConfig.API_BASE_URL`.

```
Config/APIConfig.xcconfig      ← you create this, gitignored
        │
        ▼
Config/ShareExtension.xcconfig ← base config of all three ShareExtension configurations
        │
        ▼
ShareExtension/Info.plist      ← APIBaseURL = $(PAPERDOLL_API_BASE_URL)
        │
        ▼
APIConfig.swift                ← Bundle.main
```

**Setup:** copy `Config/APIConfig.example.xcconfig` to
`Config/APIConfig.xcconfig` and point it at your dev server. It is gitignored,
on the same pattern as `.env`/`.env.example`. In CI,
`ci_scripts/ci_post_clone.sh` generates it from the decoded
`DART_DEFINES_BASE64` dotenv.

**It is deliberately independent of `.env`.** iOS does not read `client/.env`,
and the two files routinely hold different hosts — `.env` points at `10.0.2.2`,
the Android emulator's alias for the host machine, which means nothing to an
iPhone or the iOS simulator.

Two traps worth knowing:

**xcconfig treats `//` as a comment delimiter anywhere on a line, including
inside a value.** Writing `PAPERDOLL_API_BASE_URL = http://localhost:8080`
silently yields `http:`. Hence the indirection:

```
PAPERDOLL_URL_SLASH = /
PAPERDOLL_API_BASE_URL = http:$(PAPERDOLL_URL_SLASH)$(PAPERDOLL_URL_SLASH)localhost:8080
```

**This could not have been a build phase.** Xcode resolves xcconfig files when
it builds the build plan, before any Run Script phase executes, so a script that
generates an xcconfig only ever affects the _next_ build. Anything a target
needs as a _build setting_ has to exist before `xcodebuild` starts — which is
also why `ci_post_clone.sh`, not a build phase, writes both this file and
`Version.xcconfig`.

## Build settings and versioning

| File                                         | Consumed by      | Provenance                                                                            |
| -------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------- |
| `Flutter/Generated.xcconfig`                 | both targets     | Written by `flutter build`/`flutter run`. Gitignored.                                 |
| `Flutter/Version.xcconfig`                   | both targets     | Written by `ci_post_clone.sh` from `version.json`. Absent locally, hence `#include?`. |
| `Flutter/Debug.xcconfig`, `Release.xcconfig` | `Runner`         | Committed; include the two above.                                                     |
| `Config/ShareExtension.xcconfig`             | `ShareExtension` | Committed; includes the two above plus `APIConfig.xcconfig`.                          |
| `Config/APIConfig.xcconfig`                  | `ShareExtension` | Yours, or `ci_post_clone.sh`'s. Gitignored.                                           |

**An embedded extension's version must match its host app's exactly, or App
Store Connect rejects the upload.** Both targets therefore derive their versions
from the same two settings — `Runner` via `Flutter/Debug.xcconfig`, the
extension via `Config/ShareExtension.xcconfig`:

```
MARKETING_VERSION        = $(FLUTTER_BUILD_NAME)     → CFBundleShortVersionString
CURRENT_PROJECT_VERSION  = $(FLUTTER_BUILD_NUMBER)   → CFBundleVersion
```

Do not set either of these in the target's build settings in Xcode.
**Target-level settings override `baseConfigurationReference`**, so a literal
there wins over the xcconfig silently — the build stays green and the archive
fails validation at the very end. The Xcode template ships exactly these
literals (`MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`) on a new
extension target; they were deleted, not overridden, and should stay deleted.
The same applies to `IPHONEOS_DEPLOYMENT_TARGET`, which the extension inherits
from the project so it tracks the app's floor.

To check the two agree, build and compare:

```sh
plutil -p "$BUILT/Runner.app/Info.plist" | grep -i CFBundleVersion
plutil -p "$BUILT/Runner.app/PlugIns/ShareExtension.appex/Info.plist" | grep -i CFBundleVersion
```

## App Transport Security

`Runner/Info.plist` has no ATS exception and does not need one: Flutter's
`dart:io` has its own socket stack and bypasses ATS entirely. The extension uses
native `URLSession`, which does not, so `ShareExtension/Info.plist` sets
`NSAllowsLocalNetworking` — enough for `localhost` and RFC1918 addresses during
development, App-Store-safe, and no per-configuration plist juggling.
