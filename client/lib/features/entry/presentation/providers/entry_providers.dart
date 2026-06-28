import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/entry/data/entry_repository_impl.dart';
import 'package:paperdoll/features/entry/domain/entry_repository.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entry_providers.g.dart';

@riverpod
EntryRepository entryRepository(Ref ref) =>
    EntryRepositoryImpl(ref.watch(dioProvider));

@riverpod
Future<FeedEntry> entry(Ref ref, {required int id}) =>
    ref.watch(entryRepositoryProvider).getEntry(id);
