#!/bin/sh

set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

FLUTTER_VERSION=$(grep "flutter" .fvmrc | cut -d '"' -f 4)
if [ -z "$FLUTTER_VERSION" ]; then
  echo ".fvmrc or flutter version is missing." >&2
  exit 1
fi

git clone https://github.com/flutter/flutter.git \
    --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"

export PATH="$PATH:$HOME/flutter/bin"

INSTALLED_VERSION=$( \
    flutter --no-version-check --suppress-analytics --version --machine \
    | grep "flutterVersion" \
    | cut -d '"' -f 4)

if [ "$INSTALLED_VERSION" != "$FLUTTER_VERSION" ]; then
    echo "Flutter version mismatch: got $INSTALLED_VERSION, want $FLUTTER_VERSION" >&2
    exit 1
fi

# Install Flutter artifacts for iOS
flutter precache --ios
# Install Flutter dependencies
flutter pub get

exit 0
