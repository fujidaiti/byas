import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:paperdoll/features/entry/domain/feed_entry.dart';

part 'story_envelope_dto.freezed.dart';
part 'story_envelope_dto.g.dart';

/// Wire shape of `GET /newspapers/stories/{id}`: `{ type: "entry", data }`.
/// The repository unwraps [data] to a plain [FeedEntry].
@freezed
abstract class StoryEnvelopeDto with _$StoryEnvelopeDto {
  const factory StoryEnvelopeDto({
    required String type,
    required FeedEntry data,
  }) = _StoryEnvelopeDto;

  factory StoryEnvelopeDto.fromJson(Map<String, dynamic> json) =>
      _$StoryEnvelopeDtoFromJson(json);
}
