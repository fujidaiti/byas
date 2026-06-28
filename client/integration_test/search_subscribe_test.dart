import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_candidate_tile.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

    // Subscribe by tapping the candidate. Prism is stateless, so we assert the
    // action succeeds (confirmation snackbar + return to Feeds) rather than
    // that the feeds list grew.
    await tester.tap(find.byType(FeedCandidateTile));
    await pumpUntilFound(tester, find.textContaining('Subscribed to'));
    await pumpUntilFound(tester, find.byTooltip('Add feed'));
  });
}
