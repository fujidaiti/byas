import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest('sample test', ($) async {
    await setUpServer(
      debugLabel: 'sample test',
      scenarioId: 'sample_test_scenario',
    );
    await $.pumpWidget(const ProviderScope(child: PaperdollApp()));
    await $.pumpAndTrySettle();
    expect($(AppDebugKey.todayScreen), findsOneWidget);
  });
}
