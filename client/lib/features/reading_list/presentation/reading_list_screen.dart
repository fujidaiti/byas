import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/pagination/infinite_scroll.dart';
import 'package:paperdoll/core/pagination/load_more_footer.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/tokens/app_text_styles.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/scrollable_fill.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/reading_list/presentation/widgets/reading_list_row.dart';

/// Reading list home: the saved, unarchived articles, newest first.
class const ReadingListScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(readingListProvider);
    return Scaffold(
      key: AppDebugKey.readingListScreen,
      appBar: AppBar(
        actions: [
          IconButton(
            key: AppDebugKey.archivedButton,
            tooltip: 'Archived',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => context.pushNamed(routeArchivedReadingListName),
          ),
          IconButton(
            key: AppDebugKey.settingsButton,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(routeSettingsName),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readingListProvider.future),
        child: AsyncValueView<PagedState<ReadingListItem>>(
          value: itemsAsync,
          onRetry: () => ref.invalidate(readingListProvider),
          data: (state) => _ReadingList(state: state),
        ),
      ),
    );
  }
}

class const _ReadingList({required final PagedState<ReadingListItem> state})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ReadingList> createState() => _ReadingListState();
}

class _ReadingListState extends ConsumerState<_ReadingList> {
  @override
  Widget build(BuildContext context) {
    final items = widget.state.items;
    if (items.isEmpty) {
      return const ScrollableFill(
        child: EmptyPlaceholder(message: 'Your reading list is empty.'),
      );
    }
    final showFooter =
        widget.state.isLoadingMore || widget.state.loadMoreError != null;
    return InfiniteScrollList(
      onEndReached: () => ref.read(readingListProvider.notifier).loadMore(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (showFooter ? 1 : 0),
        separatorBuilder: (context, index) => const AppDivider(),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return LoadMoreFooter(
              isLoading: widget.state.isLoadingMore,
              error: widget.state.loadMoreError,
              onRetry: () => ref.read(readingListProvider.notifier).loadMore(),
            );
          }
          final item = items[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.startToEnd,
            background: ColoredBox(
              color: colorAccent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: spacingMd),
                child: Row(
                  spacing: spacingSm,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.archive,
                      color: colorBackground,
                      size: iconSm,
                    ),
                    Text(
                      'Archive',
                      style: textLabel.copyWith(color: colorBackground),
                    ),
                  ],
                ),
              ),
            ),
            onDismissed: (_) => _archive(item, index),
            child: ReadingListRow(item: item),
          );
        },
      ),
    );
  }

  Future<void> _archive(ReadingListItem item, int index) async {
    // Optimistically update UI first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: AppDebugKey.archiveSuccessSnackBar,
        persist: false,
        content: Text(
          'Archived "${item.title}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _unarchive(item, index),
        ),
      ),
    );
    try {
      await ref.read(readingListProvider.notifier).archive(item);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }

  Future<void> _unarchive(ReadingListItem item, int index) async {
    try {
      await ref.read(readingListProvider.notifier).unarchive(item, index);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }
}
