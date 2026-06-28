// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_envelope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoryEnvelopeDto _$StoryEnvelopeDtoFromJson(Map<String, dynamic> json) =>
    _StoryEnvelopeDto(
      type: json['type'] as String,
      data: FeedEntry.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StoryEnvelopeDtoToJson(_StoryEnvelopeDto instance) =>
    <String, dynamic>{'type': instance.type, 'data': instance.data.toJson()};
