import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../src/boilerplate.dart';
import '../src/stub_server.dart';

void main() {
  patrolWidgetTest('Check feeds and read a feed entry', (t) async {
    final anthropicFeed = api.Feed(
      id: 1,
      url: 'https://example.com/anthropic/feed',
      title: 'Anthropic Engineering Blog',
    );
    final entry = api.FeedEntry(
      id: 11,
      feedId: 1,
      url: 'https://example.com/anthropic/blog/effective-harness',
      title: 'Effective harnesses for long-running agents',
      snapshotAt: DateTime.utc(2026),
    );

    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/feeds',
        body: api.GetFeeds200Response(feeds: [anthropicFeed]).toJson(),
      )
      ..onGet('/feeds/1', body: anthropicFeed.toJson())
      ..onGet(
        '/feeds/1/timeline',
        body: api.GetFeedTimeline200Response(entries: [entry]).toJson(),
      )
      ..onGet('/feed-entries/11', body: entry.toJson());

    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.feedsNavDestination).tap();
    await t(AppDebugKey.feedsScreen).waitUntilVisible();
    await t(AppDebugKey.feedRow('Anthropic Engineering Blog')).tap();
    await t(AppDebugKey.feedDetailScreen).waitUntilVisible();
    await t(
      AppDebugKey.feedEntryRow('Effective harnesses for long-running agents'),
    ).tap();
    await t(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await t(
      AppDebugKey.readerTitle('Effective harnesses for long-running agents'),
    ).waitUntilVisible();
  });

  patrolWidgetTest('Subscribe to a known web feed', (t) async {
    final dartBlog = api.Feed(
      id: 99,
      url: 'https://dart.dev/blog/feed.xml',
      title: 'The Dart Blog',
    );

    // StubServer is last-registration-wins (not a queue), so /feeds is stubbed
    // once with the subscribed feed: the initial load and the post-subscribe
    // re-fetch both return it, which is all the final assertion depends on.
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/feeds',
        body: api.GetFeeds200Response(feeds: [dartBlog]).toJson(),
      )
      ..onGet(
        '/feeds/search',
        body: api.SearchFeeds200Response(
          feeds: [
            api.FeedCandidate(
              url: 'https://dart.dev/blog/feed.xml',
              iconUrl:
                  'https://www.google.com/s2/favicons?domain=dart.dev&sz=64',
              title: 'The Dart Blog',
              description:
                  'Dart is an approachable, portable, and productive '
                  'language for high-quality apps on any platform.',
            ),
          ],
        ).toJson(),
      )
      ..onPut(
        '/feeds',
        body: dartBlog.toJson(),
        data: {'url': 'https://dart.dev/blog/feed.xml'},
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.feedsNavDestination).tap();
    await t(AppDebugKey.feedsScreen).waitUntilVisible();
    await t(AppDebugKey.addFeedButton).tap();
    await t(AppDebugKey.feedSearchScreen).waitUntilVisible();
    await t(
      AppDebugKey.feedSearchTextField,
    ).enterText('https://dart.dev/blog/feed.xml');
    await t(AppDebugKey.feedSearchButton).tap();
    await t(AppDebugKey.feedCandidateTile('The Dart Blog')).tap();
    await t(AppDebugKey.subscribeSuccessSnackBar).waitUntilVisible();
    await t(AppDebugKey.feedRow('The Dart Blog')).waitUntilVisible();
  });
}
