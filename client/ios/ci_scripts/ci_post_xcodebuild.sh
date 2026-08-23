#!/bin/sh
#
# Verifies the archive Xcode Cloud just built, before it reaches TestFlight.
#
# Both checks below cover build misconfigurations that a green build does not
# catch, because the values they inspect only exist once the products are
# assembled. See DEPLOY.md for the overview of the entire deployment pipeline.

set -e

# CI_ARCHIVE_PATH is only set for an archive action, so this is a no-op for the
# build and test actions the same script runs after.
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

##### The extension's API endpoint #####

# The app and the extension reach the same API through two separate variables:
# the app gets API_BASE_URL out of DART_DEFINES_BASE64 as a --dart-define, the
# extension gets ios/Config/App.xcconfig out of APP_XCCONFIG_BASE64, surfaced as
# ShareExtension/Info.plist's APIBaseURL. An app and its own share extension
# talking to different backends is never intended, so the app's value is what
# the archive is checked against.
#
# That comparison is the only thing standing between these and a TestFlight build
# where every share silently fails:
#
#   $(PAPERDOLL_API_BASE_URL)  the xcconfig never arrived, or names a different
#                              variable, leaving the plist entry unexpanded
#   http:                      xcconfig treats // as a comment delimiter anywhere
#                              on a line, so an unescaped URL loses everything
#                              from the scheme's slashes on
#   a stale endpoint           well-formed, and pointing at the wrong server
#
# The first two are not caught at runtime either: URL(string:) accepts "http:"
# as a scheme-only URL with no host, which AppConfig.swift's guard lets through.
#
# Compared byte for byte on purpose. Two build configurations naming one endpoint
# should name it identically, so a stray trailing slash is worth a build failure.

if [ -z "$DART_DEFINES_BASE64" ]; then
  echo "DART_DEFINES_BASE64 is not defined; cannot tell what APIBaseURL should be." >&2
  exit 1
fi

# Sourced rather than parsed, because the value has to come out of the dotenv the
# way Flutter's --dart-define-from-file read it. That parser (DotEnvRegex in
# flutter_command.dart) trims the line, strips wrapping quotes and strips a
# trailing "# comment", and so does sh — whereas cutting at the first = would
# keep the quotes and the comment and then report a mismatch that is not real.
# CRs are dropped here because Flutter trims them and sh would not.
#
# sh is stricter in exactly one place: Flutter also allows spaces around the =,
# which sh reads as a command. Such a file fails below with "command not found"
# rather than a wrong answer.
#
# The command substitution runs the dotenv in a subshell, so the rest of its keys
# stay out of this script's environment.
DOT_ENV="${TMPDIR%/}/dart-defines.env"
echo "$DART_DEFINES_BASE64" | base64 -d | tr -d '\r' > "$DOT_ENV"
if ! API_BASE_URL=$(. "$DOT_ENV" && printf '%s' "$API_BASE_URL"); then
  echo "Could not read API_BASE_URL out of DART_DEFINES_BASE64." >&2
  exit 1
fi

APPEX_API_BASE_URL=$(plist_value "$APPEX_PLIST" APIBaseURL)

if [ "$APPEX_API_BASE_URL" != "$API_BASE_URL" ]; then
  echo "ShareExtension APIBaseURL '$APPEX_API_BASE_URL' does not match the app's" >&2
  echo "API_BASE_URL '$API_BASE_URL'. Check APP_XCCONFIG_BASE64 against" >&2
  echo "ios/Config/App.example.xcconfig." >&2
  exit 1
fi

##### Version parity #####

# App Store Connect rejects an upload whose embedded extension does not carry
# exactly the host app's version — after the whole archive. Both targets derive
# theirs from FLUTTER_BUILD_NAME/FLUTTER_BUILD_NUMBER, but a target-level build
# setting silently beats the xcconfig that supplies them (which is what the
# Xcode extension template ships), so the products are the only honest place to
# compare. See ios/README.md.

for KEY in CFBundleShortVersionString CFBundleVersion; do
  APP_VALUE=$(plist_value "$APP_PLIST" "$KEY")
  APPEX_VALUE=$(plist_value "$APPEX_PLIST" "$KEY")
  if [ -z "$APP_VALUE" ]; then
    echo "Runner.app has no $KEY." >&2
    exit 1
  fi
  if [ "$APP_VALUE" != "$APPEX_VALUE" ]; then
    echo "$KEY differs: Runner.app '$APP_VALUE', ShareExtension.appex '$APPEX_VALUE'." >&2
    echo "Delete any $KEY-related setting on the ShareExtension target; do not override it." >&2
    exit 1
  fi
  echo "$KEY = $APP_VALUE (app and extension agree)"
done

exit 0
