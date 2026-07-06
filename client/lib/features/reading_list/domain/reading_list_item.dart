import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_list_item.freezed.dart';

/// The kind of a reading list item, which decides the reader it opens in.
enum ReadingListItemKind { webClip, feedEntry }

/// A saved article in the reading list.
@freezed
abstract class ReadingListItem with _$ReadingListItem {
  const factory ReadingListItem({
    required int id,
    required int resourceId,
    required ReadingListItemKind kind,
    required String title,
    required DateTime savedAt,
    String? description,
  }) = _ReadingListItem;
}
