import Foundation

/// Constants in App.xcconfig.
enum AppConfig {
    static let baseURL: URL = {
        let raw =
            Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        guard let raw, !raw.isEmpty, !raw.hasPrefix("$("),
            let url = URL(string: raw)
        else {
            preconditionFailure(
                "APIBaseURL is missing or unresolved."
            )
        }
        return url
    }()
}
