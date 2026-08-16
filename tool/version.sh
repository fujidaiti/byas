#!/usr/bin/env bash
#
# Maintains and validates the version file of a build target.
#
# Each target keeps its own version file within its codebase,
# e.g., client/android/version.json:
#
#   {
#     "versionName": "1.20260813.123059.beta",
#     "buildNumber": 1
#   }
#
# versionName follows <major>.<yyyymmdd>.<HHMMSS> (UTC), optionally suffixed
# with .beta. The .beta suffix marks a stg release; without it, the version is
# treated as prod. buildNumber must increase by exactly 1 each time.
#
# Usage: tool/version.sh <command> [args...]
#
#   bump <version.json> [--beta]
#         Bumps the version name and build number in the given version file.
#         If the file doesn't exist yet, it's created with buildNumber 1.
#         --beta marks the release as a beta by suffixing the version name with
#         .beta; without it, an unsuffixed (prod-channel) version is produced
#         instead. Either way, the timestamped part of the version name is
#         regenerated from the current time.
#
#   comp <old-version.json> <new-version.json>
#         Exits normally if the two files hold the same version, or if the new
#         one is a valid bump of the old one: both well-formed, the new build
#         number exactly one higher, and the new version name strictly newer.
#         Otherwise prints what's wrong and exits 1. A missing old file means
#         there is no previous version, in which case the new build number must
#         be 1.
#
#   vet <version.json>
#         Exits normally if the file has a valid format and values.
#         Otherwise prints what's wrong and exits 1.
#
# See DEPLOY.md for the overview of the entire deployment pipeline.

set -euo pipefail

readonly MAJOR_VERSION=0
# <major>.<yyyymmdd>.<HHMMSS>[.beta], captured for comparison in comp.
readonly VERSION_NAME_RE='^([0-9]+)\.([0-9]{8})\.([0-9]{6})(\.beta)?$'

usage() {
  {
    echo "Usage: tool/version.sh bump <version.json> [--beta]"
    echo "       tool/version.sh comp <old-version.json> <new-version.json>"
    echo "       tool/version.sh vet <version.json>"
  } >&2
  exit 1
}

# Prints "<major> <yyyymmddHHMMSS> <buildNumber> <versionName>" for a
# well-formed version file, or explains what's wrong with it and exits 1.
parse() {
  local path="$1" version_name build_number
  [[ -f "$path" ]] || { echo "$path does not exist." >&2; exit 1; }
  jq -e . "$path" > /dev/null 2>&1 || { echo "$path is not valid JSON." >&2; exit 1; }
  # `strings` / `numbers` drop values of the wrong JSON type, so a quoted
  # buildNumber fails the check below rather than sneaking through.
  version_name=$(jq -r '.versionName | strings' "$path")
  build_number=$(jq -r '.buildNumber | numbers' "$path")
  if ! [[ "$version_name" =~ $VERSION_NAME_RE ]]; then
    echo "$path: versionName '$version_name' is not a string matching <major>.<yyyymmdd>.<HHMMSS>[.beta]." >&2
    exit 1
  fi
  local major="${BASH_REMATCH[1]}" date="${BASH_REMATCH[2]}" time="${BASH_REMATCH[3]}"
  if ! [[ "$build_number" =~ ^[0-9]+$ ]]; then
    echo "$path: buildNumber '$build_number' is not a non-negative integer." >&2
    exit 1
  fi
  echo "$major $date$time $build_number $version_name"
}

cmd_bump() {
  local path="" beta=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --beta)
        beta=true
        shift
        ;;
      -*)
        usage
        ;;
      *)
        [[ -z "$path" ]] || usage
        path="$1"
        shift
        ;;
    esac
  done
  [[ -n "$path" ]] || usage

  local current
  if [[ -f "$path" ]]; then
    current="$(cat "$path")"
  else
    current="{}"
  fi
  local current_build_number
  current_build_number=$(jq -r '.buildNumber // 0' <<< "$current")

  local new_build_number=$((current_build_number + 1))
  local new_version_name="$MAJOR_VERSION.$(date -u +%Y%m%d.%H%M%S)"
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
}

cmd_comp() {
  [[ $# -eq 2 ]] || usage
  local old_path="$1" new_path="$2"

  local new_parsed new_major new_stamp new_build new_name
  new_parsed=$(parse "$new_path")
  read -r new_major new_stamp new_build new_name <<< "$new_parsed"

  if [[ ! -f "$old_path" ]]; then
    if [[ "$new_build" -ne 1 ]]; then
      echo "$new_path: buildNumber $new_build must be 1 when there is no previous version ($old_path does not exist)." >&2
      exit 1
    fi
    echo "No previous version; $new_path is a valid initial version."
    return
  fi

  local old_parsed old_major old_stamp old_build old_name
  old_parsed=$(parse "$old_path")
  read -r old_major old_stamp old_build old_name <<< "$old_parsed"

  if [[ "$new_name" == "$old_name" && "$new_build" -eq "$old_build" ]]; then
    echo "$old_path and $new_path hold the same version; nothing to compare."
    return
  fi

  if [[ "$new_build" -ne $((old_build + 1)) ]]; then
    echo "$new_path: buildNumber $new_build is not $old_path's $old_build + 1." >&2
    exit 1
  fi

  # The .beta suffix is intentionally not part of the ordering: a release can
  # move between the stg and prod channels in either direction.
  if [[ "$new_major" -lt "$old_major" ]] ||
    { [[ "$new_major" -eq "$old_major" ]] && [[ "$new_stamp" -le "$old_stamp" ]]; }; then
    echo "$new_path: versionName is not newer than $old_path's." >&2
    exit 1
  fi

  echo "$new_path is a valid bump of $old_path."
}

cmd_vet() {
  [[ $# -eq 1 ]] || usage
  local path="$1"
  parse "$path" > /dev/null
}

case "${1:-}" in
  bump)
    shift
    cmd_bump "$@"
    ;;
  comp)
    shift
    cmd_comp "$@"
    ;;
  vet)
    shift
    cmd_vet "$@"
    ;;
  *)
    usage
    ;;
esac
