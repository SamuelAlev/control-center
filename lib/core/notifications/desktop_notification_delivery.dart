import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

/// The localized titles of a notification's Approve and Deny buttons.
typedef ApprovalActionLabels = ({String approve, String deny});

/// Answers the approval [approvalId] from a notification's action button.
typedef NotificationApprovalHandler =
    void Function(String approvalId, {required bool approved});

/// Port for the final OS-level delivery of a desktop notification.
///
/// `LocalNotificationService` owns all preference/suppression/sound logic and
/// then hands a fully-decided notification to a [DesktopNotificationDelivery]
/// for actual display. Isolating the native call behind this seam lets macOS
/// use the modern `UNUserNotificationCenter` (which has a real authorization
/// model and shows banners reliably on macOS 11+) while Windows and Linux keep
/// the `local_notifier` package.
abstract interface class DesktopNotificationDelivery {
  /// Requests OS permission to post notifications, where the platform requires
  /// it. A no-op where notifications need no explicit grant (Windows/Linux via
  /// `local_notifier`). On macOS this triggers the one-time system prompt and
  /// registers the app under System Settings → Notifications.
  Future<void> requestPermission();

  /// Displays a native notification. [route] is carried through so a click can
  /// navigate back into the app via the injected `onNavigate` callback.
  ///
  /// A notification already delivered under [id] is replaced, and the
  /// replacement alerts again. That is how a reminder re-raises a wait.
  ///
  /// [timeSensitive] asks the OS to treat the notification as time-sensitive
  /// (macOS: it may break through a Focus the operator allowed it in).
  /// [approvalId] adds Approve and Deny buttons that answer that approval
  /// through the injected approval handler.
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
  });

  /// Removes the notification delivered under [id], whether it is still on
  /// screen or only in the system's list. A no-op for an unknown [id].
  Future<void> remove(String id);

  /// Releases any native resources / listeners.
  void dispose();
}

/// Returns the [DesktopNotificationDelivery] appropriate for the host platform:
/// the native `UNUserNotificationCenter` channel on macOS, `local_notifier`
/// elsewhere. [onNavigate] handles click-through routing, [onApproval] the
/// Approve/Deny buttons, titled by [actionLabels] at show time.
DesktopNotificationDelivery createDesktopNotificationDelivery({
  required void Function(String route) onNavigate,
  required NotificationApprovalHandler onApproval,
  required ApprovalActionLabels Function() actionLabels,
}) {
  if (Platform.isMacOS) {
    return MacOsChannelNotificationDelivery(
      onNavigate: onNavigate,
      onApproval: onApproval,
      actionLabels: actionLabels,
    );
  }
  return LocalNotifierNotificationDelivery(
    onNavigate: onNavigate,
    onApproval: onApproval,
    actionLabels: actionLabels,
  );
}

/// macOS delivery backed by the native `UNUserNotificationCenter` method
/// channel (`com.controlcenter/notifications`, see
/// `macos/Runner/MacOsNotifier.swift`).
class MacOsChannelNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [MacOsChannelNotificationDelivery]. [channel] is injectable for
  /// tests; production uses the shared `com.controlcenter/notifications` channel.
  MacOsChannelNotificationDelivery({
    required this._onNavigate,
    required this._onApproval,
    required this._actionLabels,
    MethodChannel? channel,
  }) : _channel =
           channel ?? const MethodChannel('com.controlcenter/notifications') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final void Function(String route) _onNavigate;
  final NotificationApprovalHandler _onApproval;
  final ApprovalActionLabels Function() _actionLabels;
  final MethodChannel _channel;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    final args = call.arguments;
    if (args is! Map) {
      return null;
    }
    switch (call.method) {
      case 'onNotificationClick':
        final route = args['route'] as String?;
        if (route != null && route.isNotEmpty) {
          _onNavigate(route);
        }
      case 'onNotificationAction':
        final approvalId = args['approvalId'] as String?;
        if (approvalId == null || approvalId.isEmpty) {
          return null;
        }
        switch (args['action']) {
          case 'approve':
            _onApproval(approvalId, approved: true);
          case 'deny':
            _onApproval(approvalId, approved: false);
        }
    }
    return null;
  }

  @override
  Future<void> requestPermission() =>
      _channel.invokeMethod<void>('requestAuthorization');

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
  }) {
    final labels = approvalId == null ? null : _actionLabels();
    return _channel.invokeMethod<void>('notify', {
      'identifier': id,
      'title': title,
      'body': body,
      'route': route,
      'timeSensitive': timeSensitive,
      if (approvalId != null && labels != null) ...{
        'approvalId': approvalId,
        'approveLabel': labels.approve,
        'denyLabel': labels.deny,
      },
    });
  }

  @override
  Future<void> remove(String id) =>
      _channel.invokeMethod<void>('remove', {'identifier': id});

  @override
  void dispose() => _channel.setMethodCallHandler(null);
}

/// Windows/Linux delivery backed by the `local_notifier` package.
///
/// Neither platform has a time-sensitive level through this package, so
/// [show]'s `timeSensitive` is ignored here; the Approve/Deny buttons are
/// supported on both.
class LocalNotifierNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [LocalNotifierNotificationDelivery]. [_onNavigate] is invoked when
  /// the user clicks a delivered notification.
  LocalNotifierNotificationDelivery({
    required this._onNavigate,
    required this._onApproval,
    required this._actionLabels,
  });

  final void Function(String route) _onNavigate;
  final NotificationApprovalHandler _onApproval;
  final ApprovalActionLabels Function() _actionLabels;

  /// Notifications still open, by identifier, so a replacement or a
  /// withdrawal can close the one already on screen.
  final Map<String, LocalNotification> _open = {};

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
  }) async {
    await remove(id);
    final labels = approvalId == null ? null : _actionLabels();
    final notification = LocalNotification(
      identifier: id,
      title: title,
      body: body,
      actions: labels == null
          ? null
          : [
              LocalNotificationAction(text: labels.approve),
              LocalNotificationAction(text: labels.deny),
            ],
    )..onClick = () => _onNavigate(route);
    // Close events are matched by identifier, so the close of a replaced
    // notification can reach its replacement: forget only this instance.
    notification.onClose = (_) {
      if (identical(_open[id], notification)) {
        _open.remove(id);
      }
    };
    if (approvalId != null) {
      // Button order is fixed above: 0 approves, 1 denies.
      notification.onClickAction = (index) => switch (index) {
        0 => _onApproval(approvalId, approved: true),
        1 => _onApproval(approvalId, approved: false),
        _ => null,
      };
    }
    _open[id] = notification;
    return notification.show();
  }

  @override
  Future<void> remove(String id) async {
    final previous = _open.remove(id);
    if (previous != null) {
      await previous.destroy();
    }
  }

  @override
  void dispose() {}
}
