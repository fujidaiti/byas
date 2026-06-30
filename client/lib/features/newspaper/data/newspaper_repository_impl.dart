import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;

import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper_repository.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';

class NewspaperRepositoryImpl implements NewspaperRepository {
  const NewspaperRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Newspaper> getToday() {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/newspapers/today');
      final body = api.GetTodaysNewspaper200Response.fromJson(res.data)!;
      return Newspaper(
        id: body.id,
        publishedAt: body.publishedAt,
        stories: body.stories
            .map(
              (s) => Story(
                id: s.id,
                title: s.title,
                description: s.description,
                source: s.source_,
                publishedAt: s.publishedAt,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<FeedEntry> getStory(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/newspapers/stories/$id',
      );
      final e = api.GetStory200Response.fromJson(res.data)!.data;
      return FeedEntry(
        id: e.id,
        feedId: e.feedId,
        url: e.url,
        title: e.title,
        description: e.description,
        content: e.content,
        publishedAt: e.publishedAt,
        snapshotAt: e.snapshotAt,
      );
    });
  }
}
