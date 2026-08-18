import Combine
import SwiftUI

/// Straight port of SaveWebClipScreen.kt, copy included.
enum SaveErrorKind {
  /// The transfer genuinely gave up (not merely offline — see ReadingListUploader).
  case network
  /// No auth token is stored locally, so nothing was sent.
  case unauthenticated
  /// The server responded with an error, or anything else went wrong.
  case unexpected

  var message: String {
    switch self {
    case .network: "Couldn't reach the server. Check your connection and try again."
    case .unauthenticated: "Log in to Paperdoll first, then try sharing again."
    case .unexpected: "Couldn't add to your reading list. Please try again."
    }
  }
}

enum SaveState {
  case loading
  case success
  case error(SaveErrorKind)

  var headline: String {
    switch self {
    case .loading: "Adding to Reading List…"
    case .success: "Added to Reading List"
    case .error: "Couldn't Save"
    }
  }
}

final class SaveStateModel: ObservableObject {
  @Published var state: SaveState = .loading
}

/// Dialog shown over the host app while the share is saved. Sized and laid out to match
/// Android's Theme.SaveWebClip.Dialog rather than iOS's default full-height share sheet.
struct SaveWebClipView: View {
  let url: String
  let title: String?
  @ObservedObject var model: SaveStateModel
  let onClose: () -> Void

  private static let dialogHeight: CGFloat = 280

  /// Falls back to the raw URL when the host app didn't share a page title.
  private var label: String {
    let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.flatMap { $0.isEmpty ? nil : $0 } ?? url
  }

  /// When a title is shown, surface the URL's domain beneath it. When it isn't, the URL is
  /// already the label, so there's nothing extra to show.
  private var domain: String? {
    guard label != url, let host = URL(string: url)?.host else { return nil }
    let bare = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    return bare.isEmpty ? nil : bare
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(model.state.headline)
        .font(.title2.weight(.semibold))
        .frame(maxWidth: .infinity, alignment: .leading)
      Spacer().frame(height: 24)

      switch model.state {
      case .loading:
        ProgressView()
        Spacer().frame(height: 16)
        pageTitle
      case .success:
        pageTitle
      case .error(let kind):
        Text(kind.message)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      if let domain, !isError {
        Spacer().frame(height: 8)
        Text(domain)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer()
      // Available from the first frame: closing early doesn't cancel the transfer.
      Button("Close", action: onClose)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(24)
    .frame(height: Self.dialogHeight)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.35).ignoresSafeArea())
  }

  private var isError: Bool {
    if case .error = model.state { return true }
    return false
  }

  /// The saved page's title (or its URL when no title was shared), in a prominent style.
  private var pageTitle: some View {
    Text(label)
      .font(.body)
      .lineLimit(4)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
