import UIKit
import Flutter
import MSAL
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterSceneLifeCycleDelegate {
  private let oauthCallbackRouter = OAuthCallbackRouter(
    msal: { url, sourceApplication in
      MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: sourceApplication)
    },
    google: { url in GIDSignIn.sharedInstance.handle(url) }
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Handle OAuth first, before plugins with incompatible scene callback results.
    engineBridge.pluginRegistry
      .registrar(forPlugin: "CompositesAIOAuthCallbacks")?
      .addSceneDelegate(self)
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let connectionOptions else { return false }
    return handleOAuthCallbacks(connectionOptions.urlContexts)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    return handleOAuthCallbacks(URLContexts)
  }

  private func handleOAuthCallbacks(_ contexts: Set<UIOpenURLContext>) -> Bool {
    for context in contexts {
      if oauthCallbackRouter.handle(context.url, sourceApplication: context.options.sourceApplication) {
        return true
      }
    }
    return false
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let handled = MSALPublicClientApplication.handleMSALResponse(
      url,
      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
    )
    return handled || super.application(app, open: url, options: options)
  }
}
