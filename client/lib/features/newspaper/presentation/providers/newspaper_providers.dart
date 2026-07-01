import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/newspaper/data/newspaper_repository_impl.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'newspaper_providers.g.dart';

@riverpod
NewspaperRepository newspaperRepository(Ref ref) =>
    NewspaperRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<Newspaper> todayNewspaper(Ref ref) =>
    ref.watch(newspaperRepositoryProvider).getToday();

@riverpod
Future<FeedEntry> story(Ref ref, {required int id}) =>
    ref.watch(newspaperRepositoryProvider).getStory(id);
