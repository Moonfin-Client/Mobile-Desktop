import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let minimumWindowSize = NSSize(width: 1200, height: 760)
    self.minSize = minimumWindowSize

    var windowFrame = self.frame
    if windowFrame.size.width < minimumWindowSize.width ||
      windowFrame.size.height < minimumWindowSize.height {
      if let visibleFrame = self.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
        windowFrame.size.width = min(max(windowFrame.size.width, minimumWindowSize.width), visibleFrame.width)
        windowFrame.size.height = min(max(windowFrame.size.height, minimumWindowSize.height), visibleFrame.height)
        windowFrame.origin.x = visibleFrame.midX - (windowFrame.size.width / 2)
        windowFrame.origin.y = visibleFrame.midY - (windowFrame.size.height / 2)
      } else {
        windowFrame.size.width = max(windowFrame.size.width, minimumWindowSize.width)
        windowFrame.size.height = max(windowFrame.size.height, minimumWindowSize.height)
      }
    }

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
