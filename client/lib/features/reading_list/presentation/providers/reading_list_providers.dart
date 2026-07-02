import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/reading_list/data/reading_list_repository_impl.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_repository.dart';
import 'package:paperdoll/features/reading_list/domain/web_article.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_list_providers.g.dart';

@riverpod
ReadingListRepository readingListRepository(Ref ref) =>
    ReadingListRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<List<ReadingListItem>> readingList(Ref ref, {String? cursor}) =>
    ref.watch(readingListRepositoryProvider).list(cursor: cursor);

@riverpod
Future<WebArticle> webArticle(Ref ref, {required int id}) =>
    ref.watch(readingListRepositoryProvider).getWebArticle(id);
