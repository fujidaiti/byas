import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/web_article/data/web_article_repository_impl.dart';
import 'package:paperdoll/features/web_article/domain/web_article.dart';
import 'package:paperdoll/features/web_article/domain/web_article_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'web_article_providers.g.dart';

@riverpod
WebArticleRepository webArticleRepository(Ref ref) =>
    WebArticleRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<WebArticle> webArticle(Ref ref, {required int id}) =>
    ref.watch(webArticleRepositoryProvider).getWebArticle(id);
