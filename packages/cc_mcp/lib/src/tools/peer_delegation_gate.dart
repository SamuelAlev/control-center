import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart'
    show PeerAskLimits, PeerAskRefusals;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart' show PeerAskRefusal, PeerChain;

/// Which agent→agent hand-off a [PeerDelegationGate] check is for.
///
/// The guards are the same for both; only how the chain is anchored differs,
/// because a ticket hand-off records its depth on the child row and an ask
/// does not.
enum PeerHandOff {
  /// `ask_agent` and the other peer messages: a `parentTicketId` must be the
  /// asker's own (assigned to it), and the depth counts the agents above the
  /// asker on top of the parent's ticket depth.
  ask,

  /// `delegate_task` / `delegate_ticket`: a tracked child ticket. The parent
  /// only has to exist in this workspace (an orchestrator may split work it
  /// is not itself assigned), and the depth is the parent's ticket depth,
  /// which is exactly what the child row records.
  ticket,
}

/// Kinds of the gate's refusals besides depth and cycle
/// (`PeerAskRefusals.depth`, `PeerAskRefusals.cycle`).
abstract final class PeerGateRefusals {
  /// The parent ticket is missing or not the asker's.
  static const String parentTicket = 'delegation_parent_ticket';

  /// The delegate would act with more autonomy than the delegator.
  static const String autonomy = 'delegation_autonomy';

  /// The delegator's budget envelope is exhausted.
  static const String budget = 'delegation_budget';

  /// The policy ports are not wired.
  static const String unconfigured = 'delegation_unconfigured';

  /// The ordered pair's rate window is full.
  static const String rateLimited = 'peer_rate_limited';
}

/// A refusal as a tool result: the text, and `data.kind` for clients.
CallResult peerRefusalResult(PeerAskRefusal refusal) => CallResult(
  content: [CallResultContent(type: 'text', text: refusal.message)],
  isError: true,
  structured: {'kind': refusal.kind, 'ask_id': ?refusal.askId},
);

/// The delegation guards an agent→agent hand-off must pass, run in one place
/// and BEFORE any side effect.
///
/// Semantics (one set, anchored per [PeerHandOff]):
/// - A `parentTicketId`, when given, must exist in the workspace (and for
///   [PeerHandOff.ask] be assigned to the caller); its assignee chain joins
///   the caller's [PeerChain], delegator last.
/// - Depth and cycle read rows (plan section 10, "Guards read rows"): the
///   caller's [PeerChain] holds the chains of the wakes its run took and of
///   the pending asks it answers, and every agent that waits on it through a
///   pending ask. A hand-off to any of them closes a loop.
/// - Autonomy ceiling and budget envelope run through [DelegationGuards]. A
///   null budget means no hard stop (passes). Missing policy ports refuse:
///   production always wires both, and an unconfigured guard must not read
///   as "allowed".
class PeerDelegationGate {
  /// Creates a gate over the ticket workflow's policy ports.
  const PeerDelegationGate({required this._service});

  final TicketWorkflowService _service;

  /// The refusal for [fromAgentId] handing work to [recipientId], or null
  /// when every guard passes. [chain] is [fromAgentId]'s
  /// (`PeerAskService.chainOf`). [spaceId] is the space the autonomy levels
  /// are resolved in.
  Future<PeerAskRefusal?> refusal({
    required String workspaceId,
    required String fromAgentId,
    required String recipientId,
    required PeerChain chain,
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
        return PeerAskRefusal(
          PeerGateRefusals.parentTicket,
          TicketWorkflowService.missingParentRefusal(parentTicketId),
        );
      }
      if (handOff == PeerHandOff.ask && ticket.assignedAgentId != fromAgentId) {
        return const PeerAskRefusal(
          PeerGateRefusals.parentTicket,
          'Parent ticket is not assigned to the asker.',
        );
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
    final above = [
      ...ticketChain.where((id) => id != fromAgentId),
      ...chain.lineage.where(
        (id) => id != fromAgentId && !ticketChain.contains(id),
      ),
    ];
    if (above.contains(recipientId) ||
        chain.waiting.contains(recipientId) ||
        recipientId == fromAgentId) {
      return PeerAskRefusal(
        PeerAskRefusals.cycle,
        'Delegation refused: cycle detected '
        '(${[...above, fromAgentId, recipientId].join(' → ')}). That agent '
        'is already waiting on you; answer in your turn instead.',
      );
    }
    final depth = switch (handOff) {
      PeerHandOff.ask => ticketDepth + chain.depth,
      PeerHandOff.ticket => ticketDepth,
    };
    const guards = DelegationGuards(maxDepth: PeerAskLimits.maxDepth);
    final deep = guards.checkDepth(depth);
    if (!deep.allowed) {
      return PeerAskRefusal(PeerAskRefusals.depth, deep.refusal!);
    }
    final autonomyResolver = _service.resolveEffectiveAutonomy;
    final budgetResolver = _service.resolveRemainingBudgetMicros;
    if (autonomyResolver == null || budgetResolver == null) {
      return const PeerAskRefusal(
        PeerGateRefusals.unconfigured,
        'Delegation guard policy is not configured.',
      );
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
    final autonomy = guards.checkAutonomyCeiling(
      delegatorAutonomy,
      requestedAutonomy,
    );
    if (!autonomy.allowed) {
      return PeerAskRefusal(PeerGateRefusals.autonomy, autonomy.refusal!);
    }
    final budget = await budgetResolver(
      workspaceId: workspaceId,
      agentId: fromAgentId,
    );
    // Null is explicitly unlimited in the workflow port.
    final envelope = guards.checkBudgetEnvelope(budget ?? 1);
    if (!envelope.allowed) {
      return PeerAskRefusal(PeerGateRefusals.budget, envelope.refusal!);
    }
    return null;
  }

  /// The cycle check alone — for `send_to_agent`, which starts no
  /// delegation of its own but must not wake an agent that is, through a
  /// pending ask, already waiting on the sender.
  static PeerAskRefusal? cycleRefusal({
    required String fromAgentId,
    required String recipientId,
    required PeerChain chain,
  }) {
    if (!chain.wouldCycle(recipientId)) {
      return null;
    }
    return PeerAskRefusal(
      PeerAskRefusals.cycle,
      'Delegation refused: cycle detected '
      '(${[...chain.lineage, fromAgentId, recipientId].join(' → ')}). That '
      'agent is waiting on your answer; reply in your turn instead of '
      'messaging it.',
    );
  }
}
