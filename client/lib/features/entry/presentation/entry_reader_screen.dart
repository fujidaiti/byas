import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/providers/entry_providers.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_reader_view.dart';

class EntryReaderScreen extends ConsumerWidget {
  const EntryReaderScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider(id: id));
    final entry = entryAsync.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry?.title ?? ''),
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
        value: entryAsync,
        onRetry: () => ref.invalidate(entryProvider(id: id)),
        data: (entry) => EntryReaderView(entry: entry),
      ),
    );
  }
}
