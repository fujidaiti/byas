import 'package:flutter/widgets.dart';

// Intentional namespace class — Dart has no dedicated namespace syntax.
// ignore: avoid_classes_with_only_static_members
abstract final class AppDebugKey {
  static const addFeedButton = Key('addFeedButton');
  static const feedDetailScreen = Key('feedDetailScreen');
  static const feedEntryReaderOpenOriginalButton = Key(
    'feedEntryReaderOpenOriginalButton',
  );
  static const feedEntryReaderScreen = Key('feedEntryReaderScreen');
  static const feedSearchButton = Key('feedSearchButton');
  static const feedSearchScreen = Key('feedSearchScreen');
  static const feedSearchTextField = Key('feedSearchTextField');
  static const feedsNavDestination = Key('feedsNavDestination');
  static const feedsScreen = Key('feedsScreen');
  static const storyReaderOpenOriginalButton = Key(
    'storyReaderOpenOriginalButton',
  );
  static const storyReaderScreen = Key('storyReaderScreen');
  static const subscribeSuccessSnackBar = Key('subscribeSuccessSnackBar');
  static const todayNavDestination = Key('todayNavDestination');
  static const todayScreen = Key('todayScreen');

  static Key feedCandidateTile(String title) => Key('feedCandidate:$title');
  static Key feedEntryRow(String title) => Key('feedEntry:$title');
  static Key feedRow(String title) => Key('feed:$title');
  static Key readerTitle(String title) => Key('readerTitle:$title');
  static Key storyCard(String title) => Key('story:$title');
}
