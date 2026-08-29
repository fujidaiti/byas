import Foundation

/// Base URL of the Paperdoll REST API, compiled in.
///
/// The extension has no access to Flutter's --dart-define, so the value arrives as a build
/// setting instead: Config/App.xcconfig → Config/ShareExtension.xcconfig →
/// Info.plist's APIBaseURL. See ios/README.md.
enum AppConfig {
  static let baseURL: URL = {
    let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
    // A build misconfiguration, not a runtime condition, so it fails loudly. An
    // unexpanded "$(…)" means App.xcconfig was never created.
    guard let raw, !raw.isEmpty, !raw.hasPrefix("$("), let url = URL(string: raw) else {
      preconditionFailure(
        "APIBaseURL is missing or unresolved. Copy Config/App.example.xcconfig to "
          + "Config/App.xcconfig.")
    }
    return url
  }()
}
