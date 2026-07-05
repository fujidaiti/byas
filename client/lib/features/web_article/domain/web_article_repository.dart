import 'package:paperdoll/features/web_article/domain/web_article.dart';

/// Reads saved web articles by id.
abstract interface class WebArticleRepository {
  /// `GET /web-articles/{id}` → the article's url, title, and content.
  Future<WebArticle> getWebArticle(int id);
}
