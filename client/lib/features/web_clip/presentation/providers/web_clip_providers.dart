import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/web_clip/data/web_clip_repository_impl.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'web_clip_providers.g.dart';

@riverpod
WebClipRepository webClipRepository(Ref ref) =>
    WebClipRepositoryImpl(ref.watch(dioProvider));

/// Loads a web clip for the reader and holds it as mutable state so the reader
/// can reflect an archive/unarchive toggle optimistically, without refetching.
@riverpod
class WebClipController extends _$WebClipController {
  @override
  Future<WebClip> build({required int id}) =>
      ref.watch(webClipRepositoryProvider).getWebClip(id);

  /// Patches the cached clip's archived flag so widgets watching this provider
  /// update instantly. The reading-list request is fired by the caller, which
  /// flips this back if the request fails.
  void setArchived(bool archived) {
    final clip = state.asData?.value;
    if (clip == null) {
      return;
    }
    state = AsyncData(clip.copyWith(archived: archived));
  }
}
