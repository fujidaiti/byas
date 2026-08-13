// Bumps <target>.versionName/buildNumber in versions.json for a release.
// Run this locally, review the diff, then commit and open a PR.
//
//   fvm dart run tool/bump_version.dart android [--beta]
import 'dart:convert';
import 'dart:io';

// Edit this to change the major version (see release-ci-design doc §4.1).
const majorVersion = 1;

const supportedTargets = {'android'};

final betaSuffixPattern = RegExp(r'^(.+)\.beta(\d+)$');

void main(List<String> arguments) {
  final usageError =
      arguments.isEmpty ||
      arguments.length > 2 ||
      !supportedTargets.contains(arguments[0]) ||
      (arguments.length == 2 && arguments[1] != '--beta');
  if (usageError) {
    stderr.writeln(
      'Usage: fvm dart run tool/bump_version.dart <target> [--beta]',
    );
    stderr.writeln('  target: ${supportedTargets.join(', ')}');
    exit(1);
  }

  final target = arguments[0];
  final beta = arguments.length == 2;

  final versionsFile = File('versions.json');
  final versions =
      jsonDecode(versionsFile.readAsStringSync()) as Map<String, dynamic>;
  final section = versions[target] as Map<String, dynamic>;

  final currentVersionName = section['versionName'] as String;
  final currentBuildNumber = section['buildNumber'] as int;
  final newBuildNumber = currentBuildNumber + 1;
  final newVersionName = nextVersionName(currentVersionName, beta: beta);

  section['versionName'] = newVersionName;
  section['buildNumber'] = newBuildNumber;

  const encoder = JsonEncoder.withIndent('  ');
  versionsFile.writeAsStringSync('${encoder.convert(versions)}\n');

  stdout.writeln('Bumped $target version:');
  stdout.writeln('  versionName = $newVersionName');
  stdout.writeln('  buildNumber = $newBuildNumber');
  stdout.writeln('');
  stdout.writeln('Next steps:');
  stdout.writeln('  git add versions.json');
  stdout.writeln('  git commit -m "Bump $target version to $newVersionName"');
  stdout.writeln(
    '  # open a PR and merge; the Version Tagging workflow will create the tag',
  );
}

String nextVersionName(String currentVersionName, {required bool beta}) {
  final currentBetaMatch = betaSuffixPattern.firstMatch(currentVersionName);
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
