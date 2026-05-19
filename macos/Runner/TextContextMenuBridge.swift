import Cocoa
import FlutterMacOS

/// The OS's own right-click menu for the app's text fields.
///
/// **Why this exists.** Flutter has a `SystemContextMenu` widget, but
/// `SystemContextMenu.isSupported` is `defaultTargetPlatform == iOS` and the
/// `ContextMenu.showSystemContextMenu` channel method is implemented only in
/// the iOS embedder — the macOS embedder has no handler for it at all. So on
/// this platform a framework-drawn menu is the only thing Flutter offers, and
/// a drawn menu is never quite the real one: wrong metrics, wrong highlight,
/// wrong appearance under Increase Contrast / Reduce Transparency, no OS
/// localisation, and no Services or dictation items.
///
/// This pops a real `NSMenu` instead. It deliberately does NOT act on the text
/// itself — the guest of this menu is a Flutter `EditableText`, which AppKit
/// knows nothing about — it only reports WHICH entry the user chose and lets
/// Dart perform it through the field's own selection delegate. That keeps one
/// implementation of "what paste means" instead of two that can disagree.
///
/// Titles are lifted from the app's own Edit menu (`MainMenu.xib`), so they
/// arrive already localised by AppKit rather than hardcoded in English here.
/// Shortcut hints are deliberately omitted: a macOS text field's context menu
/// shows bare "Cut / Copy / Paste", the shortcuts live in the menu bar.
final class TextContextMenuBridge: NSObject {
  static let shared = TextContextMenuBridge()

  private var channel: FlutterMethodChannel?

  /// Replies for the popup currently tracking, so an item's action can answer
  /// Dart before the tracking loop unwinds. Reset on every `show`.
  private var reply: ((String?) -> Void)?

  private override init() {}

  /// Binds the Dart channel. Called once, from `applicationDidFinishLaunching`.
  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.controlcenter/text_context_menu",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard call.method == "show" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.show(arguments: call.arguments, result: result)
    }
    self.channel = channel
  }

  /// Pops the menu at the Flutter-supplied position and answers with the id of
  /// the chosen entry (or nil when the user dismissed it).
  private func show(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
      let x = args["x"] as? Double,
      let y = args["y"] as? Double,
      let ids = args["actions"] as? [String],
      !ids.isEmpty,
      let window = NSApp.keyWindow ?? NSApp.mainWindow,
      let view = TextContextMenuBridge.flutterView(in: window)
    else {
      // No window, no view, or nothing to offer: Dart falls back to drawing
      // its own menu rather than leaving the right-click dead.
      result(nil)
      return
    }

    var answered = false
    let answer: (String?) -> Void = { value in
      guard !answered else { return }
      answered = true
      result(value)
    }
    reply = answer

    let menu = NSMenu()
    // The items target this object, not the responder chain, so AppKit's
    // automatic validation (which would disable every one of them — nothing in
    // a Flutter app implements `cut:`/`paste:`) must be switched off.
    menu.autoenablesItems = false
    for id in ids {
      let item = NSMenuItem(
        title: TextContextMenuBridge.title(for: id),
        action: #selector(handle(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = id
      item.isEnabled = true
      menu.addItem(item)
    }

    // Flutter's global offsets are logical pixels from the view's top-left,
    // which equal AppKit points on macOS — but AppKit's origin is bottom-left
    // unless the view is flipped, so only the axis needs converting.
    let point = view.isFlipped
      ? NSPoint(x: x, y: y)
      : NSPoint(x: x, y: view.bounds.height - y)
    menu.popUp(positioning: nil, at: point, in: view)

    // Tracking has ended. A chosen item answers through `handle(_:)` during
    // the tracking loop; the dismissal reply is deferred one runloop turn so
    // that an item whose action AppKit dispatches late still wins the race
    // rather than losing to a nil that was already sent.
    DispatchQueue.main.async { [weak self] in
      answer(nil)
      self?.reply = nil
    }
  }

  @objc private func handle(_ sender: NSMenuItem) {
    reply?(sender.representedObject as? String)
  }

  /// The app's own Edit-menu title for [id], so the entry reads in the user's
  /// language. Falls back to English if the menu has been restyled away.
  private static func title(for id: String) -> String {
    let selectors: [String: Selector] = [
      "cut": #selector(NSText.cut(_:)),
      "copy": #selector(NSText.copy(_:)),
      "paste": #selector(NSText.paste(_:)),
      "selectAll": #selector(NSStandardKeyBindingResponding.selectAll(_:)),
    ]
    let fallbacks = [
      "cut": "Cut", "copy": "Copy", "paste": "Paste", "selectAll": "Select All",
    ]
    guard let selector = selectors[id] else {
      return fallbacks[id] ?? id
    }
    for top in NSApp.mainMenu?.items ?? [] {
      if let match = top.submenu?.items.first(where: { $0.action == selector }) {
        return match.title
      }
    }
    return fallbacks[id] ?? id
  }

  /// The first Flutter view under [window]'s content view.
  ///
  /// Resolved by class NAME, the way `AppDelegate` already does: `FlutterView`
  /// is not exported to Swift by `FlutterMacOS`, so there is no type to test
  /// against. `isKind(of:)` rather than an exact class match, because
  /// `AppDelegate` re-classes every Flutter view to
  /// `CCNonDraggableFlutterView` on its first display pass.
  ///
  /// Falls back to the content view: under Flutter's native windowing the
  /// Flutter surface fills the window, so the two share an origin and the
  /// menu still lands where the user clicked.
  private static func flutterView(in window: NSWindow) -> NSView? {
    guard let contentView = window.contentView else { return nil }
    guard let base = NSClassFromString("FlutterView") else { return contentView }
    func find(_ view: NSView) -> NSView? {
      if view.isKind(of: base) { return view }
      for subview in view.subviews {
        if let match = find(subview) { return match }
      }
      return nil
    }
    return find(contentView) ?? contentView
  }
}
