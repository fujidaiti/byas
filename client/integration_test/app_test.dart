import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/main.dart';
import 'package:paperdoll/test_keys.dart';
import 'package:patrol/patrol.dart';

// Android emulator reaches the host machine via 10.0.2.2.
const _prismBaseUrl = 'http://10.0.2.2:4010';

Future<void> _pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(_prismBaseUrl)),
      ],
      child: const PaperdollApp(),
    ),
  );
}

void main() {
  group('critical paths', () {
    patrolTest('open app, read today, open a story', ($) async {
      await _pumpApp($);

      await $('Demystifying evals for AI agents').tap();

      // Verify navigation and correct story content.
      await $(AppTestKeys.storyReaderScreen).waitUntilVisible();
      await $('Demystifying evals for AI agents').waitUntilVisible();
    });

    patrolTest('browse feeds, open a feed, read an entry', ($) async {
      await _pumpApp($);

      await $(AppTestKeys.feedsNavDestination).tap();

      await $('Anthropic Engineering Blog').tap();

      // Verify navigation to feed detail, then tap the entry by title.
      await $(AppTestKeys.feedDetailScreen).waitUntilVisible();
      await $('Effective harnesses for long-running agents').tap();

      // Verify navigation and that entry content loaded
      // (mock returns this title for any entry ID).
      await $(AppTestKeys.entryReaderScreen).waitUntilVisible();
      await $('Demystifying evals for AI agents').waitUntilVisible();
    });

    patrolTest('search for a feed and subscribe', ($) async {
      await _pumpApp($);

      await $(AppTestKeys.feedsNavDestination).tap();
      await $(AppTestKeys.addFeedButton).tap();

      await $(
        AppTestKeys.feedSearchTextField,
      ).enterText('https://dart.dev/blog/feed.xml');
      await $(AppTestKeys.feedSearchButton).tap();

      await $('The Dart Blog').tap();

      // Confirmation snackbar appears, then we return to the Feeds screen.
      await $(AppTestKeys.subscribeSuccessSnackBar).waitUntilVisible();
      await $(AppTestKeys.addFeedButton).waitUntilVisible();
    });
  });
}
