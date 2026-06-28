import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_entry.freezed.dart';
part 'feed_entry.g.dart';

/// A single item fetched from a feed. Shared payload of both the Story Reader
/// and the Entry Reader.
@freezed
abstract class FeedEntry with _$FeedEntry {
  const factory FeedEntry({
    required int id,
    required int feedId,
    required String url,
    required String title,
    String? description,
    String? content,
    DateTime? publishedAt,
    DateTime? snapshotAt,
  }) = _FeedEntry;

  factory FeedEntry.fromJson(Map<String, dynamic> json) =>
      _$FeedEntryFromJson(json);
}
