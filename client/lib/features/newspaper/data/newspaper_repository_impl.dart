import 'package:dio/dio.dart';

import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/newspaper/data/dtos/story_envelope_dto.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper_repository.dart';

class NewspaperRepositoryImpl implements NewspaperRepository {
  const NewspaperRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Newspaper> getToday() {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/newspapers/today');
      return Newspaper.fromJson(res.data!);
    });
  }

  @override
  Future<FeedEntry> getStory(int id) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/newspapers/stories/$id',
      );
      return StoryEnvelopeDto.fromJson(res.data!).data;
    });
  }
}
