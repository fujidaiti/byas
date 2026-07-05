import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Read a saved web article in reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const articleTitle = 'Demystifying evals for AI agents';
    adapter.onGet(
      '/reading-list',
      (s) => s.reply(
        200,
        api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              resourceId: 7,
              kind: api.ReadingListItemKindEnum.webArticle,
              title: articleTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      ),
    );
    adapter.onGet(
      '/web-articles/7',
      (s) => s.reply(
        200,
        api.GetWebArticle200Response(
          id: 7,
          url: 'https://www.anthropic.com/engineering/demystifying-evals',
          title: articleTitle,
          content:
              '<article><p>Good evaluations help teams ship.</p></article>',
        ).toJson(),
      ),
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    expect($(AppDebugKey.readingListScreen), findsOneWidget);
    await $(AppDebugKey.readingListRow(articleTitle)).tap();
    expect($(AppDebugKey.webArticleReaderScreen), findsOneWidget);
    expect($(AppDebugKey.readerTitle(articleTitle)), findsOneWidget);
  });

  patrolTest('Read a saved feed entry in reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const targetEntryTitle = 'Effective harnesses for long-running agents';
    adapter.onGet(
      '/reading-list',
      (s) => s.reply(
        200,
        api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 5,
              resourceId: 11,
              kind: api.ReadingListItemKindEnum.feedEntry,
              title: targetEntryTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      ),
    );
    adapter.onGet(
      '/feed-entries/11',
      (s) => s.reply(
        200,
        api.FeedEntry(
          id: 11,
          feedId: 1,
          url: 'https://example.com/anthropic/blog/effective-harness',
          title: targetEntryTitle,
          content:
              '<article><p>A good harness keeps the agent on track.</p></article>',
        ).toJson(),
      ),
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    expect($(AppDebugKey.readingListScreen), findsOneWidget);
    await $(AppDebugKey.readingListRow(targetEntryTitle)).tap();
    expect($(AppDebugKey.feedEntryReaderScreen), findsOneWidget);
    expect($(AppDebugKey.readerTitle(targetEntryTitle)), findsOneWidget);
  });

  patrolTest('Archive a reading list item by swiping', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const articleTitle = 'Demystifying evals for AI agents';
    adapter.onGet(
      '/reading-list',
      (s) => s.reply(
        200,
        api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              resourceId: 1,
              kind: api.ReadingListItemKindEnum.webArticle,
              title: articleTitle,
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      ),
    );
    adapter.onPatch(
      '/reading-list/1',
      (s) => s.reply(204, <String, dynamic>{}),
      data: {'archived': true},
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    expect($(AppDebugKey.readingListRow(articleTitle)), findsOneWidget);
    await $.tester.fling(
      $(AppDebugKey.readingListRow(articleTitle)).finder,
      const Offset(100, 0),
      1000,
    );
    await $(AppDebugKey.archiveSuccessSnackBar).waitUntilVisible();
    expect($(AppDebugKey.readingListRow(articleTitle)), findsNothing);
  }, tags: ['archive']);
}
