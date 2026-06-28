import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_reader_view.dart';
import 'package:paperdoll/features/newspaper/presentation/providers/newspaper_providers.dart';

class StoryReaderScreen extends ConsumerWidget {
  const StoryReaderScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyProvider(id: id));
    final entry = storyAsync.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: HeadingText(entry?.title ?? ''),
        actions: [
          if (entry != null)
            IconButton(
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => unawaited(openExternalLink(context, entry.url)),
            ),
        ],
      ),
      body: AsyncValueView<FeedEntry>(
        value: storyAsync,
        onRetry: () => ref.invalidate(storyProvider(id: id)),
        data: (entry) => EntryReaderView(entry: entry),
      ),
    );
  }
}
