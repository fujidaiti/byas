#!/bin/sh
#
# Prepares the Xcode Cloud build machine to build the iOS app.
#
# An Xcode Cloud workflow for the TestFlight deployment runs this script after
# cloning the repo and before the build. The workflow triggers on ios-stg-* tags,
# which version-tagging.yaml pushes when client/ios/version.json is bumped.
#
# That workflow has to define this environment variable:
#
#   DART_DEFINES_BASE64   base64-encoded dotenv file holding the app's
#                         --dart-define values
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
# hand-written (see ios/Config/APIConfig.example.xcconfig); here it comes from the
# same dotenv Flutter gets.
#
# This runs before the build on purpose: Xcode resolves xcconfig files when it
# builds the build plan, before any Run Script phase executes, so generating one
# from a build phase would only ever affect the *next* build.

API_BASE_URL=$(sed -n 's/^API_BASE_URL=//p' "$DOT_ENV" | tr -d '\r' | head -n 1)
if [ -z "$API_BASE_URL" ]; then
  echo "API_BASE_URL is missing or empty in DART_DEFINES_BASE64." >&2
  exit 1
fi

# xcconfig treats // as a comment delimiter anywhere on a line, including inside a
# value, so the URL's slashes have to arrive through a variable or the value would
# be truncated to "https:".
ESCAPED_API_BASE_URL=$(printf '%s' "$API_BASE_URL" |
  sed 's|//|$(PAPERDOLL_URL_SLASH)$(PAPERDOLL_URL_SLASH)|g')

cat > "$FLUTTER_PROJECT_DIR/ios/Config/APIConfig.xcconfig" <<EOF
PAPERDOLL_URL_SLASH = /
PAPERDOLL_API_BASE_URL = $ESCAPED_API_BASE_URL
EOF

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
