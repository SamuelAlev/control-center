import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:uuid/uuid.dart';

/// Resolves an agent's EFFECTIVE autonomy level in a space (the per-(space,
/// agent) dial with the server default applied). Injected as a port so the
/// pure ticket domain can enforce the delegation autonomy ceiling without
/// depending on the space-autonomy store.
typedef EffectiveAutonomyResolver =
    Future<AutonomyLevel> Function({
      required String workspaceId,
      required String agentId,
      String? spaceId,
    });

/// Resolves an agent's remaining budget envelope in cents. Null = the agent
/// has no hard-stop budget policy (unlimited). Injected as a port so the pure
/// ticket domain can enforce the budget-envelope guard without depending on
/// the budget store.
typedef RemainingBudgetResolver =
    Future<int?> Function({required String workspaceId, required String agentId});

/// Creates and drives **dumb** tickets through their lifecycle — pure
/// issue-tracking metadata. Assignment records ownership but dispatches
/// nothing: agent work lives in conversations (a hidden one when a pipeline
/// spawns it) and the structured-output contract lives on the `AgentRunLog`.
///
/// Pure domain: depends only on [TicketRepository] and the [DomainEventBus].
/// All ticket writes go through [_mutate], which carries the correct optimistic
/// concurrency contract — `expectedVersion` is the version read *before* the
/// mutation and the row is written with `version + 1` — and retries a bounded
/// number of times when a concurrent writer wins the race.
class TicketWorkflowService {
  /// Creates a [TicketWorkflowService].
  TicketWorkflowService({
    required this.repository,
    required this.eventBus,
    this.onWarn,
    DelegationGuards guards = const DelegationGuards(),
    this.resolveEffectiveAutonomy,
    this.resolveRemainingBudgetCents,
  }) : _guards = guards;

  /// Local persistence (mirror + overlay).
  final TicketRepository repository;

  /// Domain event bus.
  final DomainEventBus eventBus;

  /// Optional warning sink, injected so this domain service stays Flutter-free
  /// (the desktop wires it to `AppLog`; the headless server to stdout / no-op).
  final void Function(String message)? onWarn;

  /// The deterministic delegation guards (depth / cycle / autonomy / budget)
  /// enforced at the delegation chokepoint ([delegateGuarded]).
  final DelegationGuards _guards;

  /// Port for the autonomy-ceiling guard. Null (bare tests) skips that guard;
  /// production wiring always supplies it.
  final EffectiveAutonomyResolver? resolveEffectiveAutonomy;

  /// Port for the budget-envelope guard. Null (bare tests) skips that guard;
  /// production wiring always supplies it.
  final RemainingBudgetResolver? resolveRemainingBudgetCents;

  static const _uuid = Uuid();

  /// How many times a version-checked write is retried before giving up.
  static const _maxWriteAttempts = 4;

  /// Creates a ticket and publishes [TicketCreated] (+ [TicketAssigned] when
  /// it has an assignee).
  ///
  /// [TicketAssigned] is now a pure audit signal — nothing dispatches on it.
  /// Assignment records ownership only; agent work lives in conversations.
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
    PrincipalType assigneeType = PrincipalType.agent,
    String? createdByType,
    String? createdById,
    String? assignedTeamId,
    String? delegatedByAgentId,
    int delegationDepth = 0,
    String? delegationRootTicketId,
    String? parentTicketId,
    String? projectId,
    String? spaceId,
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
      assigneeType: assigneeType,
      createdByType: PrincipalType.fromWire(createdByType),
      createdById: createdById,
      assignedTeamId: assignedTeamId,
      delegatedByAgentId: delegatedByAgentId,
      delegationDepth: delegationDepth,
      delegationRootTicketId: delegationRootTicketId,
      spaceId: spaceId,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insert(ticket);

    eventBus.publish(
      TicketCreated(
        ticketId: ticket.id,
        workspaceId: workspaceId,
        occurredAt: now,
      ),
    );
    if (parentTicketId != null) {}
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
    String? spaceId,
  }) {
    return createTicket(
      workspaceId: workspaceId,
      title: title,
      description: description,
      parentTicketId: parentTicketId,
      delegatedByAgentId: delegatedByAgentId,
      assignedAgentId: assignedAgentId,
      spaceId: spaceId,
    );
  }

  /// Delegates a task to [assignedAgentId], enforcing the deterministic
  /// delegation guards at this single chokepoint (PRD 22 §3) before any child
  /// ticket is created.
  ///
  /// Computes the child's [Ticket.delegationDepth] and
  /// [Ticket.delegationRootTicketId] from the parent (a root delegation is
  /// depth 1), walks the parent chain to build the ordered set of agents
  /// already in the delegation chain, then runs ALL FOUR guards:
  /// [DelegationGuards.checkDepth], [DelegationGuards.checkCycle],
  /// [DelegationGuards.checkAutonomyCeiling] (via the injected
  /// [resolveEffectiveAutonomy] port) and
  /// [DelegationGuards.checkBudgetEnvelope] (via
  /// [resolveRemainingBudgetCents]). On any refusal it throws a
  /// [DelegationRefusedException] carrying the guard's reason verbatim (loud
  /// denial, never a silent no-op). On allow it creates the child through the
  /// ordinary [createTicket] path.
  Future<Ticket> delegateGuarded({
    required String workspaceId,
    required String title,
    required String assignedAgentId,
    String? parentTicketId,
    String? delegatedByAgentId,
    String? description,
    String? spaceId,
  }) async {
    Ticket? parent;
    if (parentTicketId != null) {
      parent = await repository.getById(workspaceId, parentTicketId);
      if (parent == null) {
        throw DelegationRefusedException(
          'Delegation refused: parent ticket $parentTicketId does not exist.',
        );
      }
      _assertWorkspace(parent.id, parent.workspaceId, workspaceId);
    }

    final childDepth = parent == null ? 1 : parent.delegationDepth + 1;
    final rootTicketId = parent?.delegationRootTicketId ?? parent?.id;
    final chainAgentIds = await _delegationChainAgentIds(parent);

    // Structural, deterministic guards. Depth uses the delegator's own chain
    // depth (the new delegate would be at `parentDepth + 1`); cycle checks the
    // combined ask+delegate chain (delegator last) against the new delegate.
    final depth = _guards.checkDepth(parent?.delegationDepth ?? 0);
    if (!depth.allowed) {
      throw DelegationRefusedException(depth.refusal!);
    }
    final cycle = _guards.checkCycle(chainAgentIds, assignedAgentId);
    if (!cycle.allowed) {
      throw DelegationRefusedException(cycle.refusal!);
    }
    // Autonomy ceiling: the delegate's EFFECTIVE level in the space must not
    // exceed the delegator's — privilege cannot be laundered through
    // delegation (an actWithApproval agent must not fan work out to an
    // actFreely one and collect unprompted effects by proxy). Both levels
    // resolve through the injected port so this stays pure domain.
    final autonomyResolver = resolveEffectiveAutonomy;
    if (autonomyResolver != null && delegatedByAgentId != null) {
      final delegatorLevel = await autonomyResolver(
        workspaceId: workspaceId,
        agentId: delegatedByAgentId,
        spaceId: spaceId,
      );
      final delegateLevel = await autonomyResolver(
        workspaceId: workspaceId,
        agentId: assignedAgentId,
        spaceId: spaceId,
      );
      final ceiling = _guards.checkAutonomyCeiling(
        delegatorLevel,
        delegateLevel,
      );
      if (!ceiling.allowed) {
        throw DelegationRefusedException(ceiling.refusal!);
      }
    }
    // Budget envelope: delegation bills the DELEGATOR's remaining budget and
    // cannot mint more. Null = no hard-stop policy (uncapped), which passes.
    final budgetResolver = resolveRemainingBudgetCents;
    if (budgetResolver != null && delegatedByAgentId != null) {
      final remaining = await budgetResolver(
        workspaceId: workspaceId,
        agentId: delegatedByAgentId,
      );
      if (remaining != null) {
        final envelope = _guards.checkBudgetEnvelope(remaining);
        if (!envelope.allowed) {
          throw DelegationRefusedException(envelope.refusal!);
        }
      }
    }

    return createTicket(
      workspaceId: workspaceId,
      title: title,
      description: description,
      assignedAgentId: assignedAgentId,
      delegatedByAgentId: delegatedByAgentId,
      parentTicketId: parentTicketId,
      spaceId: spaceId,
      delegationDepth: childDepth,
      delegationRootTicketId: rootTicketId,
    );
  }

  /// Walks the parent chain from [parent] up to the delegation root, collecting
  /// the assignee agent id of each ticket. Returns the chain root-first with the
  /// delegator ([parent]'s assignee) last — the order [DelegationGuards.checkCycle]
  /// expects. Bounded by a `seen` set so a pre-existing cycle can't loop forever.
  Future<List<String>> _delegationChainAgentIds(Ticket? parent) async {
    if (parent == null) {
      return const [];
    }
    final chain = <String>[];
    // The whole chain lives in one workspace: a ticket's parent can never be
    // owned by another workspace (see setParent / delegateGuarded).
    final workspaceId = parent.workspaceId;
    Ticket? cursor = parent;
    final seen = <String>{};
    while (cursor != null && seen.add(cursor.id)) {
      final assignee = cursor.assignedAgentId;
      if (assignee != null) {
        chain.add(assignee);
      }
      final parentId = cursor.parentTicketId;
      cursor = parentId == null
          ? null
          : await repository.getById(workspaceId, parentId);
    }
    return chain.reversed.toList();
  }

  /// Marks a ticket in-progress (no-op if terminal/missing/already started).
  Future<void> startTicket(
    String ticketId, {
    required String workspaceId,
  }) async {
    await tryStart(ticketId, workspaceId: workspaceId);
  }

  /// Transitions an `open`/`backlog` ticket to `in_progress`.
  ///
  /// Returns `true` only when *this* call performed the transition, so the
  /// caller (the `TicketDispatcher`) can treat it as the single-dispatch guard:
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
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: TicketStatus.inProgress.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
      },
    );
  }

  /// Atomically checks out a ticket to [agentId] for exclusive work.
  ///
  /// Single-assignee lock: a checkout succeeds only when the ticket is not
  /// terminal and is not owned by a *different* agent. On success the ticket is
  /// assigned to [agentId] and transitioned to `inProgress`. The optimistic-lock
  /// chokepoint guarantees that of two agents racing for the same ticket exactly
  /// one wins; the loser sees fresh state on re-read and is rejected with a
  /// [CheckoutConflictException].
  ///
  /// Returns true when [agentId] now holds the ticket (including an idempotent
  /// re-checkout by the same agent). Returns false when the ticket is missing or
  /// already terminal. Throws [CheckoutConflictException] when a different agent
  /// holds it.
  Future<bool> tryCheckout(
    String ticketId, {
    required String workspaceId,
    required String agentId,
  }) {
    return _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.isTerminal) {
          return null;
        }
        final holder = ticket.assignedAgentId;
        if (holder != null && holder != agentId) {
          throw CheckoutConflictException(
            'Ticket $ticketId is already checked out by agent $holder.',
            holderAgentId: holder,
          );
        }
        final now = DateTime.now();
        // Idempotent re-checkout by the same in-progress holder: just touch.
        if (ticket.status == TicketStatus.inProgress && holder == agentId) {
          return ticket.copyWith(version: ticket.version + 1, updatedAt: now);
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          assignedAgentId: agentId,
          status: TicketStatus.inProgress,
          startedAt: ticket.startedAt ?? now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        if (before.assignedAgentId != after.assignedAgentId) {
          _publishAssigned(after);
        }
        if (before.status != after.status) {
          eventBus.publish(
            TicketStatusChanged(
              ticketId: ticketId,
              from: before.status.toStorageString(),
              to: after.status.toStorageString(),
              workspaceId: workspaceId,
              occurredAt: after.updatedAt,
            ),
          );
        }
      },
    );
  }

  /// Releases a checkout, returning the ticket to `open` so another agent can
  /// claim it. Only the current holder ([agentId]) may release; a mismatch is a
  /// no-op. Used when an agent abandons work without completing it.
  Future<bool> releaseCheckout(
    String ticketId, {
    required String workspaceId,
    required String agentId,
  }) {
    return _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.status != TicketStatus.inProgress ||
            ticket.assignedAgentId != agentId) {
          return null;
        }
        final now = DateTime.now();
        return ticket.copyWith(
          version: ticket.version + 1,
          status: TicketStatus.open,
          removeAssignedAgentId: true,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: after.status.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
      },
    );
  }

  /// Completes a ticket (terminal success) — a plain status transition. The
  /// structured-output contract no longer lives on tickets (it moved to the
  /// agent run's `submit_output` path), so this only flips the status.
  ///
  /// [force] bypasses the already-terminal guard so a manual override can move
  /// a ticket straight from one terminal state to another.
  Future<void> completeTicket(
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
          status: TicketStatus.done,
          completedAt: now,
          finishedAt: now,
          updatedAt: now,
        );
      },
      onApplied: (before, after) {
        eventBus.publish(
          TicketCompleted(ticketId: ticketId, occurredAt: after.updatedAt),
        );
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: TicketStatus.done.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
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
        eventBus.publish(
          TicketFailed(
            ticketId: ticketId,
            errorMessage: errorMessage,
            occurredAt: after.updatedAt,
          ),
        );
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: TicketStatus.failed.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
      },
    );
  }

  /// Cancels a ticket (terminal).
  ///
  /// [force] bypasses the already-terminal guard (see [completeTicket]).
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
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: TicketStatus.cancelled.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
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
    final ticket = await repository.getById(workspaceId, ticketId);
    if (ticket == null) {
      return;
    }
    _assertWorkspace(ticket.id, ticket.workspaceId, workspaceId);
    if (!force) {
      if (ticket.isTerminal) {
        return;
      }
      if (!ticket.status.canTransitionTo(target)) {
        onWarn?.call(
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
        await _setStatus(
          ticketId,
          target,
          workspaceId: workspaceId,
          force: force,
        );
    }
  }

  /// Assigns a ticket to an agent and/or team.
  Future<void> assign(
    String ticketId, {
    required String workspaceId,
    String? assigneeId,
    PrincipalType assigneeType = PrincipalType.agent,
    String? teamId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) => ticket.copyWith(
        version: ticket.version + 1,
        assignedAgentId: assigneeId,
        assigneeType: assigneeType,
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
        eventBus.publish(
          TicketReassigned(
            ticketId: ticketId,
            workspaceId: workspaceId,
            fromAgentId: before.assignedAgentId,
            toAgentId: toAgentId,
            occurredAt: after.updatedAt,
          ),
        );
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
        TicketDetailsUpdated(
          ticketId: ticketId,
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ),
      ),
    );
  }

  /// Replaces a ticket's label set. No-op when [labels] already match (order
  /// independent). Emits [TicketDetailsUpdated] so the change syncs to vendors.
  Future<void> setLabels(
    String ticketId,
    List<String> labels, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        final next = {...labels}.toList();
        final current = {...ticket.labels};
        if (current.length == next.length && current.containsAll(next)) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          labels: next,
          updatedAt: DateTime.now(),
        );
      },
      onApplied: (before, after) => eventBus.publish(
        TicketDetailsUpdated(
          ticketId: ticketId,
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ),
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
    final parent = await repository.getById(workspaceId, parentTicketId);
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
      cursor = (await repository.getById(workspaceId, cursor))?.parentTicketId;
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
        TicketDetailsUpdated(
          ticketId: ticketId,
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ),
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
        TicketDetailsUpdated(
          ticketId: ticketId,
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ),
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
        TicketDetailsUpdated(
          ticketId: ticketId,
          workspaceId: workspaceId,
          occurredAt: after.updatedAt,
        ),
      ),
    );
  }

  /// Links a ticket to a pull request (by PR node id).
  Future<void> linkPullRequest(
    String ticketId,
    String prExternalId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (ticket.linkedPrIds.contains(prExternalId)) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          linkedPrIds: [...ticket.linkedPrIds, prExternalId],
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  /// Unlinks a pull request from a ticket (by PR node id). Idempotent: a no-op
  /// when the PR is not currently linked.
  Future<void> unlinkPullRequest(
    String ticketId,
    String prExternalId, {
    required String workspaceId,
  }) async {
    await _mutate(
      ticketId,
      workspaceId: workspaceId,
      mutate: (ticket) {
        if (!ticket.linkedPrIds.contains(prExternalId)) {
          return null;
        }
        return ticket.copyWith(
          version: ticket.version + 1,
          linkedPrIds: ticket.linkedPrIds
              .where((id) => id != prExternalId)
              .toList(),
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  /// Adds a collaborator (agent by default, or a human user) to a ticket.
  Future<void> addCollaborator(
    String ticketId, {
    required String workspaceId,
    required String principalId,
    PrincipalType collaboratorType = PrincipalType.agent,
    TicketCollaboratorRole role = TicketCollaboratorRole.collaborator,
  }) async {
    final ticket = await repository.getById(workspaceId, ticketId);
    if (ticket == null) {
      return;
    }
    _assertWorkspace(ticket.id, ticket.workspaceId, workspaceId);
    final now = DateTime.now();
    await repository.addCollaborator(
      workspaceId,
      TicketCollaborator(
        id: _uuid.v4(),
        ticketId: ticketId,
        principalId: principalId,
        collaboratorType: collaboratorType,
        role: role,
        joinedAt: now,
      ),
    );
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
    final ticket = await repository.getById(workspaceId, ticketId);
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
        eventBus.publish(
          TicketStatusChanged(
            ticketId: ticketId,
            from: before.status.toStorageString(),
            to: status.toStorageString(),
            workspaceId: workspaceId,
            occurredAt: after.updatedAt,
          ),
        );
        if (status == TicketStatus.inProgress) {}
      },
    );
  }

  void _publishAssigned(Ticket ticket) {
    eventBus.publish(
      TicketAssigned(
        ticketId: ticket.id,
        ticketTitle: ticket.title,
        ticketBody: ticket.description,
        ticketUrl: ticket.url,
        assignedAgentId: ticket.assignedAgentId,
        assigneeType: ticket.assigneeType.wireName,
        assignedTeamId: ticket.assignedTeamId,
        workspaceId: ticket.workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  /// Enforces workspace isolation: every by-id mutation carries the caller's
  /// [expectedWorkspaceId] and the loaded ticket's [ticketWorkspaceId] must
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
  /// just read) and runs [onApplied] only on a successful write. Retries on
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
      final current = await repository.getById(workspaceId, ticketId);
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
          onWarn?.call(
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
