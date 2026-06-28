import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/main.dart';

/// Base URL of the locally running Prism mock server
/// (`prism mock api/api.yaml`).
const prismBaseUrl = 'http://127.0.0.1:4010';

/// Launches the real app with [appConfigProvider] overridden to point dio at
/// the Prism mock server, then pumps the first frame.
Future<void> pumpApp(
  WidgetTester tester, {
  String baseUrl = prismBaseUrl,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig(baseUrl))],
      child: const PaperdollApp(),
    ),
  );
  await tester.pump();
}

/// Pumps frames until [finder] matches or the timeout elapses. Used instead of
/// pumpAndSettle because the loading spinner animates forever and because
/// responses arrive over a real (local) HTTP round-trip.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Timed out waiting for: $finder');
}
