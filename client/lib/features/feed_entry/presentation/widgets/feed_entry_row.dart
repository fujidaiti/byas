import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';

/// A single feed entry in a timeline list.
class FeedEntryRow extends StatelessWidget {
  const FeedEntryRow({required this.entry, this.onTap, super.key});

  final FeedEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = entry.description;
    final publishedAt = entry.publishedAt;
    return ListTile(
      isThreeLine: true,
      onTap: onTap,
      title: HeadingText(
        entry.title,
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
          if (publishedAt != null) ...[
            const Gap(spacingXs),
            CaptionText(formatDate(publishedAt)),
          ],
        ],
      ),
    );
  }
}
