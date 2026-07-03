import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Read a saved web article in reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

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
              title: 'Demystifying evals for AI agents',
              savedAt: DateTime.utc(2026, 7, 1),
            ),
          ],
        ).toJson(),
      ),
    );
    adapter.onGet(
      '/reading-list/1',
      (s) => s.reply(
        200,
        api.GetReadingListItem200Response(
          id: 1,
          kind: api.GetReadingListItem200ResponseKindEnum.webArticle,
          archived: false,
          savedAt: DateTime.utc(2026, 7, 1),
          attributes: api.WebArticle(
            url: 'https://www.anthropic.com/engineering/demystifying-evals',
            title: 'Demystifying evals for AI agents',
            content:
                '<article><p>Good evaluations help teams ship.</p></article>',
          ),
        ).toJson(),
      ),
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListScreen).waitUntilVisible();
    await $(AppDebugKey.readingListRow(1)).tap();
    await $(AppDebugKey.readingListWebArticleReaderScreen).waitUntilVisible();
    await $(
      AppDebugKey.readerTitle('Demystifying evals for AI agents'),
    ).waitUntilVisible();
  });

  patrolTest('Read a saved feed entry in reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

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
              title: 'Effective harnesses for long-running agents',
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
          title: 'Effective harnesses for long-running agents',
          content:
              '<article><p>A good harness keeps the agent on track.</p></article>',
        ).toJson(),
      ),
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListScreen).waitUntilVisible();
    await $(AppDebugKey.readingListRow(5)).tap();
    await $(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await $(
      AppDebugKey.readerTitle('Effective harnesses for long-running agents'),
    ).waitUntilVisible();
  });
}
