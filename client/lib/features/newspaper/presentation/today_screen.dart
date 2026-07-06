import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
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
        child: AsyncValueView<Newspaper>(
          value: newspaperAsync,
          onRetry: () => ref.invalidate(todayNewspaperProvider),
          data: (newspaper) => _NewspaperView(newspaper: newspaper),
        ),
      ),
    );
  }
}

class _NewspaperView extends StatelessWidget {
  const _NewspaperView({required this.newspaper});

  final Newspaper newspaper;

  @override
  Widget build(BuildContext context) {
    final stories = newspaper.stories;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
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
      ],
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
