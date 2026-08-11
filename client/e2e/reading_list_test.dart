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

  patrolTest(
    'Save a web page shared from the Chrome app',
    tags: 'reading-list-save-from-browser',
    ($) async {
      // Both the page's <title> and the title the server extracts from it, so
      // the row reads the same before and after the background fetch lands.
      const title = 'Shared from the browser';
      // The stub server binds the host's loopback, which the emulator reaches
      // at 10.0.2.2. Chrome loads this URL directly; the API server later
      // fetches the very same one through the stub acting as its proxy.
      const url = 'http://10.0.2.2:8081/clips/shared';

      await setUpServer(seederId: 'reading_list_share_sheet');
      await pumpAppWithAuth($);
      await $(AppDebugKey.todayScreen).waitUntilVisible();

      await $.platform.mobile.openUrl(url);
      // Wait on the URL bar rather than the page text: Chrome only builds the
      // accessibility tree for web contents lazily, so matching the article
      // body races the renderer. The URL bar is an ordinary Android view and
      // takes the new URL when the navigation commits.
      await $.platform.mobile.waitUntilVisible(
        Selector(
          resourceId: 'com.android.chrome:id/url_bar',
          text: '10.0.2.2:8081/clips/shared',
        ),
      );
      await $.platform.mobile.tap(
        Selector(resourceId: 'com.android.chrome:id/menu_button'),
      );
      // The menu item's label ends with an ellipsis ("Share…") and shares its
      // resource id with every other item in the menu, so match on the prefix.
      await $.platform.mobile.tap(
        Selector(textStartsWith: 'Share', pkg: 'com.android.chrome'),
      );
      // The Sharesheet opens collapsed, showing only its usage-ranked top row,
      // and patrol's tap does not scroll. Drag it up so the full app list is
      // rendered; we sit in it under "paperdoll".
      await $.platform.mobile.swipe(
        from: const Offset(0.5, 0.55),
        to: const Offset(0.5, 0.15),
      );
      // Our entry is SaveWebClipActivity's android:label, not the app name.
      // The label renders truncated ("Save to Rea…") but the node keeps the
      // full text.
      await $.platform.mobile.tap(Selector(text: 'Save to Reading List'));
      await $.platform.mobile.waitUntilVisible(
        Selector(text: 'Added to Reading List'),
      );

      // SaveWebClipActivity is noHistory with its own task affinity, so it is
      // already off the stack; this just brings the app back to the front.
      await $.platform.mobile.openApp();
      await $(AppDebugKey.readingListNavDestination).tap();
      await $(AppDebugKey.readingListScreen).waitUntilVisible();
      await $(AppDebugKey.readingListRow(title)).waitUntilVisible();
    },
  );
}
