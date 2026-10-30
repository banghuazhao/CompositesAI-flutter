import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.contentMinSize = NSSize(width: 700, height: 600)

    var windowFrame = self.frameRect(
      forContentRect: NSRect(x: 0, y: 0, width: 1200, height: 800))
    if let visibleFrame = self.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
      windowFrame.size.width = min(windowFrame.width, visibleFrame.width)
      windowFrame.size.height = min(windowFrame.height, visibleFrame.height)
    }
    self.setFrame(windowFrame, display: true)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    LegacySwiftCompArchive.register(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
