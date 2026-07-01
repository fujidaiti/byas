import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/features/feed_entry/domain/feed_entry.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_content_webview.dart';

/// Shared reading layout for both the Story Reader and the Feed Entry Reader: a
/// header (title) above the rendered HTML content.
class FeedEntryReaderView extends StatelessWidget {
  const FeedEntryReaderView({required this.entry, super.key});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final content = entry.content;
    if (content != null && content.trim().isNotEmpty) {
      return FeedEntryContentWebView(html: content);
    }
    return Padding(
      padding: const EdgeInsets.all(spacingMd),
      child: BodyText(entry.description ?? 'No content available.'),
    );
  }
}
