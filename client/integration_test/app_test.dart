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

      // Today shows the issue's story cards; tap the first one.
      await $(AppTestKeys.storyCard(1)).tap();

      // Story Reader is open when the "Open original" button appears.
      await $(AppTestKeys.storyReaderOpenOriginalButton).waitUntilVisible();
    });

    patrolTest('browse feeds, open a feed, read an entry', ($) async {
      await _pumpApp($);

      // Switch to the Feeds tab.
      await $(AppTestKeys.feedsNavDestination).tap();

      // Open the Anthropic Engineering Blog feed (ID 1 from the mock).
      await $(AppTestKeys.feedRow(1)).tap();

      // Open "Effective harnesses for long-running agents" (entry ID 11).
      await $(AppTestKeys.entryRow(11)).tap();

      // Entry Reader is open when the "Open original" button appears.
      await $(AppTestKeys.entryReaderOpenOriginalButton).waitUntilVisible();
    });

    patrolTest('search for a feed and subscribe', ($) async {
      await _pumpApp($);

      // Go to Feeds, then open the search screen.
      await $(AppTestKeys.feedsNavDestination).tap();
      await $(AppTestKeys.addFeedButton).tap();

      // Search by URL via the Search button.
      await $(
        AppTestKeys.feedSearchTextField,
      ).enterText('https://dart.dev/blog/feed.xml');
      await $(AppTestKeys.feedSearchButton).tap();

      // Subscribe by tapping the first candidate.
      await $(AppTestKeys.feedCandidateTile(0)).tap();

      // Confirmation snackbar appears, then we return to the Feeds screen.
      await $(AppTestKeys.subscribeSuccessSnackBar).waitUntilVisible();
      await $(AppTestKeys.addFeedButton).waitUntilVisible();
    });
  });
}
