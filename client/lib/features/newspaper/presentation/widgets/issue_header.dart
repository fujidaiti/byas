import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/title_text.dart';
import 'package:paperdoll/core/util/date_format.dart';

/// The newspaper issue header: an edition label and the publication date.
class IssueHeader extends StatelessWidget {
  const IssueHeader({required this.publishedAt, super.key});

  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CaptionText('Daily edition'),
          const Gap(spacingXs),
          TitleText(formatDate(publishedAt)),
        ],
      ),
    );
  }
}
