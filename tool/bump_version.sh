#!/usr/bin/env bash
# Bumps android.versionName/buildNumber in versions.json for a stg release.
# Run this locally, review the diff, then commit and open a PR.
set -euo pipefail

cd "$(dirname "$0")/.."

# Edit this to change the major version (see release-ci-design doc §4.1).
MAJOR=1

versions_file=versions.json

current_build_number=$(jq -r '.android.buildNumber' "$versions_file")
new_build_number=$((current_build_number + 1))

date_part=$(date -u +%Y%m%d)
time_part=$(date -u +%H%M)
new_version_name="${MAJOR}.${date_part}.${time_part}.beta1"

tmp_file=$(mktemp)
jq \
  --arg versionName "$new_version_name" \
  --argjson buildNumber "$new_build_number" \
  '.android.versionName = $versionName | .android.buildNumber = $buildNumber' \
  "$versions_file" > "$tmp_file"
mv "$tmp_file" "$versions_file"

echo "Bumped android version:"
echo "  versionName = $new_version_name"
echo "  buildNumber = $new_build_number"
echo
echo "Next steps:"
echo "  git add versions.json"
echo "  git commit -m 'Bump android stg version to $new_version_name'"
echo "  # open a PR and merge; the Version Tagging workflow will create the tag"
