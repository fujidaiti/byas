import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
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
  // Answers device_info_plus' platform channel with a fixed Android device.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/device_info'),
        (call) async => _androidDeviceInfo.data,
      );

  // The server has to exist before the first frame: signed in, the app lands
  // on Today and fetches right away.
  final container = ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
      secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
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

  // Seed the token through the real persistence path, so signed-in tests start
  // exactly where a returning user would.
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

/// An in-memory [SecureStorage] so tokens take the same path they do in
/// production, without touching the real secure-storage plugin.
class InMemorySecureStorage implements SecureStorage {
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

final AndroidDeviceInfo _androidDeviceInfo =
    AndroidDeviceInfo.setMockInitialValues(
      version: AndroidBuildVersion.setMockInitialValues(
        codename: 'REL',
        incremental: '1',
        previewSdkInt: 0,
        release: '14',
        sdkInt: 34,
      ),
      board: 'test-board',
      bootloader: 'test-bootloader',
      brand: 'google',
      device: 'test-device',
      display: 'test-display',
      fingerprint: 'test-fingerprint',
      hardware: 'test-hardware',
      host: 'test-host',
      id: 'test-id',
      manufacturer: 'Google',
      model: 'Pixel 8 Pro',
      product: 'test-product',
      name: 'test-name',
      supported32BitAbis: const [],
      supported64BitAbis: const ['arm64-v8a'],
      supportedAbis: const ['arm64-v8a'],
      tags: 'release-keys',
      type: 'user',
      isPhysicalDevice: true,
      freeDiskSize: 0,
      totalDiskSize: 0,
      systemFeatures: const [],
      isLowRamDevice: false,
      physicalRamSize: 0,
      availableRamSize: 0,
    );
