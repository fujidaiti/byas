import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/web_clip/data/web_clip_repository_impl.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'web_clip_providers.g.dart';

@riverpod
WebClipRepository webClipRepository(Ref ref) =>
    WebClipRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<WebClip> webClip(Ref ref, {required int id}) =>
    ref.watch(webClipRepositoryProvider).getWebClip(id);
