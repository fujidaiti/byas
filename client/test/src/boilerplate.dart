import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:paperdoll/core/platform/device.dart';
import 'package:paperdoll/core/platform/secure_storage.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'stub_server.dart';

/// Boots the whole app on the Flutter test framework, with in-memory
/// stand-ins for everything the app would otherwise get from a device: no
/// network, no secure storage plugin, no device info plugin.
///
/// Starts signed out unless [token] is given. Returns the [StubServer] every
/// HTTP call goes through, pre-stubbed with an empty account so the app
/// always has somewhere to land. Registering a route again overrides the
/// default — the last matching registration wins.
///
/// A stub may declare a subset of the request body (extra keys are ignored) or
/// omit the body entirely to match any request for the route. Any request no
/// stub matches fails the test at teardown, naming the endpoint.
Future<StubServer> pumpApp(PatrolTester $, {String? token}) async {
  final container = ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
      deviceProvider.overrideWithValue(_StubDevice()),
      secureStorageProvider.overrideWithValue(_InMemorySecureStorage()),
    ],
  );

  final server = StubServer.withDefaultResponses();
  container.read(dioProvider).interceptors.add(server);
  addTearDown(
    () => expect(
      server.unmatched,
      isEmpty,
      reason: 'App made unstubbed request(s): ${server.unmatched}',
    ),
  );

  if (token != null) {
    await container.read(authRepositoryProvider).writeAuthToken(token);
  }

  await $.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PaperdollApp(),
    ),
  );
  // The splash screen outlives the first settle: reading the token and the
  // redirect that follows land a frame later.
  await $.pumpAndTrySettle();

  return server;
}

class _InMemorySecureStorage implements SecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

class _StubDevice implements Device {
  @override
  Future<String> label() {
    return Future.value('TestDevice');
  }
}
