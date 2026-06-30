import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/test_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  patrolTest('open a story', ($) async {
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
          type: api.GetStory200ResponseTypeEnum.entry,
          data: api.FeedEntry(
            id: 1,
            feedId: 1,
            url: 'https://cursor.ai/blog/1',
            title: 'Demystifying evals for AI agents',
          ),
        ).toJson(),
      ),
    );

    expect($(AppTestKeys.todayScreen), findsOneWidget);
    await $(AppTestKeys.storyCard('Demystifying evals for AI agents')).tap();
    await $(AppTestKeys.storyReaderScreen).waitUntilVisible();
    await $(
      AppTestKeys.readerTitle('Demystifying evals for AI agents'),
    ).waitUntilVisible();
  });
}
