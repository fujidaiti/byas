import 'dart:convert';
import 'dart:io';

const majorVersion = 0;

const indent = '\u0020\u0020';

final betaSuffixPattern = RegExp(r'^(.+)\.beta(\d+)$');

/// Bumps the version name and build number in the given version file for a
/// release.
///
/// Each platform keeps its own version file next to its build files, e.g.
/// `client/android/version.json`:
///
/// ```json
/// {
///   "versionName": "1.20260813.0000.beta1",
///   "buildNumber": 1
/// }
/// ```
///
/// `versionName` follows `<major>.<yyyymmdd>.<HHMM>[.betaN]` (UTC). The
/// `.betaN` suffix marks a stg release; without it, the version is treated
/// as prod. `buildNumber` must increase by exactly 1 each time. The Version
/// Tagging workflow validates both rules; this script itself doesn't.
///
/// Usage: `dart run tool/bump_version.dart -f <version.json> [--beta]`
///
/// - `-f`: path to the version file to bump. If it doesn't exist yet, it's
///         created with `buildNumber` `1` and, if `--beta` is set,
///         `versionName` suffixed `.beta1`.
/// - `--beta`: marks the release as a beta. If the current version is already
///             a beta, its beta number is bumped (e.g. `.beta1` -> `.beta2`)
///             instead of generating a new dated version. Without this flag,
///             a fresh, unsuffixed (prod-channel) version is produced instead.
void main(List<String> arguments) {
  String? path;
  var beta = false;
  var usageError = false;
  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '-f' when i + 1 < arguments.length:
        path = arguments[++i];
      case '--beta':
        beta = true;
      default:
        usageError = true;
    }
  }

  if (usageError || path == null) {
    stderr.writeln(
      'Usage: fvm dart run tool/bump_version.dart -f <version.json> [--beta]',
    );
    exit(1);
  }

  final versionFile = File(path);
  final version = versionFile.existsSync()
      ? jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};

  final currentVersionName = version['versionName'] as String?;
  final currentBuildNumber = version['buildNumber'] as int? ?? 0;
  final newBuildNumber = currentBuildNumber + 1;
  final newVersionName = nextVersionName(currentVersionName, beta: beta);

  version['versionName'] = newVersionName;
  version['buildNumber'] = newBuildNumber;

  const encoder = JsonEncoder.withIndent(indent);
  versionFile.writeAsStringSync('${encoder.convert(version)}\n');

  stdout.writeln('Bumped $path:');
  stdout.writeln('${indent}version = $newVersionName');
  stdout.writeln('${indent}build = $newBuildNumber');
}

String nextVersionName(String? currentVersionName, {required bool beta}) {
  final currentBetaMatch = currentVersionName == null
      ? null
      : betaSuffixPattern.firstMatch(currentVersionName);
  if (beta && currentBetaMatch != null) {
    final base = currentBetaMatch.group(1);
    final nextBetaNumber = int.parse(currentBetaMatch.group(2)!) + 1;
    return '$base.beta$nextBetaNumber';
  }

  final now = DateTime.now().toUtc();
  final datePart = '${now.year}${_pad(now.month)}${_pad(now.day)}';
  final timePart = '${_pad(now.hour)}${_pad(now.minute)}';
  final versionName = '$majorVersion.$datePart.$timePart';
  return beta ? '$versionName.beta1' : versionName;
}

String _pad(int value) => value.toString().padLeft(2, '0');
