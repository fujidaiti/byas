import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/reading_list/data/reading_list_repository_impl.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_list_providers.g.dart';

@riverpod
ReadingListRepository readingListRepository(Ref ref) =>
    ReadingListRepositoryImpl(ref.watch(dioProvider));

@riverpod
class ReadingList extends _$ReadingList {
  @override
  Future<List<ReadingListItem>> build({String? cursor}) =>
      ref.watch(readingListRepositoryProvider).list(cursor: cursor);

  /// Optimistically removes [item] from the list, then archives it in the
  /// background. On failure, restores [item] at its original index and
  /// rethrows so the caller can show an error snackbar.
  Future<void> archive(ReadingListItem item) async {
    final current = await future;
    final index = current.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return;
    }
    state = AsyncData(List<ReadingListItem>.of(current)..removeAt(index));
    try {
      await ref.read(readingListRepositoryProvider).archive(item.id);
    } catch (_) {
      final rollback = List<ReadingListItem>.of(state.value ?? current);
      if (!rollback.any((i) => i.id == item.id)) {
        rollback.insert(index.clamp(0, rollback.length), item);
      }
      state = AsyncData(rollback);
      rethrow;
    }
  }

  /// Unarchives [item] in the background and, on success, restores it into
  /// the list at [index]. On failure, rethrows so the caller can show an
  /// error snackbar.
  Future<void> unarchive(ReadingListItem item, int index) async {
    await ref.read(readingListRepositoryProvider).unarchive(item.id);
    final current = List<ReadingListItem>.of(
      state.value ?? const <ReadingListItem>[],
    );
    if (!current.any((i) => i.id == item.id)) {
      current.insert(index.clamp(0, current.length), item);
    }
    state = AsyncData(current);
  }
}
