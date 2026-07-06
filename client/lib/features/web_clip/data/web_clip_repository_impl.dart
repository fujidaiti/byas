import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip_repository.dart';

class WebClipRepositoryImpl implements WebClipRepository {
  const WebClipRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<WebClip> getWebClip(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/web-clips/$id');
      final a = api.GetWebClip200Response.fromJson(res.data)!;
      return WebClip(
        url: a.url,
        title: a.title,
        description: a.description,
        content: a.content,
        readingListItemId: a.readLater?.id,
        archived: a.readLater?.archived,
      );
    });
  }
}
