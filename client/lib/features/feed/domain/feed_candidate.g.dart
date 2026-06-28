// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedCandidate _$FeedCandidateFromJson(Map<String, dynamic> json) =>
    _FeedCandidate(
      url: json['url'] as String,
      title: json['title'] as String,
      siteUrl: json['site_url'] as String?,
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$FeedCandidateToJson(_FeedCandidate instance) =>
    <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'site_url': instance.siteUrl,
      'icon_url': instance.iconUrl,
      'description': instance.description,
    };
