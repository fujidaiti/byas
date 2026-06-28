import 'package:paperdoll/features/entry/domain/feed_entry.dart';

/// Reads arbitrary feed entries by id.
abstract interface class EntryRepository {
  /// `GET /feed-entries/{id}` → the full entry, including `content`.
  Future<FeedEntry> getEntry(int id);
}
