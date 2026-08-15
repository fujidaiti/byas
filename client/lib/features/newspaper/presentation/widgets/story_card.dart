import 'package:material_ui/material_ui.dart';

import 'package:paperdoll/core/ui/tokens/app_colors.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/tokens/app_text_styles.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';

/// A story in the Today list: title, snippet, and source.
class const StoryCard({
  required final Story story,
  final VoidCallback? onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final description = story.description;
    final source = story.source;
    final savedToReadingList = story.readingListItemId != null;
    final archived = story.archived ?? false;
    return ListTile(
      isThreeLine: true,
      onTap: onTap,
      title: HeadingText(
        story.title,
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
          if (source != null || savedToReadingList) ...[
            const Gap(spacingSm),
            Row(
              children: [
                if (source != null) CaptionText(source),
                const Spacer(),
                if (savedToReadingList)
                  Text(
                    'Read later',
                    style: textCaption.copyWith(
                      color: archived
                          ? colorAccent.withValues(alpha: 0.5)
                          : colorAccent,
                      fontWeight: FontWeight.w600,
                      decoration: archived ? TextDecoration.lineThrough : null,
                      decorationColor: colorAccent.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
