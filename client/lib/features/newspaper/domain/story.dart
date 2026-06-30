import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';

/// A curated entry chosen to appear in a newspaper issue.
@freezed
abstract class Story with _$Story {
  const factory Story({
    required int id,
    required String title,
    String? description,
    String? source,
    DateTime? publishedAt,
  }) = _Story;
}
