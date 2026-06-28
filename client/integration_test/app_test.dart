import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_candidate_tile.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('critical paths', () {
    testWidgets('open app, read today, open a story', (t) async {
      await pumpApp(t);

      // Today shows the issue's story cards.
      await pumpUntilFound(t, find.text('Demystifying evals for AI agents'));

      // Tapping a story opens the Story Reader.
      await t.tap(find.text('Demystifying evals for AI agents'));
      await pumpUntilFound(t, find.text('Open original'));
    });

    testWidgets('browse feeds, open a feed, read an entry', (t) async {
      await pumpApp(t);

      // Switch to the Feeds tab via the bottom navigation.
      await t.tap(find.text('Feeds'));
      await pumpUntilFound(t, find.text('Anthropic Engineering Blog'));

      // Open the feed's timeline.
      await t.tap(find.text('Anthropic Engineering Blog'));
      await pumpUntilFound(
        t,
        find.text('Effective harnesses for long-running agents'),
      );

      // Open an entry in the Entry Reader.
      await t.tap(find.text('Effective harnesses for long-running agents'));
      await pumpUntilFound(t, find.text('Open original'));
    });

    testWidgets('search for a feed and subscribe', (t) async {
      await pumpApp(t);

      // Go to Feeds, then open the search screen.
      await t.tap(find.text('Feeds'));
      await pumpUntilFound(t, find.byTooltip('Add feed'));
      await t.tap(find.byTooltip('Add feed'));
      await pumpUntilFound(t, find.byType(TextField));

      // Search by URL via the keyboard action; Prism returns a spec candidate.
      await t.enterText(
        find.byType(TextField),
        'https://dart.dev/blog/feed.xml',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await pumpUntilFound(t, find.byType(FeedCandidateTile));

      // Subscribe by tapping the candidate. Prism is stateless, so we assert
      // the action succeeds (confirmation snackbar + return to Feeds) rather
      // than that the feeds list grew.
      await t.tap(find.byType(FeedCandidateTile));
      await pumpUntilFound(t, find.textContaining('Subscribed to'));
      await pumpUntilFound(t, find.byTooltip('Add feed'));
    });
  });
}
