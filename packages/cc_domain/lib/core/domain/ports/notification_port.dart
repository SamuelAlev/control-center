import 'package:cc_domain/core/domain/notifications/notification_category.dart';

/// Port for showing desktop notifications.
///
/// Implemented by `LocalNotificationService` in the infrastructure layer.
/// The domain and presentation layers depend only on this interface.
abstract interface class NotificationPort {
  /// Displays a native desktop notification.
  ///
  /// Respects category preferences and, when
  /// [AppNotification.suppressWhenViewingTarget] is set, active-route visibility.
  void show(AppNotification notification);

  /// Removes the OS notification announcing [wait], if one is still on
  /// screen or in the system's notification list.
  ///
  /// Called when the wait ends, so a stale approval cannot be answered from a
  /// notification that outlived it. A no-op when nothing was delivered.
  void withdraw(NotificationWait wait);

  /// Disposes any native resources.
  void dispose();
}
