import 'package:control_center/core/domain/notifications/notification_category.dart';

/// Port for showing desktop notifications.
///
/// Implemented by `LocalNotificationService` in the infrastructure layer.
/// The domain and presentation layers depend only on this interface.
abstract interface class NotificationPort {
  /// Displays a native desktop notification.
  ///
  /// The notification is only shown if `category` is enabled in preferences
  /// and the user is not already viewing the target `route`.
  void show(AppNotification notification);

  /// Disposes any native resources.
  void dispose();
}
