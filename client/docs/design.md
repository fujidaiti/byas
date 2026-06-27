# Paperdoll Mobile Client — Design Document

> Status: Draft · Scope: high-level design (screens & architecture), **not**
> implementation details.

> **Early stage.** The backend is incomplete and rough; this client is
> deliberately minimal. We optimize for a working, simple, testable app — not a
> polished one. Cosmetic quality (theming, accessibility) is intentionally
> deferred.

## Context

Paperdoll is an RSS reading service built around a **daily newspaper** metaphor.
On the server side, a worker continuously polls subscribed RSS feeds and stores
their items as **entries**. On a configured editorial schedule, the server
assembles a daily **newspaper** composed of **stories** — curated entries
selected to be read that day. The mobile client is the reader-facing surface for
this service.

The backend already exposes a small REST API (see `/api/api.yaml`). This
document describes how the Flutter mobile app is organized on top of it.

### Domain vocabulary

| Term               | Meaning                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| **Feed**           | A subscribed RSS source (`id`, `url`, `title`, optional `site_url`, `icon_url`, `description`). |
| **Feed candidate** | A feed discovered via search that has no local `id` yet and can be subscribed to.               |
| **Entry**          | A single item fetched from a feed (`title`, `url`, `description`, full `content`, timestamps).  |
| **Story**          | A curated entry chosen to appear in a newspaper issue. Backed 1:1 by an entry.                  |
| **Newspaper**      | A dated issue (`published_at`) bundling the stories for that day.                               |

## Goals & Non-goals

**Goals**

- Let a reader open the app and immediately read **today's newspaper**.
- Let a reader read the full content of any story or feed entry comfortably.
- Let a reader manage subscriptions: browse subscribed feeds, search/discover
  new feeds, subscribe, and browse a feed's full timeline.
- Establish a clean, testable architecture that maps directly to the existing
  API and is ready to grow (pagination, auth, offline) without rework.

**Non-goals (this iteration)**

- Authentication / multi-user accounts (the API is currently single-tenant).
- Offline-first sync, push notifications, and unsubscribe (no API support yet).
- Tablet/desktop-optimized layouts; the target is phones.

## Product surface: screens

The app has two top-level destinations exposed via bottom navigation — **Today**
(the newspaper) and **Feeds** (subscriptions) — plus detail and discovery
screens reached by navigation.

```
Bottom navigation
├── Today  (Newspaper)
│   └── Story Reader
└── Feeds  (Subscriptions)
    ├── Feed Search / Subscribe
    └── Feed Detail (Timeline)
        └── Entry Reader
```

### 1. Today (Newspaper) — home

- **Purpose:** Show the latest issue: its publication date and the list of
  stories.
- **Source:** `GET /newspapers/today`.
- **Content:** Issue header (formatted `published_at`), then a scrollable list
  of story cards (title, description snippet, published date).
- **Actions:** Tap a story → Story Reader. Pull-to-refresh.
- **States:** loading, loaded, empty (no issue yet), error (with retry).

### 2. Story Reader

- **Purpose:** Read the full article behind a story.
- **Source:** `GET /newspapers/stories/{id}` (returns the backing feed entry,
  including `content`).
- **Content:** Title, source/published metadata, the article `content` rendered
  as HTML in a `webview_flutter` view (see note below), and a link to open the
  original article (`url`) externally.
- **States:** loading, loaded, not-found, error.

### 3. Feeds (Subscriptions) — home

- **Purpose:** List the feeds the reader is subscribed to.
- **Source:** `GET /feeds`.
- **Content:** Feed rows (icon, title, description). Entry point to feed search.
- **Actions:** Tap a feed → Feed Detail. Tap "add" → Feed Search.
  Pull-to-refresh.
- **States:** loading, loaded, empty (encourage adding a feed), error.

### 4. Feed Search / Subscribe (discovery)

- **Purpose:** Find a feed by URL and subscribe to it.
- **Source:** `GET /feeds/search?q=...` to preview candidates; `PUT /feeds` to
  subscribe.
- **Content:** Search field, list of feed candidates with a subscribe action.
- **Behavior:** Subscribing is idempotent on the server. On success, return to
  the Feeds list (now including the new feed).
- **States:** idle, searching, results, no-results, subscribing, error.

### 5. Feed Detail (Timeline)

- **Purpose:** Show a single feed's metadata and its full stream of entries
  (independent of the daily newspaper curation).
- **Source:** `GET /feeds/{id}` for the header, `GET /feeds/{id}/timeline` for
  entries.
- **Content:** Feed header (icon, title, description, site link), then entry
  rows (title, snippet, published date).
- **Actions:** Tap an entry → Entry Reader.
- **States:** loading, loaded, empty, error.

### 6. Entry Reader

- **Purpose:** Read the full content of an arbitrary feed entry.
- **Source:** `GET /feed-entries/{id}`.
- **Content:** Same reading layout as the Story Reader (shared component).

> The Story Reader and Entry Reader render the same `FeedEntry` shape and share
> one reusable reader component; only their data source differs. The HTML
> `content` is rendered with `webview_flutter`.

## Architecture

### Stack

- **Flutter** with **built-in widgets** (`flutter/material`, `flutter/widgets`)
  as the default. The only third-party UI widget is **`webview_flutter`**, used
  to render HTML entry/story `content`.
- **Riverpod** for dependency injection and state management (`*.riverpod.dart`
  codegen is already excluded from analysis).
- **freezed + json_serializable / json_annotation** for immutable models and
  JSON (`*.freezed.dart` / `*.g.dart` excluded).
- **`dio`** for networking, wrapped behind the data layer.
- **go_router** for declarative navigation matching the screen tree above.
- **`package:logging`** for diagnostics (kept quiet — see below).
- **`package:url_launcher`** to open original article links externally.
- Tests: **`integration_test`** driving the app against a **mock server**, with
  **`mockito`** where mocking is needed.

> Non-widget packages (state, networking, routing, codegen, logging) are
> allowed. For UI widgets we use Flutter built-ins; `webview_flutter` is the one
> deliberate exception, to render HTML `content`.

### Styling: constants, not magic values

There is no theme. Instead, all visual values — colors, text styles, gap sizes,
corner radii, etc. — are defined as `static const` design tokens in `core`, and
reused via small **pre-styled widgets** where it reduces repetition (e.g. a
`BodyText` that wraps `Text` with the body text style, a `Gap` for spacing).
Widgets must not embed literal style values inline. This keeps the UI consistent
and trivial to restyle later without a full theming system.

### Layered structure

The app uses a feature-first layout with a conventional layered architecture.
Dependencies point inward: presentation → application → domain ← data.

```
lib/
├── core/                  # cross-cutting: http client, config, error types,
│                          #   logging, routing, design tokens (static const),
│                          #   pre-styled widgets (BodyText, Gap, …)
├── features/
│   ├── newspaper/         # Today + Story Reader
│   │   ├── data/          # repository + API mapping for newspapers/stories
│   │   ├── domain/        # Newspaper, Story models
│   │   └── presentation/  # screens, widgets, Riverpod providers
│   ├── feed/              # Feeds, Feed Detail, Search/Subscribe
│   │   ├── data/
│   │   ├── domain/        # Feed, FeedCandidate models
│   │   └── presentation/
│   └── entry/             # Entry Reader (+ shared FeedEntry model)
│       ├── data/
│       ├── domain/        # FeedEntry model
│       └── presentation/
└── main.dart
```

#### Layer responsibilities

- **Domain** — Plain immutable models (`Feed`, `FeedCandidate`, `FeedEntry`,
  `Story`, `Newspaper`) and the abstract repository contracts. No Flutter or
  HTTP dependencies. This is the stable core the rest of the app depends on.
- **Data** — Concrete repositories that call the REST API, deserialize JSON into
  domain models, and translate transport/HTTP failures into typed domain errors.
  The only layer aware of API URLs and JSON shapes.
- **Application / Presentation** — Riverpod providers expose async state
  (`AsyncValue`) for each screen; widgets render that state and dispatch user
  intents (refresh, search, subscribe) back to the providers. Screens stay free
  of networking and parsing logic.

### Data flow (read path)

```
Widget ──watch──▶ Provider ──calls──▶ Repository ──HTTP──▶ Paperdoll API
  ▲                  │                     │
  └── AsyncValue ◀───┘ ◀── domain model ◀──┘ (JSON → model, errors → DomainError)
```

1. A screen watches a provider and renders `loading / data / error` uniformly.
2. The provider asks a repository for domain models.
3. The repository performs the HTTP request, maps JSON to domain models, and
   maps failures to typed errors.
4. The provider surfaces the result as `AsyncValue`; the widget rebuilds.

### API ↔ screen mapping

| Screen                  | Endpoint(s)                                   |
| ----------------------- | --------------------------------------------- |
| Today (Newspaper)       | `GET /newspapers/today`                       |
| Story Reader            | `GET /newspapers/stories/{id}`                |
| Feeds                   | `GET /feeds`                                  |
| Feed Search / Subscribe | `GET /feeds/search?q=`, `PUT /feeds`          |
| Feed Detail (Timeline)  | `GET /feeds/{id}`, `GET /feeds/{id}/timeline` |
| Entry Reader            | `GET /feed-entries/{id}`                      |

### Cross-cutting concerns

- **Configuration:** Build params (e.g. API base URL) live in a `.env` file and
  are passed at build/run time via `--dart-define-from-file=.env`, read through
  a small config accessor in `core`. A committed `.env.example` documents the
  keys; `.env` itself is git-ignored.
- **Error handling:** Repositories normalize HTTP status codes into domain
  errors (not-found, bad-request, server, network); the API's
  `{ "message": ... }` body is surfaced where useful. The presentation layer
  chooses the error surface by context:
  - **Load failures / empty results** (a screen with no data to show) → an
    inline placeholder widget showing the message, with a retry action.
  - **User-interaction / event-driven errors** (e.g. a failed subscribe) → a
    transient **snackbar**, leaving existing content in place.
  - **Dialogs** are reserved as a last resort for rare blocking errors.
- **Content rendering:** Entry/story `content` is HTML, rendered with
  `webview_flutter`; original links open externally via `url_launcher`.
- **Logging:** A single configured `package:logging` logger in `core`. Logging
  is kept deliberately sparse (no per-request spam) so the console stays
  readable; verbose levels are opt-in.
- **Styling:** No theme — `static const` design tokens + pre-styled widgets (see
  "Styling" above).

### Testing

The primary safety net is **`integration_test`** suites that drive the real app
widget tree against a **mock server** (an in-process fake HTTP server returning
canned responses; the base URL points at it). Suites are organized around actual
**use cases / critical paths**, not exhaustive coverage:

- Open the app → read today's newspaper → open a story.
- Browse subscribed feeds → open a feed → read an entry.
- Search for a feed → subscribe → see it in the feeds list.

Error paths are intentionally **not** covered at this stage. Lightweight unit
tests may be added for pure logic (e.g. JSON deserialization) where cheap, but
they are not the focus.

## Future considerations

These shape the architecture today even though they are out of scope to build:

- **Pagination** for `GET /feeds` and `/feeds/{id}/timeline` (the server already
  flags these as `TODO`). Repository method signatures and list providers should
  be designed to accept cursors/pages without breaking callers.
- **Authentication** when the API becomes multi-tenant: an auth interceptor in
  the HTTP client and a session provider in `core`.
- **Offline reading / caching** of fetched newspapers and entries.
- **Subscription management** (unsubscribe, reordering) once the API supports
  it.
- **Polish pass** on theming / accessibility, once we move past the
  minimal-styling constraint.

```

```
