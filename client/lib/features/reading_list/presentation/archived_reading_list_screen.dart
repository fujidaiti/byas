import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/ui/widgets/scrollable_fill.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/reading_list/presentation/widgets/reading_list_row.dart';

/// The archived reading list: previously archived items, newest first. Unlike
/// the reading list, rows have no swipe actions; tapping opens the reader.
class ArchivedReadingListScreen extends ConsumerWidget {
  const ArchivedReadingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(archivedReadingListProvider);
    return Scaffold(
      key: AppDebugKey.archivedReadingListScreen,
      appBar: AppBar(title: const Text('Archived')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(archivedReadingListProvider.future),
        child: AsyncValueView<List<ReadingListItem>>(
          value: itemsAsync,
          onRetry: () => ref.invalidate(archivedReadingListProvider),
          data: (items) => _ArchivedList(items: items),
        ),
      ),
    );
  }
}

class _ArchivedList extends StatelessWidget {
  const _ArchivedList({required this.items});

  final List<ReadingListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const ScrollableFill(
        child: EmptyPlaceholder(message: 'No archived items.'),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) => ReadingListRow(item: items[index]),
    );
  }
}
