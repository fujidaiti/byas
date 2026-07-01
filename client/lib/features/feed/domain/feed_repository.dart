import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/domain/feed_candidate.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';

/// Manages feed subscriptions and reads feed timelines.
///
/// List methods take an optional `cursor` now so pagination can be added later
/// without breaking callers (the server already flags these as paginated).
abstract interface class FeedRepository {
  /// `GET /feeds` → the subscribed feeds.
  Future<List<Feed>> listFeeds({String? cursor});

  /// `GET /feeds/search?q=` → subscribable candidates.
  Future<List<FeedCandidate>> search(String query);

  /// `PUT /feeds` with `{ url }` → the subscribed feed (idempotent).
  Future<Feed> subscribe(String url);

  /// `GET /feeds/{id}` → the feed header.
  Future<Feed> getFeed(int id);

  /// `GET /feeds/{id}/timeline` → the feed's full stream of entries.
  Future<List<FeedEntry>> timeline(int id, {String? cursor});
}
