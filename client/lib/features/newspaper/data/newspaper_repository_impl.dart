import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;

import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper_repository.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';

class NewspaperRepositoryImpl implements NewspaperRepository {
  const NewspaperRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Newspaper> getToday({String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/newspapers/today',
        queryParameters: cursor != null ? {'after': cursor} : null,
      );
      final body = api.GetTodaysNewspaper200Response.fromJson(res.data)!;
      return Newspaper(
        id: body.id,
        publishedAt: body.publishedAt,
        stories: body.stories
            .map(
              (s) => Story(
                id: s.id,
                resourceId: s.resourceId,
                kind: _toKind(s.kind),
                title: s.title,
                description: s.description,
                source: s.source_,
                publishedAt: s.publishedAt,
                readingListItemId: s.readingListItemId,
              ),
            )
            .toList(),
        nextCursor: body.nextCursor,
      );
    });
  }

  StoryKind _toKind(api.StoryKindEnum kind) => switch (kind) {
    api.StoryKindEnum.webClip => StoryKind.webClip,
    api.StoryKindEnum.feedEntry => StoryKind.feedEntry,
    _ => StoryKind.feedEntry,
  };
}
