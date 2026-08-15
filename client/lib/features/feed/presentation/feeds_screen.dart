import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperdoll/core/pagination/infinite_scroll.dart';
import 'package:paperdoll/core/pagination/load_more_footer.dart';
import 'package:paperdoll/core/pagination/paged_state.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/scrollable_fill.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/providers/feed_providers.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_row.dart';

/// Feeds (Subscriptions) home: the list of subscribed feeds.
class const FeedsScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(feedsProvider);
    return Scaffold(
      key: AppDebugKey.feedsScreen,
      appBar: AppBar(
        actions: [
          IconButton(
            key: AppDebugKey.addFeedButton,
            tooltip: 'Add feed',
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed(routeFeedSearchName),
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
        onRefresh: () => ref.refresh(feedsProvider.future),
        child: AsyncValueView<PagedState<Feed>>(
          value: feedsAsync,
          onRetry: () => ref.invalidate(feedsProvider),
          data: (state) => _FeedsList(
            state: state,
            onLoadMore: () => ref.read(feedsProvider.notifier).loadMore(),
          ),
        ),
      ),
    );
  }
}

class const _FeedsList({
  required final PagedState<Feed> state,
  required final VoidCallback onLoadMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final feeds = state.items;
    if (feeds.isEmpty) {
      return ScrollableFill(
        child: EmptyPlaceholder(
          message: 'No feeds yet. Add one to get started.',
          actionLabel: 'Add feed',
          onAction: () => context.pushNamed(routeFeedSearchName),
        ),
      );
    }
    final showFooter = state.isLoadingMore || state.loadMoreError != null;
    return InfiniteScrollList(
      onEndReached: onLoadMore,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: feeds.length + (showFooter ? 1 : 0),
        separatorBuilder: (context, index) => const AppDivider(),
        itemBuilder: (context, index) {
          if (index >= feeds.length) {
            return LoadMoreFooter(
              isLoading: state.isLoadingMore,
              error: state.loadMoreError,
              onRetry: onLoadMore,
            );
          }
          final feed = feeds[index];
          return FeedRow(
            key: AppDebugKey.feedRow(feed.title),
            feed: feed,
            onTap: () => context.pushNamed(
              routeFeedDetailName,
              pathParameters: {'id': feed.id.toString()},
            ),
          );
        },
      ),
    );
  }
}
