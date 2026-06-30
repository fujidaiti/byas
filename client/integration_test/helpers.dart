import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/main.dart';
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
