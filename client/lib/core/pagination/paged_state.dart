import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/pagination/page_result.dart';

/// Accumulated state of a paginated list across the pages fetched so far. This
/// is what a paginating notifier carries inside its [AsyncValue].
///
/// [items] is every row loaded so far; [nextCursor] points at the next page
/// ([hasMore] is false once the server stops returning one). [isLoadingMore]
/// and [loadMoreError] describe the *next-page* fetch only — the first page's
/// loading/error surfaces through the enclosing [AsyncValue].
@immutable
class PagedState<T> {
  const new({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// Seeds accumulated state from the first [page].
  new first(PageResult<T> page)
    : items = page.items,
      nextCursor = page.nextCursor,
      isLoadingMore = false,
      loadMoreError = null;

  final List<T> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;

  PagedState<T> copyWith({
    List<T>? items,
    String? nextCursor,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  /// Marks the start of a next-page fetch, clearing any prior failure.
  PagedState<T> loadingMore() =>
      copyWith(isLoadingMore: true, clearLoadMoreError: true);

  /// Appends a freshly fetched [page] and clears the loading flag. Builds a
  /// fresh instance (rather than [copyWith]) so a null [PageResult.nextCursor]
  /// correctly ends pagination.
  PagedState<T> append(PageResult<T> page) => PagedState<T>(
    items: [...items, ...page.items],
    nextCursor: page.nextCursor,
  );

  /// Records a next-page fetch failure.
  PagedState<T> loadMoreFailed(Object error) =>
      copyWith(isLoadingMore: false, loadMoreError: error);
}

/// Drives one next-page fetch for a notifier whose state is
/// `AsyncValue<PagedState<T>>`. Reads the current state, no-ops when there is
/// nothing more to load or a fetch is already in flight, flips the loading
/// flag, then appends the page (or records the error). Guards against a
/// concurrent refresh resetting the list mid-fetch.
Future<void> appendNextPage<T>({
  required AsyncValue<PagedState<T>> Function() read,
  required void Function(AsyncValue<PagedState<T>> next) write,
  required Future<PageResult<T>> Function(String? cursor) fetch,
}) async {
  final current = read().value;
  if (current == null || !current.hasMore || current.isLoadingMore) {
    return;
  }
  write(AsyncData(current.loadingMore()));
  try {
    final page = await fetch(current.nextCursor);
    final latest = read().value;
    // A refresh during the fetch clears isLoadingMore; drop the stale page.
    if (latest == null || !latest.isLoadingMore) {
      return;
    }
    write(AsyncData(latest.append(page)));
  } on Object catch (error) {
    final latest = read().value;
    if (latest == null || !latest.isLoadingMore) {
      return;
    }
    write(AsyncData(latest.loadMoreFailed(error)));
  }
}
