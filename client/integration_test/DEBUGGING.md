# Debugging Integration Tests

How to diagnose a failing Patrol test in this project. Read alongside
[`README.md`](./README.md) (setup and conventions); this file is about what to
do when a test fails in a way that isn't obvious.

## Get the real state before theorizing

A finder that reports `Found 0 widgets` has several distinct causes — the widget
was never built, it was built and already removed, or the screen is in a
different state than you assumed. Don't reason about which one it is; measure
it.

- **App `print`s are swallowed** by Patrol's stdout. Don't rely on them (chasing
  them through `adb logcat` is flaky). Put the facts into the failure instead:

  ```dart
  // Counts travel with the failure because Patrol prints the failing expect.
  expect(
    find.byIcon(Icons.bookmark),
    findsOneWidget,
    reason: 'border=${find.byIcon(Icons.bookmark_border).evaluate().length} '
        'snackbars=${find.byType(SnackBar).evaluate().length}',
  );
  ```

  `finder.evaluate().length` gives you an exact count inline, with no device
  logs.

- **Assert persistent state, not just transient state.** An icon that stays
  filled tells you "the action happened"; a snackbar that auto-dismisses only
  tells you "the action happened _and_ I looked at the right frame." Check the
  persistent signal first to separate the two questions.

## Reduce to the smallest repro

- Run a single file:
  `patrol test -t integration_test/<feature>_test.dart -d <device-id>` (export
  `PATROL_FLUTTER_COMMAND` the way the `Makefile` does).
- When the failure is tangled up with navigation or mocks, write a throwaway
  probe test that exercises only the suspect step, confirm the fact, then delete
  it. Example: to learn how many times a screen calls an endpoint, register
  successive replies with **distinct** bodies and assert which one ends up
  rendered.

## Timing: UI produced by async work needs an explicit pump

Patrol actions auto-`pumpAndSettle`, which is enough for synchronous navigation
(see README → "Do not wait after actions") but **not** for a widget shown from
an `await`-ing handler — that widget mounts a frame _after_ the action settles.

- After a tap that starts async work, `await $.pump()` before asserting the
  resulting widget:

  ```dart
  await $(AppDebugKey.someButton).tap();
  await $.pump(); // let the async handler's scheduled frame land
  expect(find.byKey(AppDebugKey.someSnackBar), findsOneWidget);
  ```

- `waitUntilVisible()` is not a reliable fallback for this case; prefer
  `await $.pump()` + a plain `expect`.
- Snackbars auto-dismiss (duration defaults to 4 s; `persist` defaults to
  `action != null`). Assert immediately after the pump — don't let real time
  pass first.

## Mocks: replies are a FIFO queue per route

Each `adapter.onGet('/path', …)` **enqueues one reply**; successive requests to
that path consume the queue in order (README → "Multiple replies for the same
route"). The failure mode is assuming **one screen load = one request** — it
isn't always. A screen can hit the same endpoint more than once during
navigation and silently drain a multi-reply queue, leaving the app on a reply
you didn't intend.

- Use **distinct successive replies for one path only when you control the
  second call** (e.g. an explicit invalidation + refetch after a mutation, as in
  the feeds "subscribe" test).
- Otherwise register a **single stable reply per path**, so every call — however
  many the screen makes — gets the same body.
- If you don't know how many times a path is hit, **verify it with a probe**
  (distinct bodies, assert which renders) rather than assuming.
- Body matching on `onPost`/`onPatch`/`onPut` doubles as an assertion. If a
  mutation "isn't happening," a body mismatch may be throwing inside the app —
  check the payload the app actually sends against the `data:` you registered.
