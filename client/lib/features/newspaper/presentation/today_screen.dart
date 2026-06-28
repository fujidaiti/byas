import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/features/newspaper/domain/newspaper.dart';
import 'package:paperdoll/features/newspaper/presentation/providers/newspaper_providers.dart';
import 'package:paperdoll/features/newspaper/presentation/widgets/issue_header.dart';
import 'package:paperdoll/features/newspaper/presentation/widgets/story_card.dart';

/// Today (Newspaper) home: the latest issue and its stories.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newspaperAsync = ref.watch(todayNewspaperProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
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
    if (stories.isEmpty) {
      return const EmptyPlaceholder(message: 'No stories yet today.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: spacingLg),
      itemCount: stories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return IssueHeader(publishedAt: newspaper.publishedAt);
        }
        final story = stories[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          child: StoryCard(
            story: story,
            onTap: () => context.pushNamed(
              routeStoryName,
              pathParameters: {'id': story.id.toString()},
            ),
          ),
        );
      },
    );
  }
}
