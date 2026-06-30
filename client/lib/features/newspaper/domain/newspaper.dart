import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:paperdoll/features/newspaper/domain/story.dart';

part 'newspaper.freezed.dart';

/// A dated issue bundling the stories curated for that day.
@freezed
abstract class Newspaper with _$Newspaper {
  const factory Newspaper({
    required int id,
    required DateTime publishedAt,
    required List<Story> stories,
  }) = _Newspaper;
}
