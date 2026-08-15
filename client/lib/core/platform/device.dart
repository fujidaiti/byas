import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device.g.dart';

@riverpod
Device device(Ref ref) => const Device();

/// Provides device's information on which the app is running.
class const Device() {
  static final _plugin = DeviceInfoPlugin();

  /// A human-readable string representing the device kind that isn't associated
  /// with any personal information, such as `MacBookPro18,2`.
  Future<String> label() async {
    switch (defaultTargetPlatform) {
      case .android:
        final info = await _plugin.androidInfo;
        return info.model;

      case .iOS:
        final info = await _plugin.iosInfo;
        return info.utsname.machine;

      case .macOS:
        final info = await _plugin.macOsInfo;
        return info.model;

      case final p:
        throw StateError('unsupported platform: $p');
    }
  }
}
