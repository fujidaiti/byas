import 'dart:async';

import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/features/feed/data/feed_repository_impl.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/domain/feed_candidate.dart';
import 'package:paperdoll/features/feed/domain/feed_repository.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_providers.g.dart';

@riverpod
FeedRepository feedRepository(Ref ref) =>
    FeedRepositoryImpl(ref.watch(dioProvider));

/// The subscribed feeds, paginated. [build] loads the first page; [loadMore]
/// appends the next.
@riverpod
class Feeds extends _$Feeds {
  @override
  Future<PagedState<Feed>> build() async =>
      PagedState.first(await ref.watch(feedRepositoryProvider).listFeeds());

  Future<void> loadMore() => appendNextPage(
    read: () => state,
    write: (next) => state = next,
    fetch: (cursor) =>
        ref.read(feedRepositoryProvider).listFeeds(cursor: cursor),
  );
}

@riverpod
Future<Feed> feedDetail(Ref ref, {required int id}) =>
    ref.watch(feedRepositoryProvider).getFeed(id);

/// A feed's timeline entries, paginated. [build] loads the first page;
/// [loadMore] appends the next.
@riverpod
class FeedTimeline extends _$FeedTimeline {
  @override
  Future<PagedState<FeedEntry>> build({required int id}) async =>
      PagedState.first(await ref.watch(feedRepositoryProvider).timeline(id));

  Future<void> loadMore() => appendNextPage(
    read: () => state,
    write: (next) => state = next,
    fetch: (cursor) =>
        ref.read(feedRepositoryProvider).timeline(id, cursor: cursor),
  );
}

/// Drives the Feed Search / Subscribe screen. [search] populates the candidate
/// list; [subscribe] adds a feed and refreshes the Feeds list.
@riverpod
class FeedSearchController extends _$FeedSearchController {
  @override
  FutureOr<List<FeedCandidate>> build() => const [];

  Future<void> search(String query) async {
    state = const AsyncLoading<List<FeedCandidate>>();
    state = await AsyncValue.guard(
      () => ref.read(feedRepositoryProvider).search(query),
    );
  }

  /// Subscribes to the given url. Throws a domain error on failure so the
  /// caller can surface a snackbar; on success the Feeds list is invalidated.
  Future<void> subscribe(String url) async {
    await ref.read(feedRepositoryProvider).subscribe(url);
    ref.invalidate(feedsProvider);
  }
}
