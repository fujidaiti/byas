import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';

/// Reads arbitrary feed entries by id.
abstract interface class FeedEntryRepository {
  /// `GET /feed-entries/{id}` → the full entry, including `content`.
  Future<FeedEntry> getFeedEntry(int id);
}
