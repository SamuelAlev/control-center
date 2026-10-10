import Cocoa
import os

/// Stops a hot restart from aborting the app when a Dart-owned window is key.
///
/// On restart the engine calls `-[FlutterWindowController closeAllWindows]`
/// (FlutterWindowController.mm), which disposes each window's view controller
/// and then closes the window — but, unlike `destroyWindow:` a few lines above
/// it, leaves the window's delegate in place. Closing the key window makes
/// AppKit send `windowDidResignKey:` to that delegate, a `FlutterWindowOwner`,
/// which reads `viewIdentifier` off the controller it just disposed. The
/// getter asserts the controller is still attached, and the debug engine
/// aborts with `NSInternalInconsistencyException: This view controller is not
/// attached.` — reported by `flutter run` only as "Lost connection to device".
/// Whether a restart crashes therefore depends on whether one of our windows
/// happened to be key at that moment.
///
/// The replacement below does what `destroyWindow:` does first: it detaches
/// every owner from its window before the original closes them. That also keeps
/// the other owner callbacks (`windowDidResize:` and friends, which enter the
/// isolate being torn down) from firing during teardown. Nothing is lost: the
/// owners are dropped right after, and the restarted isolate creates fresh
/// windows with fresh owners.
///
/// The controller is engine-private, so the class, selector, ivar and type
/// encodings are checked first; an engine that renames or reshapes any of them
/// leaves `closeAllWindows` as it was and says so in the log. Delete this file
/// once `closeAllWindows` in the pinned engine clears `window.delegate` before
/// `close`.
enum WindowCloseGuard {
  private static let log = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.alev.control-center",
    category: "WindowCloseGuard"
  )
  private static var installed = false

  private typealias CloseAll = @convention(c) (AnyObject, Selector) -> Void

  /// Call at launch, before the first hot restart can reach the controller.
  /// Main thread only; repeat calls are no-ops.
  static func install() {
    dispatchPrecondition(condition: .onQueue(.main))
    guard !installed else { return }
    installed = true

    let closeAllSelector = NSSelectorFromString("closeAllWindows")
    let windowSelector = NSSelectorFromString("window")
    guard
      let controllerClass = NSClassFromString("FlutterWindowController"),
      let ownerClass = NSClassFromString("FlutterWindowOwner"),
      let closeAllMethod = class_getInstanceMethod(controllerClass, closeAllSelector),
      let windowMethod = class_getInstanceMethod(ownerClass, windowSelector),
      let windowsIvar = class_getInstanceVariable(controllerClass, "_windows"),
      let ivarType = ivar_getTypeEncoding(windowsIvar),
      String(cString: ivarType).hasPrefix("@"),
      types(of: closeAllMethod) == ["v", "@", ":"],
      types(of: windowMethod) == ["@", "@", ":"]
    else {
      log.error("Not installed: Flutter's window controller API has changed")
      return
    }

    let original = unsafeBitCast(method_getImplementation(closeAllMethod), to: CloseAll.self)

    let guarded: @convention(block) (AnyObject) -> Void = { controller in
      var detached = 0
      if let owners = object_getIvar(controller, windowsIvar) as? NSArray {
        for case let owner as NSObject in owners where owner.isKind(of: ownerClass) {
          guard let window = owner.perform(windowSelector)?.takeUnretainedValue() as? NSWindow,
            window.delegate === owner
          else {
            continue
          }
          window.delegate = nil
          detached += 1
        }
      }
      if detached > 0 {
        log.info("Detached \(detached) window owner(s) before closing all windows")
      }
      original(controller, closeAllSelector)
    }
    method_setImplementation(closeAllMethod, imp_implementationWithBlock(guarded))
    log.info("Installed")
  }

  /// The method's return type followed by its argument types, self and _cmd
  /// included.
  private static func types(of method: Method) -> [String] {
    let returnType = method_copyReturnType(method)
    var types = [String(cString: returnType)]
    free(returnType)
    for index in 0..<method_getNumberOfArguments(method) {
      guard let argumentType = method_copyArgumentType(method, index) else { return [] }
      types.append(String(cString: argumentType))
      free(argumentType)
    }
    return types
  }
}
