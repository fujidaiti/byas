import Foundation
import Shared

/// Maximum length of the placeholder title sent to the server (URL is left as-is).
private let maxTitleLength = 140

/// POSTs one URL to the reading list, on a background `URLSession` so the transfer outlives
/// this extension.
///
/// iOS kills the extension the moment it calls `completeRequest`, so the request is handed
/// to `nsurlsessiond` rather than run in-process. While the dialog is still up we get the
/// delegate callbacks ourselves and report the outcome; once it is gone, `Runner` picks
/// them up instead and silently cleans up the body file.
final class ReadingListUploader: NSObject {
  private let onFinish: (SaveState) -> Void
  private var session: URLSession?

  init(onFinish: @escaping (SaveState) -> Void) {
    self.onFinish = onFinish
  }

  func upload(url: String, title: String?, token: String) {
    do {
      // Includes a UUID so two shares in quick succession cannot collide.
      let taskName =
        "\(Bundle.main.bundleIdentifier!).\(UUID().uuidString)"
      let body = try writeBody(named: taskName, url: url, title: title)

      var request = URLRequest(
        url: AppConfig.baseURL.appendingPathComponent("reading-list")
      )
      request.httpMethod = "POST"
      request.setValue(
        "application/json",
        forHTTPHeaderField: "Content-Type"
      )
      request.setValue("application/json", forHTTPHeaderField: "Accept")
      request.setValue(
        "Bearer \(token)",
        forHTTPHeaderField: "Authorization"
      )

      let configuration = URLSessionConfiguration.background(
        withIdentifier: taskName
      )
      configuration.sharedContainerIdentifier = AppGroup.identifier
      configuration.sessionSendsLaunchEvents = true
      configuration.isDiscretionary = false

      let session = URLSession(
        configuration: configuration,
        delegate: self,
        delegateQueue: nil
      )
      self.session = session

      let task = session.uploadTask(with: request, fromFile: body)
      // Whichever process sees this task complete deletes the body by this name.
      // taskDescription is persisted with the task, so it survives our death.
      task.taskDescription = taskName
      task.resume()
    } catch {
      onFinish(.error(.unexpected))
    }
  }

  /// Background uploads are file-based — there is no in-memory body — so the JSON goes to
  /// the app group container, which Runner can reach too once this extension is gone.
  private func writeBody(named name: String, url: String, title: String?)
    throws -> URL
  {
    var payload: [String: String] = ["url": url]
    if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
      !title.isEmpty
    {
      payload["title"] = truncate(title)
    }

    guard let directory = AppGroup.sharedDirectory,
      let body = AppGroup.sharedFile(named: name)
    else {
      throw CocoaError(.fileNoSuchFile)
    }
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )

    try JSONSerialization.data(withJSONObject: payload).write(to: body)
    return body
  }

  /// Caps a title at [maxTitleLength] characters, truncating and appending "..." (so the
  /// result never exceeds the limit) when it is longer.
  private func truncate(_ title: String) -> String {
    guard title.count > maxTitleLength else { return title }
    return title.prefix(maxTitleLength - 3) + "..."
  }
}

extension ReadingListUploader: URLSessionDataDelegate {
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    if let name = task.taskDescription {
      AppGroup.removeSharedFile(named: name)
    }

    let state: SaveState
    if let error {
      // Note this is not the offline case: a background session waits for connectivity
      // rather than failing, so being offline keeps the dialog in .loading and the upload
      // lands later. Reaching here means the transfer genuinely gave up.
      state = error is URLError ? .error(.network) : .error(.unexpected)
    } else if let response = task.response as? HTTPURLResponse,
      !(200..<300).contains(response.statusCode)
    {
      state = .error(.unexpected)
    } else {
      state = .success
    }

    DispatchQueue.main.async { self.onFinish(state) }
  }
}
