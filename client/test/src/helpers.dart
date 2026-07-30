import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:openapi/api.dart' as api;
import 'package:paperdoll/app.dart';
import 'package:paperdoll/core/config/app_config.dart';
import 'package:paperdoll/core/config/app_config_provider.dart';
import 'package:paperdoll/core/network/dio_provider.dart';
import 'package:patrol_finders/patrol_finders.dart';

/// Boots the whole app on the Flutter test framework, with in-memory
/// stand-ins for everything the app would otherwise get from a device: no
/// network, no secure storage plugin, no device info plugin.
///
/// Starts signed out unless [token] is given. Returns the [DioAdapter] every
/// HTTP call goes through, pre-stubbed with an empty account so the app
/// always has somewhere to land. Registering a route again overrides the
/// default — the last matching registration wins.
///
/// Requests carrying a body only match a registration that declares the same
/// `data`, so always pass it for `onPost`/`onPut`/`onPatch`; an unmatched
/// request quietly turns into an `UnknownError` instead of a loud failure.
Future<DioAdapter> pumpApp(PatrolTester $, {String? token}) async {
  // Backs the real SecureTokenStorage with an in-memory map, so the token
  // takes the same path it does in production.
  FlutterSecureStorage.setMockInitialValues({'auth_token': ?token});
  _stubDeviceInfo();

  // The adapter has to exist before the first frame: signed in, the app lands
  // on Today and fetches right away.
  final container = ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig('http://mock')),
    ],
  );
  final adapter = DioAdapter(
    dio: container.read(dioProvider),
    matcher: const FullHttpRequestMatcher(),
  );
  _stubEmptyAccount(adapter);

  await $.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PaperdollApp(),
    ),
  );
  // The splash screen outlives the first settle: reading the token and the
  // redirect that follows land a frame later.
  await $.pumpAndSettle();
  return adapter;
}

/// The three shell tabs, all empty: enough for any test to boot and navigate
/// without stubbing anything itself.
void _stubEmptyAccount(DioAdapter adapter) {
  adapter
    ..onGet(
      '/newspapers/today',
      (server) => server.reply(
        200,
        api.GetTodaysNewspaper200Response(
          id: 1,
          publishedAt: DateTime.utc(2026, 7, 1),
        ).toJson(),
      ),
    )
    ..onGet(
      '/reading-list',
      (server) => server.reply(200, api.GetReadingList200Response().toJson()),
    )
    ..onGet(
      '/feeds',
      (server) => server.reply(200, api.GetFeeds200Response().toJson()),
    );
}

/// Answers device_info_plus' platform channel with a fixed Android device, so
/// the `device` label sent to `/signup` and `/signin` is deterministic:
/// `Pixel 8 Pro/android-14`. Tests run as [TargetPlatform.android].
void _stubDeviceInfo() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/device_info'),
        (call) async => _androidDeviceInfo.data,
      );
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
