import Shared
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Share-sheet entry point: pull the shared URL out of the extension item,
/// POST it to the reading list, show the result.
///
/// Hosts SwiftUI in a UIViewController.
class ShareViewController: UIViewController {
  private let model = SaveStateModel()
  private var uploader: ReadingListUploader?

  private enum ShareError: Error {
    case noSharedURL
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // With no storyboard, the root view is a plain opaque UIView.
    // Both properties have to be set for the host app to stay visible
    // behind the dialog; a clear background on a view still marked opaque
    // has no defined rendering result.
    view.isOpaque = false
    view.backgroundColor = .clear

    extractSharedLink { [weak self] link in
      guard let self else { return }
      guard let link else {
        // Nothing worth saving; back out without showing a dialog.
        self.extensionContext?.cancelRequest(
          withError: ShareError.noSharedURL
        )
        return
      }
      self.present(url: link.url, title: link.title)

      guard let token = SecureStorage.read(SecureStorage.authTokenKey)
      else {
        model.state = .error(.unauthenticated)
        return
      }
      let uploader = ReadingListUploader { [weak self] state in
        self?.model.state = state
      }
      self.uploader = uploader
      uploader.upload(url: link.url, title: title, token: token)
    }
  }

  private func present(url: String, title: String?) {
    let hosting = UIHostingController(
      rootView: SaveWebClipView(
        url: url,
        title: title,
        model: model,
        onClose: { [weak self] in
          // Never cancels the upload: it already belongs to nsurlsessiond.
          self?.extensionContext?.completeRequest(
            returningItems: [],
            completionHandler: nil
          )
        }
      )
    )
    hosting.view.backgroundColor = .clear
    hosting.view.translatesAutoresizingMaskIntoConstraints = false

    addChild(hosting)
    view.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(
        equalTo: view.trailingAnchor
      ),
    ])
    hosting.didMove(toParent: self)
  }

  // MARK: - Extracting the shared URL

  /// The host app shares a public.url or a public.plain-text, which may read
  /// "Page Title https://example.com/x". Both shapes are handled.
  ///
  /// The placeholder title rides on attributedContentText, which is where Safari
  /// puts the page title for a public.url share (attributedTitle is nil there,
  /// despite the name).
  ///
  /// It is only trusted on that path: on the plain-text fallback the same field
  /// is the shared text, which is not a title.
  private func extractSharedLink(
    completion: @escaping ((url: String, title: String?)?) -> Void
  ) {
    let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
    let providers = items.flatMap { $0.attachments ?? [] }
    let webTitle = items.compactMap { $0.attributedContentText?.string }
      .first

    func finish(_ url: String?, _ title: String?) {
      DispatchQueue.main.async { completion(url.map { ($0, title) }) }
    }

    // See public.url first.
    let urlType = UTType.url.identifier
    if let provider = providers.first(where: {
      $0.hasItemConformingToTypeIdentifier(urlType)
    }) {
      provider.loadItem(forTypeIdentifier: urlType) { item, _ in
        finish(
          (item as? URL).map(\.absoluteString).flatMap(Self.httpLink),
          webTitle
        )
      }
      return
    }

    // Fall back to public.plain-text otherwise.
    let textType = UTType.plainText.identifier
    if let provider = providers.first(where: {
      $0.hasItemConformingToTypeIdentifier(textType)
    }) {
      provider.loadItem(forTypeIdentifier: textType) { item, _ in
        finish((item as? String).flatMap(Self.firstHTTPLink), nil)
      }
      return
    }

    finish(nil, nil)
  }

  private nonisolated static func firstHTTPLink(in text: String) -> String? {
    guard
      let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
      )
    else {
      return nil
    }

    let full = NSRange(text.startIndex..., in: text)
    guard
      let match = detector.firstMatch(in: text, options: [], range: full),
      let range = Range(match.range, in: text)
    else {
      return nil
    }

    return httpLink(String(text[range]))
  }

  private nonisolated static func httpLink(_ candidate: String) -> String? {
    let scheme = URL(string: candidate)?.scheme?.lowercased()
    return scheme == "http" || scheme == "https" ? candidate : nil
  }

}
