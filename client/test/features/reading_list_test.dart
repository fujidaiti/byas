import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../src/boilerplate.dart';
import '../src/stub_server.dart';

void main() {
  patrolWidgetTest('Read a saved web clip in reading list', (t) async {
    const articleTitle = 'Demystifying evals for AI agents';
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/reading-list',
        body: api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              resourceId: 7,
              kind: api.ReadingListItemKindEnum.webClip,
              title: articleTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      )
      ..onGet(
        '/web-clips/7',
        body: api.GetWebClip200Response(
          id: 7,
          url: 'https://www.anthropic.com/engineering/demystifying-evals',
          title: articleTitle,
          content:
              '<article><p>Good evaluations help teams ship.</p></article>',
        ).toJson(),
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.readingListNavDestination).tap();
    expect(t(AppDebugKey.readingListScreen), findsOneWidget);
    await t(AppDebugKey.readingListRow(articleTitle)).tap();
    expect(t(AppDebugKey.webClipReaderScreen), findsOneWidget);
    expect(t(AppDebugKey.readerTitle(articleTitle)), findsOneWidget);
  });

  patrolWidgetTest('Read a saved feed entry in reading list', (t) async {
    const targetEntryTitle = 'Effective harnesses for long-running agents';
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/reading-list',
        body: api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 5,
              resourceId: 11,
              kind: api.ReadingListItemKindEnum.feedEntry,
              title: targetEntryTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      )
      ..onGet(
        '/feed-entries/11',
        body: api.FeedEntry(
          id: 11,
          feedId: 1,
          url: 'https://example.com/anthropic/blog/effective-harness',
          title: targetEntryTitle,
          content:
              '<article><p>A good harness keeps the agent on track.</p></article>',
          snapshotAt: DateTime.utc(2026),
        ).toJson(),
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.readingListNavDestination).tap();
    expect(t(AppDebugKey.readingListScreen), findsOneWidget);
    await t(AppDebugKey.readingListRow(targetEntryTitle)).tap();
    expect(t(AppDebugKey.feedEntryReaderScreen), findsOneWidget);
    expect(t(AppDebugKey.readerTitle(targetEntryTitle)), findsOneWidget);
  });

  patrolWidgetTest('Archive a reading list item by swiping', (t) async {
    const articleTitle = 'Demystifying evals for AI agents';
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/reading-list',
        body: api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              resourceId: 1,
              kind: api.ReadingListItemKindEnum.webClip,
              title: articleTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      )
      ..onPatch(
        '/reading-list/1',
        status: 204,
        body: <String, dynamic>{},
        data: {'archived': true},
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.readingListNavDestination).tap();
    expect(t(AppDebugKey.readingListRow(articleTitle)), findsOneWidget);
    await t.tester.fling(
      t(AppDebugKey.readingListRow(articleTitle)).finder,
      const Offset(100, 0),
      1000,
    );
    await t(AppDebugKey.archiveSuccessSnackBar).waitUntilVisible();
    expect(t(AppDebugKey.readingListRow(articleTitle)), findsNothing);
  });

  patrolWidgetTest('Read an archived item from the archived screen', (t) async {
    const archivedTitle = 'Demystifying evals for AI agents';
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/reading-list',
        body: api.GetReadingList200Response(items: []).toJson(),
      )
      ..onGet(
        '/reading-list/archived',
        body: api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              resourceId: 7,
              kind: api.ReadingListItemKindEnum.webClip,
              title: archivedTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      )
      ..onGet(
        '/web-clips/7',
        body: api.GetWebClip200Response(
          id: 7,
          url: 'https://www.anthropic.com/engineering/demystifying-evals',
          title: archivedTitle,
          content:
              '<article><p>Good evaluations help teams ship.</p></article>',
        ).toJson(),
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.readingListNavDestination).tap();
    expect(t(AppDebugKey.readingListScreen), findsOneWidget);
    await t(AppDebugKey.archivedButton).tap();
    expect(t(AppDebugKey.archivedReadingListScreen), findsOneWidget);
    await t(AppDebugKey.readingListRow(archivedTitle)).tap();
    expect(t(AppDebugKey.webClipReaderScreen), findsOneWidget);
    expect(t(AppDebugKey.readerTitle(archivedTitle)), findsOneWidget);
  });

  patrolWidgetTest('Read an archived feed entry from the archived screen', (
    t,
  ) async {
    const archivedTitle = 'Effective harnesses for long-running agents';
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/reading-list',
        body: api.GetReadingList200Response(items: []).toJson(),
      )
      ..onGet(
        '/reading-list/archived',
        body: api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 5,
              resourceId: 11,
              kind: api.ReadingListItemKindEnum.feedEntry,
              title: archivedTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      )
      ..onGet(
        '/feed-entries/11',
        body: api.FeedEntry(
          id: 11,
          feedId: 1,
          url: 'https://example.com/anthropic/blog/effective-harness',
          title: archivedTitle,
          content:
              '<article><p>A good harness keeps the agent on track.</p></article>',
          snapshotAt: DateTime.utc(2026),
        ).toJson(),
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.readingListNavDestination).tap();
    expect(t(AppDebugKey.readingListScreen), findsOneWidget);
    await t(AppDebugKey.archivedButton).tap();
    expect(t(AppDebugKey.archivedReadingListScreen), findsOneWidget);
    await t(AppDebugKey.readingListRow(archivedTitle)).tap();
    expect(t(AppDebugKey.feedEntryReaderScreen), findsOneWidget);
    expect(t(AppDebugKey.readerTitle(archivedTitle)), findsOneWidget);
  });

  patrolWidgetTest('Save a feed entry to the reading list in reader', (
    t,
  ) async {
    const entryTitle = 'Effective harnesses for long-running agents';
    final feed = api.Feed(
      id: 1,
      url: 'https://example.com/anthropic/feed',
      title: 'Anthropic Engineering Blog',
    );
    final entry = api.FeedEntry(
      id: 11,
      feedId: 1,
      url: 'https://example.com/anthropic/blog/effective-harness',
      title: entryTitle,
      content:
          '<article><p>A good harness keeps the agent on track.</p></article>',
      snapshotAt: DateTime.utc(2026),
      readLater: null, // This entry is not yet saved
    );

    final server = StubServer.withDefaultResponses()
      ..onGet('/feeds', body: api.GetFeeds200Response(feeds: [feed]).toJson())
      ..onGet('/feeds/1', body: feed.toJson())
      ..onGet(
        '/feeds/1/timeline',
        body: api.GetFeedTimeline200Response(entries: [entry]).toJson(),
      )
      ..onGet('/feed-entries/11', body: entry.toJson())
      ..onPost(
        '/reading-list',
        status: 201,
        body: api.ReadingListItem(
          id: 42,
          resourceId: 11,
          kind: api.ReadingListItemKindEnum.feedEntry,
          title: entryTitle,
          savedAt: DateTime.utc(2026, 7, 1),
        ).toJson(),
        data: {'feed_entry_id': 11},
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.feedsNavDestination).tap();
    expect(t(AppDebugKey.feedsScreen), findsOneWidget);
    await t(AppDebugKey.feedRow('Anthropic Engineering Blog')).tap();
    expect(t(AppDebugKey.feedDetailScreen), findsOneWidget);
    await t(AppDebugKey.feedEntryRow(entryTitle)).tap();
    expect(t(AppDebugKey.feedEntryReaderScreen), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await t(AppDebugKey.feedEntryReaderBookmarkButton).tap();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(
      find.byKey(AppDebugKey.saveToReadingListSuccessSnackBar),
      findsOneWidget,
    );
  });
}
