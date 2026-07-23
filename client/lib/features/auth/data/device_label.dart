import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Builds the `device` label sent to `/signup` and `/signin`, in the form
/// `<device model>/<os version>` (e.g. `iPhone15,3/17.4`, `Pixel 8 Pro/14`).
/// Stored server-side alongside the issued token for session debugging.
Future<String> buildDeviceLabel() async {
  final plugin = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    return '${info.model}/${info.version.release}';
  }
  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    return '${info.utsname.machine}/${info.systemVersion}';
  }
  if (Platform.isMacOS) {
    final info = await plugin.macOsInfo;
    return '${info.model}/${info.osRelease}';
  }
  return Platform.operatingSystem;
}
