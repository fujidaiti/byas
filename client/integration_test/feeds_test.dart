import 'package:openapi/api.dart' as api;
import 'package:paperdoll/test_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Check feeds and read a feed entry', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

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
    );

    adapter.onGet(
      '/feeds',
      (s) => s.reply(
        200,
        api.GetFeeds200Response(feeds: [anthropicFeed]).toJson(),
      ),
    );
    adapter.onGet('/feeds/1', (s) => s.reply(200, anthropicFeed.toJson()));
    adapter.onGet(
      '/feeds/1/timeline',
      (s) => s.reply(
        200,
        api.GetFeedTimeline200Response(entries: [entry]).toJson(),
      ),
    );
    adapter.onGet('/feed-entries/11', (s) => s.reply(200, entry.toJson()));

    await $(AppTestKeys.feedsNavDestination).tap();
    await $(AppTestKeys.feedsScreen).waitUntilVisible();
    await $(AppTestKeys.feedRow('Anthropic Engineering Blog')).tap();
    await $(AppTestKeys.feedDetailScreen).waitUntilVisible();
    await $(
      AppTestKeys.entryRow('Effective harnesses for long-running agents'),
    ).tap();
    await $(AppTestKeys.entryReaderScreen).waitUntilVisible();
    await $(
      AppTestKeys.readerTitle('Effective harnesses for long-running agents'),
    ).waitUntilVisible();
  });

  patrolTest('Subscribe to a known web feed', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);
    final dartBlog = api.Feed(
      id: 99,
      url: 'https://dart.dev/blog/feed.xml',
      title: 'The Dart Blog',
    );

    // Two registrations: consumed in order — initial load (empty), then after
    // subscribe invalidates feedsProvider and FeedsScreen re-fetches.
    adapter.onGet(
      '/feeds',
      (s) => s.reply(200, api.GetFeeds200Response().toJson()),
    );
    adapter.onGet(
      '/feeds',
      (s) => s.reply(200, api.GetFeeds200Response(feeds: [dartBlog]).toJson()),
    );
    adapter.onGet(
      '/feeds/search',
      (s) => s.reply(
        200,
        api.SearchFeeds200Response(
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
      ),
      queryParameters: {'q': 'https://dart.dev/blog/feed.xml'},
    );
    adapter.onPut(
      '/feeds',
      (s) => s.reply(200, dartBlog.toJson()),
      data: {'url': 'https://dart.dev/blog/feed.xml'},
    );

    await $(AppTestKeys.feedsNavDestination).tap();
    await $(AppTestKeys.feedsScreen).waitUntilVisible();
    await $(AppTestKeys.addFeedButton).tap();
    await $(AppTestKeys.feedSearchScreen).waitUntilVisible();
    await $(
      AppTestKeys.feedSearchTextField,
    ).enterText('https://dart.dev/blog/feed.xml');
    await $(AppTestKeys.feedSearchButton).tap();
    await $(AppTestKeys.feedCandidateTile('The Dart Blog')).tap();
    await $(AppTestKeys.subscribeSuccessSnackBar).waitUntilVisible();
    await $(AppTestKeys.feedRow('The Dart Blog')).waitUntilVisible();
  });
}
