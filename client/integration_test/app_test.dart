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
  group('critical paths', () {
    patrolTest('open app, read today, open a story', ($) async {
      await _pumpApp($);

      final dio = $.tester.container().read(dioProvider);
      final adapter = DioAdapter(
        dio: dio,
        matcher: const FullHttpRequestMatcher(),
      );

      final story = api.Story(id: 1, title: 'Demystifying evals for AI agents');
      final storyEntry = api.FeedEntry(
        id: 1,
        feedId: 1,
        url: 'https://example.com/story/1',
        title: 'Demystifying evals for AI agents',
      );

      adapter.onGet(
        '/newspapers/today',
        (server) => server.reply(200, {
          'id': 1,
          'published_at': '2026-06-30T00:00:00.000Z',
          'stories': [story.toJson()],
        }),
      );
      adapter.onGet(
        '/newspapers/stories/1',
        (server) =>
            server.reply(200, {'type': 'entry', 'data': storyEntry.toJson()}),
      );

      await $('Demystifying evals for AI agents').tap();
      await $(AppTestKeys.storyReaderScreen).waitUntilVisible();
      await $('Demystifying evals for AI agents').waitUntilVisible();
    });

    patrolTest('browse feeds, open a feed, read an entry', ($) async {
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
        url: 'https://example.com/anthropic/entry/11',
        title: 'Effective harnesses for long-running agents',
      );

      adapter.onGet(
        '/feeds',
        (server) => server.reply(200, {
          'feeds': [anthropicFeed.toJson()],
        }),
      );
      adapter.onGet(
        '/feeds/1',
        (server) => server.reply(200, anthropicFeed.toJson()),
      );
      adapter.onGet(
        '/feeds/1/timeline',
        (server) => server.reply(200, {
          'entries': [entry.toJson()],
        }),
      );
      adapter.onGet(
        '/feed-entries/11',
        (server) => server.reply(200, entry.toJson()),
      );

      await $(AppTestKeys.feedsNavDestination).tap();
      await $('Anthropic Engineering Blog').tap();
      await $(AppTestKeys.feedDetailScreen).waitUntilVisible();
      await $('Effective harnesses for long-running agents').tap();
      await $(AppTestKeys.entryReaderScreen).waitUntilVisible();
      await $('Effective harnesses for long-running agents').waitUntilVisible();
    });

    patrolTest('search for a feed and subscribe', ($) async {
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
      final dartBlogCandidate = api.FeedCandidate(
        url: 'https://dart.dev/blog/feed.xml',
        title: 'The Dart Blog',
      );

      // Two registrations: consumed in order — initial load (empty), then after
      // subscribe invalidates feedsProvider and FeedsScreen re-fetches.
      adapter.onGet(
        '/feeds',
        (server) => server.reply(200, {'feeds': <Object>[]}),
      );
      adapter.onGet(
        '/feeds',
        (server) => server.reply(200, {
          'feeds': [dartBlog.toJson()],
        }),
      );
      adapter.onGet(
        '/feeds/search',
        (server) => server.reply(200, {
          'feeds': [dartBlogCandidate.toJson()],
        }),
        queryParameters: {'q': 'https://dart.dev/blog/feed.xml'},
      );
      adapter.onPut(
        '/feeds',
        (server) => server.reply(200, dartBlog.toJson()),
        data: Matchers.any,
      );

      await $(AppTestKeys.feedsNavDestination).tap();
      await $(AppTestKeys.addFeedButton).tap();
      await $(
        AppTestKeys.feedSearchTextField,
      ).enterText('https://dart.dev/blog/feed.xml');
      await $(AppTestKeys.feedSearchButton).tap();
      await $('The Dart Blog').tap();
      await $(AppTestKeys.subscribeSuccessSnackBar).waitUntilVisible();
      await $('The Dart Blog').waitUntilVisible();
    });
  });
}
