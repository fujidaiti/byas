# Deploying the Android app (staging)

Based on the tag-driven release design in the release-CI doc. Currently only the
Android **stg** path is implemented — Android prod and iOS aren't wired up yet.

## How to cut a stg release

```sh
./tool/bump_version.sh
git add versions.json
git commit -m "Bump android stg version to <versionName>"
# open a PR, get it reviewed, squash-merge to main
```

That's it — merging is the trigger. Everything past this point is automatic:

1. **Version Tagging** (`.github/workflows/version-tagging.yaml`) runs on the
   push to `main`, diffs `versions.json` against the previous commit, and
   validates it (`versionName` format, `buildNumber` == previous + 1). If
   `versionName` ends in `.betaN`, it creates a tag `android-stg-<versionName>`
   using the release bot's GitHub App token (a plain `GITHUB_TOKEN`-created tag
   wouldn't trigger the next workflow, so this has to go through the App).
2. **Android Staging Deploy** (`.github/workflows/android-stg-deploy.yaml`) runs
   on that tag push, builds a release APK, and uploads it to Firebase App
   Distribution's `Dev` group.

No manual `git tag` and no manual workflow dispatch — pushing/merging
`versions.json` is the only action a developer takes.

## `versions.json`

Root-level, one entry per platform (only `android` exists so far):

```json
{
  "android": {
    "versionName": "1.20260813.0000.beta1",
    "buildNumber": 1
  }
}
```

- `versionName` format: `<major>.<yyyymmdd>.<HHMM>[.betaN]` (UTC). The `.betaN`
  suffix marks a stg release; without it, the version would be treated as prod —
  but there's no prod deploy workflow yet, so a non-beta version only gets
  validated, not tagged or shipped.
- `buildNumber` must increase by exactly 1 each time; the tagging workflow
  rejects anything else.
- `tool/bump_version.sh` handles all of this for you: it hardcodes the major
  version (edit the script to bump it), computes the date/time part from the
  current UTC time, and always appends `.beta1` (it only produces stg versions
  right now).

## Where the version actually lands in the app

`versions.json` isn't read directly by Gradle. Right before building,
`android-stg-deploy.yaml` renders it into `client/android/version.properties`:

```properties
versionName=1.20260813.0000.beta1
versionCode=1
```

`client/android/app/build.gradle.kts` reads `versionCode`/`versionName` from
this file (not from `pubspec.yaml`). The copy committed to the repo is just a
placeholder (`0.0.0.dev` / `1`) for local/debug/profile builds — CI overwrites
it and never commits the result.

## The release build itself

Same build as `make dev`, just release mode instead of debug:

```sh
flutter build apk --release --dart-define-from-file=.env
```

Same `.env` requirement as local dev — `API_BASE_URL` is read from it both by
`--dart-define-from-file` (Dart side) and directly by Gradle
(`BuildConfig.API_BASE_URL`). In CI, `.env` is decoded from the base64
`CLIENT_ENV` secret rather than committed.

Signing works exactly like local dev (see the main README): CI writes
`android/signing.properties` from the `ANDROID_SIGNING_PROPERTIES` secret, then
decodes `ANDROID_KEYSTORE` (base64) to whatever relative `keystore.path` that
file specifies, under `android/app/`.

## GitHub configuration this depends on

**`staging` environment** (protected):

| Secret / variable                       | Purpose                                                                |
| --------------------------------------- | ---------------------------------------------------------------------- |
| `CLIENT_ENV`                            | Base64-encoded contents of a working `client/.env`                     |
| `ANDROID_SIGNING_PROPERTIES`            | Contents of `android/signing.properties`                               |
| `ANDROID_KEYSTORE`                      | Base64-encoded release keystore                                        |
| `FIREBASE_APP_DISTRIBUTION_CREDENTIALS` | Base64-encoded service account JSON (App Distribution Admin role only) |
| `FIREBASE_APP_ID`                       | Firebase App ID for `dev.norelease.paperdoll`                          |
| `FIREBASE_TESTER_GROUP` (variable)      | Tester group alias, currently `Dev`                                    |

**Repo/org level** (used by the tagging workflow, not `staging`-scoped):

| Secret / variable           | Purpose                                  |
| --------------------------- | ---------------------------------------- |
| `NORELEASE_BOT_APP_ID`      | The release bot's GitHub App ID          |
| `NORELEASE_BOT_PRIVATE_KEY` | The release bot's GitHub App private key |

The bot's installation needs `contents: write` on this repo to push tags.

## Defense in depth

`android-stg-deploy.yaml` refuses to deploy unless the tag's push actor is
`norelease-bot[bot]` — logged explicitly as a step (not a silent job-level skip)
so a misconfigured check fails loudly instead of looking like a no-op success.
There's no GitHub Ruleset yet restricting who can create `android-stg-*` tags or
push to `deploy/*` branches directly — this check is currently the only
enforcement, until Rulesets are configured.

## Known gaps

- **Android prod** and **iOS** (stg + prod) aren't implemented — only Android
  stg.
- No GitHub Ruleset restricts tag creation or `deploy/*` pushes yet.
- Failures aren't retried automatically; re-run the failed workflow.
