import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../src/boilerplate.dart';
import '../src/fixture.dart';
import '../src/stub_server.dart';

void main() {
  patrolWidgetTest('Check feeds and read a feed entry', (t) async {
    final bbcNews = fixture.feeds.bbcNews;
    final entry = fixture.entries.nuclearDeal;
    final timeline = [
      entry,
      fixture.entries.houthiStrikes,
      fixture.entries.moonshotAi,
    ];

    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/feeds',
        body: api.GetFeeds200Response(
          feeds: [
            bbcNews,
            fixture.feeds.stackOverflow,
            fixture.feeds.wikipedia,
          ],
        ).toJson(),
      )
      ..onGet('/feeds/${bbcNews.id}', body: bbcNews.toJson())
      ..onGet(
        '/feeds/${bbcNews.id}/timeline',
        body: api.GetFeedTimeline200Response(entries: timeline).toJson(),
      )
      ..onGet('/feed-entries/${entry.id}', body: entry.toJson());

    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.feedsNavDestination).tap();
    await t(AppDebugKey.feedsScreen).waitUntilVisible();
    await t(AppDebugKey.feedRow(bbcNews.title)).tap();
    await t(AppDebugKey.feedDetailScreen).waitUntilVisible();
    await t(AppDebugKey.feedEntryRow(entry.title)).tap();
    await t(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await t(AppDebugKey.readerTitle(entry.title)).waitUntilVisible();
  });

  patrolWidgetTest('Subscribe to a known web feed', (t) async {
    final candidate = fixture.candidates.nasa;
    final nasa = fixture.feeds.nasa;

    final server = StubServer.withDefaultResponses()
      // There's no feed at first.
      ..onGet('/feeds', body: api.GetFeeds200Response(feeds: []).toJson())
      ..onGet(
        '/feeds/search',
        body: api.SearchFeeds200Response(feeds: [candidate]).toJson(),
      );
    await pumpAppWithAuth(t, server);

    await t(AppDebugKey.feedsNavDestination).tap();
    await t(AppDebugKey.feedsScreen).waitUntilVisible();
    await t(AppDebugKey.addFeedButton).tap();
    await t(AppDebugKey.feedSearchScreen).waitUntilVisible();

    server
      ..onPut('/feeds', body: nasa.toJson(), data: {'url': nasa.url})
      ..onGet('/feeds', body: api.GetFeeds200Response(feeds: [nasa]).toJson());

    await t(AppDebugKey.feedSearchTextField).enterText(nasa.url);
    await t(AppDebugKey.feedSearchButton).tap();
    await t(AppDebugKey.feedCandidateTile(candidate.title)).tap();
    await t(AppDebugKey.subscribeSuccessSnackBar).waitUntilVisible();
    await t(AppDebugKey.feedRow(nasa.title)).waitUntilVisible();
  });
}
