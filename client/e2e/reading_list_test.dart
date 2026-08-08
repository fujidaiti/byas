import 'package:flutter/widgets.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  // Initialize the Flutter binding up front so the host-facing socket is ready
  // before the first request; without it the connection can abort transiently
  // right after a test's app relaunch ("Software caused connection abort").
  WidgetsFlutterBinding.ensureInitialized();

  patrolTest('Open a saved reading list item', tags: 'reading-list-read', (
    $,
  ) async {
    await setUpServer(seederId: 'reading_list_item');
    await pumpAppWithAuth($);

    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListScreen).waitUntilVisible();
    await $(AppDebugKey.readingListRow('Hello there')).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
  });
}
