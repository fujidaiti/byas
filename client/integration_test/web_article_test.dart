import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Toggle a saved web article bookmark from the reader', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const articleTitle = 'Demystifying evals for AI agents';
    const articleUrl =
        'https://www.anthropic.com/engineering/demystifying-evals';

    adapter.onGet(
      '/reading-list',
      (s) => s.reply(
        200,
        api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 5,
              resourceId: 7,
              kind: api.ReadingListItemKindEnum.webArticle,
              title: articleTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      ),
    );
    // Single stable reply: the reader may hit this path more than once on load,
    // and the post-resave refetch hits it again. A stable body (item id 5, so
    // the article opens saved) keeps every call — however many — consistent, so
    // the unsave always targets DELETE /reading-list/5. (See DEBUGGING.md.)
    adapter.onGet(
      '/web-articles/7',
      (s) => s.reply(
        200,
        api.GetWebArticle200Response(
          id: 7,
          url: articleUrl,
          title: articleTitle,
          content:
              '<article><p>Good evaluations help teams ship.</p></article>',
          readingListItemId: 5,
        ).toJson(),
      ),
    );
    adapter.onDelete(
      '/reading-list/5',
      (s) => s.reply(204, <String, dynamic>{}),
    );
    // The matched body doubles as an assertion that the app re-saves by id.
    adapter.onPost(
      '/reading-list',
      (s) => s.reply(201, <String, dynamic>{}),
      data: {'web_article_id': 7},
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    expect($(AppDebugKey.readingListScreen), findsOneWidget);
    await $(AppDebugKey.readingListRow(articleTitle)).tap();
    expect($(AppDebugKey.webArticleReaderScreen), findsOneWidget);
    // The article opens already saved, so the bookmark is filled.
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Tap to remove: the icon outlines optimistically and a confirmation
    // snackbar mounts on the next frame (the delete runs after the tap lands).
    await $(AppDebugKey.webArticleReaderBookmarkButton).tap();
    await $.pump();
    expect(
      find.byIcon(Icons.bookmark_border),
      findsOneWidget,
      reason:
          'filled=${find.byIcon(Icons.bookmark).evaluate().length} '
          'errorText=${find.textContaining('went wrong').evaluate().length}',
    );
    expect(
      find.byKey(AppDebugKey.removeFromReadingListSuccessSnackBar),
      findsOneWidget,
    );

    // Tap again to re-save. Assert the persistent icon rather than the queued
    // snackbar: the re-save POST body match ensures the app re-saved by id, and
    // the filled icon proves it succeeded (a failed POST would revert it).
    await $(AppDebugKey.webArticleReaderBookmarkButton).tap();
    await $.pump();
    expect(
      find.byIcon(Icons.bookmark),
      findsOneWidget,
      reason: 'border=${find.byIcon(Icons.bookmark_border).evaluate().length}',
    );
  });
}
