import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/providers/feed_providers.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_row.dart';
import 'package:paperdoll/test_keys.dart';

/// Feeds (Subscriptions) home: the list of subscribed feeds.
class FeedsScreen extends ConsumerWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(feedsProvider());
    return Scaffold(
      key: AppTestKeys.feedsScreen,
      appBar: AppBar(
        actions: [
          IconButton(
            key: AppTestKeys.addFeedButton,
            tooltip: 'Add feed',
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed(routeFeedSearchName),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(feedsProvider().future),
        child: AsyncValueView<List<Feed>>(
          value: feedsAsync,
          onRetry: () => ref.invalidate(feedsProvider()),
          data: (feeds) => _FeedsList(feeds: feeds),
        ),
      ),
    );
  }
}

class _FeedsList extends StatelessWidget {
  const _FeedsList({required this.feeds});

  final List<Feed> feeds;

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) {
      return EmptyPlaceholder(
        message: 'No feeds yet. Add one to get started.',
        actionLabel: 'Add feed',
        onAction: () => context.pushNamed(routeFeedSearchName),
      );
    }
    return ListView.separated(
      itemCount: feeds.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) {
        final feed = feeds[index];
        return FeedRow(
          key: AppTestKeys.feedRow(feed.title),
          feed: feed,
          onTap: () => context.pushNamed(
            routeFeedDetailName,
            pathParameters: {'id': feed.id.toString()},
          ),
        );
      },
    );
  }
}
