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
  return repo.watchFeed(workspaceId).map((page) => page.items);
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

/// Mirrors desktop precedence: ended waits, dismissal and clear hide; a
/// per-item read state overrides mark-all.
final activityEntriesProvider = Provider<List<ActivityEntry>>((ref) {
  final feed =
      ref.watch(activityFeedProvider).value ?? const <NotificationFeedItem>[];
  final mark = ref.watch(activityReadMarkProvider);
  final states =
      ref.watch(activityItemStatesProvider).value ??
      const <String, NotificationItemState>{};
  final muted = ref.watch(activityMutedReposProvider);
  final ownLogins =
      ref.watch(viewerLoginsProvider).value?.values.toSet() ?? const <String>{};
  final entries = <ActivityEntry>[];
  for (final item in feed) {
    // Who an item is FOR is decided on the server (`notificationTargetsUser`)
    // before the feed reaches this client; only per-device preferences apply
    // here.
    final params = item.params;
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
    // A resolved item is an agent wait that ended; waits are time-bound, so
    // the row leaves rather than asking for an answer nobody can give.
    if (item.isResolved ||
        state?.isDismissed == true ||
        (mark.value?.hides(item) ?? false)) {
      continue;
    }
    entries.add(
      ActivityEntry(
        item,
        state?.isRead ??
            (!mark.hasValue || (mark.value?.hasSeen(item) ?? false)),
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
