import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest("Check today's issue and read a story", ($) async {
    await setUpServer(seederId: 'newspaper_today');

    await pumpApp($);
    expect($(AppDebugKey.todayScreen), findsOneWidget);
    await $(AppDebugKey.storyCard('Hello there')).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
  });
}
