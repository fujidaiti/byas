import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_list_item.freezed.dart';

/// A saved article in the reading list.
@freezed
abstract class ReadingListItem with _$ReadingListItem {
  const factory ReadingListItem({
    required int id,
    required String title,
    required DateTime savedAt,
    String? description,
  }) = _ReadingListItem;
}
