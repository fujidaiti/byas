import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/ui/widgets/async_value_view.dart';
import 'package:paperdoll/core/ui/widgets/heading_text.dart';
import 'package:paperdoll/core/util/link_launcher.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/reading_list/domain/web_article.dart';
import 'package:paperdoll/features/reading_list/presentation/providers/reading_list_providers.dart';
import 'package:paperdoll/features/reading_list/presentation/widgets/reading_list_web_article_reader_view.dart';

/// Reader for a `web_article` reading list item: fetches the article's details
/// and renders its content, falling back to a placeholder when there is none.
class ReadingListWebArticleReaderScreen extends ConsumerWidget {
  const ReadingListWebArticleReaderScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(webArticleProvider(id: id));
    final article = articleAsync.asData?.value;
    return Scaffold(
      key: AppDebugKey.readingListWebArticleReaderScreen,
      appBar: AppBar(
        title: HeadingText(
          article?.title ?? '',
          key: article != null ? AppDebugKey.readerTitle(article.title) : null,
        ),
        actions: [
          if (article != null)
            IconButton(
              key: AppDebugKey.readingListWebArticleReaderOpenOriginalButton,
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
        data: (article) => ReadingListWebArticleReaderView(article: article),
      ),
    );
  }
}
