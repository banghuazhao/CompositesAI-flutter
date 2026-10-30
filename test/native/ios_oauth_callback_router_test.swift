import Foundation

private enum RouterCheckFailure: Error {
  case assertion(String)
}

private func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
  if !condition() { throw RouterCheckFailure.assertion(message) }
}

@main
struct IOSOAuthCallbackRouterChecks {
  static func main() throws {
    let url = URL(string: "fixture://auth/callback?value=a%2Bb#fragment")!
    let source = "com.example.fixture"

    // Constructing the router does not initialize either SDK handler.
    var msalCalls = 0
    var googleCalls = 0
    var order: [String] = []
    var observed: [(URL, String?)] = []
    let msalHandled = OAuthCallbackRouter(
      msal: { received, sourceApplication in
        msalCalls += 1
        order.append("msal")
        observed.append((received, sourceApplication))
        return true
      },
      google: { _ in
        googleCalls += 1
        order.append("google")
        return true
      }
    )
    try check(msalCalls == 0 && googleCalls == 0, "Handler ran during initialization")
    try check(msalHandled.handle(url, sourceApplication: source), "MSAL result was lost")
    try check(msalCalls == 1 && googleCalls == 0, "Handled MSAL callback reached Google")
    try check(order == ["msal"], "MSAL did not receive priority")
    try check(observed.count == 1 && observed[0].0 == url && observed[0].1 == source,
              "MSAL URL or source application changed")

    order = []
    var googleURLs: [URL] = []
    let googleHandled = OAuthCallbackRouter(
      msal: { _, _ in order.append("msal"); return false },
      google: { received in
        order.append("google")
        googleURLs.append(received)
        return true
      }
    )
    try check(googleHandled.handle(url, sourceApplication: source), "Google result was lost")
    try check(order == ["msal", "google"] && googleURLs == [url],
              "Google fallback order, URL or call count changed")

    order = []
    let unhandled = OAuthCallbackRouter(
      msal: { _, _ in order.append("msal"); return false },
      google: { _ in order.append("google"); return false }
    )
    try check(!unhandled.handle(url, sourceApplication: source), "Unhandled URL was consumed")
    try check(order == ["msal", "google"], "Unhandled callback invoked a handler more than once")

    observed = []
    var noSourceGoogleCalls = 0
    let noSource = OAuthCallbackRouter(
      msal: { received, sourceApplication in
        observed.append((received, sourceApplication))
        return true
      },
      google: { _ in noSourceGoogleCalls += 1; return false }
    )
    try check(noSource.handle(url, sourceApplication: nil), "Nil-source callback was lost")
    try check(observed.count == 1 && observed[0].0 == url && observed[0].1 == nil,
              "Nil source application was replaced")
    try check(noSourceGoogleCalls == 0, "Nil-source MSAL callback reached Google")

    // Distinct deliveries are not cached or deduplicated across SDK calls.
    msalCalls = 0
    googleCalls = 0
    let consecutive = OAuthCallbackRouter(
      msal: { _, _ in msalCalls += 1; return false },
      google: { _ in googleCalls += 1; return googleCalls == 2 }
    )
    try check(!consecutive.handle(url, sourceApplication: nil), "First SDK result changed")
    try check(consecutive.handle(url, sourceApplication: source), "Second SDK result changed")
    try check(msalCalls == 2 && googleCalls == 2, "Delivery was repeated or incorrectly cached")

    print("Native iOS OAuth callback router checks passed: SDK priority, exact handled results, URL/source preservation, nil source and per-delivery call counts.")
  }
}
