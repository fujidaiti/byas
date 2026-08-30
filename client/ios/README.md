# iOS

The iOS project ships two targets and a local Swift package:

- `Runner` — the Flutter app.
- `ShareExtension` — share sheet entry point for saving a URL from other apps
  such as Safari to the reading list.
- `Shared` — code both targets use: the Keychain vault and the App Group
  container they exchange upload bodies through.

## Setup

The share extension reads configurations from an xcconfig. Copy the template and
point it at your dev environment:

```sh
cp Config/App.example.xcconfig Config/App.xcconfig
```

## Shared auth token

The extension is useful only when the user is already logged in, To ensure that
Flutter and native code agree on one physical Keychain item, the `Shared`
package's `SecureStorage.swift` implements the vault and the Flutter app
interacts with it through a MethodChannel.

The token key is the one attribute still declared twice, once per language:

- `auth_repository_impl.dart` — `authTokenStorageKey`
- `SecureStorage.swift` — `authTokenKey`

**Make sure they always stay in-sync.**

## Versioning

An embedded extension's version must match the Flutter app's exactly, so both
targets derive `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from
`FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` via their xcconfigs. Do not set
either version in a target's build settings in Xcode: that silently overrides
the xcconfig, and the archive fails validation at the end of an otherwise green
build.

## Xcode Cloud

An Xcode Cloud workflow builds and uploads the TestFlight release. See DEPLOY.md
for more details.
