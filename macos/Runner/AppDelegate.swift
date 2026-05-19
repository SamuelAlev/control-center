import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var appChannel: FlutterMethodChannel?
  var macOsNotifier: MacOsNotifier?

  // The headless engine that backs the app. With Flutter's native windowing,
  // the runner no longer creates an NSWindow / FlutterViewController — the Dart
  // side (`runWidget(ViewCollection(...))` in main.dart) creates every window
  // through the windowing owner. We run one engine here and host all our
  // platform channels on it.
  var engine: FlutterEngine?

  // Held while a meeting is recording to keep the app out of App Nap (and to
  // hold off idle system sleep), so audio capture + transcription keep running
  // continuously when the Control Center window is unfocused/occluded.
  private var backgroundActivity: NSObjectProtocol?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // With Flutter's native windowing, every window is Dart-owned. A hot
    // restart tears down the widget tree — closing all NSWindows — before the
    // restarted isolate recreates them, so the window count momentarily hits
    // zero. If we terminated on the last window closing, every hot restart
    // would kill the app ("Lost connection to device"). Hot restart is
    // debug-only (JIT), so suppress auto-terminate in DEBUG and keep the normal
    // close-to-quit behavior for release.
    #if DEBUG
      return false
    #else
      return true
    #endif
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Run a headless engine and register all generated plugins on it. Flutter's
    // windowing owner attaches the windows created from Dart to this engine.
    let engine = FlutterEngine(name: "control_center", project: nil)
    engine.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: engine)
    self.engine = engine

    let messenger = engine.binaryMessenger

    let fontsChannel = FlutterMethodChannel(
      name: "com.controlcenter/fonts",
      binaryMessenger: messenger
    )
    fontsChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getSystemFonts":
        self?.getSystemFonts(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    appChannel = FlutterMethodChannel(
      name: "com.controlcenter/app",
      binaryMessenger: messenger
    )

    // Dart → native power-management calls (begin/end background activity for a
    // meeting recording). The same channel is used native → Dart for openUrl /
    // openSettings; the two directions have independent handlers.
    appChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "beginBackgroundActivity":
        let reason = (call.arguments as? [String: Any])?["reason"] as? String
          ?? "Meeting recording"
        self?.beginBackgroundActivity(reason: reason)
        result(nil)
      case "endBackgroundActivity":
        self?.endBackgroundActivity()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Modern desktop notifications via UNUserNotificationCenter. Created and
    // authorized at launch so the app prompts once and registers under System
    // Settings → Notifications (the deprecated NSUserNotification path used by
    // local_notifier never does this and is silently dropped on macOS 11+).
    let notifier = MacOsNotifier(messenger: messenger)
    notifier.requestAuthorization()
    macOsNotifier = notifier

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

  /// Begins (idempotently) an `NSProcessInfo` activity that prevents App Nap and
  /// idle system sleep for the duration of a recording. `.latencyCritical` keeps
  /// timer/IO precision high for real-time audio capture.
  private func beginBackgroundActivity(reason: String) {
    guard backgroundActivity == nil else {
      NSLog("[BackgroundActivity] begin ignored — already active")
      return
    }
    backgroundActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .latencyCritical],
      reason: reason
    )
    NSLog("[BackgroundActivity] started (App Nap disabled): \(reason)")
  }

  /// Ends the activity begun by `beginBackgroundActivity`, letting the app nap
  /// again. Idempotent.
  private func endBackgroundActivity() {
    if let activity = backgroundActivity {
      ProcessInfo.processInfo.endActivity(activity)
      backgroundActivity = nil
      NSLog("[BackgroundActivity] ended (App Nap re-enabled)")
    }
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
