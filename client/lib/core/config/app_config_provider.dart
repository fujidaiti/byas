import 'package:paperdoll/core/config/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config_provider.g.dart';

@riverpod
AppConfig appConfig(Ref ref) {
  // Build-time value from --dart-define-from-file=.env. This is the single
  // point that reads the environment; tests override this provider instead.
  // ignore: do_not_use_environment
  const baseUrl = String.fromEnvironment('API_BASE_URL');
  if (!validUrl(baseUrl)) {
    throw StateError('Invalid API_BASE_URL: $baseUrl');
  }

  return const AppConfig(baseUrl);
}

bool validUrl(String s) {
  return switch (Uri.tryParse(s)) {
    null => false,
    final s => s.scheme == 'http' || s.scheme == 'https',
  };
}
