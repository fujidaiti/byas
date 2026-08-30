#!/bin/sh
#
# Verifies the archive Xcode Cloud just built,
# before it reaches App Store Connect.

set -e

if [ -z "$CI_ARCHIVE_PATH" ]; then
  echo "Not an archive action; nothing to verify."
  exit 0
fi

APP_PLIST="$CI_ARCHIVE_PATH/Products/Applications/Runner.app/Info.plist"
APPEX_PLIST="$CI_ARCHIVE_PATH/Products/Applications/Runner.app/PlugIns/ShareExtension.appex/Info.plist"

for PLIST in "$APP_PLIST" "$APPEX_PLIST"; do
  if [ ! -f "$PLIST" ]; then
    echo "Missing $PLIST." >&2
    exit 1
  fi
done

# plutil exits non-zero on a missing key, which set -e would turn into a bare
# failure; swallow it so the checks below can report what was wrong.
plist_value() {
  plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

# API Endpoint Parity
#
# Check if the app and extention point the same API server.

if [ -z "$DART_DEFINES_BASE64" ]; then
  echo "DART_DEFINES_BASE64 is not defined." >&2
  exit 1
fi

DOT_ENV="${TMPDIR%/}/dart-defines.env"
echo "$DART_DEFINES_BASE64" | base64 -d | tr -d '\r' > "$DOT_ENV"

if ! API_BASE_URL=$(. "$DOT_ENV" && printf '%s' "$API_BASE_URL"); then
  echo "Could not read API_BASE_URL out of DART_DEFINES_BASE64." >&2
  exit 1
fi

APPEX_API_BASE_URL=$(plist_value "$APPEX_PLIST" APIBaseURL)

if [ "$APPEX_API_BASE_URL" != "$API_BASE_URL" ]; then
  echo "ShareExtension APIBaseURL '$APPEX_API_BASE_URL' does not match the app's" >&2
  echo "API_BASE_URL '$API_BASE_URL'." >&2
  exit 1
fi

# App Version Parity
#
# Check if the app and extension have the same version labels,
# otherwise App Store Connect rejects the upload.

for KEY in CFBundleShortVersionString CFBundleVersion; do
  APP_VALUE=$(plist_value "$APP_PLIST" "$KEY")
  APPEX_VALUE=$(plist_value "$APPEX_PLIST" "$KEY")
  if [ -z "$APP_VALUE" ]; then
    echo "Runner.app has no $KEY." >&2
    exit 1
  fi
  if [ "$APP_VALUE" != "$APPEX_VALUE" ]; then
    echo "$KEY differs: Runner.app '$APP_VALUE', ShareExtension.appex '$APPEX_VALUE'." >&2
    exit 1
  fi
done

exit 0
