# Integration Test Guide

Tests live in `integration_test/app_test.dart` and run with
[Patrol](https://patrol.leancode.co/) against a
[Prism](https://stoplight.io/open-source/prism) mock server serving
`api/api.yaml`.

## Running tests

Start Prism first, then run Patrol:

```sh
prism mock api/api.yaml --port 4010
patrol test --flutter-command "fvm flutter" --device <device-id>
```

The test suite targets Android. The emulator reaches the host machine via
`10.0.2.2`, not `127.0.0.1`.

---

## Test key conventions

Keys are defined in `lib/test_keys.dart` and shared between app code and tests.

**Assign keys only to:**

- Navigation controls (nav bar destinations, buttons, text fields)
- Destination screens (the `Scaffold` of each screen navigated to)
- Feedback widgets (snackbars)

**Do not assign keys to dynamically-generated list items.** If a list item is
uniquely identified by its visible label, tap it by text instead (see below).

---

## Writing assertions

### Tap list items by visible text

When a list item is uniquely identified by its label, use `$('Label').tap()`.
This is simultaneously the locator and the content check — it fails if the text
is not on screen at all, with no key required.

```dart
// Good — one line does both jobs
await $('Anthropic Engineering Blog').tap();

// Avoid — text check and key tap are unrelated; if feedRow(1) renders
// the wrong title, the text check still passes (text may exist elsewhere)
await $('Anthropic Engineering Blog').waitUntilVisible();
await $(AppTestKeys.feedRow(1)).tap();
```

### Verify navigation with screen-level keys

After a tap that navigates to a new screen, do **not** check for text that also
appeared on the source screen. Text from the previous screen can still be
visible in the widget tree and will cause a false pass even if navigation never
happened.

Instead, attach a `Key` to each destination screen's `Scaffold` and assert on
it:

```dart
// In entry_reader_screen.dart
return Scaffold(
  key: AppTestKeys.entryReaderScreen,
  ...
);

// In the test
await $('Entry title').tap();
await $(AppTestKeys.entryReaderScreen).waitUntilVisible(); // unambiguous
await $('Expected content').waitUntilVisible();
```

### The full pattern for each navigation step

```dart
// 1. Tap by visible text (locates + verifies source content)
await $('Label on source screen').tap();

// 2. Assert the destination screen is present
await $(AppTestKeys.destinationScreen).waitUntilVisible();

// 3. Assert the correct entity loaded
await $('Expected content on destination').waitUntilVisible();
```

---

## Mock server caveats

Prism returns the single example defined for each endpoint, regardless of the
requested ID. If an endpoint has only one example, every ID resolves to the same
response. Always cross-check assertion strings against the example in the
relevant `api/paths/*.yaml` file, not against what a list endpoint happens to
return for the same entity.
