import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';

/// A saved article in the reading list: title, optional description, and the
/// date it was saved. Tapping opens the reader for the item's kind.
class ReadingListRow extends StatelessWidget {
  const ReadingListRow({required this.item, super.key});

  final ReadingListItem item;

  @override
  Widget build(BuildContext context) {
    final description = item.description;
    final title = item.title.isEmpty ? 'Fetching…' : item.title;
    return ListTile(
      key: AppDebugKey.readingListRow(item.id),
      onTap: () => _open(context),
      title: HeadingText(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) ...[
            const Gap(spacingXs),
            BodyText(description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const Gap(spacingSm),
          CaptionText('Saved ${formatDate(item.savedAt)}'),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    switch (item.kind) {
      case ReadingListItemKind.webArticle:
        unawaited(
          context.pushNamed(
            routeReadingListWebArticleReaderName,
            pathParameters: {'id': '${item.id}'},
            extra: item.title,
          ),
        );
      case ReadingListItemKind.feedEntry:
        // TODO: Route to the feed entry reader once it supports reading list
        // items. The list never returns feed_entry today.
        break;
    }
  }
}
