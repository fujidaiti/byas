import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest("Check today's issue and read a story", config: e2eConfig, (
    $,
  ) async {
    await setUpServer(seederId: 'newspaper_today');
    // The newspaper is gated behind auth; boot already signed in so this test
    // doesn't depend on the sign-in/up UI.
    await pumpAppWithAuth($);
    await $(AppDebugKey.todayScreen).waitUntilVisible();
    await $(AppDebugKey.storyCard('Hello there')).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
  });
}
