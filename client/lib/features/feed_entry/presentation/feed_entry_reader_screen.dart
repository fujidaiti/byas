import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/presentation/providers/feed_entry_providers.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_reader_view.dart';

class FeedEntryReaderScreen extends ConsumerWidget {
  const FeedEntryReaderScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(feedEntryProvider(id: id));
    final entry = entryAsync.asData?.value;
    return Scaffold(
      key: AppDebugKey.feedEntryReaderScreen,
      appBar: AppBar(
        title: HeadingText(
          entry?.title ?? '',
          key: entry != null ? AppDebugKey.readerTitle(entry.title) : null,
        ),
        actions: [
          if (entry != null)
            IconButton(
              key: AppDebugKey.feedEntryReaderOpenOriginalButton,
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => unawaited(openExternalLink(context, entry.url)),
            ),
        ],
      ),
      body: AsyncValueView<FeedEntry>(
        value: entryAsync,
        onRetry: () => ref.invalidate(feedEntryProvider(id: id)),
        data: (entry) => FeedEntryReaderView(entry: entry),
      ),
    );
  }
}
