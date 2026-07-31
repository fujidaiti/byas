import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../src/boilerplate.dart';
import '../src/stub_server.dart';

void main() {
  patrolWidgetTest("Check today's issue and read a story", (t) async {
    final server = StubServer.withDefaultResponses()
      ..onGet(
        '/newspapers/today',
        body: api.GetTodaysNewspaper200Response(
          id: 1,
          publishedAt: DateTime.utc(2026, 7, 1),
          stories: [
            api.Story(
              id: 1,
              resourceId: 1,
              kind: api.StoryKindEnum.feedEntry,
              title: 'Demystifying evals for AI agents',
              source_: 'Cursor AI Blog',
            ),
          ],
        ).toJson(),
      )
      ..onGet(
        '/feed-entries/1',
        body: api.FeedEntry(
          id: 1,
          feedId: 1,
          url: 'https://cursor.ai/blog/1',
          title: 'Demystifying evals for AI agents',
          snapshotAt: DateTime.utc(2026),
        ).toJson(),
      );
    await pumpAppWithAuth(t, server);

    expect(t(AppDebugKey.todayScreen), findsOneWidget);
    await t(AppDebugKey.storyCard('Demystifying evals for AI agents')).tap();
    await t(AppDebugKey.feedEntryReaderScreen).waitUntilVisible();
    await t(
      AppDebugKey.readerTitle('Demystifying evals for AI agents'),
    ).waitUntilVisible();
  });
}
