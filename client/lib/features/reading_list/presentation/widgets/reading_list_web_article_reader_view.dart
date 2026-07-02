import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paperdoll/core/ui/widgets/empty_placeholder.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/features/feed_entry/presentation/widgets/feed_entry_content_webview.dart';
import 'package:paperdoll/features/reading_list/domain/web_article.dart';

/// Renders a saved web article: its fetched HTML content, or a placeholder that
/// points to the original when the content hasn't been fetched.
class ReadingListWebArticleReaderView extends StatelessWidget {
  const ReadingListWebArticleReaderView({required this.article, super.key});

  final WebArticle article;

  @override
  Widget build(BuildContext context) {
    final content = article.content;
    if (content != null && content.trim().isNotEmpty) {
      return FeedEntryContentWebView(html: content);
    }
    return EmptyPlaceholder(
      message: "This article's content isn't available.",
      actionLabel: 'Open in browser',
      onAction: () => unawaited(openExternalLink(context, article.url)),
    );
  }
}
