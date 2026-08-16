#!/bin/sh

set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

FLUTTER_VERSION=$(grep "flutter" .fvmrc | cut -d '"' -f 4)
if [ -z "$FLUTTER_VERSION" ]; then
  echo ".fvmrc or flutter version is missing." >&2
  exit 1
fi

git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

FLUTTER_VERSION_OUT="${TMPDIR%/}/flutter-version.json"
flutter --no-version-check --suppress-analytics --version --machine > "$FLUTTER_VERSION_OUT"
INSTALLED_VERSION=$(grep "flutterVersion" "$FLUTTER_VERSION_OUT" | cut -d '"' -f 4)
echo "flutter --version:"
cat "$FLUTTER_VERSION_OUT"

if [ "$INSTALLED_VERSION" != "$FLUTTER_VERSION" ]; then
    echo "Flutter version mismatch: got $INSTALLED_VERSION, want $FLUTTER_VERSION" >&2
    exit 1
fi

# Install Flutter artifacts for iOS
flutter precache --ios
# Install Flutter dependencies
flutter pub get

# TODO: copy version name in version.json to xconfig
# TODO: decode and apply .env

exit 0
