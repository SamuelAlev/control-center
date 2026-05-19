import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Garbage-collects isolated repo worktrees when a unit ends.
///
/// Triggers:
/// - ticket marked done ([TicketCompleted]) or won't-do ([TicketCancelled])
///   → tear down the ticket's worktrees + branches;
/// - a conversation is deleted ([ChannelDeleted]) → tear down its
///   worktrees;
/// - a PR is merged ([PrMerged]) → resolve the review channel(s) for the PR,
///   tear down their worktrees, and auto-archive their conversations (the PR
///   workbench closes; history is kept and reopenable);
/// - a PR is merged or closed ([PullRequestStatusChanged]) → tear down the
///   ephemeral "open in editor" worktree materialized for that PR.
///
/// Follows the long-lived listener shape of `TicketDispatcher`.
class WorktreeGcListener {
  /// Creates a [WorktreeGcListener].
  WorktreeGcListener({
    required DomainEventBus eventBus,
    required RepoWorkspaceProvisionerPort provisioner,
    required ReviewChannelRepository reviewChannels,
    required PrWorktreePort prWorktrees,
    ConversationRepository? conversations,
  }) : _eventBus = eventBus,
       _provisioner = provisioner,
       _reviewChannels = reviewChannels,
       _prWorktrees = prWorktrees,
       _conversations = conversations;

  final DomainEventBus _eventBus;
  final RepoWorkspaceProvisionerPort _provisioner;
  final ReviewChannelRepository _reviewChannels;
  final PrWorktreePort _prWorktrees;

  /// Optional: when wired, a merged PR's channel conversations are archived
  /// (the workbench closes automatically). Null → worktrees are still GC'd but
  /// the conversations stay active.
  final ConversationRepository? _conversations;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Subscribes to the lifecycle events.
  void start() {
    _subs.add(
      _eventBus.on<TicketCompleted>().listen(
        (e) => _guard(() => _provisioner.releaseTicket(ticketId: e.ticketId)),
      ),
    );
    _subs.add(
      _eventBus.on<TicketCancelled>().listen(
        (e) => _guard(() => _provisioner.releaseTicket(ticketId: e.ticketId)),
      ),
    );
    _subs.add(
      _eventBus.on<ChannelDeleted>().listen((e) {
        final workspaceId = e.workspaceId;
        _guard(
          () => workspaceId != null && workspaceId.isNotEmpty
              ? _provisioner.releaseConversation(
                  workspaceId: workspaceId,
                  channelId: e.channelId,
                )
              : _provisioner.releaseConversationAnyWorkspace(
                  channelId: e.channelId,
                ),
        );
      }),
    );
    _subs.add(
      _eventBus.on<PrMerged>().listen((e) => _guard(() => _onPrMerged(e))),
    );
    // Ephemeral "open in editor" PR worktrees: drop them when the PR reaches a
    // terminal state. Carries `repoFullName` + `prNumber` (not the node id).
    _subs.add(
      _eventBus.on<PullRequestStatusChanged>().listen((e) {
        final repoFullName = e.repoFullName;
        final prNumber = e.prNumber;
        if ((e.status == 'merged' || e.status == 'closed') &&
            repoFullName != null &&
            repoFullName.isNotEmpty &&
            prNumber != null) {
          _guard(
            () => _prWorktrees.release(
              repoFullName: repoFullName,
              prNumber: prNumber,
            ),
          );
        }
      }),
    );
  }

  /// Cancels all subscriptions.
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _onPrMerged(PrMerged event) async {
    final assocs = await _reviewChannels
        .watchByWorkspace(event.workspaceId)
        .first;
    final matches = assocs.where((a) => a.prNodeId == event.prId);
    for (final assoc in matches) {
      await _provisioner.releaseConversation(
        workspaceId: event.workspaceId,
        channelId: assoc.channelId,
      );
      // Auto-archive the PR workbench's conversations (kept + reopenable).
      await _archiveConversations(event.workspaceId, assoc.channelId);
    }
  }

  Future<void> _archiveConversations(
    String workspaceId,
    String channelId,
  ) async {
    final repo = _conversations;
    if (repo == null) {
      return;
    }
    final convs = await repo.listForChannel(
      workspaceId: workspaceId,
      channelId: channelId,
    );
    for (final c in convs) {
      if (c.status == ConversationStatus.archived) {
        continue;
      }
      await repo.setStatus(
        workspaceId: workspaceId,
        conversationId: c.id,
        status: ConversationStatus.archived,
      );
    }
  }

  void _guard(Future<void> Function() action) {
    unawaited(
      action().catchError((Object e, StackTrace st) {
        CcInfraLog.warning('worktree GC failed: $e');
      }),
    );
  }
}
