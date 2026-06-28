import 'dart:async';

import 'package:flutter/material.dart';

import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/app_divider.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/core/ui/widgets/caption_text.dart';
import 'package:paperdoll/core/ui/widgets/gap.dart';
import 'package:paperdoll/core/ui/widgets/title_text.dart';
import 'package:paperdoll/core/util/date_format.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_content_webview.dart';

/// Shared reading layout for both the Story Reader and the Entry Reader: a
/// header (title, date, open-original link) above the rendered HTML content.
class EntryReaderView extends StatelessWidget {
  const EntryReaderView({required this.entry, super.key});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final publishedAt = entry.publishedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleText(entry.title),
              if (publishedAt != null) ...[
                const Gap(spacingXs),
                CaptionText(formatDate(publishedAt)),
              ],
              const Gap(spacingSm),
              OutlinedButton.icon(
                onPressed: () =>
                    unawaited(openExternalLink(context, entry.url)),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open original'),
              ),
            ],
          ),
        ),
        const AppDivider(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final content = entry.content;
    if (content != null && content.trim().isNotEmpty) {
      return EntryContentWebView(html: content);
    }
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: BodyText(entry.description ?? 'No content available.'),
    );
  }
}
