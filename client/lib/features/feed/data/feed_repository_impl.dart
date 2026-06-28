import 'package:dio/dio.dart';

import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/domain/feed_candidate.dart';
import 'package:paperdoll/features/feed/domain/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Feed>> listFeeds({String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/feeds');
      return _listFrom(res.data!, 'feeds', Feed.fromJson);
    });
  }

  @override
  Future<List<FeedCandidate>> search(String query) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/feeds/search',
        queryParameters: {'q': query},
      );
      return _listFrom(res.data!, 'feeds', FeedCandidate.fromJson);
    });
  }

  @override
  Future<Feed> subscribe(String url) {
    return runRequest(() async {
      final res = await _dio.put<Map<String, dynamic>>(
        '/feeds',
        data: {'url': url},
      );
      return Feed.fromJson(res.data!);
    });
  }

  @override
  Future<Feed> getFeed(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/feeds/$id');
      return Feed.fromJson(res.data!);
    });
  }

  @override
  Future<List<FeedEntry>> timeline(int id, {String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/feeds/$id/timeline');
      return _listFrom(res.data!, 'entries', FeedEntry.fromJson);
    });
  }

  List<T> _listFrom<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = json[key] as List<dynamic>;
    return items.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }
}
