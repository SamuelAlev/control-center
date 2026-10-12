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

  /// Disposes any native resources.
  void dispose();
}
