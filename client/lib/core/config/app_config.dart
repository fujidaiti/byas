/// Immutable build/runtime configuration, read from `--dart-define-from-file`.
class AppConfig {
  const AppConfig(this.apiBaseUrl);

  /// Base URL of the Paperdoll REST API.
  final String apiBaseUrl;
}
