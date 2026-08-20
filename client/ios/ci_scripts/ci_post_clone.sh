#!/bin/sh
#
# Prepares the Xcode Cloud build machine to build the iOS app.
#
# An Xcode Cloud workflow for the TestFlight deployment runs this script after
# cloning the repo and before the build. The workflow triggers on ios-stg-* tags,
# which version-tagging.yaml pushes when client/ios/version.json is bumped.
#
# That workflow has to define these environment variables:
#
#   DART_DEFINES_BASE64          base64-encoded dotenv file holding the app's
#                                --dart-define values
#   API_CONFIG_XCCONFIG_BASE64   base64-encoded Config/APIConfig.xcconfig
#                                (see ios/Config/APIConfig.example.xcconfig)
#
# See DEPLOY.md for the overview of the entire deployment pipeline.

FLUTTER_PROJECT_DIR="$CI_PROJECT_FILE_PATH/../.."

set -e
brew install jq
cd "$CI_PRIMARY_REPOSITORY_PATH"

##### Create Version.xcconfig #####

VERSION_FILE="$FLUTTER_PROJECT_DIR/ios/version.json"
tool/version.sh vet "$VERSION_FILE"
# Extract version name dropping the 'beta' suffix.
VERSION_NAME=$(jq -r '.versionName // empty' "$VERSION_FILE" | sed 's/\.beta$//')

# Flutter/Debug.xcconfig and Release.xcconfig will load this xcconfig,
# which overrides the default version values from pubspec.yaml.
#
# We ignore the build number in the version file here,
# and use the built-in incremental counter instead.
cat > "$FLUTTER_PROJECT_DIR/ios/Flutter/Version.xcconfig" <<EOF
FLUTTER_BUILD_NAME=$VERSION_NAME
FLUTTER_BUILD_NUMBER=$CI_BUILD_NUMBER
EOF

##### Prepare Dart defines #####

if [ -z "$DART_DEFINES_BASE64" ]; then
  echo "DART_DEFINES_BASE64 is not defined." >&2
  exit 1
fi

DOT_ENV="${TMPDIR%/}/.env"
echo "$DART_DEFINES_BASE64" | base64 -d > "$DOT_ENV"

##### Create APIConfig.xcconfig #####

# The share extension is native code with no access to --dart-define, so the API
# endpoint has to reach it as a build setting instead. Locally that file is
# hand-written (see ios/Config/APIConfig.example.xcconfig); here it arrives
# verbatim in an environment variable, the same way the dotenv above does.
#
# The file is taken as-is rather than assembled from API_BASE_URL, so the
# xcconfig quirks — chiefly that // starts a comment anywhere on a line, even
# inside a value — are the example file's business and not this script's.
#
# This runs before the build on purpose: Xcode resolves xcconfig files when it
# builds the build plan, before any Run Script phase executes, so writing one
# from a build phase would only ever affect the *next* build.

if [ -z "$API_CONFIG_XCCONFIG_BASE64" ]; then
  echo "API_CONFIG_XCCONFIG_BASE64 is not defined." >&2
  exit 1
fi

echo "$API_CONFIG_XCCONFIG_BASE64" | base64 -d \
  > "$FLUTTER_PROJECT_DIR/ios/Config/APIConfig.xcconfig"

# Whether that file yields the right endpoint is checked after the build, by
# ci_post_xcodebuild.sh, which compares the value that reached the archive
# against the API_BASE_URL in the dotenv above.

##### Install Flutter SDK #####

FLUTTER_VERSION=$(jq -r '.flutter // empty' .fvmrc)
if [ -z "$FLUTTER_VERSION" ]; then
  echo ".fvmrc or flutter version is missing." >&2
  exit 1
fi

git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# On a fresh clone, the first `flutter` invocation downloads the Dart SDK and
# writes curl's progress meter to stdout, which would corrupt the JSON below.
# Run a throwaway command first so that download happens before we capture
# machine-readable output.
flutter --no-version-check --suppress-analytics --version > /dev/null

FLUTTER_VERSION_OUT="${TMPDIR%/}/flutter-version.json"
flutter --no-version-check --suppress-analytics --version --machine > "$FLUTTER_VERSION_OUT"
echo "flutter --version:"
cat "$FLUTTER_VERSION_OUT"

INSTALLED_VERSION=$(jq -r '.flutterVersion // empty' "$FLUTTER_VERSION_OUT")
if [ "$INSTALLED_VERSION" != "$FLUTTER_VERSION" ]; then
    echo "Flutter version mismatch: got $INSTALLED_VERSION, want $FLUTTER_VERSION" >&2
    exit 1
fi

##### Build #####

cd "$FLUTTER_PROJECT_DIR"
# See https://docs.flutter.dev/deployment/cd#xcode-cloud
flutter precache --ios
# Configure the Xcode project without archiving.
# Xcode Cloud runs the actual build afterwards.
# TODO: upload the symbol file to Firebase crashlytics.
flutter build ios \
    --release \
    --config-only \
    --obfuscate \
    --split-debug-info="${TMPDIR%/}/ios-symbols" \
    --dart-define-from-file="$DOT_ENV"

exit 0
