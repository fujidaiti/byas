import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/pagination/infinite_scroll.dart';
import 'package:paperdoll/core/pagination/load_more_footer.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';
import 'package:paperdoll/features/newspaper/presentation/providers/newspaper_providers.dart';
import 'package:paperdoll/features/newspaper/presentation/widgets/story_card.dart';

/// Today (Newspaper) home: the latest issue and its stories.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newspaperAsync = ref.watch(todayNewspaperProvider);
    return Scaffold(
      key: AppDebugKey.todayScreen,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(todayNewspaperProvider.future),
        child: AsyncValueView<TodayState>(
          value: newspaperAsync,
          onRetry: () => ref.invalidate(todayNewspaperProvider),
          data: (newspaper) => _NewspaperView(
            newspaper: newspaper,
            onLoadMore: () =>
                ref.read(todayNewspaperProvider.notifier).loadMore(),
          ),
        ),
      ),
    );
  }
}

class _NewspaperView extends StatelessWidget {
  const _NewspaperView({required this.newspaper, required this.onLoadMore});

  final TodayState newspaper;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final page = newspaper.stories;
    final stories = page.items;
    final showFooter = page.isLoadingMore || page.loadMoreError != null;
    return InfiniteScrollList(
      onEndReached: onLoadMore,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            actions: [
              IconButton(
                key: AppDebugKey.settingsButton,
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.pushNamed(routeSettingsName),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(
                start: spacingMd,
                bottom: spacingSm,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CaptionText('Daily edition'),
                  HeadingText(formatDate(newspaper.publishedAt)),
                ],
              ),
            ),
          ),
          if (stories.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyPlaceholder(message: 'No stories yet today.'),
            )
          else
            SliverList.separated(
              itemCount: stories.length,
              separatorBuilder: (context, index) => const AppDivider(),
              itemBuilder: (context, index) {
                final story = stories[index];
                return StoryCard(
                  key: AppDebugKey.storyCard(story.title),
                  story: story,
                  onTap: () => _openStory(context, story),
                );
              },
            ),
          if (showFooter)
            SliverToBoxAdapter(
              child: LoadMoreFooter(
                isLoading: page.isLoadingMore,
                error: page.loadMoreError,
                onRetry: onLoadMore,
              ),
            ),
        ],
      ),
    );
  }

  void _openStory(BuildContext context, Story story) {
    switch (story.kind) {
      case StoryKind.feedEntry:
        unawaited(
          context.pushNamed(
            routeTodayFeedEntryReaderName,
            pathParameters: {'feedEntryId': '${story.resourceId}'},
          ),
        );
      case StoryKind.webClip:
        throw UnimplementedError(
          'Web-clip-backed stories are not supported yet.',
        );
    }
  }
}
