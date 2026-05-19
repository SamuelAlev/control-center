import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Garbage-collects isolated repo worktrees when a unit ends.
///
/// Triggers:
/// - ticket marked done ([TicketCompleted]) or won't-do ([TicketCancelled])
///   → tear down the ticket's worktrees + branches;
/// - a conversation is deleted ([ConversationDeleted]) → tear down its
///   worktrees;
/// - a PR is merged ([PrMerged]) → resolve the review channel(s) for the PR and
///   tear down their worktrees;
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
  })  : _eventBus = eventBus,
        _provisioner = provisioner,
        _reviewChannels = reviewChannels,
        _prWorktrees = prWorktrees;

  final DomainEventBus _eventBus;
  final RepoWorkspaceProvisionerPort _provisioner;
  final ReviewChannelRepository _reviewChannels;
  final PrWorktreePort _prWorktrees;

  static const _tag = 'WorktreeGcListener';

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Subscribes to the lifecycle events.
  void start() {
    _subs.add(_eventBus.on<TicketCompleted>().listen(
          (e) => _guard(() => _provisioner.releaseTicket(ticketId: e.ticketId)),
        ));
    _subs.add(_eventBus.on<TicketCancelled>().listen(
          (e) => _guard(() => _provisioner.releaseTicket(ticketId: e.ticketId)),
        ));
    _subs.add(_eventBus.on<ConversationDeleted>().listen((e) {
      final workspaceId = e.workspaceId;
      _guard(() => workspaceId != null && workspaceId.isNotEmpty
          ? _provisioner.releaseConversation(
              workspaceId: workspaceId,
              channelId: e.channelId,
            )
          : _provisioner.releaseConversationAnyWorkspace(
              channelId: e.channelId,
            ));
    }));
    _subs.add(_eventBus.on<PrMerged>().listen((e) => _guard(() => _onPrMerged(e))));
    // Ephemeral "open in editor" PR worktrees: drop them when the PR reaches a
    // terminal state. Carries `repoFullName` + `prNumber` (not the node id).
    _subs.add(_eventBus.on<PullRequestStatusChanged>().listen((e) {
      final repoFullName = e.repoFullName;
      final prNumber = e.prNumber;
      if ((e.status == 'merged' || e.status == 'closed') &&
          repoFullName != null &&
          repoFullName.isNotEmpty &&
          prNumber != null) {
        _guard(() => _prWorktrees.release(
              repoFullName: repoFullName,
              prNumber: prNumber,
            ));
      }
    }));
  }

  /// Cancels all subscriptions.
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _onPrMerged(PrMerged event) async {
    final assocs =
        await _reviewChannels.watchByWorkspace(event.workspaceId).first;
    final matches = assocs.where((a) => a.prNodeId == event.prId);
    for (final assoc in matches) {
      await _provisioner.releaseConversation(
        workspaceId: event.workspaceId,
        channelId: assoc.channelId,
      );
    }
  }

  void _guard(Future<void> Function() action) {
    unawaited(action().catchError((Object e, StackTrace st) {
      AppLog.w(_tag, 'worktree GC failed: $e');
    }));
  }
}
