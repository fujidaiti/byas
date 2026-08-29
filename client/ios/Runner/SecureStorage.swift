import Foundation
import Security

/// Native-side backing store for the app's secure key-value storage, reached from Dart
/// through a MethodChannel in `AppDelegate`.
///
/// Values live in a Keychain generic-password item, which encrypts them for us.
enum SecureStorage {
  static let service = "dev.norelease.paperdoll"

  struct Failure: Error {
    let status: OSStatus
  }

  static func read(_ key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data
    else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  /// Writes [value], or removes the item when it is nil.
  static func write(_ key: String, _ value: String?) throws {
    let identity: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrAccessGroup as String: appGroupIdentifier,
    ]

    // Delete first: SecItemAdd on an existing item fails with errSecDuplicateItem, and
    // this puts removal and overwrite on one path.
    let deleted = SecItemDelete(identity as CFDictionary)
    guard deleted == errSecSuccess || deleted == errSecItemNotFound else {
      throw Failure(status: deleted)
    }
    guard let value else { return }

    var item = identity
    item[kSecValueData as String] = Data(value.utf8)
    // Keeps the token out of iCloud backup and device transfer.
    item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

    let added = SecItemAdd(item as CFDictionary, nil)
    guard added == errSecSuccess else { throw Failure(status: added) }
  }
}
