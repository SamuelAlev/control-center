import 'dart:async';

import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/ports/notification_port.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:local_notifier/local_notifier.dart';

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

/// Infrastructure implementation of [NotificationPort] using `local_notifier`.
///
/// Shows native desktop notifications and handles click-through navigation
/// via a callback supplied at construction time. The callback decouples
/// this class from the router.
class LocalNotificationService implements NotificationPort {
  /// Creates a [LocalNotificationService].
  LocalNotificationService({
    required NotificationPreferencesPort preferences,
    required void Function(String route) onNavigate,
    required bool Function(String route) isRouteActive,
    required NotificationSoundService soundService,
    bool Function()? isFocusModeActive,
    bool Function(String channelId)? isChannelActive,
    LocalNotification Function({required String title, required String body})?
        localNotificationFactory,
  })  : _preferences = preferences,
        _onNavigate = onNavigate,
        _isRouteActive = isRouteActive,
        _soundService = soundService,
        _isFocusModeActive = isFocusModeActive ?? (() => false),
        _isChannelActive = isChannelActive ?? ((_) => false),
        _localNotificationFactory = localNotificationFactory;

  final NotificationPreferencesPort _preferences;
  final void Function(String route) _onNavigate;
  final bool Function(String route) _isRouteActive;
  final bool Function() _isFocusModeActive;
  final NotificationSoundService _soundService;
  final bool Function(String channelId) _isChannelActive;
  final LocalNotification Function({required String title, required String body})?
      _localNotificationFactory;

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

      final localNotification = _localNotificationFactory != null
          ? _localNotificationFactory(
              title: notification.title,
              body: notification.body,
            )
          : LocalNotification(
              title: notification.title,
              body: notification.body,
            );
      localNotification.onClick = () {
        _onNavigate(notification.route);
      };
      unawaited(localNotification.show());
    } on Object catch (e) {
      AppLog.e('notifications', 'Failed to show notification: $e');
    }
  }

  @override
  void dispose() {
    _soundService.dispose();
  }
}
