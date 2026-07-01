# Integration Test

Tests live in `integration_test/` and run with
[Patrol](https://patrol.leancode.co/). HTTP calls are intercepted in-process, so
no external mock server is required.

## File organisation

Each app feature has its own test file:

```
integration_test/
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

## How mocking works

Each test uses two helpers from `helpers.dart`:

- `pumpApp($)` — starts the app inside a `ProviderScope` with a dummy base URL.
- `httpMockAdapter($)` — creates a `DioAdapter` which all subsequent HTTP calls
  go through instead of the network.

Both must be called before the first Patrol action that triggers an HTTP
request. A typlical test suit would look something like this:

```dart
patrolTest('...', ($) async {
  await pumpApp($);
  final adapter = httpMockAdapter($);

  adapter.onGet('/some/path', (server) => server.reply(200, responseBody));

  // Test actions follow.
  await $(AppDebugKey.someScreen).waitUntilVisible();
  // ...
});
```

### Building response bodies

Use the auto-generated `api.*` model constructors (from `package:openapi`) for
type safety:

```dart
final feed = api.Feed(id: 1, url: '...', title: 'Anthropic Engineering Blog');
```

Prefer using generated models over raw Map objects for each response as well:

```dart
// Good
adapter.onGet('/newspapers/stories/1',
  (server) => server.reply(
    200,
    api.GetStory200Response(
      type: api.GetStory200ResponseTypeEnum.entry,
      data: storyEntry,
    ).toJson(),
  ),
);

// Equivalent to above, but do not abuse this pattern
adapter.onGet('/newspapers/stories/1',
  (server) => server.reply(
    200,
    {
      'type': 'entry',
      'data': storyEntry.toJson(),
    },
  ),
);
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

### Matching PUT / POST / PATCH with a body

Always pass the exact expected body to the handler's `data` when the shape is
known — this turns the mock registration into an implicit assertion that the app
sends the right payload:

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

## Naming tests

Name each `patrolTest` after the **use case** it covers, not the sequence of
operations performed. A use case name answers "what can the user accomplish?" —
an operation name answers "what does the test click through?":

```dart
// Good — describes the user goal
patrolTest('Check feeds and read a feed entry', ($) async { ... });
patrolTest('Subscribe to a known web feed', ($) async { ... });

// Avoid — describes button-click sequence, not the goal
patrolTest('Open a story', ($) async { ... });
patrolTest('Tap feed and scroll to entry', ($) async { ... });
```

Use sentence case (capital first word only). Keep names short enough to read at
a glance in test output — one phrase, no punctuation.

## Test key conventions

Keys are defined in `lib/debug_keys.dart` and shared between app code and tests.

### Static keys

Assign a fixed `const Key` to:

- Navigation controls (nav bar destinations, buttons, text fields)
- Destination screens (the `Scaffold` of each screen navigated to)
- Feedback widgets (snackbars)

### Parameterized keys

Assign a parameterized key to dynamically-generated list items. The key value
format is `<widget identifier>:<display text>`, e.g.:

```
feed:Anthropic Engineering Blog   → AppDebugKey.feedRow('Anthropic Engineering Blog')
entry:Effective harnesses…        → AppDebugKey.entryRow('Effective harnesses…')
story:Demystifying evals…         → AppDebugKey.storyCard('Demystifying evals…')
readerTitle:Demystifying evals…   → AppDebugKey.readerTitle('Demystifying evals…')
```

Parameterized keys make the widget identifier unambiguous even when the same
text appears on multiple screens. The key is assigned at the call site in the
list builder:

```dart
return FeedRow(
  key: AppDebugKey.feedRow(feed.title),
  feed: feed,
  onTap: ...,
);
```

## Writing assertions

### Check the current screen before acting

Before the first tap on any screen, assert that the expected screen is visible.
For the initial screen after `pumpApp` (no animation, synchronous), use a plain
`expect`:

```dart
await pumpApp($);
expect($(AppDebugKey.todayScreen), findsOneWidget);
await $(AppDebugKey.storyCard('Story title')).tap();
```

After a navigation tap (animation in progress), use `waitUntilVisible`:

```dart
await $(AppDebugKey.feedsNavDestination).tap();
await $(AppDebugKey.feedsScreen).waitUntilVisible();
await $(AppDebugKey.feedRow('Anthropic Engineering Blog')).tap();
```

### Tap list items by parameterized key

Use the parameterized key factory to locate and tap list items. This
simultaneously verifies that the item with the correct title is present on the
current screen — it fails if no widget with that key exists:

```dart
// Good — parameterized key ties the locator to the specific widget and title
await $(AppDebugKey.feedRow('Anthropic Engineering Blog')).tap();

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
  key: AppDebugKey.entryReaderScreen,
  ...
);

// In the test
await $(AppDebugKey.entryRow('Entry title')).tap();
await $(AppDebugKey.entryReaderScreen).waitUntilVisible(); // navigation confirmed
await $(AppDebugKey.readerTitle('Entry title')).waitUntilVisible(); // content loaded
```

### The full pattern for each navigation step

```dart
// 1. Assert current screen is visible (expect for sync, waitUntilVisible after animation)
expect($(AppDebugKey.sourceScreen), findsOneWidget);

// 2. Tap by parameterized key (locates the widget and verifies its title)
await $(AppDebugKey.feedRow('Label on source screen')).tap();

// 3. Assert the destination screen is present (navigation confirmed)
await $(AppDebugKey.destinationScreen).waitUntilVisible();

// 4. Assert the correct entity loaded
await $(AppDebugKey.readerTitle('Expected content on destination')).waitUntilVisible();
```
