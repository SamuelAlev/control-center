import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Categories that are always delivered in real-time regardless of batch
/// policy, quiet hours, or focus mode. These represent blocking situations
/// the user needs to know about immediately (e.g. a CVE in a dependency,
/// or a PR that is blocking a release train).
const _urgentCategories = {
  NotificationCategory.pullRequestPublished,
  // A meeting alert the user only sees after quiet hours / focus mode is
  // worthless — it is time-sensitive, so it always delivers in real time.
  NotificationCategory.meetingStartsSoon,
};

/// Infrastructure implementation of [NotificationPort].
///
/// Owns all preference/suppression/sound policy, then delegates the actual
/// OS-level display to a [DesktopNotificationDelivery] (the native
/// `UNUserNotificationCenter` channel on macOS, `local_notifier` elsewhere).
/// Click-through navigation is handled by the delivery via the `onNavigate`
/// callback it was constructed with, keeping this class decoupled from the
/// router.
class LocalNotificationService implements NotificationPort {
  /// Creates a [LocalNotificationService].
  LocalNotificationService({
    required NotificationPreferencesPort preferences,
    required DesktopNotificationDelivery delivery,
    required bool Function(String route) isRouteActive,
    required NotificationSoundService soundService,
    bool Function()? isFocusModeActive,
    bool Function(String channelId)? isChannelActive,
  })  : _preferences = preferences,
        _delivery = delivery,
        _isRouteActive = isRouteActive,
        _soundService = soundService,
        _isFocusModeActive = isFocusModeActive ?? (() => false),
        _isChannelActive = isChannelActive ?? ((_) => false);

  final NotificationPreferencesPort _preferences;
  final DesktopNotificationDelivery _delivery;
  final bool Function(String route) _isRouteActive;
  final bool Function() _isFocusModeActive;
  final NotificationSoundService _soundService;
  final bool Function(String channelId) _isChannelActive;

  /// Monotonic sequence for unique native notification identifiers.
  int _seq = 0;

  @override
  void show(AppNotification notification) async {
    try {
      final globalEnabled = await _preferences.isGlobalEnabled();
      if (!globalEnabled) {
        return;
      }

      final categoryEnabled =
          await _preferences.isCategoryEnabled(notification.category);
      if (!categoryEnabled) {
        return;
      }

      // Suppress if the user is already viewing the target route AND
      // (when a channelId is provided) the specific channel.
      final routeActive = _isRouteActive(notification.route);
      if (routeActive) {
        final channelId = notification.channelId;
        if (channelId == null || _isChannelActive(channelId)) {
          return;
        }
      }

      final isUrgent = _urgentCategories.contains(notification.category);

      // Focus mode: suppress all non-urgent notifications.
      if (!isUrgent && _isFocusModeActive()) {
        return;
      }

      // Quiet hours: suppress all non-urgent notifications.
      if (!isUrgent) {
        final quietHours = await _preferences.getQuietHours();
        if (quietHours.isQuiet(DateTime.now())) {
          return;
        }
      }

      // Play notification sound.
      final sound = await _preferences.getNotificationSound();
      final volume = await _preferences.getVolume();
      unawaited(_soundService.play(sound, volume: volume));

      // Awaited (not fire-and-forget) so a native delivery failure surfaces in
      // the catch below instead of being silently swallowed.
      await _delivery.show(
        id: '${notification.category.name}-${_seq++}',
        title: notification.title,
        body: notification.body,
        route: notification.route,
      );
    } on Object catch (e) {
      AppLog.e('notifications', 'Failed to show notification: $e');
    }
  }

  @override
  void dispose() {
    _delivery.dispose();
    _soundService.dispose();
  }
}
