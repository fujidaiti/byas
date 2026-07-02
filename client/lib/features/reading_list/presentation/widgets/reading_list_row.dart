import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/features/reading_list/domain/reading_list_item.dart';

/// A saved article in the reading list: title, optional description, and the
/// date it was saved. Not tappable yet — the reader lands in a later PR.
class ReadingListRow extends StatelessWidget {
  const ReadingListRow({required this.item, super.key});

  final ReadingListItem item;

  @override
  Widget build(BuildContext context) {
    final description = item.description;
    return ListTile(
      title: HeadingText(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
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
}
