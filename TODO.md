# TODO

## Mobile app distribution (deploy workflow)

The `distribute-android` and `distribute-ios` jobs in
`.github/workflows/deploy.yaml` are a **draft**. They lay out the shape of the
pipeline but cannot produce/distribute a real build yet. Outstanding work:

### Shared

- [ ] **App config from secrets.** Both jobs currently `cp .env.example .env`.
      The example only holds a placeholder API base URL. Generate the real
      `.env` (or `--dart-define`s) from a secret so distributed builds point at
      the production API.
- [ ] **Build numbers / versioning.** `pubspec.yaml` is pinned at `0.0.1+1`.
      TestFlight (and Firebase) reject duplicate build numbers, so the build
      number must be bumped per run (e.g. derive from `github.run_number` via
      `--build-number`). Decide on a versioning strategy.
- [ ] **Trigger strategy.** The jobs run on every push to `main` alongside the
      docs deploy. Consider gating on tags/releases or path filters
      (`client/**`) and/or `workflow_dispatch` so every merge doesn't ship a
      tester build.
- [ ] **De-duplicate Flutter setup.** The SDK install + pub cache steps are
      copied from `client_health.yaml`. Extract a composite action and reuse it
      across all three workflows.
- [ ] Decide whether build artifacts (APK/IPA) should also be uploaded as
      workflow artifacts for debugging.

### Android (Firebase App Distribution)

- [ ] **Release signing.** `client/android/app/build.gradle.kts` signs the
      release build with the **debug** keys (see the TODO in that file). Create
      an upload keystore, store it + credentials as secrets, restore it in the
      job, and wire up a real `signingConfig`.
- [ ] **Firebase project + app.** Register the Android app
      (`dev.norelease.paperdoll`) in a Firebase project and grab its App ID.
- [ ] **Secrets to add:**
  - `FIREBASE_ANDROID_APP_ID` — Firebase Android App ID (`1:...:android:...`).
  - `FIREBASE_SERVICE_ACCOUNT` — JSON contents of a service account with the
    Firebase App Distribution Admin role.
- [ ] **Tester groups.** The job distributes to a `testers` group; create that
      group in the Firebase console (or change the name).
- [ ] Decide APK vs AAB. The draft builds an APK because Firebase App
      Distribution handles APKs directly; an AAB needs extra handling.

### iOS (TestFlight)

- [ ] **Code signing.** Import the Apple distribution certificate and an App
      Store provisioning profile from secrets (e.g.
      `apple-actions/import-codesign-certs`).
- [ ] **ExportOptions.plist.** Add `client/ios/ExportOptions.plist` configured
      for `app-store` distribution (method, team ID, signing style, bundle ID
      `dev.norelease.paperdoll`). The draft references it but it does not exist
      yet.
- [ ] **App Store Connect app record.** Create the app in App Store Connect for
      bundle id `dev.norelease.paperdoll`.
- [ ] **Secrets to add (App Store Connect API key):**
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_KEY_ID`
  - `APP_STORE_CONNECT_PRIVATE_KEY` — contents of the `.p8` key.
- [ ] **Runner cost.** `macos-latest` runners are billed at a higher rate;
      confirm this is acceptable / consider self-hosted.
- [ ] Verify the pinned action versions
      (`apple-actions/upload-testflight-build`,
      `wzieba/Firebase-Distribution-Github-Action`) and pin to commit SHAs if
      stricter supply-chain hygiene is desired.
