import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/features/auth/data/token_storage.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:patrol/patrol.dart';

/// Boots the app. Defaults to a pre-seeded [token] so feature tests land
/// straight on Today without going through the sign-in screen; pass `null`
/// to start signed out (used by auth-flow tests).
Future<void> pumpApp(
  PatrolIntegrationTester $, {
  String? token = 'test-token',
}) async {
  await $.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage(token)),
      ],
      child: const PaperdollApp(),
    ),
  );
}

/// In-memory [TokenStorage] fake, so tests don't touch the real secure
/// storage plugin and each test starts from a known state.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

/// Creates a [DioAdapter] for HTTP mocking.
///
/// Make sure to [pumpApp] before calling this function.
DioAdapter httpMockAdapter(PatrolIntegrationTester $) {
  final dio = $.tester.container().read(dioProvider);
  return DioAdapter(dio: dio, matcher: const FullHttpRequestMatcher());
}
