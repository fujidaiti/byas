import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/tokens/app_spacing.dart';
import 'package:paperdoll/core/ui/widgets/body_text.dart';
import 'package:paperdoll/features/entry/domain/feed_entry.dart';
import 'package:paperdoll/features/entry/presentation/widgets/entry_content_webview.dart';

/// Shared reading layout for both the Story Reader and the Entry Reader: a
/// header (title) above the rendered HTML content.
class EntryReaderView extends StatelessWidget {
  const EntryReaderView({required this.entry, super.key});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
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
