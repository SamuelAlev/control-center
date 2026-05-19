// The active [NotificationPort] the client renders OS notifications through.
//
// Pure client-side composition (preferences, router, sound, focus mode, the
// in-app bell) — no server dependency. The events it renders come from
// `RpcNotificationMapper`, which decodes the `notifications/*` frames the
// connected `cc_server` pushes (see `RemoteEventForwarder`).
library;

import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:control_center/app/app_window_focused.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/live_notification_lane.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/recording_notification_port.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/shell/providers/current_route_provider.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repositories whose PR notifications the operator has muted, as lowercased
/// `owner/name`.
///
/// Lives here rather than beside either consumer because BOTH the live toast
/// path and the durable bell must apply the same set: they share one frame
/// mapper, and a mute that reached only one of them would suppress the toast
/// while leaving the bell full of the repo just muted.
final mutedReposProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(notificationPreferencesProvider).getMutedRepos();
});

/// The operator's account names across every connected forge, lower-cased.
///
/// The "was this me?" identity for notification routing: a frame naming one of
/// these as the merger, reviewer or comment author describes something the
/// operator just did, and is dropped rather than announced back at them.
///
/// Flattened from [viewerLoginsProvider] (which is keyed by forge) because the
/// notification frames carry a bare login with no forge alongside it. Collapsing
/// the forges is safe for this use: the set only ever grows to the handful of
/// accounts belonging to this one human.
///
/// Lives here, beside [mutedReposProvider], for the same reason: BOTH the live
/// toast and the durable bell must apply the identical set, and they share one
/// frame mapper.
final viewerLoginSetProvider = Provider<Set<String>>((ref) {
  return ref.watch(viewerLoginsProvider).values.toSet();
});

/// The active [NotificationPort]: renders OS notifications and reports every
/// produced notification (before suppression) into the live banner lane so
/// time-critical banner-class events reach the ambient rail. The durable bell
/// history is NOT recorded here any more — the server records it per
/// workspace (`NotificationFeedRecorder`) and the bell watches that feed.
///
/// Wires route-awareness, space-level suppression and click-through
/// navigation by reading from the [routerProvider] and
/// [selectedSpaceIdProvider] at call time (not at construction time),
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
    isSpaceActive: (spaceId) => ref.read(selectedSpaceIdProvider) == spaceId,
    // Polled at show time, not tracked: the native window event handlers do
    // not fire on macOS, so a mirrored `isFocused` would latch at whatever it
    // was when the app launched.
    isAppFocused: appWindowFocused,
  );

  return RecordingNotificationPort(
    inner: inner,
    onRecord: (notification) =>
        ref.read(liveNotificationLaneProvider).add(notification),
  );
});
