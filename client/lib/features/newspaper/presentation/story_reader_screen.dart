import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_reader_view.dart';
import 'package:paperdoll/features/newspaper/presentation/providers/newspaper_providers.dart';

class StoryReaderScreen extends ConsumerWidget {
  const StoryReaderScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyProvider(id: id));
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: AsyncValueView<FeedEntry>(
        value: storyAsync,
        onRetry: () => ref.invalidate(storyProvider(id: id)),
        data: (entry) => EntryReaderView(entry: entry),
      ),
    );
  }
}
