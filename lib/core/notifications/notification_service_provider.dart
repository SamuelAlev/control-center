// The active [NotificationPort] the client renders OS notifications through.
//
// Pure client-side composition (preferences, router, sound, focus mode, the
// in-app bell) — no server dependency. The events it renders come from
// `RpcNotificationMapper`, which decodes the `notifications/*` frames the
// connected `cc_server` pushes (see `RemoteEventForwarder`).
library;

import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/live_notification_lane.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/recording_notification_port.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/shell/providers/current_route_provider.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The active [NotificationPort]: renders OS notifications, and reports every
/// produced notification (before suppression) into the live banner lane so
/// time-critical banner-class events reach the ambient rail. The durable bell
/// history is NOT recorded here any more — the server records it per
/// workspace (`NotificationFeedRecorder`), and the bell watches that feed.
///
/// Wires route-awareness, channel-level suppression, and click-through
/// navigation by reading from the [routerProvider] and
/// [selectedChannelIdProvider] at call time (not at construction time),
/// keeping the service decoupled from the router lifecycle.
final notificationServiceProvider = Provider<NotificationPort>((ref) {
  final preferences = ref.watch(notificationPreferencesProvider);
  final router = ref.watch(routerProvider);
  final soundService = ref.watch(notificationSoundServiceProvider);

  final inner = LocalNotificationService(
    preferences: preferences,
    delivery: createDesktopNotificationDelivery(onNavigate: router.go),
    isRouteActive: (route) => isRouteActive(router, route),
    isFocusModeActive: () => ref.read(focusModeProvider).active,
    soundService: soundService,
    isChannelActive: (channelId) =>
        ref.read(selectedChannelIdProvider) == channelId,
  );

  return RecordingNotificationPort(
    inner: inner,
    onRecord: (notification) =>
        ref.read(liveNotificationLaneProvider).add(notification),
  );
});
