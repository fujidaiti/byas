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
# Extract version name and build number dropping the 'beta' suffix.
VERSION_NAME=$(jq -r '.versionName // empty' "$VERSION_FILE" | sed 's/\.beta$//')
BUILD_NUMBER=$(jq -r '.buildNumber // empty' "$VERSION_FILE")

# Flutter/Deubg.xcconfig and Release.xcconfig will load this xcconfig,
# which overrides the default version values from pubspec.yaml.
cat > "$FLUTTER_PROJECT_DIR/ios/Flutter/Version.xcconfig" <<EOF
FLUTTER_BUILD_NAME=$VERSION_NAME
FLUTTER_BUILD_NUMBER=$BUILD_NUMBER
EOF

##### Prepare Dart defines #####

if [ -z "$DART_DEFINES_BASE64" ]; then
  echo "DART_DEFINES_BASE64 is not defined." >&2
  exit 1
fi

DOT_ENV="${TMPDIR%/}/.env"
echo "$DART_DEFINES_BASE64" | base64 -d > "$DOT_ENV"

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
flutter build ios \
    --release \
    --config-only \
    --obfuscate \
    --split-debug-info \
    --dart-define-from-file="$DOT_ENV"

exit 0
