import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';

/// Reads the saved reading list.
///
/// The list method takes an optional `cursor` now so pagination can be added
/// later without breaking callers (the server already flags this as paginated).
abstract interface class ReadingListRepository {
  /// `GET /reading-list` → the saved, unarchived items, newest first.
  Future<List<ReadingListItem>> list({String? cursor});

  /// `POST /reading-list` with `{"feed_entry_id": id}` → saves the feed entry
  /// and returns the created reading list item.
  Future<ReadingListItem> saveFeedEntry(int feedEntryId);

  /// `POST /reading-list` with `{"web_clip_id": id}` → re-saves an existing
  /// web clip (e.g. one just unsaved from the reader) and returns the
  /// created reading list item.
  Future<ReadingListItem> saveWebClip(int webClipId);

  /// `DELETE /reading-list/{id}` → removes the item from the reading list.
  Future<void> removeItem(int id);

  /// `PATCH /reading-list/{id}` with `{"archived": true}` → archives the item.
  Future<void> archive(int id);

  /// `PATCH /reading-list/{id}` with `{"archived": false}` → unarchives the item.
  Future<void> unarchive(int id);
}
