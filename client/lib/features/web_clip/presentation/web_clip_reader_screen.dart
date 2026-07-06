import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';
import 'package:paperdoll/features/web_clip/presentation/providers/web_clip_providers.dart';
import 'package:paperdoll/features/web_clip/presentation/widgets/web_clip_reader_view.dart';

/// Reader for a web clip: fetches the clip's details by its id and
/// renders its content, falling back to a placeholder when there is none.
class WebClipReaderScreen extends ConsumerWidget {
  const WebClipReaderScreen({required this.id, this.initialTitle, super.key});

  final int id;

  /// The title already known from the reading list row, shown while the
  /// clip details are still loading so the app bar isn't blank.
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipAsync = ref.watch(webClipProvider(id: id));
    final clip = clipAsync.asData?.value;
    final title = switch ((clip?.title, initialTitle)) {
      (final title?, _) when title.isNotEmpty => title,
      (_, final title?) when title.isNotEmpty => title,
      _ => 'Fetching…',
    };
    return Scaffold(
      key: AppDebugKey.webClipReaderScreen,
      appBar: AppBar(
        title: HeadingText(
          title,
          key: clip != null ? AppDebugKey.readerTitle(clip.title ?? '') : null,
        ),
        actions: [
          if (clip != null) _BookmarkButton(id: id, clip: clip),
          if (clip != null && clip.readingListItemId != null)
            _ArchiveButton(clip: clip),
          if (clip != null)
            IconButton(
              key: AppDebugKey.webClipReaderOpenOriginalButton,
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => unawaited(openExternalLink(context, clip.url)),
            ),
        ],
      ),
      body: AsyncValueView<WebClip>(
        value: clipAsync,
        onRetry: () => ref.invalidate(webClipProvider(id: id)),
        data: (clip) => WebClipReaderView(clip: clip),
      ),
    );
  }
}

/// Archive toggle in the reader appbar. Archives the saved clip
/// (`PATCH /reading-list/{id}` with `{"archived": true}`) or unarchives it
/// (`{"archived": false}`), updating the icon optimistically and rolling back
/// with an error snackbar on failure. Only shown when the clip is saved.
class _ArchiveButton extends ConsumerStatefulWidget {
  const _ArchiveButton({required this.clip});

  final WebClip clip;

  @override
  ConsumerState<_ArchiveButton> createState() => _ArchiveButtonState();
}

class _ArchiveButtonState extends ConsumerState<_ArchiveButton> {
  late final int _itemId;
  var _archived = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.clip.readingListItemId!;
    _archived = widget.clip.archived ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: AppDebugKey.webClipReaderArchiveButton,
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

/// Bookmark toggle in the reader appbar. Removes the clip from the reading
/// list (`DELETE /reading-list/{id}`) or re-saves it
/// (`POST /reading-list {web_clip_id}`), updating the icon optimistically
/// and rolling back with an error snackbar on failure. A web clip opened
/// from the reading list starts saved, so the common action here is removal.
class _BookmarkButton extends ConsumerStatefulWidget {
  const _BookmarkButton({required this.id, required this.clip});

  final int id;
  final WebClip clip;

  @override
  ConsumerState<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<_BookmarkButton> {
  int? _itemId;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.clip.readingListItemId;
    _saved = _itemId != null;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: AppDebugKey.webClipReaderBookmarkButton,
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
      // The save response carries the created item, so the toggle can remember
      // its id for a later remove without a follow-up fetch.
      final item = await ref
          .read(readingListRepositoryProvider)
          .saveWebClip(widget.id);
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
