import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
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
  // Backs the real SecureTokenStorage with an in-memory map, so the token
  // takes the same path it does in production.
  FlutterSecureStorage.setMockInitialValues({'auth_token': ?token});
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
