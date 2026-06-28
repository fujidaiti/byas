import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';

/// A story in the Today list: title, snippet, and publication date.
class StoryCard extends StatelessWidget {
  const StoryCard({required this.story, this.onTap, super.key});

  final Story story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = story.description;
    final publishedAt = story.publishedAt;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeadingText(story.title),
              if (description != null) ...[
                const Gap(spacingSm),
                BodyText(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (publishedAt != null) ...[
                const Gap(spacingSm),
                CaptionText(formatDate(publishedAt)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
