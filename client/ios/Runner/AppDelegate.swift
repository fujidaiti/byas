import Flutter
import UIKit

private let secureStorageChannel = "dev.norelease.paperdoll/secure_storage"

/// App group container shared with the share extension, which writes upload bodies into
/// it. Declared there too — see `ShareExtension/ReadingListUploader.swift`.
///
/// It doubles as the Keychain access group holding the auth token, which is why
/// `SecureStorage.swift` reaches for this: an app group name is a valid access group, and
/// carries no team-id prefix that would have to be resolved at signing time.
let appGroupIdentifier = "group.dev.norelease.paperdoll"
private let uploadBodyDirectory = "ShareUploads"

/// Upload bodies older than this are assumed orphaned and swept on launch.
private let orphanedBodyAge: TimeInterval = 24 * 60 * 60

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    /// Held between `handleEventsForBackgroundURLSession` and the session telling us it has
    /// delivered everything it had.
    private var backgroundSessionCompletionHandlers: [String: () -> Void] = [:]

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        sweepOrphanedUploadBodies()
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func didInitializeImplicitFlutterEngine(
        _ engineBridge: FlutterImplicitEngineBridge
    ) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // The Dart side is `SecureStorage` in lib/core/platform/secure_storage.dart.
        FlutterMethodChannel(
            name: secureStorageChannel,
            binaryMessenger: engineBridge.applicationRegistrar.messenger()
        ).setMethodCallHandler { call, result in
            guard
                let key = (call.arguments as? [String: Any])?["key"] as? String
            else {
                result(
                    FlutterError(
                        code: "secure_storage_failed",
                        message: "key is missing",
                        details: nil
                    )
                )
                return
            }
            do {
                switch call.method {
                case "read":
                    result(SecureStorage.read(key))
                case "write":
                    try SecureStorage.write(
                        key,
                        (call.arguments as? [String: Any])?["value"] as? String
                    )
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                result(
                    FlutterError(
                        code: "secure_storage_failed",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        }
    }

    override func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        backgroundSessionCompletionHandlers[identifier] = completionHandler

        // Create a new session with the ID that the share extension generated,
        // so that we can receive session events.
        let configuration = URLSessionConfiguration.background(
            withIdentifier: identifier
        )
        configuration.sharedContainerIdentifier = appGroupIdentifier
        _ = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    /// Removes bodies orphaned by a crash before any task delegate fired.
    /// Anything younger than the cutoff may still belong to a transfer the system is holding.
    private func sweepOrphanedUploadBodies() {
        guard let directory = uploadBodyDirectoryURL else { return }
        let cutoff = Date().addingTimeInterval(-orphanedBodyAge)
        let bodies =
            (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )) ?? []

        for body in bodies {
            let modified = try? body.resourceValues(forKeys: [
                .contentModificationDateKey
            ])
            .contentModificationDate
            if let modified, modified < cutoff {
                try? FileManager.default.removeItem(at: body)
            }
        }
    }

    fileprivate var uploadBodyDirectoryURL: URL? {
        FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            )?
            .appendingPathComponent(uploadBodyDirectory, isDirectory: true)
    }
}

/// Handles HTTP transfer completion events for requests that the share extension makes.
/// Since URLSession requires us to write the request body to a local file, we remove it here
/// after the transfer finishes regardless of the result.
extension AppDelegate: URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let name = task.taskDescription,
            let directory = uploadBodyDirectoryURL
        else { return }
        try? FileManager.default.removeItem(
            at: directory.appendingPathComponent(name)
        )
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        guard let identifier = session.configuration.identifier else { return }
        let completionHandler = backgroundSessionCompletionHandlers.removeValue(
            forKey: identifier
        )
        // UIKit requires this on the main thread.
        DispatchQueue.main.async { completionHandler?() }
    }
}
