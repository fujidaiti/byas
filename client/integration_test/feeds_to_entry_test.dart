import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
    await tester.tap(find.text('Effective harnesses for long-running agents'));
    await pumpUntilFound(tester, find.text('Open original'));
  });
}
