import 'package:dio/dio.dart';

import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/entry/domain/entry_repository.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';

class EntryRepositoryImpl implements EntryRepository {
  const EntryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<FeedEntry> getEntry(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/feed-entries/$id');
      return FeedEntry.fromJson(res.data!);
    });
  }
}
