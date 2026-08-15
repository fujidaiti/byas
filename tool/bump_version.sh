#!/usr/bin/env bash
#
# Bumps the version name and build number in the given version file for a
# release.
#
# Each platform keeps its own version file next to its build files, e.g.
# client/android/version.json:
#
#   {
#     "versionName": "1.20260813.123059.beta",
#     "buildNumber": 1
#   }
#
# versionName follows <major>.<yyyymmdd>.<HHMMSS>[.beta] (UTC). The .beta
# suffix marks a stg release; without it, the version is treated as prod.
# buildNumber must increase by exactly 1 each time. The Version Tagging
# workflow validates both rules; this script itself doesn't.
#
# Usage: tool/bump_version.sh -f <version.json> [--beta]
#
# -f      Path to the version file to bump. If it doesn't exist yet, it's
#         created with buildNumber 1.
# --beta  Marks the release as a beta by suffixing the version name with
#         .beta. Without this flag, an unsuffixed (prod-channel) version is
#         produced instead. Either way, the timestamped part of the version
#         name is regenerated from the current time.

set -euo pipefail

readonly MAJOR_VERSION=0

usage() {
  echo "Usage: tool/bump_version.sh -f <version.json> [--beta]" >&2
  exit 1
}

path=""
beta=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f)
      [[ $# -ge 2 ]] || usage
      path="$2"
      shift 2
      ;;
    --beta)
      beta=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done
[[ -n "$path" ]] || usage

if [[ -f "$path" ]]; then
  current="$(cat "$path")"
else
  current="{}"
fi
current_build_number=$(jq -r '.buildNumber // 0' <<< "$current")

new_build_number=$((current_build_number + 1))
new_version_name="$MAJOR_VERSION.$(date -u +%Y%m%d.%H%M%S)"
if [[ "$beta" == true ]]; then
  new_version_name="$new_version_name.beta"
fi

jq \
  --arg versionName "$new_version_name" \
  --argjson buildNumber "$new_build_number" \
  '.versionName = $versionName | .buildNumber = $buildNumber' \
  <<< "$current" > "$path"

echo "Bumped $path:"
echo "  version = $new_version_name"
echo "  build = $new_build_number"
