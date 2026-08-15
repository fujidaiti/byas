import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:paperdoll/features/newspaper/domain/story.dart';

part 'newspaper.freezed.dart';

/// A dated issue bundling the stories curated for that day. [stories] is one
/// page of the issue's stories; [nextCursor] fetches the next page (null on the
/// last page).
@freezed
abstract class Newspaper with _$Newspaper {
  const factory({
    required int id,
    required DateTime publishedAt,
    required List<Story> stories,
    String? nextCursor,
  }) = _Newspaper;
}
