// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newspaper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Newspaper _$NewspaperFromJson(Map<String, dynamic> json) => _Newspaper(
  id: (json['id'] as num).toInt(),
  publishedAt: DateTime.parse(json['published_at'] as String),
  stories: (json['stories'] as List<dynamic>)
      .map((e) => Story.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NewspaperToJson(_Newspaper instance) =>
    <String, dynamic>{
      'id': instance.id,
      'published_at': instance.publishedAt.toIso8601String(),
      'stories': instance.stories.map((e) => e.toJson()).toList(),
    };
