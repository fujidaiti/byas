import Foundation
import Security

/// Native-side backing store for the app's secure key-value storage, reached from Dart
/// through a MethodChannel in `AppDelegate`.
///
/// Values live in a Keychain generic-password item, which encrypts them for us.
///
/// The share extension reads the auth token straight out of the Keychain rather than
/// linking this file (see `ShareExtension/ReadingListUploader.swift`); it needs one read,
/// not this whole surface. That means `service` and the key names are declared in both
/// places. Change one, change the other: nothing breaks at compile time, and the
/// extension would just read nil forever and claim the user is logged out.
enum SecureStorage {
  static let service = "dev.norelease.paperdoll"

  struct Failure: Error {
    let status: OSStatus
  }

  static func read(_ key: String) -> String? {
    // Deliberately no kSecAttrAccessGroup: a query without one searches every group this
    // process can reach, so the item is found wherever the entitlement allows and a read
    // can never look in the wrong place.
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
      // The one place the access group is named. It is the app group rather than a
      // dedicated Keychain group: an app group name doubles as a Keychain access group,
      // and unlike a Keychain group it carries no team-id prefix, so the string is a
      // literal here instead of something Info.plist has to resolve at signing time.
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
