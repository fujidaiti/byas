import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/feed_entry/data/feed_entry_repository_impl.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry_repository.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_entry_providers.g.dart';

@riverpod
FeedEntryRepository feedEntryRepository(Ref ref) =>
    FeedEntryRepositoryImpl(ref.watch(dioProvider));

/// Single source of truth for one feed entry in the reader. It loads the entry
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached entry optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.
@riverpod
class FeedEntryController extends _$FeedEntryController {
  late int _id;

  @override
  Future<FeedEntry> build({required int id}) {
    _id = id;
    return ref.watch(feedEntryRepositoryProvider).getFeedEntry(id);
  }

  /// Adds the entry to the reading list. Flips `saved` on immediately so the
  /// bookmark fills before the request completes; the created item's id lands
  /// once the server responds, which is when archiving becomes available.
  Future<void> save() async {
    final entry = state.asData?.value;
    if (entry == null || entry.saved) {
      return;
    }
    state = AsyncData(entry.copyWith(saved: true, archived: false));
    try {
      final item = await ref
          .read(readingListRepositoryProvider)
          .saveFeedEntry(_id);
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(current.copyWith(readingListItemId: item.id));
      }
    } on Exception {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(saved: false, readingListItemId: null),
        );
      }
      rethrow;
    }
  }

  /// Removes the entry from the reading list, clearing its item id and archived
  /// flag optimistically.
  Future<void> remove() async {
    final entry = state.asData?.value;
    final itemId = entry?.readingListItemId;
    if (entry == null || itemId == null) {
      return;
    }
    state = AsyncData(
      entry.copyWith(saved: false, readingListItemId: null, archived: false),
    );
    try {
      await ref.read(readingListRepositoryProvider).removeItem(itemId);
    } on Exception {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(saved: true, readingListItemId: itemId),
        );
      }
      rethrow;
    }
  }

  /// Archives the entry, hiding it from the reading list.
  Future<void> archive() async {
    final entry = state.asData?.value;
    final itemId = entry?.readingListItemId;
    if (entry == null || itemId == null) {
      return;
    }
    state = AsyncData(entry.copyWith(archived: true));
    try {
      await ref.read(readingListRepositoryProvider).archive(itemId);
    } on Exception {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(current.copyWith(archived: false));
      }
      rethrow;
    }
  }

  /// Unarchives the entry, returning it to the reading list.
  Future<void> unarchive() async {
    final entry = state.asData?.value;
    final itemId = entry?.readingListItemId;
    if (entry == null || itemId == null) {
      return;
    }
    state = AsyncData(entry.copyWith(archived: false));
    try {
      await ref.read(readingListRepositoryProvider).unarchive(itemId);
    } on Exception {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(current.copyWith(archived: true));
      }
      rethrow;
    }
  }
}
