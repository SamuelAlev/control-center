import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/notifications/notification_sound.dart';

/// How non-urgent notifications are delivered.
enum BatchDeliveryPolicy {
  /// Show every notification immediately.
  realtime,

  /// Accumulate non-urgent notifications and deliver as a digest every 2 hours.
  digest2h,

  /// Deliver one daily digest at a configured time; urgent always real-time.
  digestDaily,
}

/// Time-of-day representation for quiet hours.
class TimeOfDay {
  /// Creates a [TimeOfDay].
  const TimeOfDay({required this.hour, required this.minute});

  /// Hour (0–23).
  final int hour;

  /// Minute (0–59).
  final int minute;

  /// Total minutes from midnight.
  int get totalMinutes => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Configuration for quiet hours during which non-urgent notifications are
/// suppressed.
class QuietHoursConfig {
  /// Creates a [QuietHoursConfig].
  const QuietHoursConfig({
    required this.enabled,
    required this.start,
    required this.end,
  });

  /// Whether quiet hours are active.
  final bool enabled;

  /// Start of quiet period.
  final TimeOfDay start;

  /// End of quiet period.
  final TimeOfDay end;

  /// Returns `true` if [now] falls within the quiet hours window.
  bool isQuiet(DateTime now) {
    if (!enabled) {
      return false;
    }
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.totalMinutes;
    final endMinutes = end.totalMinutes;
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    // Wraps midnight.
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }
}

/// Port for querying notification preferences.
///
/// Implemented by `SharedPreferencesNotificationPreferences` in the
/// infrastructure layer. The domain/presentation layers depend only on
/// this interface.
abstract interface class NotificationPreferencesPort {
  /// Returns `true` when all notifications are enabled.
  Future<bool> isGlobalEnabled();

  /// Sets the global enable/disable flag.
  Future<void> setGlobalEnabled({required bool enabled});

  /// Returns `true` when [category] is allowed to fire.
  Future<bool> isCategoryEnabled(NotificationCategory category);

  /// Enables or disables a specific [category].
  Future<void> setCategoryEnabled(
    NotificationCategory category, {
    required bool enabled,
  });

  /// Returns the current [BatchDeliveryPolicy].
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy();

  /// Sets the [BatchDeliveryPolicy].
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy);

  /// Returns the current [QuietHoursConfig].
  Future<QuietHoursConfig> getQuietHours();

  /// Updates the [QuietHoursConfig].
  Future<void> setQuietHours(QuietHoursConfig config);

  /// Returns the currently selected notification sound.
  Future<NotificationSound> getNotificationSound();

  /// Sets the notification sound.
  Future<void> setNotificationSound(NotificationSound sound);
  /// Returns the current notification sound volume (0.0–1.0).
  Future<double> getVolume();

  /// Sets the notification sound volume (0.0–1.0).
  Future<void> setVolume(double volume);

  /// Returns the lead time, in minutes, for "meeting starting soon" calendar
  /// alerts (how long before an event's start the alert fires). Defaults to 5.
  Future<int> getCalendarAlertLeadMinutes();

  /// Sets the "meeting starting soon" alert lead time, in minutes.
  Future<void> setCalendarAlertLeadMinutes(int minutes);
}
