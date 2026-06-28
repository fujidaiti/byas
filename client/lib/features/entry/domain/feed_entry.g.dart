// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedEntry _$FeedEntryFromJson(Map<String, dynamic> json) => _FeedEntry(
  id: (json['id'] as num).toInt(),
  feedId: (json['feed_id'] as num).toInt(),
  url: json['url'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  content: json['content'] as String?,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  snapshotAt: json['snapshot_at'] == null
      ? null
      : DateTime.parse(json['snapshot_at'] as String),
);

Map<String, dynamic> _$FeedEntryToJson(_FeedEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'feed_id': instance.feedId,
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'content': instance.content,
      'published_at': instance.publishedAt?.toIso8601String(),
      'snapshot_at': instance.snapshotAt?.toIso8601String(),
    };
