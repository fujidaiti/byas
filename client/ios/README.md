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
Flutter and native code agree on one physical Keychain item, the `Shared`
package's `SecureStorage.swift` implements the vault and the Flutter app
interacts with it through a MethodChannel.

The token key is the one attribute still declared twice, once per language:

- `auth_repository_impl.dart` — `authTokenStorageKey`
- `SecureStorage.swift` — `authTokenKey`

**Make sure they always stay in-sync.**

## Versioning

App Store requires the share extension's version matches the Flutter app's
exactly. Both of them use `FLUTTER_BUILD_NAME` as the version name, which is
derived from pubspec.yaml in debug builds, and [version.json] in release builds.

As to the build number, we use `CI_BUILD_NUMBER`, which is a built-in
incremental counter managed by Xcode Cloud.

See [Release.xcconfig] and [ShareExtension.xcconfig] for more details.

[version.json]: version.json
[Release.xcconfig]: Flutter/Release.xcconfig
[ShareExtension.xcconfig]: Config/ShareExtension.xcconfig

## Deployment

An Xcode Cloud workflow builds and uploads the TestFlight release. See these
files for more details:

- [DEPLOY.md], which describes an overview of the release pipeline
- [ci_post_clone.sh], which prepares Xcode Cloud machine to build the app
- [ci_post_xcodebuild.sh], which validates the build archive

[DEPLOY.md]: ../../DEPLOY.md
[ci_post_clone.sh]: ci_scripts/ci_post_clone.sh
[ci_post_xcodebuild.sh]: ci_scripts/ci_post_xcodebuild.sh
