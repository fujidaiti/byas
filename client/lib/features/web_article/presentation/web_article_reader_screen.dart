import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/web_article/domain/web_article.dart';
import 'package:paperdoll/features/web_article/presentation/providers/web_article_providers.dart';
import 'package:paperdoll/features/web_article/presentation/widgets/web_article_reader_view.dart';

/// Reader for a web article: fetches the article's details by its id and
/// renders its content, falling back to a placeholder when there is none.
class WebArticleReaderScreen extends ConsumerWidget {
  const WebArticleReaderScreen({
    required this.id,
    this.initialTitle,
    super.key,
  });

  final int id;

  /// The title already known from the reading list row, shown while the
  /// article details are still loading so the app bar isn't blank.
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(webArticleProvider(id: id));
    final article = articleAsync.asData?.value;
    final title = switch ((article?.title, initialTitle)) {
      (final title?, _) when title.isNotEmpty => title,
      (_, final title?) when title.isNotEmpty => title,
      _ => 'Fetching…',
    };
    return Scaffold(
      key: AppDebugKey.webArticleReaderScreen,
      appBar: AppBar(
        title: HeadingText(
          title,
          key: article != null ? AppDebugKey.readerTitle(article.title) : null,
        ),
        actions: [
          if (article != null)
            IconButton(
              key: AppDebugKey.webArticleReaderOpenOriginalButton,
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: () =>
                  unawaited(openExternalLink(context, article.url)),
            ),
        ],
      ),
      body: AsyncValueView<WebArticle>(
        value: articleAsync,
        onRetry: () => ref.invalidate(webArticleProvider(id: id)),
        data: (article) => WebArticleReaderView(article: article),
      ),
    );
  }
}
