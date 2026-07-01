import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/error_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_row.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/providers/feed_providers.dart';

/// Feed Detail (Timeline): a feed's header and its full stream of entries.
class FeedDetailScreen extends ConsumerWidget {
  const FeedDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedDetailProvider(id: id));
    final timelineAsync = ref.watch(feedTimelineProvider(id: id));
    return Scaffold(
      key: AppDebugKey.feedDetailScreen,
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          centerTitle: false,
          title: BodyText(feed.title),
        ),
        SliverToBoxAdapter(child: _FeedDetails(feed: feed)),
        timeline.when(
          data: _buildTimeline,
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingIndicator(),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorPlaceholder(
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
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyPlaceholder(message: 'No entries yet.'),
      );
    }
    return SliverList.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return EntryRow(
          key: AppDebugKey.entryRow(entry.title),
          entry: entry,
          onTap: () => onOpenEntry(entry.id),
        );
      },
    );
  }
}

/// The feed's description and a link to its site, shown below the app bar.
class _FeedDetails extends StatelessWidget {
  const _FeedDetails({required this.feed});

  final Feed feed;

  @override
  Widget build(BuildContext context) {
    final description = feed.description;
    final siteUrl = feed.siteUrl;
    if (description == null && siteUrl == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) BodyText(description),
          if (siteUrl != null) ...[
            if (description != null) const Gap(spacingSm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => unawaited(openExternalLink(context, siteUrl)),
                icon: const Icon(Icons.public),
                label: const Text('Visit site'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
