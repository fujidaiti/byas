import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_repository.dart';

class ReadingListRepositoryImpl implements ReadingListRepository {
  const ReadingListRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ReadingListItem>> list({String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>('/reading-list');
      final body = api.GetReadingList200Response.fromJson(res.data)!;
      return body.items.map(_toItem).toList();
    });
  }

  ReadingListItem _toItem(api.ReadingListItem i) => ReadingListItem(
    id: i.id,
    title: i.title,
    savedAt: i.savedAt,
    description: i.description,
  );
}
