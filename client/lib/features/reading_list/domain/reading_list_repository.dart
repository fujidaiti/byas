import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';

/// Reads the saved reading list.
///
/// The list method takes an optional `cursor` now so pagination can be added
/// later without breaking callers (the server already flags this as paginated).
abstract interface class ReadingListRepository {
  /// `GET /reading-list` → the saved, unarchived items, newest first.
  Future<List<ReadingListItem>> list({String? cursor});
}
