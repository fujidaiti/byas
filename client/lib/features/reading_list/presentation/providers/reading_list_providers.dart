import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/features/reading_list/data/reading_list_repository_impl.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_list_providers.g.dart';

@riverpod
ReadingListRepository readingListRepository(Ref ref) =>
    ReadingListRepositoryImpl(ref.watch(dioProvider));

/// The archived reading list, paginated. [build] loads the first page;
/// [loadMore] appends the next. Read-only: the archived screen has no swipe
/// actions.
@riverpod
class ArchivedReadingList extends _$ArchivedReadingList {
  @override
  Future<PagedState<ReadingListItem>> build() async => PagedState.first(
    await ref.watch(readingListRepositoryProvider).listArchived(),
  );

  Future<void> loadMore() => appendNextPage(
    read: () => state,
    write: (next) => state = next,
    fetch: (cursor) =>
        ref.read(readingListRepositoryProvider).listArchived(cursor: cursor),
  );
}

/// The saved, unarchived reading list, paginated. [build] loads the first page;
/// [loadMore] appends the next.
@riverpod
class ReadingList extends _$ReadingList {
  @override
  Future<PagedState<ReadingListItem>> build() async =>
      PagedState.first(await ref.watch(readingListRepositoryProvider).list());

  Future<void> loadMore() => appendNextPage(
    read: () => state,
    write: (next) => state = next,
    fetch: (cursor) =>
        ref.read(readingListRepositoryProvider).list(cursor: cursor),
  );

  /// Optimistically removes [item] from the list, then archives it in the
  /// background. On failure, restores [item] at its original index and
  /// rethrows so the caller can show an error snackbar.
  Future<void> archive(ReadingListItem item) async {
    final current = (await future).items;
    final index = current.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return;
    }
    state = AsyncData(
      state.requireValue.copyWith(
        items: List<ReadingListItem>.of(current)..removeAt(index),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).archive(item.id);
    } catch (_) {
      final rollback = List<ReadingListItem>.of(state.value?.items ?? current);
      if (!rollback.any((i) => i.id == item.id)) {
        rollback.insert(index.clamp(0, rollback.length), item);
      }
      state = AsyncData(state.requireValue.copyWith(items: rollback));
      rethrow;
    }
  }

  /// Unarchives [item] in the background and, on success, restores it into
  /// the list at [index]. On failure, rethrows so the caller can show an
  /// error snackbar.
  Future<void> unarchive(ReadingListItem item, int index) async {
    await ref.read(readingListRepositoryProvider).unarchive(item.id);
    final restored = List<ReadingListItem>.of(state.value?.items ?? const []);
    if (!restored.any((i) => i.id == item.id)) {
      restored.insert(index.clamp(0, restored.length), item);
    }
    state = AsyncData(state.requireValue.copyWith(items: restored));
  }
}
