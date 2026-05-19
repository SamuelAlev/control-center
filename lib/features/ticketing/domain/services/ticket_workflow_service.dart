import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_channel_service.dart' show TicketChannelService;
import 'package:control_center/features/ticketing/domain/services/ticket_dispatcher.dart' show TicketDispatcher;
import 'package:control_center/features/ticketing/domain/services/ticket_remote_sync_handler.dart' show TicketRemoteSyncHandler;
import 'package:uuid/uuid.dart';

/// Creates and drives tickets through their lifecycle. Replaces the old
/// `TaskDelegationService` method-for-method (the pipeline engine relies on the
/// same `create → start → complete/fail/cancel` flow and terminal guards) and
/// adds assignment / reassignment / collaboration.
///
/// Pure domain: depends only on [TicketRepository] and the [DomainEventBus].
/// All ticket writes go through [_mutate], which carries the correct optimistic
/// concurrency contract — `expectedVersion` is the version read *before* the
/// mutation, and the row is written with `version + 1` — and retries a bounded
/// number of times when a concurrent writer wins the race. Agent dispatch is
/// owned exclusively by [TicketDispatcher]; messaging side effects (channels,
/// participants) by [TicketChannelService]; remote provider sync by
/// [TicketRemoteSyncHandler]. This service never dispatches or opens channels.
class TicketWorkflowService implements TicketWorkflowPort {
  /// Creates a [TicketWorkflowService].
  TicketWorkflowService({
    required this.repository,
    required this.eventBus,
  });

  /// Local persistence (mirror + overlay).
  final TicketRepository repository;

  /// Domain event bus.
  final DomainEventBus eventBus;

  static const _uuid = Uuid();

  /// How many times a version-checked write is retried before giving up.
  static const _maxWriteAttempts = 4;

  /// Creates a ticket and publishes [TicketCreated] (+ [TicketDelegated] when
  /// it has a parent, + [TicketAssigned] when it has an assignee).
  ///
  /// [TicketAssigned] is the single trigger the [TicketDispatcher] listens to;
  /// the ticket is created in [status] (defaults to `open`, the only other
  /// sensible creation state being `backlog`) and the dispatcher owns the
  /// readiness check → channel → start → dispatch sequence. `tryStart` accepts
  /// both `open` and `backlog`, so an assigned-on-create ticket still starts.
  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  }) async {
    final now = DateTime.now();
    final externalKey = provider == TicketProvider.local ? _uuid.v4() : null;

    final ticket = Ticket(
      id: id ?? _uuid.v4(),
      workspaceId: workspaceId,
      provider: provider,
      externalKey: externalKey,
      title: title,
      description: description,
      priority: priority,
      labels: labels,
      status: status,
      parentTicketId: parentTicketId,
      projectId: projectId,
      assignedAgentId: assignedAgentId,
      assignedTeamId: assignedTeamId,
      delegatedByAgentId: delegatedByAgentId,
      channelId: channelId,
      mode: mode,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      expectedOutputSchema: expectedOutputSchema,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insert(ticket);

    eventBus.publish(TicketCreated(ticketId: ticket.id, occurredAt: now));
    if (parentTicketId != null) {
      eventBus.publish(TicketDelegated(
        ticketId: ticket.id,
        parentTicketId: parentTicketId,
        occurredAt: now,
      ));
    }
    if (assignedAgentId != null || assignedTeamId != null) {
      _publishAssigned(ticket);
    }
    return ticket;
  }

  /// Creates a delegated child ticket (always local — internal sub-work is not
  /// pushed to a remote tracker).
  Future<Ticket> delegate({
    required String workspaceId,
    required String title,
    required String parentTicketId,
    required String delegatedByAgentId,
    required String assignedAgentId,
    String? description,
    String? channelId,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
  }) {
    return createTicket(
      workspaceId: workspaceId,
      title: title,
      description: description,
      parentTicketId: parentTicketId,
      delegatedByAgentId: delegatedByAgentId,
      assignedAgentId: assignedAgentId,
      channelId: channelId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      expectedOutputSchema: expectedOutputSchema,
    );
  }

  /// Marks a ticket in-progress (no-op if terminal/missing/already started).
  Future<void> startTicket(String ticketId, {required String workspaceId}) async {
    await tryStart(ticketId, workspaceId: workspaceId);
  }

  /// Transitions an `open`/`backlog` ticket to `in_progress`.
  ///
  /// Returns `true` only when *this* call performed the transition, so the
  /// caller (the [TicketDispatcher]) can treat it as the single-dispatch guard:
  /// a duplicate `TicketAssigned` for an already-started ticket returns `false`
  /// and does not re-dispatch. Returns `false` for missing/terminal tickets or
  /// tickets already past `open`/`backlog`.
  Future<bool> tryStart(String ticketId, {required String workspaceId}) {
    return _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.isTerminal) {
          return null;
        }
        if (ticket.status != TicketStatus.open &&
            ticket.status != TicketStatus.backlog) {
          return null;
        }
        final now = DateTime.now();
        return ticket.copyWith(
          version: ticket.version + 1,
          status: TicketStatus.inProgress,
          startedAt: now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(TicketStatusChanged(
          ticketId: ticketId,
          from: before.status.toStorageString(),
          to: TicketStatus.inProgress.toStorageString(),
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ));
        eventBus.publish(
          TicketStarted(ticketId: ticketId, occurredAt: after.updatedAt),
        );
      },
    );
  }

  /// Attaches a discussion channel to a ticket (version-safe, idempotent).
  /// Owned by the [TicketDispatcher] once it has ensured a channel exists.
  Future<void> attachChannel(
    String ticketId,
    String channelId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.channelId == channelId) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          channelId: channelId,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  /// Completes a ticket with optional output (terminal success).
  ///
  /// [force] bypasses the already-terminal guard so a manual override can move
  /// a ticket straight from one terminal state to another.
  @override
  Future<void> completeTicket(
    String ticketId, {
    required String workspaceId,
    Map<String, dynamic>? output,
    bool force = false,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!force && ticket.isTerminal) {
          return null;
        }
        final now = DateTime.now();
        return ticket.copyWith(
          version: ticket.version + 1,
          status: TicketStatus.done,
          outputJson: output,
          finishedAt: now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(
          TicketCompleted(ticketId: ticketId, occurredAt: after.updatedAt),
        );
        eventBus.publish(TicketStatusChanged(
          ticketId: ticketId,
          from: before.status.toStorageString(),
          to: TicketStatus.done.toStorageString(),
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ));
      },
    );
  }

  /// Fails a ticket with an error message (terminal failure).
  ///
  /// [force] bypasses the already-terminal guard (see [completeTicket]).
  Future<void> failTicket(
    String ticketId,
    String errorMessage, {
    required String workspaceId,
    bool force = false,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!force && ticket.isTerminal) {
          return null;
        }
        final now = DateTime.now();
        return ticket.copyWith(
          version: ticket.version + 1,
          status: TicketStatus.failed,
          errorMessage: errorMessage,
          finishedAt: now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(TicketFailed(
          ticketId: ticketId,
          errorMessage: errorMessage,
          occurredAt: after.updatedAt,
        ));
        eventBus.publish(TicketStatusChanged(
          ticketId: ticketId,
          from: before.status.toStorageString(),
          to: TicketStatus.failed.toStorageString(),
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ));
      },
    );
  }

  /// Cancels a ticket (terminal).
  ///
  /// [force] bypasses the already-terminal guard (see [completeTicket]).
  @override
  Future<void> cancelTicket(
    String ticketId, {
    required String workspaceId,
    bool force = false,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!force && ticket.isTerminal) {
          return null;
        }
        final now = DateTime.now();
        return ticket.copyWith(
          version: ticket.version + 1,
          status: TicketStatus.cancelled,
          finishedAt: now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(
          TicketCancelled(ticketId: ticketId, occurredAt: after.updatedAt),
        );
        eventBus.publish(TicketStatusChanged(
          ticketId: ticketId,
          from: before.status.toStorageString(),
          to: TicketStatus.cancelled.toStorageString(),
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ));
      },
    );
  }

  /// Transitions a ticket to [target], guarded by [TicketStatus.canTransitionTo].
  /// Terminal targets route through the dedicated methods so the event contract
  /// (and pipeline resume) is preserved.
  ///
  /// The transition graph is enforced only for the agent/automation path (MCP
  /// tools, reconcilers): an illegal transition there is logged and ignored.
  /// User-driven UI changes pass [force] `true` to bypass the graph entirely —
  /// the human operator may move a ticket to any status, including reopening a
  /// terminal ticket.
  Future<void> transitionStatus(
    String ticketId,
    TicketStatus target, {
    required String workspaceId,
    bool force = false,
  }) async {
    final ticket = await repository.getById(ticketId);
    if (ticket == null) {
      return;
    }
    _assertWorkspace(ticket.id, ticket.workspaceId, workspaceId);
    if (!force) {
      if (ticket.isTerminal) {
        return;
      }
      if (!ticket.status.canTransitionTo(target)) {
        AppLog.w(
          'TicketWorkflowService',
          'Illegal transition ${ticket.status} -> $target for $ticketId',
        );
        return;
      }
    }
    switch (target) {
      case TicketStatus.done:
        await completeTicket(ticketId, workspaceId: workspaceId, force: force);
      case TicketStatus.failed:
        await failTicket(
          ticketId,
          ticket.errorMessage ?? 'Failed',
          workspaceId: workspaceId,
          force: force,
        );
      case TicketStatus.cancelled:
        await cancelTicket(ticketId, workspaceId: workspaceId, force: force);
      case TicketStatus.inProgress:
      case TicketStatus.backlog:
      case TicketStatus.open:
      case TicketStatus.blocked:
      case TicketStatus.inReview:
        await _setStatus(ticketId, target, workspaceId: workspaceId, force: force);
    }
  }

  /// Assigns a ticket to an agent and/or team.
  Future<void> assign(
    String ticketId, {
    required String workspaceId,
    String? agentId,
    String? teamId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) => ticket.copyWith(
        version: ticket.version + 1,
        assignedAgentId: agentId,
        assignedTeamId: teamId,
        updatedAt: DateTime.now(),
      ),
      onApplied: (before, after) => _publishAssigned(after),
    );
  }

  /// Reassigns a ticket from its current agent to [toAgentId].
  Future<void> reassign(
    String ticketId, {
    required String workspaceId,
    String? toAgentId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) => ticket.copyWith(
        version: ticket.version + 1,
        assignedAgentId: toAgentId,
        updatedAt: DateTime.now(),
      ),
      onApplied: (before, after) {
        eventBus.publish(TicketReassigned(
          ticketId: ticketId,
          fromAgentId: before.assignedAgentId,
          toAgentId: toAgentId,
          occurredAt: after.updatedAt,
        ));
        if (toAgentId != null) {
          _publishAssigned(after);
        }
      },
    );
  }

  /// Updates a ticket's editable fields (title / description / priority).
  Future<void> updateDetails(
    String ticketId, {
    required String workspaceId,
    String? title,
    String? description,
    TicketPriority? priority,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) => ticket.copyWith(
        version: ticket.version + 1,
        title: title,
        description: description,
        priority: priority,
        updatedAt: DateTime.now(),
      ),
      onApplied: (before, after) => eventBus.publish(
        TicketDetailsUpdated(ticketId: ticketId, occurredAt: after.updatedAt),
      ),
    );
  }

  /// Sets a ticket's parent (the "sub-issue of" relation), guarding against
  /// self-parenting and cycles. The parent must exist and live in the same
  /// workspace; otherwise a [WorkspaceMismatchException] / [ArgumentError] is
  /// thrown. No-op when the parent is already set to [parentTicketId].
  Future<void> setParent(
    String ticketId,
    String parentTicketId, {
    required String workspaceId,
  }) async {
    if (ticketId == parentTicketId) {
      throw ArgumentError('A ticket cannot be its own parent');
    }
    final parent = await repository.getById(parentTicketId);
    if (parent == null) {
      throw ArgumentError('Parent ticket $parentTicketId does not exist');
    }
    if (parent.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Ticket $parentTicketId belongs to a different workspace.',
      );
    }
    // Cycle guard: walking up from the proposed parent must never reach the
    // ticket itself. `seen` also bounds the walk if the tree already has a cycle.
    String? cursor = parentTicketId;
    final seen = <String>{};
    while (cursor != null && seen.add(cursor)) {
      if (cursor == ticketId) {
        throw ArgumentError('Setting this parent would create a cycle');
      }
      cursor = (await repository.getById(cursor))?.parentTicketId;
    }
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.parentTicketId == parentTicketId) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          parentTicketId: parentTicketId,
          updatedAt: DateTime.now(),
        );
      },
      onApplied: (before, after) => eventBus.publish(
        TicketDetailsUpdated(ticketId: ticketId, occurredAt: after.updatedAt),
      ),
    );
  }

  /// Clears a ticket's parent (removes the "sub-issue of" relation).
  Future<void> clearParent(
    String ticketId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.parentTicketId == null) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          removeParentTicketId: true,
          updatedAt: DateTime.now(),
        );
      },
      onApplied: (before, after) => eventBus.publish(
        TicketDetailsUpdated(ticketId: ticketId, occurredAt: after.updatedAt),
      ),
    );
  }

  /// Assigns the ticket to [projectId] (or clears it when null). The ticket's
  /// own workspace is asserted by the mutation; callers are responsible for
  /// ensuring [projectId] names a project in the same workspace (the UI only
  /// offers same-workspace projects; MCP tools validate ownership explicitly).
  Future<void> setProject(
    String ticketId,
    String? projectId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.projectId == projectId) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          projectId: projectId,
          removeProjectId: projectId == null,
          updatedAt: DateTime.now(),
        );
      },
      onApplied: (before, after) => eventBus.publish(
        TicketDetailsUpdated(ticketId: ticketId, occurredAt: after.updatedAt),
      ),
    );
  }

  /// Links a ticket to a pull request (by PR node id).
  Future<void> linkPullRequest(
    String ticketId,
    String prNodeId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.linkedPrIds.contains(prNodeId)) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          linkedPrIds: [...ticket.linkedPrIds, prNodeId],
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  /// Unlinks a pull request from a ticket (by PR node id). Idempotent: a no-op
  /// when the PR is not currently linked.
  Future<void> unlinkPullRequest(
    String ticketId,
    String prNodeId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!ticket.linkedPrIds.contains(prNodeId)) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          linkedPrIds:
              ticket.linkedPrIds.where((id) => id != prNodeId).toList(),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  /// Adds a collaborator to a ticket.
  Future<void> addCollaborator(
    String ticketId, {
    required String workspaceId,
    required String agentId,
    TicketCollaboratorRole role = TicketCollaboratorRole.collaborator,
  }) async {
    final ticket = await repository.getById(ticketId);
    if (ticket == null) {
      return;
    }
    _assertWorkspace(ticket.id, ticket.workspaceId, workspaceId);
    final now = DateTime.now();
    await repository.addCollaborator(TicketCollaborator(
      id: _uuid.v4(),
      ticketId: ticketId,
      agentId: agentId,
      role: role,
      joinedAt: now,
    ));
    eventBus.publish(TicketCollaboratorAdded(
      ticketId: ticketId,
      agentId: agentId,
      role: role.toStorageString(),
      occurredAt: now,
    ));
  }

  /// Permanently deletes a ticket. Its collaborators and any child tickets are
  /// removed via `ON DELETE CASCADE`. Local removal only — a vendor-backed
  /// ticket is not deleted on the remote tracker (no provider supports it), so
  /// it may reappear on the next sync.
  ///
  /// Enforces workspace isolation: a ticket belonging to another workspace is
  /// rejected with a [WorkspaceMismatchException]. A no-op when the ticket is
  /// already gone.
  Future<void> deleteTicket(
    String ticketId, {
    required String workspaceId,
  }) async {
    final ticket = await repository.getById(ticketId);
    if (ticket == null) {
      return;
    }
    _assertWorkspace(ticket.id, ticket.workspaceId, workspaceId);
    await repository.delete(ticketId, workspaceId: workspaceId);
  }

  Future<void> _setStatus(
    String ticketId,
    TicketStatus status, {
    required String workspaceId,
    bool force = false,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!force && ticket.isTerminal) {
          return null;
        }
        final now = DateTime.now();
        // `_setStatus` only ever targets non-terminal states, so clearing
        // `finishedAt` keeps a force-reopened terminal ticket consistent (it is
        // already null on the normal, non-terminal-source path).
        return ticket.copyWith(
          version: ticket.version + 1,
          status: status,
          startedAt: status == TicketStatus.inProgress ? now : null,
          removeFinishedAt: true,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(TicketStatusChanged(
          ticketId: ticketId,
          from: before.status.toStorageString(),
          to: status.toStorageString(),
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ));
        if (status == TicketStatus.inProgress) {
          eventBus.publish(
            TicketStarted(ticketId: ticketId, occurredAt: after.updatedAt),
          );
        }
      },
    );
  }

  void _publishAssigned(Ticket ticket) {
    eventBus.publish(TicketAssigned(
      ticketId: ticket.id,
      ticketTitle: ticket.title,
      ticketBody: ticket.description,
      ticketUrl: ticket.url,
      assignedAgentId: ticket.assignedAgentId,
      assignedTeamId: ticket.assignedTeamId,
      workspaceId: ticket.workspaceId,
      occurredAt: DateTime.now(),
    ));
  }

  /// Enforces workspace isolation: every by-id mutation carries the caller's
  /// [expectedWorkspaceId], and the loaded ticket's [ticketWorkspaceId] must
  /// match. A mismatch is a cross-workspace access attempt — rejected loudly
  /// with a [WorkspaceMismatchException] (explicit denial, never a silent
  /// no-op) so the breach surfaces instead of leaking another workspace's data.
  void _assertWorkspace(
    String ticketId,
    String ticketWorkspaceId,
    String expectedWorkspaceId,
  ) {
    if (ticketWorkspaceId != expectedWorkspaceId) {
      throw WorkspaceMismatchException(
        'Ticket $ticketId belongs to a different workspace.',
      );
    }
  }

  /// Reads the ticket, applies [mutate] to compute the next state, writes it
  /// with the correct optimistic-lock contract (`expectedVersion` = the version
  /// just read), and runs [onApplied] only on a successful write. Retries on
  /// `ConcurrencyConflictException` by re-reading fresh state; a [mutate] that
  /// returns `null` is a no-op (e.g. the ticket is missing or already terminal).
  ///
  /// Returns `true` when the write landed, `false` when skipped.
  Future<bool> _mutate(
    String ticketId, {
    required String workspaceId,
    required Ticket? Function(Ticket current) mutate,
    void Function(Ticket before, Ticket after)? onApplied,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final current = await repository.getById(ticketId);
      if (current == null) {
        return false;
      }
      _assertWorkspace(current.id, current.workspaceId, workspaceId);
      final next = mutate(current);
      if (next == null) {
        return false;
      }
      try {
        await repository.update(next, expectedVersion: current.version);
        onApplied?.call(current, next);
        return true;
      } on ConcurrencyConflictException catch (e) {
        if (attempt >= _maxWriteAttempts - 1) {
          AppLog.w(
            'TicketWorkflowService',
            'Giving up on $ticketId after $_maxWriteAttempts attempts: ${e.message}',
          );
          rethrow;
        }
        // Back off briefly, then re-read fresh state and re-evaluate the guard:
        // a concurrent writer may have reached a terminal state, in which case
        // the next `mutate` returns null and this becomes a no-op success.
        await Future<void>.delayed(Duration(milliseconds: 5 * (attempt + 1)));
      }
    }
  }
}
