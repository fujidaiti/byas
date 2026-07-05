import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/web_article/domain/web_article.dart';
import 'package:paperdoll/features/web_article/domain/web_article_repository.dart';

class WebArticleRepositoryImpl implements WebArticleRepository {
  const WebArticleRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<WebArticle> getWebArticle(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/web-articles/$id');
      final a = api.GetWebArticle200Response.fromJson(res.data)!;
      return WebArticle(
        url: a.url,
        title: a.title,
        description: a.description,
        content: a.content,
      );
    });
  }
}
