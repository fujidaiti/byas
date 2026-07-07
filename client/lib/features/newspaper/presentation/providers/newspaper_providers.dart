import 'package:flutter/foundation.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/core/pagination/page_result.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/features/newspaper/data/newspaper_repository_impl.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper_repository.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'newspaper_providers.g.dart';

@riverpod
NewspaperRepository newspaperRepository(Ref ref) =>
    NewspaperRepositoryImpl(ref.watch(dioProvider));

/// Today's issue: the header (from the first page) plus its stories accumulated
/// across pages.
@immutable
class TodayState {
  const TodayState({
    required this.id,
    required this.publishedAt,
    required this.stories,
  });

  final int id;
  final DateTime publishedAt;
  final PagedState<Story> stories;

  /// Same issue header with a different accumulated [stories] state.
  TodayState withStories(PagedState<Story> stories) =>
      TodayState(id: id, publishedAt: publishedAt, stories: stories);
}

/// Today's newspaper, with its stories paginated. [build] loads the first page;
/// [loadMore] appends the next page of stories while keeping the header.
@riverpod
class TodayNewspaper extends _$TodayNewspaper {
  @override
  Future<TodayState> build() async {
    final paper = await ref.watch(newspaperRepositoryProvider).getToday();
    return TodayState(
      id: paper.id,
      publishedAt: paper.publishedAt,
      stories: PagedState.first(_pageOf(paper)),
    );
  }

  /// Fetches the next page of stories and appends it, keeping the header.
  /// Mirrors [appendNextPage] but threads the story page through the
  /// [TodayState] envelope. No-ops when a fetch is in flight or there are no
  /// more stories.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.stories.hasMore ||
        current.stories.isLoadingMore) {
      return;
    }
    state = AsyncData(current.withStories(current.stories.loadingMore()));
    try {
      final paper = await ref
          .read(newspaperRepositoryProvider)
          .getToday(cursor: current.stories.nextCursor);
      // A refresh during the fetch clears isLoadingMore; drop the stale page.
      final latest = state.value;
      if (latest == null || !latest.stories.isLoadingMore) {
        return;
      }
      state = AsyncData(
        latest.withStories(latest.stories.append(_pageOf(paper))),
      );
    } on Object catch (error) {
      final latest = state.value;
      if (latest == null || !latest.stories.isLoadingMore) {
        return;
      }
      state = AsyncData(
        latest.withStories(latest.stories.loadMoreFailed(error)),
      );
    }
  }

  PageResult<Story> _pageOf(Newspaper paper) =>
      PageResult(items: paper.stories, nextCursor: paper.nextCursor);
}
