import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:patrol/patrol.dart';

Future<void> pumpApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
      ],
      child: const PaperdollApp(),
    ),
  );
}

/// Creates a [DioAdapter] for HTTP mocking.
///
/// Make sure to [pumpApp] before calling this function.
DioAdapter httpMockAdapter(PatrolIntegrationTester $) {
  final dio = $.tester.container().read(dioProvider);
  return DioAdapter(dio: dio, matcher: const FullHttpRequestMatcher());
}
