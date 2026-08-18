import Foundation

/// Base URL of the Paperdoll REST API, compiled in.
///
/// The extension has no access to Flutter's --dart-define, so the value arrives as a build
/// setting instead: Config/APIConfig.xcconfig → Config/ShareExtension.xcconfig →
/// Info.plist's APIBaseURL. See ios/README.md.
enum APIConfig {
  static let baseURL: URL = {
    let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
    // A build misconfiguration, not a runtime condition — the same stance as Android's
    // Gradle build failing on a missing API_BASE_URL. An unexpanded "$(…)" means
    // APIConfig.xcconfig was never created.
    guard let raw, !raw.isEmpty, !raw.hasPrefix("$("), let url = URL(string: raw) else {
      preconditionFailure(
        "APIBaseURL is missing or unresolved. Copy Config/APIConfig.example.xcconfig to "
          + "Config/APIConfig.xcconfig.")
    }
    return url
  }()
}
