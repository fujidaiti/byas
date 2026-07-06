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
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';

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
          if (entry != null) _BookmarkButton(entry: entry),
          if (entry != null && entry.readingListItemId != null)
            _ArchiveButton(entry: entry),
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

/// Archive toggle in the reader appbar. Archives the saved entry
/// (`PATCH /reading-list/{id}` with `{"archived": true}`) or unarchives it
/// (`{"archived": false}`), updating the icon optimistically and rolling back
/// with an error snackbar on failure. Only shown when the entry is saved.
class _ArchiveButton extends ConsumerStatefulWidget {
  const _ArchiveButton({required this.entry});

  final FeedEntry entry;

  @override
  ConsumerState<_ArchiveButton> createState() => _ArchiveButtonState();
}

class _ArchiveButtonState extends ConsumerState<_ArchiveButton> {
  late final int _itemId;
  var _archived = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.entry.readingListItemId!;
    _archived = widget.entry.archived ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: AppDebugKey.feedEntryReaderArchiveButton,
      tooltip: _archived ? 'Move back to reading list' : 'Archive',
      icon: Icon(_archived ? Icons.unarchive_outlined : Icons.archive_outlined),
      onPressed: () => unawaited(_archived ? _unarchive() : _archive()),
    );
  }

  Future<void> _archive() async {
    // Optimistically flip the icon and confirm before the request completes.
    setState(() => _archived = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.archiveSuccessSnackBar,
        content: Text('Archived'),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).archive(_itemId);
    } on Exception {
      if (mounted) {
        setState(() => _archived = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }

  Future<void> _unarchive() async {
    // Optimistically flip the icon and confirm before the request completes.
    setState(() => _archived = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.unarchiveSuccessSnackBar,
        content: Text('Moved back to reading list'),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).unarchive(_itemId);
    } on Exception {
      if (mounted) {
        setState(() => _archived = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }
}

/// Bookmark toggle in the reader appbar. Saves the entry to the reading list
/// (`POST /reading-list`) or removes it (`DELETE /reading-list/{id}`), updating
/// the icon optimistically and rolling back with an error snackbar on failure.
class _BookmarkButton extends ConsumerStatefulWidget {
  const _BookmarkButton({required this.entry});

  final FeedEntry entry;

  @override
  ConsumerState<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<_BookmarkButton> {
  int? _itemId;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.entry.readingListItemId;
    _saved = _itemId != null;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: AppDebugKey.feedEntryReaderBookmarkButton,
      tooltip: _saved ? 'Remove from reading list' : 'Save to reading list',
      icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () => unawaited(_saved ? _unsave() : _save()),
    );
  }

  Future<void> _save() async {
    // Optimistically fill the icon and confirm before the request completes.
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.saveToReadingListSuccessSnackBar,
        content: Text('Saved to reading list'),
      ),
    );
    try {
      final repository = ref.read(readingListRepositoryProvider);
      // The save response carries the created item, so the toggle can remember
      // its id for a later remove without a follow-up fetch.
      final item = await repository.saveFeedEntry(widget.entry.id);
      if (mounted) {
        setState(() => _itemId = item.id);
      }
    } on Exception {
      if (mounted) {
        setState(() => _saved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }

  Future<void> _unsave() async {
    final id = _itemId;
    if (id == null) {
      return;
    }
    // Optimistically outline the icon and confirm before the request completes.
    setState(() => _saved = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.removeFromReadingListSuccessSnackBar,
        content: Text('Removed from reading list'),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).removeItem(id);
      if (mounted) {
        setState(() => _itemId = null);
      }
    } on Exception {
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }
}
