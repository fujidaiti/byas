import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open app, read today, open a story', (tester) async {
    await pumpApp(tester);

    // Today shows the issue's story cards.
    await pumpUntilFound(tester, find.text('Demystifying evals for AI agents'));

    // Tapping a story opens the Story Reader.
    await tester.tap(find.text('Demystifying evals for AI agents'));
    await pumpUntilFound(tester, find.text('Open original'));
  });
}
