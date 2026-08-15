import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry_repository.dart';

class const FeedEntryRepositoryImpl(final Dio _dio)
    implements FeedEntryRepository {
  @override
  Future<FeedEntry> getFeedEntry(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/feed-entries/$id');
      final e = api.FeedEntry.fromJson(res.data)!;
      return FeedEntry(
        id: e.id,
        feedId: e.feedId,
        url: e.url,
        title: e.title,
        description: e.description,
        content: e.content,
        publishedAt: e.publishedAt,
        snapshotAt: e.snapshotAt,
        readingListItemId: e.readLater?.id,
        archived: e.readLater?.archived,
        saved: e.readLater != null,
      );
    });
  }
}
