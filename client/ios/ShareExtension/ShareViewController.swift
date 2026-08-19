import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Share-sheet entry point, the iOS counterpart of Android's SaveWebClipActivity: pull the
/// shared URL out of the extension item, POST it to the reading list, show the result.
///
/// Hosts SwiftUI in a UIViewController because the extension point wants a view controller
/// (MainInterface.storyboard names this class). The storyboard's root view is transparent,
/// so the dialog draws over the host app.
class ShareViewController: UIViewController {
  private let model = SaveStateModel()
  private var uploader: ReadingListUploader?

  private enum ShareError: Error {
    case noSharedURL
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    extractSharedLink { [weak self] link in
      guard let self else { return }
      guard let link else {
        // Nothing worth saving; back out without a dialog, like SaveWebClipActivity's
        // bare finish().
        self.extensionContext?.cancelRequest(withError: ShareError.noSharedURL)
        return
      }
      self.present(url: link.url, title: link.title)
    }
  }

  private func present(url: String, title: String?) {
    let hosting = UIHostingController(
      rootView: SaveWebClipView(
        url: url, title: title, model: model,
        onClose: { [weak self] in
          // Never cancels the upload: it already belongs to nsurlsessiond.
          self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }))
    hosting.view.backgroundColor = .clear
    hosting.view.translatesAutoresizingMaskIntoConstraints = false

    addChild(hosting)
    view.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    hosting.didMove(toParent: self)

    guard let token = readAuthToken() else {
      model.state = .error(.unauthenticated)
      return
    }
    let uploader = ReadingListUploader { [weak self] state in self?.model.state = state }
    self.uploader = uploader
    uploader.upload(url: url, title: title, token: token)
  }

  // MARK: - Extracting the shared URL

  /// Browsers share a public.url; sharing selected text gives public.plain-text, which may
  /// read "Page Title https://example.com/x". Those are the same two shapes extractUrl()
  /// handles in SaveWebClipActivity.kt, for the same reason.
  ///
  /// The placeholder title rides on attributedContentText, which is where Safari puts the
  /// page title for a public.url share (attributedTitle is nil there, despite the name).
  /// It is Android's EXTRA_SUBJECT equivalent, so it is only trusted on that path: on the
  /// plain-text fallback the same field is the shared text, which is not a title. Better
  /// to send nothing than to invent one — SaveWebClip only overwrites the placeholder when
  /// the scrape extracts a real title, so a fabricated one would stick to a page the
  /// scraper cannot read forever, and an empty title is what tells the reading list it has
  /// none to show.
  private func extractSharedLink(completion: @escaping ((url: String, title: String?)?) -> Void) {
    let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
    let providers = items.flatMap { $0.attachments ?? [] }
    let webTitle = items.compactMap { $0.attributedContentText?.string }.first

    func finish(_ url: String?, _ title: String?) {
      DispatchQueue.main.async { completion(url.map { ($0, title) }) }
    }

    let urlType = UTType.url.identifier
    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(urlType) }) {
      provider.loadItem(forTypeIdentifier: urlType) { item, _ in
        finish((item as? URL).map(\.absoluteString).flatMap(Self.httpURL), webTitle)
      }
      return
    }

    let textType = UTType.plainText.identifier
    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(textType) }) {
      provider.loadItem(forTypeIdentifier: textType) { item, _ in
        finish((item as? String).flatMap(Self.firstLink), nil)
      }
      return
    }

    finish(nil, nil)
  }

  private static func firstLink(in text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    else {
      return nil
    }
    let full = NSRange(trimmed.startIndex..., in: trimmed)
    for match in detector.matches(in: trimmed, range: full) {
      // Check the matched text, not the URL the detector built from it: the scheme guard
      // is what keeps a bare "example.com" inside a page title from being saved.
      let candidate = (trimmed as NSString).substring(with: match.range)
      if let url = httpURL(candidate) { return url }
    }
    return nil
  }

  private static func httpURL(_ candidate: String) -> String? {
    let scheme = URL(string: candidate)?.scheme?.lowercased()
    return scheme == "http" || scheme == "https" ? candidate : nil
  }
}
