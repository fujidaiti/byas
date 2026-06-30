# Integration Test Guide

Tests live in `integration_test/app_test.dart` and run with
[Patrol](https://patrol.leancode.co/). HTTP calls are intercepted in-process
using [http_mock_adapter](https://pub.dev/packages/http_mock_adapter) — no
external mock server is required.

## Running tests

```sh
make integration-test D=<device-id>
```

The test suite targets Android. List connected devices with
`fvm flutter devices`.

---

## How mocking works

Each test calls `_pumpApp($)` to start the app, then immediately reads the live
`Dio` instance from the Riverpod container and attaches a `DioAdapter` to it.
All subsequent HTTP calls go through the adapter instead of the network.

```dart
patrolTest('...', ($) async {
  await _pumpApp($);

  // Must happen before the first Patrol action that triggers an HTTP call.
  final dio = $.tester.container().read(dioProvider);
  final adapter = DioAdapter(dio: dio, matcher: const FullHttpRequestMatcher());

  adapter.onGet('/some/path', (server) => server.reply(200, responseBody));

  // Test actions follow.
  await $('Some text').tap();
  // ...
});
```

### Building response bodies

Use the auto-generated `api.*` model constructors (from `package:openapi`) for
type safety. `server.reply()` passes the data through `jsonEncode`, which
recursively calls `.toJson()` on nested objects — so wrapper types work
correctly even though their own `toJson()` stores nested model instances rather
than pre-serialized Maps:

```dart
final feed = api.Feed(id: 1, url: '...', title: 'Anthropic Engineering Blog');

// Wrapper model — pass directly to .toJson(); jsonEncode handles the nested Feed objects
adapter.onGet('/feeds', (server) => server.reply(200,
  api.GetFeeds200Response(feeds: [feed]).toJson(),
));

adapter.onGet('/newspapers/stories/1', (server) => server.reply(200,
  api.GetStory200Response(
    type: api.GetStory200ResponseTypeEnum.entry,
    data: storyEntry,
  ).toJson(),
));
```

### Multiple replies for the same route

Each `adapter.onGet()` call enqueues one reply. Register the same path twice to
return different responses on successive calls:

```dart
// First GET /feeds → empty list (initial screen load)
adapter.onGet('/feeds', (server) => server.reply(200, api.GetFeeds200Response().toJson()));
// Second GET /feeds → list with the new feed (after invalidation + re-fetch)
adapter.onGet('/feeds', (server) => server.reply(200, api.GetFeeds200Response(feeds: [feed]).toJson()));
```

### Matching PUT / POST with a body

`FullHttpRequestMatcher` requires the handler's `data` to match the request
body. When you don't need to verify the body content, use `Matchers.any`:

```dart
adapter.onPut(
  '/feeds',
  (server) => server.reply(200, feed.toJson()),
  data: Matchers.any,
);
```

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
