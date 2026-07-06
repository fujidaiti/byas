import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/archived_banner.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/presentation/providers/feed_entry_providers.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_reader_view.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';

class FeedEntryReaderScreen extends ConsumerStatefulWidget {
  const FeedEntryReaderScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<FeedEntryReaderScreen> createState() =>
      _FeedEntryReaderScreenState();
}

class _FeedEntryReaderScreenState extends ConsumerState<FeedEntryReaderScreen> {
  // Shared archived state so the app-bar toggle and the body banner stay in
  // sync. Created once the entry loads, seeded from its archived flag.
  ValueNotifier<bool>? _archived;

  @override
  void dispose() {
    _archived?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(feedEntryProvider(id: widget.id));
    final entry = entryAsync.asData?.value;
    if (entry != null) {
      _archived ??= ValueNotifier(entry.archived ?? false);
    }
    final archived = _archived;
    return Scaffold(
      key: AppDebugKey.feedEntryReaderScreen,
      appBar: AppBar(
        title: HeadingText(
          entry?.title ?? '',
          key: entry != null ? AppDebugKey.readerTitle(entry.title) : null,
        ),
        actions: [
          if (entry != null && archived != null)
            _ReadingListActions(entry: entry, archived: archived),
          if (entry != null)
            IconButton(
              key: AppDebugKey.feedEntryReaderOpenOriginalButton,
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => unawaited(openExternalLink(context, entry.url)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (archived != null)
            ValueListenableBuilder<bool>(
              valueListenable: archived,
              builder: (context, isArchived, _) => isArchived
                  ? const ArchivedBanner(
                      key: AppDebugKey.feedEntryReaderArchivedBanner,
                    )
                  : const SizedBox.shrink(),
            ),
          Expanded(
            child: AsyncValueView<FeedEntry>(
              value: entryAsync,
              onRetry: () => ref.invalidate(feedEntryProvider(id: widget.id)),
              data: (entry) => FeedEntryReaderView(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reading-list controls in the reader appbar: a bookmark toggle that saves the
/// entry to the reading list (`POST /reading-list`) or removes it
/// (`DELETE /reading-list/{id}`), and — once saved — an archive toggle that
/// hides the item from the list (`PATCH /reading-list/{id}`) or unarchives it.
/// Both update optimistically and roll back with an error snackbar on failure.
/// Sharing one widget lets saving or removing show or hide the archive toggle
/// immediately. The archived state is owned by the screen (via [archived]) so
/// the "Archived" banner below the app bar tracks the same toggle.
class _ReadingListActions extends ConsumerStatefulWidget {
  const _ReadingListActions({required this.entry, required this.archived});

  final FeedEntry entry;
  final ValueNotifier<bool> archived;

  @override
  ConsumerState<_ReadingListActions> createState() =>
      _ReadingListActionsState();
}

class _ReadingListActionsState extends ConsumerState<_ReadingListActions> {
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: AppDebugKey.feedEntryReaderBookmarkButton,
          tooltip: _saved ? 'Remove from reading list' : 'Save to reading list',
          icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => unawaited(_saved ? _unsave() : _save()),
        ),
        // The archive toggle only applies to an item that is in the list, so it
        // appears and disappears together with the bookmark state.
        if (_saved && _itemId != null)
          ValueListenableBuilder<bool>(
            valueListenable: widget.archived,
            builder: (context, archived, _) => IconButton(
              key: AppDebugKey.feedEntryReaderArchiveButton,
              tooltip: archived ? 'Unarchive' : 'Archive',
              icon: Icon(
                archived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
              onPressed: () => unawaited(archived ? _unarchive() : _archive()),
            ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    // Optimistically fill the icon and confirm before the request completes. A
    // freshly saved item is never archived.
    setState(() => _saved = true);
    widget.archived.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.saveToReadingListSuccessSnackBar,
        content: Text('Saved to reading list'),
      ),
    );
    try {
      // The save response carries the created item, so the toggle can remember
      // its id for a later remove/archive without a follow-up fetch.
      final item = await ref
          .read(readingListRepositoryProvider)
          .saveFeedEntry(widget.entry.id);
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
    // A removed item is no longer archived, so hide the banner too.
    setState(() => _saved = false);
    widget.archived.value = false;
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

  Future<void> _archive() async {
    final id = _itemId;
    if (id == null) {
      return;
    }
    // Optimistically flip the icon and confirm before the request completes.
    widget.archived.value = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.archiveSuccessSnackBar,
        content: Text('Archived'),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).archive(id);
    } on Exception {
      if (mounted) {
        widget.archived.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }

  Future<void> _unarchive() async {
    final id = _itemId;
    if (id == null) {
      return;
    }
    // Optimistically flip the icon and confirm before the request completes.
    widget.archived.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: AppDebugKey.unarchiveSuccessSnackBar,
        content: Text('Unarchived'),
      ),
    );
    try {
      await ref.read(readingListRepositoryProvider).unarchive(id);
    } on Exception {
      if (mounted) {
        widget.archived.value = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong', maxLines: 1)),
        );
      }
    }
  }
}
