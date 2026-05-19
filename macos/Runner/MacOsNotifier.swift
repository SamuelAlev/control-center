import Cocoa
import FlutterMacOS
import UserNotifications

/// Bridges Flutter to the modern macOS `UNUserNotificationCenter` so desktop
/// notifications actually appear on macOS 10.14+.
///
/// The `local_notifier` package delivers via the deprecated `NSUserNotification`
/// API, which has no authorization model: it never prompts, never registers the
/// app under System Settings → Notifications, and is silently dropped for an
/// unauthorized app on modern macOS. This class owns the
/// `com.controlcenter/notifications` method channel and the supported API:
///   • `requestAuthorization` → triggers the one-time system prompt and
///     registers the app under System Settings → Notifications.
///   • `notify` → posts an immediate banner, stashing the click-through `route`
///     in the request's `userInfo`.
///
/// Banners are presented even while the app is frontmost (the common case for
/// Control Center), and a tap is forwarded back to Dart via `onNotificationClick`.
class MacOsNotifier: NSObject, UNUserNotificationCenterDelegate {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.controlcenter/notifications",
      binaryMessenger: messenger
    )
    super.init()
    // Must be set before the app finishes launching so taps that launched the
    // app (and foreground presentation) are routed through us.
    UNUserNotificationCenter.current().delegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  /// Requests permission to post notifications. Idempotent — macOS shows the
  /// prompt only on the first call and returns the cached decision thereafter.
  func requestAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { _, error in
      if let error = error {
        NSLog("MacOsNotifier: requestAuthorization failed: \(error)")
      }
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      requestAuthorization()
      result(nil)
    case "notify":
      notify(call.arguments as? [String: Any] ?? [:], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func notify(_ args: [String: Any], result: @escaping FlutterResult) {
    let identifier = args["identifier"] as? String ?? UUID().uuidString
    let content = UNMutableNotificationContent()
    content.title = args["title"] as? String ?? ""
    content.body = args["body"] as? String ?? ""
    // The app plays its own sound via NotificationSoundService, so leave the
    // OS sound off to avoid a double chime.
    content.sound = nil
    if let route = args["route"] as? String {
      content.userInfo = ["route": route]
    }

    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: nil  // deliver immediately
    )
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          NSLog("MacOsNotifier: add() failed: \(error)")
          result(FlutterError(
            code: "notify_failed",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(nil)
        }
      }
    }
  }

  // Present banners even while the app is in the foreground.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }

  // Route a tap back into the app.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let route = response.notification.request.content.userInfo["route"] as? String {
      channel.invokeMethod("onNotificationClick", arguments: ["route": route])
    }
    completionHandler()
  }
}
