import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';

/// Reads the daily newspaper and the entries backing its stories.
abstract interface class NewspaperRepository {
  /// `GET /newspapers/today`. Throws a not-found error when no issue exists.
  Future<Newspaper> getToday();

  /// `GET /newspapers/stories/{id}` → the backing feed entry (envelope
  /// `{type, data}` is unwrapped by the implementation).
  Future<FeedEntry> getStory(int id);
}
