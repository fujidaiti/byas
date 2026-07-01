import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest("Check today's issue and read a story", ($) async {
    await pumpApp($);
    final adapter = httpMockAdapter($);

    adapter.onGet(
      '/newspapers/today',
      (s) => s.reply(
        200,
        api.GetTodaysNewspaper200Response(
          id: 1,
          publishedAt: DateTime.utc(2026, 7, 1),
          stories: [
            api.Story(
              id: 1,
              title: 'Demystifying evals for AI agents',
              source_: 'Cursor AI Blog',
            ),
          ],
        ).toJson(),
      ),
    );
    adapter.onGet(
      '/newspapers/stories/1',
      (s) => s.reply(
        200,
        api.GetStory200Response(
          type: api.GetStory200ResponseTypeEnum.feedEntry,
          data: api.FeedEntry(
            id: 1,
            feedId: 1,
            url: 'https://cursor.ai/blog/1',
            title: 'Demystifying evals for AI agents',
          ),
        ).toJson(),
      ),
    );

    expect($(AppDebugKey.todayScreen), findsOneWidget);
    await $(AppDebugKey.storyCard('Demystifying evals for AI agents')).tap();
    await $(AppDebugKey.storyReaderScreen).waitUntilVisible();
    await $(
      AppDebugKey.readerTitle('Demystifying evals for AI agents'),
    ).waitUntilVisible();
  });
}
