import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An active agent question, not limited by the current conversation's page.
class PendingQuestion {
  const PendingQuestion(this.message, this.workspaceId);
  final MessageDto message;
  final String workspaceId;
}

final pendingQuestionsProvider = StreamProvider<List<PendingQuestion>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return client
      .subscribe('questions.watchPending', {'workspace_id': workspaceId})
      .map(
        (frame) => [
          for (final row
              in (frame['questions'] as List? ?? const []).whereType<Map>())
            PendingQuestion(
              MessageDto.fromJson({
                ...row.cast<String, dynamic>(),
                'sender_id': '',
                'sender_type': 'agent',
                'message_type': 'user_question',
              }),
              workspaceId,
            ),
        ],
      );
});

final workspaceCredentialBlocksProvider =
    StreamProvider<List<RunCredentialBlockDto>>((ref) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return const Stream.empty();
      return RemoteCredentialGateRepository(client).watchBlocked().map(
        (rows) => [
          for (final row in rows)
            if (row.workspaceId == workspaceId) row,
        ],
      );
    });

/// Latest failed attempt per (vendor, ticket); a newer success resolves it.
final failedTicketSyncProvider = StreamProvider<List<TicketSyncLogEntry>>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RpcTicketSyncLogRepository(client).watchForWorkspace(workspaceId).map((
    rows,
  ) {
    final latest = <String, TicketSyncLogEntry>{};
    for (final row in rows) {
      final key =
          '${row.vendor}:${row.ticketId ?? ''}:${row.direction.toStorageString()}';
      final prior = latest[key];
      if (prior == null || prior.createdAt.isBefore(row.createdAt)) {
        latest[key] = row;
      }
    }
    return [
      for (final row in latest.values)
        if (row.outcome == SyncOutcome.failed) row,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
});

/// Urgent non-PR count. The PR inbox adds its own actionable sections; activity
/// unread is deliberately not part of this badge.
final requestActionableCountProvider = Provider<int>(
  (ref) =>
      (ref.watch(workspacePendingConfirmationsProvider).value?.length ?? 0) +
      (ref.watch(pendingQuestionsProvider).value?.length ?? 0) +
      (ref.watch(workspaceCredentialBlocksProvider).value?.length ?? 0) +
      (ref.watch(failedTicketSyncProvider).value?.length ?? 0),
);

final notificationFeedRepositoryProvider =
    Provider<RpcNotificationFeedRepository?>((ref) {
      final client = ref.watch(rpcClientProvider).value;
      return client == null ? null : RpcNotificationFeedRepository(client);
    });

final activityFeedProvider = StreamProvider<List<NotificationFeedItem>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  final repo = ref.watch(notificationFeedRepositoryProvider);
  if (workspaceId == null || repo == null) return const Stream.empty();
  return repo.watchFeed(workspaceId);
});

final activityReadMarkProvider = StreamProvider<NotificationReadMark?>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  final userId = ref.watch(remoteIdentityProvider).value?.userId;
  final repo = ref.watch(notificationFeedRepositoryProvider);
  if (workspaceId == null || userId == null || repo == null) {
    return const Stream.empty();
  }
  return repo.watchReadMark(workspaceId, userId);
});

final activityItemStatesProvider =
    StreamProvider<Map<String, NotificationItemState>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      final userId = ref.watch(remoteIdentityProvider).value?.userId;
      final repo = ref.watch(notificationFeedRepositoryProvider);
      if (workspaceId == null || userId == null || repo == null) {
        return const Stream.empty();
      }
      return repo
          .watchItemStates(workspaceId, userId)
          .map((rows) => {for (final row in rows) row.itemId: row});
    });

class ActivityEntry {
  const ActivityEntry(this.item, this.read);
  final NotificationFeedItem item;
  final bool read;
}

final activityMutedReposProvider = Provider<Set<String>>((ref) {
  final raw = ref
      .watch(sharedPrefsProvider)
      .getString('notifications_muted_repos');
  if (raw == null) return const {};
  try {
    return (jsonDecode(raw) as List)
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .toSet();
  } on Object {
    return const {};
  }
});

/// Only events the desktop's notification frame mapper presents. The feed
/// also records lifecycle frames which are not operator notifications.
const activityMethods = <String>{
  'notifications/pr_ready_to_merge',
  'notifications/pr_merge_blocked',
  'notifications/pr_approved',
  'notifications/pr_changes_requested',
  'notifications/pr_review_dismissed',
  'notifications/pr_checks_failed',
  'notifications/pr_checks_recovered',
  'notifications/pr_comment_mentioned',
  'notifications/pr_thread_replied',
  'notifications/pr_thread_resolved',
  'notifications/agent_run_completed',
  'notifications/pr_published',
  'notifications/pr_merged',
  'notifications/message_received',
  'notifications/pr_mentioned',
  'notifications/pr_review_requested',
  'notifications/review_stale',
  'notifications/external_pr_merged',
  'notifications/ticket_assigned',
  'notifications/ticket_status_changed',
  'notifications/meeting_starting_soon',
  'notifications/calendar_auth_expired',
  'notifications/rig_control_changed',
  'notifications/rig_reaped',
  'notifications/rig_closed',
  'notifications/agent_awaiting_input',
  'notifications/agent_action_blocked',
};

/// Mirrors desktop precedence: dismissal/clear hide, per-item state overrides
/// resolution and mark-all, resolved waits otherwise read by default.
final activityEntriesProvider = Provider<List<ActivityEntry>>((ref) {
  final feed =
      ref.watch(activityFeedProvider).value ?? const <NotificationFeedItem>[];
  final mark = ref.watch(activityReadMarkProvider);
  final states =
      ref.watch(activityItemStatesProvider).value ??
      const <String, NotificationItemState>{};
  final userId = ref.watch(remoteIdentityProvider).value?.userId;
  final muted = ref.watch(activityMutedReposProvider);
  final ownLogins =
      ref.watch(viewerLoginsProvider).value?.values.toSet() ?? const <String>{};
  final entries = <ActivityEntry>[];
  for (final item in feed) {
    if (!activityMethods.contains(item.method)) continue;
    final params = item.params;
    if (userId != null &&
        params['for_user_id'] is String &&
        params['for_user_id'] != userId) {
      continue;
    }
    if (userId != null &&
        params['assignee_type'] == 'user' &&
        params['assigned_agent_id'] is String &&
        params['assigned_agent_id'] != userId) {
      continue;
    }
    if (item.method == 'notifications/message_received') {
      if (userId != null && params['sender_user_id'] == userId) continue;
      final mentions = (params['mentions'] as List? ?? const [])
          .whereType<String>();
      final mentioned = userId != null && mentions.contains('user:$userId');
      if (!mentioned) {
        if (params['is_agent_message'] == false) continue;
        if (userId != null &&
            params['requested_by_user_id'] is String &&
            params['requested_by_user_id'] != userId) {
          continue;
        }
      }
      if ((params['content_preview'] as String? ?? '').trim().isEmpty) continue;
    }
    if (userId != null &&
        params['controller'] == 'user:$userId' &&
        params['held'] != false) {
      continue;
    }
    final owner = params['repo_owner'] as String?;
    final name = params['repo_name'] as String?;
    if (owner != null &&
        name != null &&
        muted.contains('$owner/$name'.toLowerCase())) {
      continue;
    }
    if (ownLogins.isNotEmpty &&
        ['merged_by_login', 'approver_login', 'author_login'].any(
          (key) =>
              params[key] is String &&
              ownLogins.contains((params[key] as String).toLowerCase()),
        )) {
      continue;
    }
    final state = states[item.id];
    if (state?.isDismissed == true ||
        (mark.value?.clearedBefore != null &&
            !item.createdAt.isAfter(mark.value!.clearedBefore!))) {
      continue;
    }
    entries.add(
      ActivityEntry(
        item,
        state?.isRead ??
            (item.isResolved ||
                !mark.hasValue ||
                (mark.value?.lastSeenAt != null &&
                    !item.createdAt.isAfter(mark.value!.lastSeenAt!))),
      ),
    );
  }
  return entries;
});

final unreadActivityCountProvider = Provider<int>(
  (ref) =>
      ref.watch(activityEntriesProvider).where((entry) => !entry.read).length,
);

/// Capture the workspace/user at invocation, never from a late workspace
/// switch after awaiting a confirmation dialog or another asynchronous step.
class ActivityActions {
  const ActivityActions(this.client, this.workspaceId, this.userId);
  final RemoteRpcClient client;
  final String workspaceId;
  final String userId;
  RpcNotificationFeedRepository get _repo =>
      RpcNotificationFeedRepository(client);
  Future<void> read(String id, {required bool value}) =>
      _repo.setItemRead(workspaceId, userId, id, read: value);
  Future<void> dismiss(String id) => _repo.dismissItem(workspaceId, userId, id);
  Future<void> markAll() => _repo.markAllRead(workspaceId, userId);
  Future<void> clear() => _repo.clearAll(workspaceId, userId);
}

final activityActionsProvider = Provider<ActivityActions?>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  final userId = ref.watch(remoteIdentityProvider).value?.userId;
  return client == null || workspaceId == null || userId == null
      ? null
      : ActivityActions(client, workspaceId, userId);
});
