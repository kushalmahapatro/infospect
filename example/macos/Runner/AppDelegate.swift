import Cocoa
import FlutterMacOS
import multiview_desktop

@main
class AppDelegate: FlutterAppDelegate {
  // Multiview owns last-window / terminate / reopen / dock menu.
  // applicationShouldTerminate returns .terminateCancel until Dart Multiview
  // replies — the Dart entry MUST use runMultiApp (Infospect.instance.run or
  // Infospect.bootstrapMultiViewApp). Plain runApp leaves quit cancelled forever.

  override func applicationShouldTerminateAfterLastWindowClosed(
      _ sender: NSApplication
  ) -> Bool {
    return MultiviewDesktopPlugin.applicationShouldTerminateAfterLastWindowClosed()
  }

  override func applicationShouldHandleReopen(
      _ sender: NSApplication,
      hasVisibleWindows flag: Bool
  ) -> Bool {
    if MultiviewDesktopPlugin.applicationShouldHandleReopen(
      sender,
      hasVisibleWindows: flag
    ) {
      return true
    }
    return super.applicationShouldHandleReopen(sender, hasVisibleWindows: flag)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication)
      -> Bool
  {
    return true
  }

  override func applicationShouldTerminate(_ sender: NSApplication)
      -> NSApplication.TerminateReply
  {
    return MultiviewDesktopPlugin.applicationShouldTerminate(sender)
  }

  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    return MultiviewDesktopPlugin.applicationDockMenu(sender)
  }
}
