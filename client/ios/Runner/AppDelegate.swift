import Flutter
import Shared
import UIKit

private let secureStorageChannel = "dev.norelease.paperdoll/secure_storage"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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

    private var backgroundSessionCompletionHandlers: [String: () -> Void] = [:]

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
        configuration.sharedContainerIdentifier = AppGroup.identifier
        _ = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    /// Upload bodies older than this are assumed orphaned and swept on launch.
    private let orphanedBodyAge: TimeInterval = 24 * 60 * 60

    /// Removes request bodies orphaned by a crash before any task delegate fired.
    /// Anything younger than the cutoff may still belong to a transfer the system is holding.
    private func sweepOrphanedUploadBodies() {
        guard let directory = AppGroup.sharedDirectory else { return }
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
}

/// Handles HTTP transfer completion events for requests that the share extension makes.
/// Since URLSession requires us to write the request body to a local file, we remove it
/// here after the transfer finishes regardless of the result.
extension AppDelegate: URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let name = task.taskDescription else { return }
        AppGroup.removeSharedFile(named: name)
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
