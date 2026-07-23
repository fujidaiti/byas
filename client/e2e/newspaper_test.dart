import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest("Check today's issue and read a story", config: e2eConfig, (
    $,
  ) async {
    await setUpServer(seederId: 'newspaper_today');
    await pumpApp($);
    // The newspaper is gated behind auth; sign up a fresh user to reach Today.
    await signUp(
      $,
      email: 'reader@example.com',
      password: existingUserPassword,
    );
    await $(AppDebugKey.todayScreen).waitUntilVisible();
    await $(AppDebugKey.storyCard('Hello there')).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
  });
}
