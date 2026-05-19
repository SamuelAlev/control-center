import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  var appChannel: FlutterMethodChannel?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register all Flutter plugins (including window_manager) for every
    // sub-window created by desktop_multi_window. Without this the sub-window
    // engine only has the multi_window channel registered.
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
    }

    guard let controller = NSApplication.shared.windows
      .first(where: { $0.contentViewController is FlutterViewController })?
      .contentViewController as? FlutterViewController else {
      super.applicationDidFinishLaunching(notification)
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.controlcenter/fonts",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getSystemFonts":
        self?.getSystemFonts(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    appChannel = FlutterMethodChannel(
      name: "com.controlcenter/app",
      binaryMessenger: controller.engine.binaryMessenger
    )

    super.applicationDidFinishLaunching(notification)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      appChannel?.invokeMethod("openUrl", arguments: url.absoluteString)
    }
  }

  @objc func openPreferences(_ sender: Any?) {
    appChannel?.invokeMethod("openSettings", arguments: nil)
  }

  private func getSystemFonts(result: FlutterResult) {
    let fontManager = NSFontManager.shared
    let families = fontManager.availableFontFamilies
    var fonts: [[String: String]] = []
    var seenPaths = Set<String>()

    for family in families {
      guard let members = fontManager.availableMembers(ofFontFamily: family),
            !members.isEmpty,
            let firstMember = members.first,
            let fontName = firstMember.first as? String else {
        continue
      }

      guard let font = NSFont(name: fontName, size: 12) else { continue }

      let descriptor = font.fontDescriptor
      guard let url = CTFontDescriptorCopyAttribute(descriptor, kCTFontURLAttribute) as? URL else {
        continue
      }

      let path = url.path
      let isSupported = path.hasSuffix(".ttf") || path.hasSuffix(".otf") || path.hasSuffix(".TTF") || path.hasSuffix(".OTF")
      if FileManager.default.fileExists(atPath: path), isSupported, !seenPaths.contains(path) {
        seenPaths.insert(path)
        fonts.append(["family": family, "path": path])
      }
    }

    result(fonts)
  }
}
