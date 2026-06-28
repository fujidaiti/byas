import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/title_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/feed/domain/feed.dart';
import 'package:paperdoll/features/feed/presentation/widgets/feed_icon.dart';

/// Feed Detail header: icon, title, description, and a link to the site.
class FeedHeader extends StatelessWidget {
  const FeedHeader({required this.feed, super.key});

  final Feed feed;

  @override
  Widget build(BuildContext context) {
    final description = feed.description;
    final siteUrl = feed.siteUrl;
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedIcon(url: feed.iconUrl),
              const Gap(spacingSm),
              Expanded(
                child: TitleText(
                  feed.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const Gap(spacingSm),
            BodyText(description),
          ],
          if (siteUrl != null) ...[
            const Gap(spacingSm),
            TextButton.icon(
              onPressed: () => unawaited(openExternalLink(context, siteUrl)),
              icon: const Icon(Icons.public),
              label: const Text('Visit site'),
            ),
          ],
        ],
      ),
    );
  }
}
