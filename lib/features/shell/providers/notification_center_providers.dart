import 'dart:ui' show PlatformDispatcher;

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single entry in the in-app notification center: the rendered
/// notification, when the server recorded it, and whether this user has seen
/// it.
///
/// Distinct from the ephemeral OS toast: these persist so the user has a
/// durable "what happened" history (the live-activity surface).
class NotificationEntry {
  /// Creates a [NotificationEntry].
  const NotificationEntry({
    required this.notification,
    required this.receivedAt,
    this.read = false,
  });

  /// The rendered notification payload.
  final AppNotification notification;

  /// When the server recorded the notification.
  final DateTime receivedAt;

  /// Whether the user has seen this entry.
  final bool read;
}

/// The active workspace's durable notification feed, straight from the
/// server (`notifications.watch`). Stored per workspace in that workspace's
/// own database — never in device-local preferences, so a dev build and a
/// production install no longer share (or leak) a bell history.
final notificationFeedProvider =
    StreamProvider.autoDispose<List<NotificationFeedItem>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || workspaceId.isEmpty) {
        return const Stream<List<NotificationFeedItem>>.empty();
      }
      return ref
          .watch(notificationFeedRepositoryProvider)
          .watchFeed(workspaceId);
    });

/// The current user's read/cleared watermarks over the active workspace's
/// feed (`notifications.watchReadMark`). Per user server-side, so read state
/// follows the user across devices.
final notificationReadMarkProvider =
    StreamProvider.autoDispose<NotificationReadMark?>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (workspaceId == null || workspaceId.isEmpty || userId == null) {
        return const Stream<NotificationReadMark?>.empty();
      }
      return ref
          .watch(notificationFeedRepositoryProvider)
          .watchReadMark(workspaceId, userId);
    });

/// The notification center's rendered entries, most-recent-first.
///
/// Renders the stored feed through the SAME frame mapper the live toast path
/// uses, so localization happens in the viewer's current locale and the
/// PRD 16 §7 principal routing applies identically at read time: a frame that
/// would not have pinged this user live is simply not rendered here either.
final notificationCenterProvider = Provider<List<NotificationEntry>>((ref) {
  final items = ref.watch(notificationFeedProvider).value;
  if (items == null || items.isEmpty) {
    return const [];
  }
  final markAsync = ref.watch(notificationReadMarkProvider);
  final mark = markAsync.value;
  final lastSeenAt = mark?.lastSeenAt;
  final clearedBefore = mark?.clearedBefore;
  final l10n = lookupAppLocalizations(
    ref.watch(localeProvider) ?? PlatformDispatcher.instance.locale,
  );
  final me = ref.watch(currentUserIdProvider);

  final entries = <NotificationEntry>[];
  for (final item in items) {
    if (clearedBefore != null && !item.createdAt.isAfter(clearedBefore)) {
      continue;
    }
    final notification = mapNotificationFrame(
      item.method,
      item.params,
      l10n: l10n,
      currentUserId: me,
    );
    if (notification == null) {
      continue;
    }
    // While the mark is still loading we cannot tell "never acknowledged"
    // from "not loaded yet"; rendering read avoids a spurious badge flash.
    final read =
        !markAsync.hasValue ||
        (lastSeenAt != null && !item.createdAt.isAfter(lastSeenAt));
    entries.add(
      NotificationEntry(
        notification: notification,
        receivedAt: item.createdAt,
        read: read,
      ),
    );
  }
  return entries;
});

/// Count of unread notification entries, for the top-bar bell badge.
final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationCenterProvider).where((e) => !e.read).length,
);

/// Acknowledge/clear actions over the current user's server-side read mark.
final notificationCenterActionsProvider = Provider<NotificationCenterActions>(
  NotificationCenterActions.new,
);

/// Thin action facade the bell calls: both stamp the CALLING user's watermark
/// on the server (the server clock and the session's authenticated user are
/// authoritative), so acknowledging on one device acknowledges everywhere.
class NotificationCenterActions {
  /// Creates the actions facade.
  NotificationCenterActions(this._ref);

  final Ref _ref;

  /// Marks every entry as seen. No-op when nothing is unread, or before the
  /// workspace/identity have resolved.
  Future<void> markAllRead() async {
    if (_ref.read(unreadNotificationCountProvider) == 0) {
      return;
    }
    final workspaceId = _ref.read(activeWorkspaceIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (workspaceId == null || workspaceId.isEmpty || userId == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .markAllRead(workspaceId, userId);
  }

  /// Hides every current entry ("clear all").
  Future<void> clearAll() async {
    final workspaceId = _ref.read(activeWorkspaceIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (workspaceId == null || workspaceId.isEmpty || userId == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .clearAll(workspaceId, userId);
  }
}
