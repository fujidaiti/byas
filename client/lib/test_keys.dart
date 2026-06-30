import 'package:flutter/widgets.dart';

// Intentional namespace class — Dart has no dedicated namespace syntax.
// ignore: avoid_classes_with_only_static_members
abstract final class AppTestKeys {
  static const addFeedButton = Key('addFeedButton');
  static const entryReaderOpenOriginalButton = Key(
    'entryReaderOpenOriginalButton',
  );
  static const entryReaderScreen = Key('entryReaderScreen');
  static const feedDetailScreen = Key('feedDetailScreen');
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

  static Key entryRow(String title) => Key('entry:$title');
  static Key feedCandidateTile(String title) => Key('feedCandidate:$title');
  static Key feedRow(String title) => Key('feed:$title');
  static Key storyCard(String title) => Key('story:$title');
}
