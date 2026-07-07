import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/feed_entry/data/feed_entry_repository_impl.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_entry_providers.g.dart';

@riverpod
FeedEntryRepository feedEntryRepository(Ref ref) =>
    FeedEntryRepositoryImpl(ref.watch(dioProvider));

/// Loads a feed entry for the reader and holds it as mutable state so the
/// reader can reflect an archive/unarchive toggle optimistically, without
/// refetching.
@riverpod
class FeedEntryController extends _$FeedEntryController {
  @override
  Future<FeedEntry> build({required int id}) =>
      ref.watch(feedEntryRepositoryProvider).getFeedEntry(id);

  /// Patches the cached entry's archived flag so widgets watching this provider
  /// update instantly. The reading-list request is fired by the caller, which
  /// flips this back if the request fails.
  void setArchived(bool archived) {
    final entry = state.asData?.value;
    if (entry == null) {
      return;
    }
    state = AsyncData(entry.copyWith(archived: archived));
  }
}
