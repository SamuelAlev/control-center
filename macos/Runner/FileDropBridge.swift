import Cocoa
import FlutterMacOS
import ObjectiveC

/// OS file drag-and-drop, implemented here rather than by `super_drag_and_drop`.
///
/// **Why this exists, and why it is not a duplicate.** `super_native_extensions`
/// (which backs every `DropRegion` in the app) asks `irondash_engine_context`
/// for the `NSView` to call `registerForDraggedTypes:` on. Irondash captures
/// that view ONCE, from `registrar.view`, inside the `dispatch_async` in its
/// `+registerWithRegistrar:` — and it never re-resolves it.
///
/// This app has no view at that moment. The runner is headless: `AppDelegate`
/// runs a bare `FlutterEngine` and every window is created later from Dart
/// through Flutter's native windowing (`runWidget(ViewCollection(...))`, see
/// `lib/app/app_windows.dart`). `RegisterGeneratedPlugins(registry: engine)`
/// therefore hands irondash a registrar whose `view` is nil, it caches nil
/// forever, and `registerForDraggedTypes:` is never called on anything.
///
/// The consequence is total and silent: **no drag from Finder has ever reached
/// this app** — not the composer, not the terminal panel, not a rig canvas. No
/// highlight, no cursor change, no drop. Nothing in Dart can fix that, because
/// the window never advertised itself to AppKit as a drag destination in the
/// first place.
///
/// So the destination is registered here, on the views this app actually has.
/// `AppDelegate` already finds every real `FlutterView` as its window reports in
/// (that is how it disables AppKit's window-drag); registering for dragged types
/// on the same pass costs one extra call.
///
/// The dragging methods are added to `CCNonDraggableFlutterView` — the subclass
/// `AppDelegate` already adopts — and NOT to `FlutterView`, deliberately.
/// `super_native_extensions.prepare_flutter()` patches `FlutterView` itself with
/// these very selectors; `class_addMethod` returns NO for a method a class
/// already has, and objc2 turns that into a Rust panic across an `extern "C"`
/// boundary, which aborts the process. That crash has already happened once
/// here. A subclass sidesteps it outright: their methods land on `FlutterView`
/// unopposed, ours shadow them for our instances, and neither has to know about
/// the other.
final class FileDropBridge {
  static let shared = FileDropBridge()

  private var channel: FlutterMethodChannel?
  private var methodsInstalled = false

  private init() {}

  /// Binds the Dart channel. Called once, from `applicationDidFinishLaunching`.
  func attach(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.controlcenter/filedrop",
      binaryMessenger: messenger
    )
  }

  /// Makes [view] a file-drop destination.
  ///
  /// Idempotent: `registerForDraggedTypes:` replaces the view's type list
  /// rather than appending, so re-registering the same view is a no-op.
  func register(view: NSView) {
    installMethodsIfNeeded(on: type(of: view))
    view.registerForDraggedTypes([
      .fileURL,
      .png,
      .tiff,
    ])
  }

  // MARK: - Dragging callbacks

  fileprivate func over(view: NSView, info: NSDraggingInfo) {
    let point = flutterPoint(in: view, info: info)
    send(
      "over",
      [
        "viewId": viewIdentifier(of: view),
        "x": point.x,
        "y": point.y,
        "count": info.numberOfValidItemsForDrop,
      ])
  }

  fileprivate func exited(view: NSView?) {
    send("exit", ["viewId": view.map(viewIdentifier(of:)) ?? -1])
  }

  fileprivate func perform(view: NSView, info: NSDraggingInfo) -> Bool {
    let point = flutterPoint(in: view, info: info)
    let paths = filePaths(from: info.draggingPasteboard)
    let images = paths.isEmpty ? imageData(from: info.draggingPasteboard) : []
    if paths.isEmpty && images.isEmpty {
      send("exit", ["viewId": viewIdentifier(of: view)])
      return false
    }
    send(
      "drop",
      [
        "viewId": viewIdentifier(of: view),
        "x": point.x,
        "y": point.y,
        "paths": paths,
        "images": images.map { FlutterStandardTypedData(bytes: $0) },
      ])
    return true
  }

  // MARK: - Payload

  /// The local paths a pasteboard names. Finder's drags are exactly this.
  private func filePaths(from pasteboard: NSPasteboard) -> [String] {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true
    ]
    guard
      let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options)
        as? [URL]
    else {
      return []
    }
    return urls.map { $0.path }
  }

  /// Raw picture bytes, for a drag that carries an image and no file behind it
  /// — what a browser or a design tool offers. Read only when there is no file
  /// path, so a dropped PNG is carried by path (cheap) rather than by value.
  private func imageData(from pasteboard: NSPasteboard) -> [Data] {
    for type in [NSPasteboard.PasteboardType.png, .tiff] {
      if let data = pasteboard.data(forType: type) {
        return [data]
      }
    }
    return []
  }

  // MARK: - Geometry and identity

  /// The drag location in Flutter's logical coordinates for [view].
  ///
  /// `draggingLocation` is in WINDOW coordinates, and AppKit's origin is
  /// bottom-left while Flutter's is top-left. On macOS a logical pixel is a
  /// point, so no device-pixel-ratio scaling is involved — only the conversion
  /// and the flip, and the flip is conditional because `FlutterView` may report
  /// itself as flipped already.
  private func flutterPoint(in view: NSView, info: NSDraggingInfo) -> CGPoint {
    let inView = view.convert(info.draggingLocation, from: nil)
    return CGPoint(
      x: inView.x,
      y: view.isFlipped ? inView.y : view.bounds.height - inView.y
    )
  }

  /// The Flutter view id this view belongs to, or -1 when it cannot be
  /// resolved. Dart matches it against `View.of(context).viewId` so a drag over
  /// a HUD panel never lights up a target in the main window.
  private func viewIdentifier(of view: NSView) -> Int64 {
    var responder: NSResponder? = view
    while let current = responder {
      if let controller = current as? FlutterViewController {
        return controller.viewIdentifier
      }
      responder = current.nextResponder
    }
    if let controller = view.window?.contentViewController as? FlutterViewController {
      return controller.viewIdentifier
    }
    return -1
  }

  private func send(_ method: String, _ arguments: [String: Any]) {
    channel?.invokeMethod(method, arguments: arguments)
  }

  // MARK: - Method installation

  /// Adds the `NSDraggingDestination` methods to [cls] the first time a view of
  /// ours is registered.
  ///
  /// The IMPs are blocks (so `self` is only ever treated as the `NSView` it is)
  /// while the TYPE ENCODINGS are read off a donor class the compiler generated.
  /// Hand-writing them is the trap: `BOOL` encodes as `c` on x86_64 and `B` on
  /// arm64, and `NSDragOperation` is an `NSUInteger` — a wrong string here is a
  /// corrupted stack frame, not a compile error.
  private func installMethodsIfNeeded(on cls: AnyClass) {
    guard !methodsInstalled else { return }
    methodsInstalled = true

    let entered: @convention(block) (AnyObject, AnyObject) -> UInt = { view, info in
      guard let view = view as? NSView, let info = info as? NSDraggingInfo else {
        return 0
      }
      FileDropBridge.shared.over(view: view, info: info)
      // Copy, never move: dropping a file into the app must not invite Finder
      // to delete the original.
      return NSDragOperation.copy.rawValue
    }
    let exited: @convention(block) (AnyObject, AnyObject?) -> Void = { view, _ in
      FileDropBridge.shared.exited(view: view as? NSView)
    }
    let performed: @convention(block) (AnyObject, AnyObject) -> Bool = { view, info in
      guard let view = view as? NSView, let info = info as? NSDraggingInfo else {
        return false
      }
      return FileDropBridge.shared.perform(view: view, info: info)
    }
    let ended: @convention(block) (AnyObject, AnyObject?) -> Void = { view, _ in
      FileDropBridge.shared.exited(view: view as? NSView)
    }
    let prepare: @convention(block) (AnyObject, AnyObject) -> Bool = { _, _ in true }

    add(#selector(NSView.draggingEntered(_:)), imp: entered, to: cls)
    add(#selector(NSView.draggingUpdated(_:)), imp: entered, to: cls)
    add(#selector(NSView.draggingExited(_:)), imp: exited, to: cls)
    add(#selector(NSView.prepareForDragOperation(_:)), imp: prepare, to: cls)
    add(#selector(NSView.performDragOperation(_:)), imp: performed, to: cls)
    add(#selector(NSView.draggingEnded(_:)), imp: ended, to: cls)
  }

  private func add(_ selector: Selector, imp block: Any, to cls: AnyClass) {
    guard let donor = class_getInstanceMethod(CCDropDonor.self, selector) else {
      NSLog("[FileDrop] no donor method for \(selector) — drop disabled")
      return
    }
    if !class_addMethod(
      cls, selector, imp_implementationWithBlock(block),
      method_getTypeEncoding(donor))
    {
      NSLog("[FileDrop] \(cls) already implements \(selector)")
    }
  }
}

/// Source of compiler-generated type encodings for the dragging selectors.
///
/// Never instantiated and never used as a receiver — only
/// `method_getTypeEncoding` is read from it. Its bodies exist because a Swift
/// `override` is what makes the compiler emit the method (and thus the
/// encoding) at all.
private final class CCDropDonor: NSView {
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
  override func draggingExited(_ sender: NSDraggingInfo?) {}
  override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { true }
  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { true }
  override func draggingEnded(_ sender: NSDraggingInfo) {}
}
