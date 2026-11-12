import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';

/// Which agent→agent hand-off a [PeerDelegationGate] check is for.
///
/// The guards are the same for both; only how the chain is anchored differs,
/// because a ticket hand-off records its depth on the child row and an ask
/// does not.
enum PeerHandOff {
  /// `ask_agent`: a blocking request/reply. A `parentTicketId` must be the
  /// asker's own (assigned to it), and the depth counts the in-flight asks
  /// above the asker on top of the parent's ticket depth.
  ask,

  /// `delegate_task` / `delegate_ticket`: a tracked child ticket. The parent
  /// only has to exist in this workspace (an orchestrator may split work it
  /// is not itself assigned), and the depth is the parent's ticket depth,
  /// which is exactly what the child row records.
  ticket,
}

/// The delegation guards an agent→agent hand-off must pass, run in one place
/// and BEFORE any side effect.
///
/// `ask_agent` used to mint the DM space and spend the pair's rate-limit slot
/// first and only then evaluate its guards, so a refused ask still left a new
/// space behind and counted against the pair; `delegate_task` and
/// `delegate_ticket` ran a second copy inside the ticket workflow with looser
/// rules (an unconfigured policy passed). Every hand-off now asks this gate
/// first and touches nothing when it refuses.
///
/// Semantics (one set, anchored per [PeerHandOff]):
/// - A `parentTicketId`, when given, must exist in the workspace (and for
///   [PeerHandOff.ask] be assigned to the caller); its assignee chain joins
///   the in-flight `ask_agent` hops, delegator last.
/// - Depth, cycle, autonomy ceiling and budget envelope run through
///   [DelegationGuards.evaluate]. A null budget means no hard stop (passes).
/// - Missing autonomy/budget policy refuses: production always wires both,
///   and an unconfigured guard must not read as "allowed".
/// - Finally the in-flight hop graph is checked for a cycle, which also
///   catches loops no ticket records.
class PeerDelegationGate {
  /// Creates a gate over the ticket workflow's policy ports and the shared
  /// in-flight hop registry.
  const PeerDelegationGate({
    required this._service,
    required this._pendingHops,
  });

  final TicketWorkflowService _service;
  final PendingDelegationHops _pendingHops;

  /// The refusal for [fromAgentId] handing work to [recipientId], or null
  /// when every guard passes. [spaceId] is the space the autonomy levels are
  /// resolved in (the pair's existing DM for an ask, the ticket's space for a
  /// delegation).
  Future<String?> refusal({
    required String workspaceId,
    required String fromAgentId,
    required String recipientId,
    PeerHandOff handOff = PeerHandOff.ask,
    String? parentTicketId,
    String? spaceId,
  }) async {
    final ticketChain = <String>[];
    var ticketDepth = 0;
    if (parentTicketId != null) {
      var ticket = await _service.repository.getById(
        workspaceId,
        parentTicketId,
      );
      if (ticket == null || ticket.workspaceId != workspaceId) {
        return TicketWorkflowService.missingParentRefusal(parentTicketId);
      }
      if (handOff == PeerHandOff.ask && ticket.assignedAgentId != fromAgentId) {
        return 'Parent ticket is not assigned to the asker.';
      }
      ticketDepth = ticket.delegationDepth;
      final seen = <String>{};
      while (ticket != null && seen.add(ticket.id)) {
        if (ticket.assignedAgentId != null) {
          ticketChain.insert(0, ticket.assignedAgentId!);
        }
        final parent = ticket.parentTicketId;
        ticket = parent == null
            ? null
            : await _service.repository.getById(workspaceId, parent);
      }
    }
    final autonomyResolver = _service.resolveEffectiveAutonomy;
    final budgetResolver = _service.resolveRemainingBudgetMicros;
    if (autonomyResolver == null || budgetResolver == null) {
      return 'Delegation guard policy is not configured.';
    }
    final delegatorAutonomy = await autonomyResolver(
      workspaceId: workspaceId,
      agentId: fromAgentId,
      spaceId: spaceId,
    );
    final requestedAutonomy = await autonomyResolver(
      workspaceId: workspaceId,
      agentId: recipientId,
      spaceId: spaceId,
    );
    final budget = await budgetResolver(
      workspaceId: workspaceId,
      agentId: fromAgentId,
    );
    final pendingChain = _pendingHops.chain(workspaceId, fromAgentId);
    final chain = [
      ...ticketChain,
      ...pendingChain.where((id) => !ticketChain.contains(id)),
    ];
    if (chain.isEmpty || chain.last != fromAgentId) {
      chain.add(fromAgentId);
    }
    final guard = const DelegationGuards().evaluate(
      chainAgentIds: chain,
      chainDepth: switch (handOff) {
        PeerHandOff.ask => ticketDepth + pendingChain.length - 1,
        PeerHandOff.ticket => ticketDepth,
      },
      targetAgentId: recipientId,
      delegatorAutonomy: delegatorAutonomy,
      requestedAutonomy: requestedAutonomy,
      // Null is explicitly unlimited in the workflow port.
      remainingBudgetMicros: budget ?? 1,
    );
    if (!guard.allowed) {
      return guard.refusal;
    }
    return cycleRefusal(
      workspaceId: workspaceId,
      fromAgentId: fromAgentId,
      recipientId: recipientId,
    );
  }

  /// The in-flight hop cycle check alone — for `send_to_agent`, which starts
  /// no delegation of its own but must not wake an agent that is, through a
  /// chain of pending asks, already waiting on the sender.
  String? cycleRefusal({
    required String workspaceId,
    required String fromAgentId,
    required String recipientId,
  }) => cycleRefusalIn(
    _pendingHops,
    workspaceId: workspaceId,
    fromAgentId: fromAgentId,
    recipientId: recipientId,
  );

  /// [cycleRefusal] over a bare hop registry (no policy ports needed).
  static String? cycleRefusalIn(
    PendingDelegationHops hops, {
    required String workspaceId,
    required String fromAgentId,
    required String recipientId,
  }) {
    if (!hops.wouldCycle(workspaceId, fromAgentId, recipientId)) {
      return null;
    }
    final chain = hops.chain(workspaceId, fromAgentId);
    return 'Delegation refused: cycle detected '
        '(${[...chain, recipientId].join(' → ')}).';
  }
}
