import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_candidate_tile.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('critical paths', () {
    testWidgets('open app, read today, open a story', (tester) async {
      await pumpApp(tester);

      // Today shows the issue's story cards.
      await pumpUntilFound(
        tester,
        find.text('Demystifying evals for AI agents'),
      );

      // Tapping a story opens the Story Reader.
      await tester.tap(find.text('Demystifying evals for AI agents'));
      await pumpUntilFound(tester, find.text('Open original'));
    });

    testWidgets('browse feeds, open a feed, read an entry', (tester) async {
      await pumpApp(tester);

      // Switch to the Feeds tab via the bottom navigation.
      await tester.tap(find.text('Feeds'));
      await pumpUntilFound(tester, find.text('Anthropic Engineering Blog'));

      // Open the feed's timeline.
      await tester.tap(find.text('Anthropic Engineering Blog'));
      await pumpUntilFound(
        tester,
        find.text('Effective harnesses for long-running agents'),
      );

      // Open an entry in the Entry Reader.
      await tester.tap(
        find.text('Effective harnesses for long-running agents'),
      );
      await pumpUntilFound(tester, find.text('Open original'));
    });

    testWidgets('search for a feed and subscribe', (tester) async {
      await pumpApp(tester);

      // Go to Feeds, then open the search screen.
      await tester.tap(find.text('Feeds'));
      await pumpUntilFound(tester, find.byTooltip('Add feed'));
      await tester.tap(find.byTooltip('Add feed'));
      await pumpUntilFound(tester, find.byType(TextField));

      // Search by URL via the keyboard action; Prism returns a spec candidate.
      await tester.enterText(
        find.byType(TextField),
        'https://dart.dev/blog/feed.xml',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpUntilFound(tester, find.byType(FeedCandidateTile));

      // Subscribe by tapping the candidate. Prism is stateless, so we assert
      // the action succeeds (confirmation snackbar + return to Feeds) rather
      // than that the feeds list grew.
      await tester.tap(find.byType(FeedCandidateTile));
      await pumpUntilFound(tester, find.textContaining('Subscribed to'));
      await pumpUntilFound(tester, find.byTooltip('Add feed'));
    });
  });
}
