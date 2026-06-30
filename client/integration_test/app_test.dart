import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/main.dart';
import 'package:paperdoll/test_keys.dart';
import 'package:patrol/patrol.dart';

Future<void> _pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
      ],
      child: const PaperdollApp(),
    ),
  );
}

void main() {
  group('today', () {
    patrolTest('open a story', ($) async {
      await _pumpApp($);

      final dio = $.tester.container().read(dioProvider);
      final adapter = DioAdapter(
        dio: dio,
        matcher: const FullHttpRequestMatcher(),
      );

      adapter.onGet(
        '/newspapers/today',
        (s) => s.reply(
          200,
          api.GetTodaysNewspaper200Response(
            id: 1,
            publishedAt: DateTime.utc(2026, 7, 1),
            stories: [
              api.Story(
                id: 1,
                title: 'Demystifying evals for AI agents',
                source_: 'Cursor AI Blog',
              ),
            ],
          ).toJson(),
        ),
      );
      adapter.onGet(
        '/newspapers/stories/1',
        (s) => s.reply(
          200,
          api.GetStory200Response(
            type: api.GetStory200ResponseTypeEnum.entry,
            data: api.FeedEntry(
              id: 1,
              feedId: 1,
              url: 'https://cursor.ai/blog/1',
              title: 'Demystifying evals for AI agents',
            ),
          ).toJson(),
        ),
      );

      expect($(AppTestKeys.todayScreen), findsOneWidget);
      await $(AppTestKeys.storyCard('Demystifying evals for AI agents')).tap();
      await $(AppTestKeys.storyReaderScreen).waitUntilVisible();
      await $(
        AppTestKeys.readerTitle('Demystifying evals for AI agents'),
      ).waitUntilVisible();
    });
  });

  group('feeds', () {
    patrolTest('open a feed and read an entry', ($) async {
      await _pumpApp($);

      final dio = $.tester.container().read(dioProvider);
      final adapter = DioAdapter(
        dio: dio,
        matcher: const FullHttpRequestMatcher(),
      );

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

    patrolTest('search and subscribe', ($) async {
      await _pumpApp($);

      final dio = $.tester.container().read(dioProvider);
      final adapter = DioAdapter(
        dio: dio,
        matcher: const FullHttpRequestMatcher(),
      );

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
        (s) =>
            s.reply(200, api.GetFeeds200Response(feeds: [dartBlog]).toJson()),
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
        data: Matchers.any,
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
  });
}
