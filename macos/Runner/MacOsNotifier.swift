import Cocoa
import FlutterMacOS
import UserNotifications

/// Bridges Flutter to the modern macOS `UNUserNotificationCenter` so desktop
/// notifications actually appear on macOS 10.14+.
///
/// The `local_notifier` package delivers via the deprecated `NSUserNotification`
/// API, which has no authorization model: it never prompts, never registers the
/// app under System Settings → Notifications and is silently dropped for an
/// unauthorized app on modern macOS. This class owns the
/// `com.controlcenter/notifications` method channel and the supported API:
///   • `requestAuthorization` → triggers the one-time system prompt and
///     registers the app under System Settings → Notifications.
///   • `notify` → posts an immediate banner, stashing the click-through `route`
///     in the request's `userInfo`. One already delivered under the same
///     identifier is replaced and alerts again (how a reminder re-raises a
///     wait). `timeSensitive` sets the time-sensitive interruption level;
///     `approvalId` adds Approve and Deny buttons.
///   • `remove` → withdraws a delivered notification by identifier.
///
/// Banners are presented even while the app is frontmost (the common case for
/// Control Center). A tap is forwarded back to Dart via `onNotificationClick`,
/// a button via `onNotificationAction`.
///
/// Time-sensitive delivery takes effect only when the app is signed with the
/// `com.apple.developer.usernotifications.time-sensitive` entitlement. Without
/// it macOS shows the notification at the normal level.
class MacOsNotifier: NSObject, UNUserNotificationCenterDelegate {
  private static let approvalCategory = "cc.agentApproval"
  private static let approveAction = "cc.approve"
  private static let denyAction = "cc.deny"

  private let channel: FlutterMethodChannel

  /// The button titles last registered, so the category is re-registered only
  /// when the app's language changes.
  private var registeredLabels: (approve: String, deny: String)?

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
    case "remove":
      if let identifier = (call.arguments as? [String: Any])?["identifier"] as? String {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
      }
      result(nil)
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
    var userInfo: [String: Any] = [:]
    if let route = args["route"] as? String {
      userInfo["route"] = route
    }
    if args["timeSensitive"] as? Bool == true {
      content.interruptionLevel = .timeSensitive
    }
    if let approvalId = args["approvalId"] as? String,
      let approveLabel = args["approveLabel"] as? String,
      let denyLabel = args["denyLabel"] as? String
    {
      registerApprovalCategory(approve: approveLabel, deny: denyLabel)
      content.categoryIdentifier = MacOsNotifier.approvalCategory
      userInfo["approvalId"] = approvalId
    }
    content.userInfo = userInfo

    let center = UNUserNotificationCenter.current()
    // Re-adding a delivered identifier only updates it in place. Removing it
    // first makes a reminder alert again instead of changing silently.
    center.removeDeliveredNotifications(withIdentifiers: [identifier])
    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: nil  // deliver immediately
    )
    center.add(request) { error in
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

  /// Registers the Approve/Deny category with the current localized titles.
  /// Neither button opens the app: the answer goes to the server in the
  /// background, as the in-app card's does.
  private func registerApprovalCategory(approve: String, deny: String) {
    if let labels = registeredLabels, labels == (approve, deny) {
      return
    }
    let category = UNNotificationCategory(
      identifier: MacOsNotifier.approvalCategory,
      actions: [
        UNNotificationAction(
          identifier: MacOsNotifier.approveAction,
          title: approve,
          options: [.authenticationRequired]
        ),
        UNNotificationAction(
          identifier: MacOsNotifier.denyAction,
          title: deny,
          options: [.destructive]
        ),
      ],
      intentIdentifiers: [],
      options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
    registeredLabels = (approve, deny)
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
    let request = response.notification.request
    let userInfo = request.content.userInfo
    switch response.actionIdentifier {
    case MacOsNotifier.approveAction, MacOsNotifier.denyAction:
      if let approvalId = userInfo["approvalId"] as? String {
        let action = response.actionIdentifier == MacOsNotifier.approveAction ? "approve" : "deny"
        channel.invokeMethod(
          "onNotificationAction",
          arguments: ["action": action, "approvalId": approvalId]
        )
      }
      // Answered: it must not stay in the list with buttons that now do nothing.
      center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
    case UNNotificationDefaultActionIdentifier:
      if let route = userInfo["route"] as? String {
        channel.invokeMethod("onNotificationClick", arguments: ["route": route])
      }
    default:
      break
    }
    completionHandler()
  }
}
