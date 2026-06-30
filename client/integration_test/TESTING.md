# Integration Test Guide

Tests live in `integration_test/` and run with
[Patrol](https://patrol.leancode.co/). HTTP calls are intercepted in-process
using [http_mock_adapter](https://pub.dev/packages/http_mock_adapter) — no
external mock server is required.

## File organisation

Each app feature has its own test file:

```
integration_test/
  helpers.dart        # shared pumpApp helper
  today_test.dart     # today / newspaper feature
  feeds_test.dart     # feeds feature
```

Add a new `<feature>_test.dart` file for each new feature. Do not group tests
from different features into a single file. Shared setup belongs in
`helpers.dart`.

## Running tests

```sh
make integration-test D=<device-id>
```

The test suite targets Android. List connected devices with
`fvm flutter devices`.

---

## How mocking works

Each test uses two helpers from `helpers.dart`:

- `pumpApp($)` — starts the app inside a `ProviderScope` with a dummy base URL.
- `httpMockAdapter($)` — reads the live `Dio` from the Riverpod container and
  returns a `DioAdapter` configured with `FullHttpRequestMatcher`. All
  subsequent HTTP calls go through the adapter instead of the network.

Both must be called before the first Patrol action that triggers an HTTP
request:

```dart
patrolTest('...', ($) async {
  await pumpApp($);
  final adapter = httpMockAdapter($);

  adapter.onGet('/some/path', (server) => server.reply(200, responseBody));

  // Test actions follow.
  await $(AppTestKeys.someScreen).waitUntilVisible();
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

`FullHttpRequestMatcher` matches the handler's `data` against the serialized
request body. Always pass the exact expected body when the shape is known — this
turns the mock registration into an implicit assertion that the app sends the
right payload:

```dart
adapter.onPut(
  '/feeds',
  (server) => server.reply(200, feed.toJson()),
  data: {'url': 'https://dart.dev/blog/feed.xml'},
);
```

Only fall back to `Matchers.any` when the body is genuinely variable or
irrelevant to the scenario being tested. Avoid it for `onPost` and `onPatch`
handlers — those mutations are exactly where body correctness matters most.

---

## Test key conventions

Keys are defined in `lib/test_keys.dart` and shared between app code and tests.

### Static keys

Assign a fixed `const Key` to:

- Navigation controls (nav bar destinations, buttons, text fields)
- Destination screens (the `Scaffold` of each screen navigated to)
- Feedback widgets (snackbars)

### Parameterized keys

Assign a parameterized key to dynamically-generated list items. The key value
format is `<widget identifier>:<display text>`, e.g.:

```
feed:Anthropic Engineering Blog   → AppTestKeys.feedRow('Anthropic Engineering Blog')
entry:Effective harnesses…        → AppTestKeys.entryRow('Effective harnesses…')
story:Demystifying evals…         → AppTestKeys.storyCard('Demystifying evals…')
readerTitle:Demystifying evals…   → AppTestKeys.readerTitle('Demystifying evals…')
```

Parameterized keys make the widget identifier unambiguous even when the same
text appears on multiple screens. The key is assigned at the call site in the
list builder:

```dart
return FeedRow(
  key: AppTestKeys.feedRow(feed.title),
  feed: feed,
  onTap: ...,
);
```

---

## Writing assertions

### Check the current screen before acting

Before the first tap on any screen, assert that the expected screen is visible.
For the initial screen after `pumpApp` (no animation, synchronous), use a plain
`expect`:

```dart
await pumpApp($);
expect($(AppTestKeys.todayScreen), findsOneWidget);
await $(AppTestKeys.storyCard('Story title')).tap();
```

After a navigation tap (animation in progress), use `waitUntilVisible`:

```dart
await $(AppTestKeys.feedsNavDestination).tap();
await $(AppTestKeys.feedsScreen).waitUntilVisible();
await $(AppTestKeys.feedRow('Anthropic Engineering Blog')).tap();
```

### Tap list items by parameterized key

Use the parameterized key factory to locate and tap list items. This
simultaneously verifies that the item with the correct title is present on the
current screen — it fails if no widget with that key exists:

```dart
// Good — parameterized key ties the locator to the specific widget and title
await $(AppTestKeys.feedRow('Anthropic Engineering Blog')).tap();

// Avoid — a text finder matches any widget on any screen with that string,
// which can cause false passes if the same text is present in the background
await $('Anthropic Engineering Blog').tap();
```

### Verify navigation with screen-level keys

After a tap that navigates to a new screen, assert on the destination screen's
key before making content assertions:

```dart
// In entry_reader_screen.dart
return Scaffold(
  key: AppTestKeys.entryReaderScreen,
  ...
);

// In the test
await $(AppTestKeys.entryRow('Entry title')).tap();
await $(AppTestKeys.entryReaderScreen).waitUntilVisible(); // navigation confirmed
await $(AppTestKeys.readerTitle('Entry title')).waitUntilVisible(); // content loaded
```

### The full pattern for each navigation step

```dart
// 1. Assert current screen is visible (expect for sync, waitUntilVisible after animation)
expect($(AppTestKeys.sourceScreen), findsOneWidget);

// 2. Tap by parameterized key (locates the widget and verifies its title)
await $(AppTestKeys.feedRow('Label on source screen')).tap();

// 3. Assert the destination screen is present (navigation confirmed)
await $(AppTestKeys.destinationScreen).waitUntilVisible();

// 4. Assert the correct entity loaded
await $(AppTestKeys.readerTitle('Expected content on destination')).waitUntilVisible();
```
