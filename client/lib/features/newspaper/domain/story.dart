import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';

/// The kind of resource backing a [Story]. Mirrors the reading list so a story
/// row can navigate straight to the matching reader. Stories are always backed
/// by a feed entry today; other kinds are reserved for future use.
enum StoryKind { webClip, feedEntry }

/// A curated entry chosen to appear in a newspaper issue.
@freezed
abstract class Story with _$Story {
  const factory Story({
    required int id,
    required int resourceId,
    required StoryKind kind,
    required String title,
    String? description,
    String? source,
    DateTime? publishedAt,
    int? readingListItemId,
  }) = _Story;
}
