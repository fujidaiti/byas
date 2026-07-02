import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('Open a saved web article from the reading list', ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    const title = 'Demystifying evals for AI agents';
    adapter.onGet(
      '/reading-list',
      (s) => s.reply(
        200,
        api.GetReadingList200Response(
          items: [
            api.ReadingListItem(
              id: 1,
              kind: api.ReadingListItemKindEnum.webArticle,
              title: title,
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
            title: title,
            content:
                '<article><p>Good evaluations help teams ship.</p></article>',
          ),
        ).toJson(),
      ),
    );

    await $(AppDebugKey.readingListNavDestination).tap();
    await $(AppDebugKey.readingListRow(title)).tap();
    await $(AppDebugKey.readingListWebArticleReaderScreen).waitUntilVisible();
    await $(AppDebugKey.readerTitle(title)).waitUntilVisible();
  });
}
