import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/pagination/infinite_scroll.dart';
import 'package:paperdoll/core/pagination/load_more_footer.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/error_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/ui/widgets/loading_indicator.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';
import 'package:paperdoll/features/newspaper/presentation/providers/newspaper_providers.dart';
import 'package:paperdoll/features/newspaper/presentation/widgets/story_card.dart';

/// Today (Newspaper) home: the latest issue and its stories.
///
/// The settings action lives in the always-present [_TodayAppBar] sliver
/// rather than behind the newspaper's [AsyncValue] state, so it stays
/// reachable (e.g. to sign out) even while the newspaper is loading or failed
/// to load — mirroring how Feeds/Reading List keep settings in a persistent
/// Scaffold.appBar.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newspaperAsync = ref.watch(todayNewspaperProvider);
    void loadMore() => ref.read(todayNewspaperProvider.notifier).loadMore();
    return Scaffold(
      key: AppDebugKey.todayScreen,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(todayNewspaperProvider.future),
        child: InfiniteScrollList(
          onEndReached: loadMore,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _TodayAppBar(publishedAt: newspaperAsync.value?.publishedAt),
              ...newspaperAsync.when(
                data: (newspaper) => _storySlivers(newspaper, loadMore),
                loading: () => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingIndicator(),
                  ),
                ],
                error: (error, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorPlaceholder(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(todayNewspaperProvider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayAppBar extends StatelessWidget {
  const _TodayAppBar({required this.publishedAt});

  final DateTime? publishedAt;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
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
            if (publishedAt != null) HeadingText(formatDate(publishedAt!)),
          ],
        ),
      ),
    );
  }
}

List<Widget> _storySlivers(TodayState newspaper, VoidCallback onLoadMore) {
  final page = newspaper.stories;
  final stories = page.items;
  final showFooter = page.isLoadingMore || page.loadMoreError != null;
  return [
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
  ];
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
