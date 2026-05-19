import 'dart:ui' show PlatformDispatcher;

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single entry in the in-app notification center: the rendered
/// notification, when the server recorded it and whether this user has seen
/// it.
///
/// Distinct from the ephemeral OS toast: these persist so the user has a
/// durable "what happened" history (the live-activity surface).
class NotificationEntry {
  /// Creates a [NotificationEntry].
  const NotificationEntry({
    required this.id,
    required this.notification,
    required this.receivedAt,
    this.read = false,
    this.repoFullName,
  });

  /// The feed item's server-side id — what the per-item read/delete actions
  /// address. Without it a row could only be acted on as part of "everything
  /// up to here".
  final String id;

  /// The rendered notification payload.
  final AppNotification notification;

  /// When the server recorded the notification.
  final DateTime receivedAt;

  /// Whether the user has seen this entry.
  final bool read;

  /// The `owner/name` this entry came from, when it is PR-shaped.
  ///
  /// Derived from the frame params here rather than added to [AppNotification]
  /// because it exists to power one UI affordance — the row's "mute this
  /// repository" action — and the domain object has no business carrying a
  /// field only the bell reads.
  final String? repoFullName;
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

/// The current user's PER-ITEM overrides, keyed by feed item id
/// (`notifications.watchItemStates`).
///
/// The watermarks above are the bulk answer; a row here is the answer for one
/// item, either way — including "explicitly unread", which a watermark cannot
/// express without dragging every older row with it.
final notificationItemStatesProvider =
    StreamProvider.autoDispose<Map<String, NotificationItemState>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (workspaceId == null || workspaceId.isEmpty || userId == null) {
        return const Stream<Map<String, NotificationItemState>>.empty();
      }
      return ref
          .watch(notificationFeedRepositoryProvider)
          .watchItemStates(workspaceId, userId)
          .map((states) => {for (final s in states) s.itemId: s});
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
  final states =
      ref.watch(notificationItemStatesProvider).value ??
      const <String, NotificationItemState>{};
  final l10n = lookupAppLocalizations(
    ref.watch(localeProvider) ?? PlatformDispatcher.instance.locale,
  );
  final me = ref.watch(currentUserIdProvider);
  // Muted repositories are filtered on RENDER, not on record: the server feed
  // keeps the rows, so un-muting a repository brings its history back instead
  // of having thrown it away.
  final muted = ref.watch(mutedReposProvider).value ?? const <String>{};
  // The operator's own forge logins, so their own merges/reviews/comments are
  // not replayed at them as history.
  final viewerLogins = ref.watch(viewerLoginSetProvider);

  final entries = <NotificationEntry>[];
  for (final item in items) {
    final state = states[item.id];
    if (state != null && state.isDismissed) {
      continue;
    }
    if (clearedBefore != null && !item.createdAt.isAfter(clearedBefore)) {
      continue;
    }
    final notification = mapNotificationFrame(
      item.method,
      item.params,
      l10n: l10n,
      currentUserId: me,
      mutedRepos: muted,
      viewerLogins: viewerLogins,
    );
    if (notification == null) {
      continue;
    }
    // A per-item state is an OVERRIDE: where one exists it is the whole
    // answer, so "mark as unread" survives a watermark that would otherwise
    // cover the row. Where none exists the watermark decides, and while the
    // mark is still loading we cannot tell "never acknowledged" from "not
    // loaded yet" — rendering read avoids a spurious badge flash.
    final read =
        state?.isRead ??
        (!markAsync.hasValue ||
            (lastSeenAt != null && !item.createdAt.isAfter(lastSeenAt)));
    final owner = item.params['repo_owner'] as String?;
    final repoName = item.params['repo_name'] as String?;
    entries.add(
      NotificationEntry(
        id: item.id,
        notification: notification,
        receivedAt: item.createdAt,
        read: read,
        repoFullName: (owner == null || repoName == null)
            ? null
            : '$owner/$repoName',
      ),
    );
  }
  return entries;
});

/// Count of unread notification entries, for the top-bar bell badge.
final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationCenterProvider).where((e) => !e.read).length,
);

/// Acknowledge/clear actions over the current user's server-side read state.
final notificationCenterActionsProvider = Provider<NotificationCenterActions>(
  NotificationCenterActions.new,
);

/// Thin action facade the bell calls: every method writes the CALLING user's
/// own state on the server (the server clock and the session's authenticated
/// user are authoritative), so acting on one device acts everywhere.
class NotificationCenterActions {
  /// Creates the actions facade.
  NotificationCenterActions(this._ref);

  final Ref _ref;

  /// The (workspace, user) pair every write needs, or null before the
  /// workspace/identity have resolved.
  ({String workspaceId, String userId})? get _scope {
    final workspaceId = _ref.read(activeWorkspaceIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (workspaceId == null || workspaceId.isEmpty || userId == null) {
      return null;
    }
    return (workspaceId: workspaceId, userId: userId);
  }

  /// Marks every entry as seen. No-op when nothing is unread.
  Future<void> markAllRead() async {
    if (_ref.read(unreadNotificationCountProvider) == 0) {
      return;
    }
    final scope = _scope;
    if (scope == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .markAllRead(scope.workspaceId, scope.userId);
  }

  /// Hides every current entry ("clear all").
  Future<void> clearAll() async {
    final scope = _scope;
    if (scope == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .clearAll(scope.workspaceId, scope.userId);
  }

  /// Marks one entry read, or back to unread.
  Future<void> setRead(String itemId, {required bool read}) async {
    final scope = _scope;
    if (scope == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .setItemRead(scope.workspaceId, scope.userId, itemId, read: read);
  }

  /// Removes one entry from this user's list.
  Future<void> dismiss(String itemId) async {
    final scope = _scope;
    if (scope == null) {
      return;
    }
    await _ref
        .read(notificationFeedRepositoryProvider)
        .dismissItem(scope.workspaceId, scope.userId, itemId);
  }
}
