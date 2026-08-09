import 'package:flutter/widgets.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
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

  patrolTest('Read a saved web clip', tags: 'reading-list-web-clip', ($) async {
    await setUpServer(seederId: 'reading_list_web_clip');
    await pumpAppWithAuth($);

    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListScreen).waitUntilVisible();
    await $(AppDebugKey.readingListRow('Building effective agents')).tap();
    await $(AppDebugKey.webClipReaderScreen).waitUntilVisible();
    await $(
      AppDebugKey.readerTitle('Building effective agents'),
    ).waitUntilVisible();
  });

  patrolTest(
    'Archive a reading list item from the reader',
    tags: 'reading-list-archive',
    ($) async {
      await setUpServer(seederId: 'reading_list_item');
      await pumpAppWithAuth($);

      await $(AppDebugKey.readingListNavDestination).tap();
      await $(AppDebugKey.readingListScreen).waitUntilVisible();
      await $(AppDebugKey.readingListRow('Hello there')).tap();
      await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
      await $(AppDebugKey.feedEntryReaderArchiveButton).tap();
      await $(AppDebugKey.archiveSuccessSnackBar).waitUntilVisible();
      await $(AppDebugKey.feedEntryReaderArchivedBanner).waitUntilVisible();

      await $.tester.pageBack();
      await $(AppDebugKey.readingListScreen).waitUntilVisible();
      // Refresh the page and see if the item disappears from the list.
      await $.tester.fling(
        $(AppDebugKey.readingListScreen).finder,
        const Offset(0, 300),
        1000,
      );
      await $('Your reading list is empty.').waitUntilVisible();

      await $(AppDebugKey.archivedButton).tap();
      await $(AppDebugKey.archivedReadingListScreen).waitUntilVisible();
      await $(AppDebugKey.readingListRow('Hello there')).waitUntilVisible();
    },
  );

  patrolTest(
    'Read an archived web clip',
    tags: 'reading-list-archived-web-clip',
    ($) async {
      await setUpServer(seederId: 'reading_list_archived');
      await pumpAppWithAuth($);

      await $(AppDebugKey.readingListNavDestination).tap();
      await $(AppDebugKey.readingListScreen).waitUntilVisible();
      await $(AppDebugKey.archivedButton).tap();
      await $(AppDebugKey.archivedReadingListScreen).waitUntilVisible();
      await $(AppDebugKey.readingListRow('Building effective agents')).tap();
      await $(AppDebugKey.webClipReaderScreen).waitUntilVisible();
      await $(
        AppDebugKey.readerTitle('Building effective agents'),
      ).waitUntilVisible();
    },
  );

  patrolTest(
    'Read an archived feed entry',
    tags: 'reading-list-archived-feed-entry',
    ($) async {
      await setUpServer(seederId: 'reading_list_archived');
      await pumpAppWithAuth($);

      await $(AppDebugKey.readingListNavDestination).tap();
      await $(AppDebugKey.readingListScreen).waitUntilVisible();
      await $(AppDebugKey.archivedButton).tap();
      await $(AppDebugKey.archivedReadingListScreen).waitUntilVisible();
      await $(AppDebugKey.readingListRow('Hello there')).tap();
      await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
      await $(AppDebugKey.readerTitle('Hello there')).waitUntilVisible();
    },
  );

  patrolTest('Save a feed entry from the reader', tags: 'reading-list-save', (
    $,
  ) async {
    const title = 'US signs landmark nuclear deal with Saudi Arabia';
    await setUpServer(seederId: 'feed_bbc_news');
    await pumpAppWithAuth($);

    await $(AppDebugKey.feedsNavDestination).tap();
    await $(AppDebugKey.feedsScreen).waitUntilVisible();
    await $(AppDebugKey.feedRow('BBC News')).tap();
    await $(AppDebugKey.feedDetailScreen).waitUntilVisible();
    await $(AppDebugKey.feedEntryRow(title)).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(AppDebugKey.feedEntryReaderBookmarkButton).tap();
    await $(AppDebugKey.saveToReadingListSuccessSnackBar).waitUntilVisible();

    // The entry really landed in the list on the server. The reader covers the
    // nav bar (it's pushed on the root navigator), so leave it first; and as
    // with archiving, refresh to avoid racing the still-in-flight save.
    await $.tester.pageBack();
    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListScreen).waitUntilVisible();
    await $.tester.fling(
      $(AppDebugKey.readingListScreen).finder,
      const Offset(0, 300),
      1000,
    );
    await $(AppDebugKey.readingListRow(title)).waitUntilVisible();
  });
}
