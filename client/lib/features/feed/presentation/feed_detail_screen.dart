import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/error_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_row.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/providers/feed_providers.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_header.dart';

/// Feed Detail (Timeline): a feed's header and its full stream of entries.
class FeedDetailScreen extends ConsumerWidget {
  const FeedDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedDetailProvider(id: id));
    final timelineAsync = ref.watch(feedTimelineProvider(id: id));
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(feedDetailProvider(id: id));
          return ref.refresh(feedTimelineProvider(id: id).future);
        },
        child: AsyncValueView<Feed>(
          value: feedAsync,
          onRetry: () => ref.invalidate(feedDetailProvider(id: id)),
          data: (feed) => _FeedDetailBody(
            feed: feed,
            timeline: timelineAsync,
            onRetryTimeline: () => ref.invalidate(feedTimelineProvider(id: id)),
            onOpenEntry: (entryId) => context.pushNamed(
              routeEntryReaderName,
              pathParameters: {
                'id': id.toString(),
                'entryId': entryId.toString(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedDetailBody extends StatelessWidget {
  const _FeedDetailBody({
    required this.feed,
    required this.timeline,
    required this.onRetryTimeline,
    required this.onOpenEntry,
  });

  final Feed feed;
  final AsyncValue<List<FeedEntry>> timeline;
  final VoidCallback onRetryTimeline;
  final void Function(int entryId) onOpenEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FeedHeader(feed: feed),
        const AppDivider(),
        Expanded(
          child: timeline.when(
            data: _buildTimeline,
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorPlaceholder(
              message: describeError(error),
              onRetry: onRetryTimeline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<FeedEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyPlaceholder(message: 'No entries yet.');
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return EntryRow(entry: entry, onTap: () => onOpenEntry(entry.id));
      },
    );
  }
}
