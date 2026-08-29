import Foundation

/// The App Group the Flutter app and the share extension share. Must match the
/// `com.apple.security.application-groups` entitlement of both targets
/// (Config/Runner.entitlements, Config/ShareExtension.entitlements).
///
/// It backs two things: the Keychain access group `SecureStorage` writes into, and the
/// container the upload bodies below live in.
public enum AppGroup {
    public static let identifier = "group.dev.norelease.paperdoll"

    /// Directory holding the JSON bodies of in-flight reading list uploads.
    ///
    /// Background uploads are file-based — there is no in-memory body — so the share
    /// extension writes one here and whichever process sees the task finish deletes it:
    /// the extension while its dialog is still up, the app once the extension is gone.
    public static var uploadBodyDirectory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appendingPathComponent("ShareUploads", isDirectory: true)
    }

    /// Body file of the upload task named [name]. The name travels with the task as its
    /// `taskDescription`, which is persisted, so it outlives the process that started it.
    public static func uploadBody(named name: String) -> URL? {
        uploadBodyDirectory?.appendingPathComponent(name)
    }

    public static func removeUploadBody(named name: String) {
        guard let body = uploadBody(named: name) else { return }
        try? FileManager.default.removeItem(at: body)
    }

    /// Configuration for the background session that carries an upload. Both processes
    /// build it from here so they agree on `sharedContainerIdentifier`, which is what lets
    /// the app reattach to a session the extension started.
    public static func backgroundSessionConfiguration(identifier sessionIdentifier: String)
        -> URLSessionConfiguration
    {
        let configuration = URLSessionConfiguration.background(
            withIdentifier: sessionIdentifier
        )
        configuration.sharedContainerIdentifier = identifier
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        return configuration
    }
}
