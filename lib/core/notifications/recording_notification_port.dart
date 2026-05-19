import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';

/// A [NotificationPort] decorator that records every notification into the
/// in-app notification center before delegating to the real port.
///
/// Recording happens *before* delegation so the in-app history captures the
/// event even when the inner port suppresses the OS toast (focus mode, quiet
/// hours, already viewing the target route/channel).
class RecordingNotificationPort implements NotificationPort {
  /// Creates a [RecordingNotificationPort] wrapping [inner], reporting each
  /// shown notification to [onRecord].
  RecordingNotificationPort({required this.inner, required this.onRecord});

  /// The underlying port that performs the actual OS-level display.
  final NotificationPort inner;

  /// Callback invoked with every notification, in produced order.
  final void Function(AppNotification notification) onRecord;

  @override
  void show(AppNotification notification) {
    onRecord(notification);
    inner.show(notification);
  }

  @override
  void dispose() => inner.dispose();
}
