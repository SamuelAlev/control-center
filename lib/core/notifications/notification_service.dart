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
/// `UNUserNotificationCenter` space on macOS, `local_notifier` elsewhere).
/// Click-through navigation is handled by the delivery via the `onNavigate`
/// callback it was constructed with, keeping this class decoupled from the
/// router.
class LocalNotificationService implements NotificationPort {
  /// Creates a [LocalNotificationService].
  LocalNotificationService({
    required this._preferences,
    required this._delivery,
    required this._isRouteActive,
    required this._soundService,
    bool Function()? isFocusModeActive,
    bool Function(String spaceId)? isSpaceActive,
    bool Function()? isAppFocused,
  }) : _isFocusModeActive = isFocusModeActive ?? (() => false),
       _isSpaceActive = isSpaceActive ?? ((_) => false),
       _isAppFocused = isAppFocused ?? (() => true);

  final NotificationPreferencesPort _preferences;
  final DesktopNotificationDelivery _delivery;
  final bool Function(String route) _isRouteActive;
  final bool Function() _isFocusModeActive;
  final NotificationSoundService _soundService;
  final bool Function(String spaceId) _isSpaceActive;

  /// Whether one of the app's windows holds keyboard focus right now.
  ///
  /// Defaults to `true` — the pre-focus-gating behaviour — so a caller that
  /// does not wire it keeps suppressing on-screen notifications rather than
  /// suddenly becoming noisy.
  final bool Function() _isAppFocused;

  /// Monotonic sequence for unique native notification identifiers.
  int _seq = 0;

  @override
  void show(AppNotification notification) async {
    try {
      final globalEnabled = await _preferences.isGlobalEnabled();
      if (!globalEnabled) {
        return;
      }

      final categoryEnabled = await _preferences.isCategoryEnabled(
        notification.category,
      );
      if (!categoryEnabled) {
        return;
      }

      // Suppress if the user is already LOOKING AT the thing being announced:
      // the app holds keyboard focus AND they are on the target route AND
      // (when a spaceId is provided) in that specific space.
      //
      // The focus test is what makes this "already looking at it" rather than
      // "happened to leave that screen open". A conversation left open behind
      // another app is not being read, so a new message in it is exactly the
      // notification the operator wants — the whole point of the banner is to
      // reach them where they are, and where they are is the other app.
      //
      // Toast-only by construction: the durable bell renders through
      // `mapNotificationFrame` and never consults this service, so a message
      // silenced here is still recorded as history.
      if (_isAppFocused() && _isRouteActive(notification.route)) {
        final spaceId = notification.spaceId;
        if (spaceId == null || _isSpaceActive(spaceId)) {
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
    // The media_kit player releases its native resources asynchronously;
    // `dispose()` cannot await, so the chain runs detached.
    unawaited(_soundService.dispose());
  }
}
