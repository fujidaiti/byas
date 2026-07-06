import 'package:flutter/widgets.dart';

// Intentional namespace class — Dart has no dedicated namespace syntax.
// ignore: avoid_classes_with_only_static_members
abstract final class AppDebugKey {
  static const addFeedButton = Key('addFeedButton');
  static const archiveSuccessSnackBar = Key('archiveSuccessSnackBar');
  static const feedDetailScreen = Key('feedDetailScreen');
  static const feedEntryReaderBookmarkButton = Key(
    'feedEntryReaderBookmarkButton',
  );
  static const feedEntryReaderOpenOriginalButton = Key(
    'feedEntryReaderOpenOriginalButton',
  );
  static const feedEntryReaderScreen = Key('feedEntryReaderScreen');
  static const feedSearchButton = Key('feedSearchButton');
  static const feedSearchScreen = Key('feedSearchScreen');
  static const feedSearchTextField = Key('feedSearchTextField');
  static const feedsNavDestination = Key('feedsNavDestination');
  static const feedsScreen = Key('feedsScreen');
  static const readingListNavDestination = Key('readingListNavDestination');
  static const readingListScreen = Key('readingListScreen');
  static const webClipReaderScreen = Key('webClipReaderScreen');
  static const webClipReaderBookmarkButton = Key('webClipReaderBookmarkButton');
  static const webClipReaderOpenOriginalButton = Key(
    'webClipReaderOpenOriginalButton',
  );
  static const removeFromReadingListSuccessSnackBar = Key(
    'removeFromReadingListSuccessSnackBar',
  );
  static const saveToReadingListSuccessSnackBar = Key(
    'saveToReadingListSuccessSnackBar',
  );
  static const subscribeSuccessSnackBar = Key('subscribeSuccessSnackBar');
  static const todayNavDestination = Key('todayNavDestination');
  static const todayScreen = Key('todayScreen');

  static Key feedCandidateTile(String title) => Key('feedCandidate:$title');
  static Key feedEntryRow(String title) => Key('feedEntry:$title');
  static Key feedRow(String title) => Key('feed:$title');
  static Key readingListRow(String title) => Key('readingList:$title');
  static Key readerTitle(String title) => Key('readerTitle:$title');
  static Key storyCard(String title) => Key('story:$title');
}
