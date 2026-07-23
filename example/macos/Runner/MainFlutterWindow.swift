import Cocoa
import FlutterMacOS
import multiview_desktop

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let engine = FlutterEngine(
      name: "main_flutter_engine",
      project: nil,
      allowHeadlessExecution: true
    )
    // Multiview orderOuts the host window here — do not also call
    // window_manager hiddenWindowAtLaunch (double-hide). Keep display: false.
    MultiviewDesktopPlugin.prepareEngine(engine, window: self)

    let flutterViewController =
      FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: false)

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
