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

class _FeedDetailBody extends StatefulWidget {
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
  State<_FeedDetailBody> createState() => _FeedDetailBodyState();
}

class _FeedDetailBodyState extends State<_FeedDetailBody> {
  final GlobalKey _titleKey = GlobalKey();
  var _showTitle = false;

  bool _onScroll(ScrollNotification notification) {
    final titleContext = _titleKey.currentContext;
    if (titleContext == null) {
      return false;
    }
    final box = titleContext.findRenderObject() as RenderBox?;
    if (box == null) {
      return false;
    }
    // The big title's bottom edge in global coordinates; once it scrolls above
    // the top of the app bar, reveal the app bar title.
    final titleBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final appBarBottom = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final shouldShow = titleBottom <= appBarBottom;
    if (shouldShow != _showTitle) {
      setState(() => _showTitle = shouldShow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: AnimatedOpacity(
              opacity: _showTitle ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                widget.feed.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                FeedHeader(feed: widget.feed, titleKey: _titleKey),
                const AppDivider(),
              ],
            ),
          ),
          widget.timeline.when(
            data: _buildTimeline,
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingIndicator(),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorPlaceholder(
                message: describeError(error),
                onRetry: widget.onRetryTimeline,
              ),
            ),
          ),
        ],
      ),
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
          entry: entry,
          onTap: () => widget.onOpenEntry(entry.id),
        );
      },
    );
  }
}
