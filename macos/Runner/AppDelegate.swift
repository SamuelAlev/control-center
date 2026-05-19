import Cocoa
import FlutterMacOS
import ObjectiveC

/// Stops macOS from moving the window on its own when a drag begins on Flutter
/// content.
///
/// The app draws its own title bar, so the window runs with a hidden,
/// transparent titlebar over a full-size content view. In that layout the top
/// strip belongs to AppKit *and* to us: clicks fall through to the Flutter view
/// (which is what lets our own buttons live up there), but AppKit still offers
/// to move the window when a mouse-down lands on a view whose
/// `mouseDownCanMoveWindow` is true — and `FlutterView` inherits `NSView`'s
/// default rather than answering for itself. So a press both activates the
/// control and starts a server-side window drag: nudging the mouse a few pixels
/// while clicking the sidebar toggle, back/forward, a breadcrumb or any of the
/// title bar's popover triggers walks the whole window across the screen.
///
/// `WindowDragArea` cannot fix this from Dart. It decides whether *we* call
/// `performWindowDragWithEvent:`; this drag is started by AppKit before Dart
/// ever sees the event.
///
/// Answering `false` for the view is the narrow fix. The alternative —
/// `NSWindow.movable = false` — disables "server-side dragging of the window
/// via titlebar or background" wholesale (`NSWindow.h`), and that is the same
/// machinery our deliberate drag rides on, since `WindowDragArea` hands its
/// mouse-down to `performWindowDragWithEvent:`. Leaving `isMovable` alone keeps
/// dragging from the inert gaps between the title bar's controls working.
///
/// The override lives on a SUBCLASS whose instances we adopt, rather than on
/// `FlutterView` itself, because `FlutterView`'s method list is shared property.
/// `super_native_extensions` patches the very same class with the very same
/// selector: its one-shot `prepare_flutter()` adds a `mouseDownCanMoveWindow`
/// returning YES the first time a drag context is created — i.e. when the
/// terminal panel's `DropRegion` or a rig input surface first mounts.
/// `class_addMethod` returns NO for a method the class already implements,
/// objc2 asserts on that, and a Rust panic crossing an `extern "C"` boundary
/// aborts the process. Adding this override to `FlutterView` at launch is
/// therefore not "first one wins": it made opening the terminal tab a
/// guaranteed crash, with the panic as the only clue.
///
/// Sequencing the two is possible but fragile (it hangs on plugin-internal
/// timing that has already bitten once). Owning a subclass instead removes the
/// conflict outright: their method lands on `FlutterView` unopposed, our
/// instances inherit everything they add, and the getter resolves to ours
/// because a subclass wins. Nothing here depends on whether, or when, that
/// plugin runs.
private let nonDraggableFlutterViewClass: AnyClass? = {
  let selector = #selector(getter: NSView.mouseDownCanMoveWindow)
  guard let base = NSClassFromString("FlutterView"),
    let baseMethod = class_getInstanceMethod(NSView.self, selector),
    let subclass = objc_allocateClassPair(base, "CCNonDraggableFlutterView", 0)
  else {
    NSLog("[WindowDrag] could not create the non-draggable FlutterView subclass")
    return nil
  }
  let block: @convention(block) (AnyObject) -> Bool = { _ in false }
  // The type encoding is read off NSView's own method rather than written by
  // hand, because `BOOL` is not encoded alike on every architecture.
  class_addMethod(
    subclass, selector, imp_implementationWithBlock(block),
    method_getTypeEncoding(baseMethod))
  objc_registerClassPair(subclass)
  return subclass
}()

/// Adopts [nonDraggableFlutterViewClass] for every `FlutterView` in [window].
///
/// Isa-swizzling an instance is what KVO does to arbitrary objects, and it is
/// contained here: only a view whose class is EXACTLY `FlutterView` is adopted,
/// so a view someone else has already re-classed is left alone, and the swap
/// adds no ivars.
/// Adopting a view is also where it becomes a FILE DROP DESTINATION: the same
/// pass has already found the one thing OS drag-and-drop needs and cannot get
/// any other way in this app — a real `FlutterView`. See `FileDropBridge` for
/// why the plugin that normally does this never can here.
private func adoptNonDraggableFlutterViews(in window: NSWindow) -> Int {
  guard let base = NSClassFromString("FlutterView"),
    let subclass = nonDraggableFlutterViewClass,
    let contentView = window.contentView
  else {
    return 0
  }
  func adopt(_ view: NSView) -> Int {
    var adopted = 0
    if object_getClass(view) === base {
      object_setClass(view, subclass)
      FileDropBridge.shared.register(view: view)
      adopted += 1
    }
    for subview in view.subviews {
      adopted += adopt(subview)
    }
    return adopted
  }
  return adopt(contentView)
}

/// The primary window's title — Swift twin of `primaryWindowTitle` in
/// lib/app/window_chrome.dart, where the window chrome is keyed on title (the
/// windowing layer creates windows untitled, so the title is the only identity
/// both sides can match on).
private let primaryWindowTitle = "Control Center"

/// Height of the app-drawn title bar row (`ShellTitleBar` in
/// lib/features/shell/presentation/layout/shell_title_bar.dart). The traffic
/// lights are vertically centered against THIS height, not against the stock
/// titlebar they technically live in — move one, move the other.
private let appTitleBarHeight: CGFloat = 40

/// Nudges the primary window's traffic lights down to the vertical center of
/// the app-drawn title bar.
///
/// The window runs `TitleBarStyle.hidden` (set in `styleWindowOnShow`): the
/// Flutter content extends under a transparent titlebar whose only visible
/// remnant is the traffic-light cluster. AppKit centers that cluster in the
/// stock 28pt titlebar, so its midpoint sits at 14pt from the top — six points
/// above the 40pt bar's own center (20pt) — and it reads as floating above the
/// nav buttons it belongs beside. macOS has no public API to move the cluster
/// (only to hide it), so the buttons' frame origins are shifted directly.
///
/// The alignment is re-applied on EVERY `didUpdate` pass because AppKit re-lays
/// the titlebar (fullscreen transitions, style changes) and resets the origins;
/// a one-shot pass would silently lose the alignment the first time that
/// happened. The move is idempotent — once the origins match, each pass is
/// three frame reads — and `standardWindowButton` is re-resolved each time, so
/// a rebuilt titlebar view hierarchy is picked up too.
private func alignTrafficLights(of window: NSWindow) {
  // Exact match only: "Control Center setup" must keep its stock, movable
  // titlebar, and the HUDs ("Focus \ Control Center", …) hide their buttons
  // outright (`isWindowControlButtonsVisible = false`).
  guard window.title == primaryWindowTitle,
    let close = window.standardWindowButton(.closeButton),
    let titleBarView = close.superview
  else {
    return
  }
  let buttons = [
    close,
    window.standardWindowButton(.miniaturizeButton),
    window.standardWindowButton(.zoomButton),
  ].compactMap { $0 }
  // The titlebar view is flipped (origin at the window's top-left, y growing
  // downward), so the flipped branch is the live one; the other is guarded so a
  // wrong assumption can never park the buttons above the window.
  let buttonHeight = close.bounds.height
  let targetY = titleBarView.isFlipped
    ? (appTitleBarHeight - buttonHeight) / 2
    : titleBarView.bounds.height - (appTitleBarHeight + buttonHeight) / 2
  for button in buttons where button.frame.minY != targetY {
    var frame = button.frame
    frame.origin.y = targetY
    button.frame = frame
  }
}

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

  // Held for the life of the process so RPC-driven UI (a Slack thread becoming
  // a channel, live agent turns, notifications) keeps updating while the
  // operator is in another app. macOS App Nap would otherwise coalesce the
  // client's socket reads until the window is focused again — the same stall
  // meeting recording used to hit. Allows idle system sleep; recording and
  // agent-awake take a stronger assertion on top via beginBackgroundActivity.
  private var liveSessionActivity: NSObjectProtocol?

  // Held while a meeting is recording to keep the app out of App Nap (and to
  // hold off idle system sleep), so audio capture + transcription keep running
  // continuously when the Control Center window is unfocused/occluded.
  private var backgroundActivity: NSObjectProtocol?

  // Windows whose FlutterViews already answer `mouseDownCanMoveWindow` for
  // themselves. Weak entries so a closed window drops out: a set of addresses
  // would keep a stale one that a NEW window could be allocated at, and that
  // window would then be skipped forever.
  private let windowsWithSystemDragDisabled = NSHashTable<NSWindow>.weakObjects()
  private var windowDragObserver: NSObjectProtocol?

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

    // The app draws its own title bar over a full-size content view, where
    // AppKit would otherwise start a window drag from any press on Flutter
    // content — including on the title bar's own buttons. Every window is
    // Dart-owned under native windowing, so there is no creation point to hook
    // here: adopt the subclass as each window reports in. `didUpdate` is the
    // one notification EVERY window gets (the HUD panels never become key or
    // main) and it arrives during the first display pass, before the window can
    // route a mouse-down. The same "every window, every pass" property is what
    // keeps the traffic-light alignment alive across AppKit's titlebar
    // re-layouts, so it rides this observer too.
    windowDragObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.didUpdateNotification, object: nil, queue: nil
    ) { [weak self] notification in
      guard let self,
        let window = notification.object as? NSWindow
      else {
        return
      }
      alignTrafficLights(of: window)
      guard !self.windowsWithSystemDragDisabled.contains(window) else {
        return
      }
      // Recorded only once a view was actually adopted: `didUpdate` can arrive
      // before the FlutterView is attached, and marking the window then would
      // skip it for good. Logged because this is invisible when it works and
      // indistinguishable from "the fix did not land" when the app was
      // hot-restarted rather than rebuilt — a Swift change needs a native build.
      if adoptNonDraggableFlutterViews(in: window) > 0 {
        self.windowsWithSystemDragDisabled.add(window)
        NSLog("[WindowDrag] disabled AppKit window drags on a Flutter window")
      }
    }

    let messenger = engine.binaryMessenger

    // Must be bound before any window reports in: the first `didUpdate` pass
    // registers the drop destination, and a drag that arrived before the
    // channel existed would be dropped on the floor with no way to tell.
    FileDropBridge.shared.attach(messenger: messenger)

    // The OS's own right-click menu for text fields. Flutter offers no macOS
    // path to it (`SystemContextMenu` is iOS-only), so cc_ui asks for it here
    // and falls back to drawing its own if this channel ever goes unanswered.
    TextContextMenuBridge.shared.attach(messenger: messenger)

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

    liveSessionActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiatedAllowingIdleSystemSleep],
      reason: "Control Center live session"
    )
    NSLog("[BackgroundActivity] live session started (App Nap disabled)")

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationWillTerminate(_ notification: Notification) {
    if let activity = liveSessionActivity {
      ProcessInfo.processInfo.endActivity(activity)
      liveSessionActivity = nil
    }
    super.applicationWillTerminate(notification)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      appChannel?.invokeMethod("openUrl", arguments: url.absoluteString)
    }
  }

  @objc func openPreferences(_ sender: Any?) {
    appChannel?.invokeMethod("openSettings", arguments: nil)
  }

  /// App-menu "Check for Updates…" (right under About). Bridges to the
  /// Dart-side DesktopUpdateController — the one path that owns the drain
  /// rule (a prompt is deferred while a meeting is recording) — which then
  /// drives Sparkle's interactive check.
  @objc func checkForUpdatesFromMenu(_ sender: Any?) {
    appChannel?.invokeMethod("checkForUpdates", arguments: nil)
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
