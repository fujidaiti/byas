import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/web_clip/data/web_clip_repository_impl.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'web_clip_providers.g.dart';

@riverpod
WebClipRepository webClipRepository(Ref ref) =>
    WebClipRepositoryImpl(ref.watch(dioProvider));

/// Single source of truth for one web clip in the reader. It loads the clip
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached clip optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.
@riverpod
class WebClipController extends _$WebClipController {
  late int _id;

  @override
  Future<WebClip> build({required int id}) {
    _id = id;
    return ref.watch(webClipRepositoryProvider).getWebClip(id);
  }

  /// Adds the clip to the reading list. Flips `saved` on immediately so the
  /// bookmark fills before the request completes; the created item's id lands
  /// once the server responds, which is when archiving becomes available.
  Future<void> save() async {
    final clip = state.asData?.value;
    if (clip == null || clip.saved) {
      return;
    }
    state = AsyncData(clip.copyWith(saved: true, archived: false));
    try {
      final item = await ref
          .read(readingListRepositoryProvider)
          .saveWebClip(_id);
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

  /// Removes the clip from the reading list, clearing its item id and archived
  /// flag optimistically.
  Future<void> remove() async {
    final clip = state.asData?.value;
    final itemId = clip?.readingListItemId;
    if (clip == null || itemId == null) {
      return;
    }
    state = AsyncData(
      clip.copyWith(saved: false, readingListItemId: null, archived: false),
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

  /// Archives the clip, hiding it from the reading list.
  Future<void> archive() async {
    final clip = state.asData?.value;
    final itemId = clip?.readingListItemId;
    if (clip == null || itemId == null) {
      return;
    }
    state = AsyncData(clip.copyWith(archived: true));
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

  /// Unarchives the clip, returning it to the reading list.
  Future<void> unarchive() async {
    final clip = state.asData?.value;
    final itemId = clip?.readingListItemId;
    if (clip == null || itemId == null) {
      return;
    }
    state = AsyncData(clip.copyWith(archived: false));
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
