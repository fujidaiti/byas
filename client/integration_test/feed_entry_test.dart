import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Save a feed entry to the reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const entryTitle = 'Effective harnesses for long-running agents';
    final feed = api.Feed(
      id: 1,
      url: 'https://example.com/anthropic/feed',
      title: 'Anthropic Engineering Blog',
    );
    final entry = api.FeedEntry(
      id: 11,
      feedId: 1,
      url: 'https://example.com/anthropic/blog/effective-harness',
      title: entryTitle,
    );

    adapter.onGet(
      '/feeds',
      (s) => s.reply(200, api.GetFeeds200Response(feeds: [feed]).toJson()),
    );
    adapter.onGet('/feeds/1', (s) => s.reply(200, feed.toJson()));
    adapter.onGet(
      '/feeds/1/timeline',
      (s) => s.reply(
        200,
        api.GetFeedTimeline200Response(entries: [entry]).toJson(),
      ),
    );
    // The entry is not yet saved, so the reader opens with an empty bookmark.
    adapter.onGet('/feed-entries/11', (s) => s.reply(200, entry.toJson()));
    adapter.onPost(
      '/reading-list',
      (s) => s.reply(201, <String, dynamic>{}),
      data: {'feed_entry_id': 11},
    );

    await $(AppDebugKey.feedsNavDestination).tap();
    expect($(AppDebugKey.feedsScreen), findsOneWidget);
    await $(AppDebugKey.feedRow('Anthropic Engineering Blog')).tap();
    expect($(AppDebugKey.feedDetailScreen), findsOneWidget);
    await $(AppDebugKey.feedEntryRow(entryTitle)).tap();
    expect($(AppDebugKey.feedEntryReaderScreen), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await $(AppDebugKey.feedEntryReaderBookmarkButton).tap();
    // The bookmark fills optimistically and a confirmation snackbar mounts on
    // the next frame (the save runs asynchronously after the tap settles).
    await $.pump();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(
      find.byKey(AppDebugKey.saveToReadingListSuccessSnackBar),
      findsOneWidget,
    );
  });
}
