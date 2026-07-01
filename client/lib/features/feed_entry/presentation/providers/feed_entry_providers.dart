import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/feed_entry/data/feed_entry_repository_impl.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_entry_providers.g.dart';

@riverpod
FeedEntryRepository feedEntryRepository(Ref ref) =>
    FeedEntryRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<FeedEntry> feedEntry(Ref ref, {required int id}) =>
    ref.watch(feedEntryRepositoryProvider).getFeedEntry(id);
