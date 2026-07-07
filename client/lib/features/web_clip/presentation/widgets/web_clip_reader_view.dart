import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_content_webview.dart';
import 'package:paperdoll/features/web_clip/domain/web_clip.dart';

/// Renders a saved web clip: its fetched HTML content, or a placeholder that
/// points to the original when the content hasn't been fetched.
class WebClipReaderView extends StatelessWidget {
  const WebClipReaderView({required this.clip, super.key});

  final WebClip clip;

  @override
  Widget build(BuildContext context) {
    final content = clip.content;
    if (content != null && content.trim().isNotEmpty) {
      return FeedEntryContentWebView(html: content);
    }
    return EmptyPlaceholder(
      message: "This clip's content isn't available.",
      actionLabel: 'Open in browser',
      onAction: () => unawaited(openExternalLink(context, clip.url)),
    );
  }
}
