import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_entry.freezed.dart';

/// A single item fetched from a feed. Shared payload of both the Story Reader
/// and the Feed Entry Reader.
///
/// `saved` is whether the entry is in the reading list. It normally agrees with
/// `readingListItemId != null`, but the reader flips it on optimistically the
/// moment a save is tapped — before the server hands back the item id — so the
/// two diverge briefly during an in-flight save.
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
    int? readingListItemId,
    bool? archived,
    @Default(false) bool saved,
  }) = _FeedEntry;
}
