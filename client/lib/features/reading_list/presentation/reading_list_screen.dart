import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/error/domain_error.dart';
import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/tokens/app_text_styles.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/reading_list/presentation/widgets/reading_list_row.dart';

/// Reading list home: the saved, unarchived articles, newest first.
class ReadingListScreen extends ConsumerWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(readingListProvider());
    return Scaffold(
      key: AppDebugKey.readingListScreen,
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(readingListProvider().future),
        child: AsyncValueView<List<ReadingListItem>>(
          value: itemsAsync,
          onRetry: () => ref.invalidate(readingListProvider()),
          data: (items) => _ReadingList(items: items),
        ),
      ),
    );
  }
}

class _ReadingList extends ConsumerStatefulWidget {
  const _ReadingList({required this.items});

  final List<ReadingListItem> items;

  @override
  ConsumerState<_ReadingList> createState() => _ReadingListState();
}

class _ReadingListState extends ConsumerState<_ReadingList> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const EmptyPlaceholder(message: 'Your reading list is empty.');
    }
    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.startToEnd,
          background: ColoredBox(
            color: colorAccent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacingMd),
              child: Row(
                spacing: spacingSm,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.archive,
                    color: colorBackground,
                    size: iconSm,
                  ),
                  Text(
                    'Archive',
                    style: textLabel.copyWith(color: colorBackground),
                  ),
                ],
              ),
            ),
          ),
          onDismissed: (_) => _archive(item, index),
          child: ReadingListRow(item: item),
        );
      },
    );
  }

  void _archive(ReadingListItem item, int index) {
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      ref
          .read(readingListProvider().notifier)
          .archive(item)
          .then(
            (_) {
              messenger.showSnackBar(
                SnackBar(
                  key: AppDebugKey.archiveSuccessSnackBar,
                  content: Text('Archived "${item.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => _unarchive(item, index),
                  ),
                ),
              );
            },
            onError: (Object error) {
              messenger.showSnackBar(
                SnackBar(content: Text(describeError(error))),
              );
            },
          ),
    );
  }

  void _unarchive(ReadingListItem item, int index) {
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      ref
          .read(readingListProvider().notifier)
          .unarchive(item, index)
          .catchError((Object error) {
            messenger.showSnackBar(
              SnackBar(content: Text(describeError(error))),
            );
          }),
    );
  }
}
