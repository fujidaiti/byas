// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Feed _$FeedFromJson(Map<String, dynamic> json) => _Feed(
  id: (json['id'] as num).toInt(),
  url: json['url'] as String,
  title: json['title'] as String,
  siteUrl: json['site_url'] as String?,
  iconUrl: json['icon_url'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$FeedToJson(_Feed instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'title': instance.title,
  'site_url': instance.siteUrl,
  'icon_url': instance.iconUrl,
  'description': instance.description,
};
