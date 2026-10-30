import Foundation

/// Uses the SDKs' typed results instead of relying on plugin callback signatures.
struct OAuthCallbackRouter {
  typealias MSALHandler = (URL, String?) -> Bool
  typealias GoogleHandler = (URL) -> Bool

  private let msal: MSALHandler
  private let google: GoogleHandler

  init(msal: @escaping MSALHandler, google: @escaping GoogleHandler) {
    self.msal = msal
    self.google = google
  }

  func handle(_ url: URL, sourceApplication: String?) -> Bool {
    if msal(url, sourceApplication) {
      return true
    }
    return google(url)
  }
}
