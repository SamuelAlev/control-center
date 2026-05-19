import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

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
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
  });

  /// Releases any native resources / listeners.
  void dispose();
}

/// Returns the [DesktopNotificationDelivery] appropriate for the host platform:
/// the native `UNUserNotificationCenter` channel on macOS, `local_notifier`
/// elsewhere. [onNavigate] handles click-through routing.
DesktopNotificationDelivery createDesktopNotificationDelivery({
  required void Function(String route) onNavigate,
}) {
  if (Platform.isMacOS) {
    return MacOsChannelNotificationDelivery(onNavigate: onNavigate);
  }
  return LocalNotifierNotificationDelivery(onNavigate: onNavigate);
}

/// macOS delivery backed by the native `UNUserNotificationCenter` method
/// channel (`com.controlcenter/notifications`, see
/// `macos/Runner/MacOsNotifier.swift`).
class MacOsChannelNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [MacOsChannelNotificationDelivery]. [channel] is injectable for
  /// tests; production uses the shared `com.controlcenter/notifications` channel.
  MacOsChannelNotificationDelivery({
    required void Function(String route) onNavigate,
    MethodChannel? channel,
  })  : _onNavigate = onNavigate,
        _channel =
            channel ?? const MethodChannel('com.controlcenter/notifications') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final void Function(String route) _onNavigate;
  final MethodChannel _channel;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onNotificationClick') {
      final args = call.arguments;
      final route = args is Map ? args['route'] as String? : null;
      if (route != null && route.isNotEmpty) {
        _onNavigate(route);
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
  }) =>
      _channel.invokeMethod<void>('notify', {
        'identifier': id,
        'title': title,
        'body': body,
        'route': route,
      });

  @override
  void dispose() => _channel.setMethodCallHandler(null);
}

/// Windows/Linux delivery backed by the `local_notifier` package.
class LocalNotifierNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [LocalNotifierNotificationDelivery]. [onNavigate] is invoked when
  /// the user clicks a delivered notification.
  LocalNotifierNotificationDelivery({
    required void Function(String route) onNavigate,
  }) : _onNavigate = onNavigate;

  final void Function(String route) _onNavigate;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
  }) {
    final notification = LocalNotification(title: title, body: body)
      ..onClick = () => _onNavigate(route);
    return notification.show();
  }

  @override
  void dispose() {}
}
