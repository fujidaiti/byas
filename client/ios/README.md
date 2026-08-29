# iOS

The iOS project ships two targets:

- `Runner` — the Flutter app.
- `ShareExtension` — share sheet entry point for saving a URL from other apps
  such as Safari to the reading list.

## Setup

The share extension reads configurations from an xcconfig. Copy the template and
point it at your dev environment:

```sh
cp Config/App.example.xcconfig Config/App.xcconfig
```

## Shared auth token

The extension is useful only when the user is already logged in, To ensure that
Flutter and native code agree on one physical Keychain item,
`SecureStorage.swift` implements the vault and the Flutter app interacts with it
through a MethodChannel.

The item's identifying attributes are declared independently in three places:

- `auth_repository_impl.dart` — `authTokenStorageKey`, the token key
- `SecureStorage.swift` — App Group ID
- `ReadingListUploader.swift` — Keychain service name, App Group ID, and the
  token key

**Make sure they always stay in-sync.**

## Versioning

An embedded extension's version must match its host app's exactly, so both
targets derive `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from
`FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` via their xcconfigs. Do not set
either version in a target's build settings in Xcode: that silently overrides
the xcconfig, and the archive fails validation at the end of an otherwise green
build.

## Xcode Cloud

An Xcode Cloud workflow builds and uploads the TestFlight release. See DEPLOY.md
for more details.
