import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/pagination/infinite_scroll.dart';
import 'package:paperdoll/core/pagination/load_more_footer.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/scrollable_fill.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/reading_list/presentation/widgets/reading_list_row.dart';

/// The archived reading list: previously archived items, newest first. Unlike
/// the reading list, rows have no swipe actions; tapping opens the reader.
class const ArchivedReadingListScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(archivedReadingListProvider);
    return Scaffold(
      key: AppDebugKey.archivedReadingListScreen,
      appBar: AppBar(title: const Text('Archived')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(archivedReadingListProvider.future),
        child: AsyncValueView<PagedState<ReadingListItem>>(
          value: itemsAsync,
          onRetry: () => ref.invalidate(archivedReadingListProvider),
          data: (state) => _ArchivedList(state: state),
        ),
      ),
    );
  }
}

class const _ArchivedList({required final PagedState<ReadingListItem> state})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.items;
    if (items.isEmpty) {
      return const ScrollableFill(
        child: EmptyPlaceholder(message: 'No archived items.'),
      );
    }
    final showFooter = state.isLoadingMore || state.loadMoreError != null;
    return InfiniteScrollList(
      onEndReached: () =>
          ref.read(archivedReadingListProvider.notifier).loadMore(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showFooter ? 1 : 0),
        separatorBuilder: (context, index) => const AppDivider(),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return LoadMoreFooter(
              isLoading: state.isLoadingMore,
              error: state.loadMoreError,
              onRetry: () =>
                  ref.read(archivedReadingListProvider.notifier).loadMore(),
            );
          }
          return ReadingListRow(item: items[index]);
        },
      ),
    );
  }
}
