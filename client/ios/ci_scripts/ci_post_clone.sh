#!/bin/sh
#
# Prepares the Xcode Cloud build machine to build the iOS app.
#
# Xcode Cloud runs this after cloning the repo and before the build, purely
# because of where it lives (ci_scripts/ next to the project). It installs the
# Flutter SDK, which isn't on the build machine, and generates the two inputs
# the build needs that aren't checked in: Flutter/Version.xcconfig and the
# dotenv file backing --dart-define-from-file. The final `flutter build ios` is
# --config-only: it configures the Xcode project without archiving, and Xcode
# Cloud runs the actual build afterwards.
#
# The workflow that runs this script is configured in App Store Connect rather
# than in this repo. It triggers on ios-stg-* tags, which version-tagging.yaml
# pushes when client/ios/version.json is bumped, and uploads the resulting
# build to TestFlight.
#
# That workflow has to define this environment variable, as a secret:
#
#   DART_DEFINES_BASE64   base64-encoded dotenv file holding the app's
#                         --dart-define values
#
# Nothing else is needed here: signing and the TestFlight upload are Xcode
# Cloud's own, configured alongside the workflow.
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
flutter build ios \
    --release \
    --config-only \
    --obfuscate \
    --split-debug-info \
    --dart-define-from-file="$DOT_ENV"

exit 0
