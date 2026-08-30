import Foundation

/// The App Group the Flutter app and the share extension share. Must match the
/// `com.apple.security.application-groups` entitlement of both targets
/// (Config/Runner.entitlements, Config/ShareExtension.entitlements).
///
/// It backs two things: the Keychain access group `SecureStorage` writes into, and the
/// file container below.
public enum AppGroup {
  public static let identifier = "group.dev.norelease.paperdoll"

  /// Directory both targets can read and write, for files one of them hands to the other.
  public static var sharedDirectory: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
      .appendingPathComponent("Shared", isDirectory: true)
  }

  public static func sharedFile(named name: String) -> URL? {
    sharedDirectory?.appendingPathComponent(name)
  }

  public static func removeSharedFile(named name: String) {
    guard let file = sharedFile(named: name) else { return }
    try? FileManager.default.removeItem(at: file)
  }
}
