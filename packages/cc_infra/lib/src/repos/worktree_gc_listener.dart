import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Garbage-collects isolated repo worktrees when a unit ends.
///
/// Triggers:
/// - ticket marked done ([TicketCompleted]) or won't-do ([TicketCancelled])
///   → tear down the ticket's worktrees + branches;
/// - a conversation is deleted ([SpaceDeleted]) → tear down its
///   worktrees;
/// - a PR is merged ([PrMerged]) → resolve the review space(s) for the PR,
///   tear down their worktrees and auto-archive their conversations (the PR
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
    required ReviewSpaceRepository reviewSpaces,
    required PrWorktreePort prWorktrees,
    ConversationRepository? conversations,
  }) : _eventBus = eventBus,
       _provisioner = provisioner,
       _reviewSpaces = reviewSpaces,
       _prWorktrees = prWorktrees,
       _conversations = conversations;

  final DomainEventBus _eventBus;
  final RepoWorkspaceProvisionerPort _provisioner;
  final ReviewSpaceRepository _reviewSpaces;
  final PrWorktreePort _prWorktrees;

  /// Optional: when wired, a merged PR's space conversations are archived
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
      _eventBus.on<SpaceDeleted>().listen((e) {
        // `SpaceDeleted.workspaceId` is required and non-null now, so the
        // cross-workspace fallback this used to take when it was absent
        // (`releaseSpaceAnyWorkspace`, a scan of every workspace file)
        // is unreachable from here. An EMPTY id is still possible from a
        // malformed wire payload, and teardown across every workspace is not
        // the right answer to that either — it is louder than the bug.
        final workspaceId = e.workspaceId;
        if (workspaceId.isEmpty) {
          CcInfraLog.warning(
            'worktree gc: SpaceDeleted for ${e.spaceId} carries an empty '
            'workspace; not tearing down (nothing can be located safely)',
          );
          return;
        }
        _guard(
          () => _provisioner.releaseSpace(
            workspaceId: workspaceId,
            spaceId: e.spaceId,
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
    final assocs = await _reviewSpaces
        .watchByWorkspace(event.workspaceId)
        .first;
    final matches = assocs.where((a) => a.prExternalId == event.prId);
    for (final assoc in matches) {
      await _provisioner.releaseSpace(
        workspaceId: event.workspaceId,
        spaceId: assoc.spaceId,
      );
      // Auto-archive the PR workbench's conversations (kept + reopenable).
      await _archiveConversations(event.workspaceId, assoc.spaceId);
    }
  }

  Future<void> _archiveConversations(String workspaceId, String spaceId) async {
    final repo = _conversations;
    if (repo == null) {
      return;
    }
    final convs = await repo.listForSpace(
      workspaceId: workspaceId,
      spaceId: spaceId,
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
