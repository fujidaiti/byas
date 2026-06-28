import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed.freezed.dart';
part 'feed.g.dart';

/// A subscribed RSS source.
@freezed
abstract class Feed with _$Feed {
  const factory Feed({
    required int id,
    required String url,
    required String title,
    String? siteUrl,
    String? iconUrl,
    String? description,
  }) = _Feed;

  factory Feed.fromJson(Map<String, dynamic> json) => _$FeedFromJson(json);
}
