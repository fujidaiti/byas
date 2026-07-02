import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
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

class _ReadingList extends StatelessWidget {
  const _ReadingList({required this.items});

  final List<ReadingListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyPlaceholder(message: 'Your reading list is empty.');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const AppDivider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ReadingListRow(item: item);
      },
    );
  }
}
