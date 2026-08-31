import Foundation

public enum AppGroup {
  ///  Make sure this matches `com.apple.security.application-groups` entitlement
  ///  of both targets.
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
