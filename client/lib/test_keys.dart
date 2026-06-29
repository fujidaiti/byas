import 'package:flutter/widgets.dart';

// Intentional namespace class — Dart has no dedicated namespace syntax.
// ignore: avoid_classes_with_only_static_members
abstract final class AppTestKeys {
  static const addFeedButton = Key('addFeedButton');
  static const entryReaderOpenOriginalButton = Key(
    'entryReaderOpenOriginalButton',
  );
  static const feedSearchButton = Key('feedSearchButton');
  static const feedSearchTextField = Key('feedSearchTextField');
  static const feedsNavDestination = Key('feedsNavDestination');
  static const storyReaderOpenOriginalButton = Key(
    'storyReaderOpenOriginalButton',
  );
  static const subscribeSuccessSnackBar = Key('subscribeSuccessSnackBar');
  static const todayNavDestination = Key('todayNavDestination');

  static Key entryRow(int id) => Key('entryRow_$id');
  static Key feedRow(int id) => Key('feedRow_$id');
  static Key storyCard(int id) => Key('storyCard_$id');
}
