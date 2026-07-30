import 'package:flutter/widgets.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  // Initialize the Flutter binding up front so the host-facing socket is ready
  // before the first request; without it the connection can abort transiently
  // right after a test's app relaunch ("Software caused connection abort").
  WidgetsFlutterBinding.ensureInitialized();

  patrolTest("Check today's issue and read a story", ($) async {
    await setUpServer(seederId: 'newspaper_today');
    await pumpAppWithAuth($);

    await $(AppDebugKey.todayScreen).waitUntilVisible();
    await $(AppDebugKey.storyCard('Hello there')).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
  });
}
