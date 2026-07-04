import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/web_article.dart';

/// Reads the saved reading list.
///
/// The list method takes an optional `cursor` now so pagination can be added
/// later without breaking callers (the server already flags this as paginated).
abstract interface class ReadingListRepository {
  /// `GET /reading-list` → the saved, unarchived items, newest first.
  Future<List<ReadingListItem>> list({String? cursor});

  /// `GET /reading-list/{id}` → a single web_article item's details.
  Future<WebArticle> getWebArticle(int id);

  /// `PATCH /reading-list/{id}` with `{"archived": true}` → archives the item.
  Future<void> archive(int id);

  /// `PATCH /reading-list/{id}` with `{"archived": false}` → unarchives the item.
  Future<void> unarchive(int id);
}
