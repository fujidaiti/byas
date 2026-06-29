import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/features/newspaper/domain/story.dart';

/// A story in the Today list: title, snippet, and source.
class StoryCard extends StatelessWidget {
  const StoryCard({required this.story, this.onTap, super.key});

  final Story story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = story.description;
    final source = story.source;
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
          if (source != null) ...[const Gap(spacingSm), CaptionText(source)],
        ],
      ),
    );
  }
}
