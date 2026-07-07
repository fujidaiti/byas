import 'package:dio/dio.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/core/network/request_runner.dart';
import 'package:paperdoll/core/pagination/page_result.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_repository.dart';

class ReadingListRepositoryImpl implements ReadingListRepository {
  const ReadingListRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<ReadingListItem>> list({String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reading-list',
        queryParameters: cursor != null ? {'after': cursor} : null,
      );
      final body = api.GetReadingList200Response.fromJson(res.data)!;
      return PageResult(
        items: body.items.map(_toItem).toList(),
        nextCursor: body.nextCursor,
      );
    });
  }

  @override
  Future<PageResult<ReadingListItem>> listArchived({String? cursor}) {
    return runRequest(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reading-list/archived',
        queryParameters: cursor != null ? {'after': cursor} : null,
      );
      final body = api.GetReadingList200Response.fromJson(res.data)!;
      return PageResult(
        items: body.items.map(_toItem).toList(),
        nextCursor: body.nextCursor,
      );
    });
  }

  @override
  Future<ReadingListItem> saveFeedEntry(int feedEntryId) {
    return runRequest(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/reading-list',
        data: api.SaveToReadingListRequestOneOf1(
          feedEntryId: feedEntryId,
        ).toJson(),
      );
      return _toItem(api.ReadingListItem.fromJson(res.data)!);
    });
  }

  @override
  Future<ReadingListItem> saveWebClip(int webClipId) {
    return runRequest(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/reading-list',
        data: api.SaveToReadingListRequestOneOf2(webClipId: webClipId).toJson(),
      );
      return _toItem(api.ReadingListItem.fromJson(res.data)!);
    });
  }

  @override
  Future<void> removeItem(int id) {
    return runRequest(() async {
      await _dio.delete<void>('/reading-list/$id');
    });
  }

  @override
  Future<void> archive(int id) => _setArchived(id, archived: true);

  @override
  Future<void> unarchive(int id) => _setArchived(id, archived: false);

  Future<void> _setArchived(int id, {required bool archived}) {
    return runRequest(() async {
      await _dio.patch<void>(
        '/reading-list/$id',
        data: api.SetReadingListItemArchivedStatusRequest(
          archived: archived,
        ).toJson(),
      );
    });
  }

  ReadingListItem _toItem(api.ReadingListItem i) => ReadingListItem(
    id: i.id,
    resourceId: i.resourceId,
    kind: _toKind(i.kind),
    title: i.title,
    savedAt: i.savedAt,
    description: i.description,
  );

  ReadingListItemKind _toKind(api.ReadingListItemKindEnum kind) =>
      switch (kind) {
        api.ReadingListItemKindEnum.webClip => ReadingListItemKind.webClip,
        api.ReadingListItemKindEnum.feedEntry => ReadingListItemKind.feedEntry,
        _ => ReadingListItemKind.webClip,
      };
}
