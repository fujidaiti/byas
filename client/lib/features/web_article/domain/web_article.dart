import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_article.freezed.dart';

/// A saved web article's details, the payload of the Web Article Reader.
///
/// `content` is the fetched HTML body; it is null while the fetch is still
/// pending or has failed.
@freezed
abstract class WebArticle with _$WebArticle {
  const factory WebArticle({
    required String url,
    String? title,
    String? description,
    String? content,
    int? readingListItemId,
  }) = _WebArticle;
}
