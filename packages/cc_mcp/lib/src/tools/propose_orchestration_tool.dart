import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/orchestration_events.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:uuid/uuid.dart';

/// MCP tool the orchestrator calls (once) to emit a structured orchestration
/// plan. The plan is validated deterministically; a violation is returned as
/// the exact list so the agent self-corrects in the same run (the error path
/// is the retry loop). On success the proposal is persisted, the parent ticket
/// moves to `blocked` (waiting on the user), an `orchestration_proposal`
/// message is posted and the user reviews + approves from the UI.
class ProposeOrchestrationTool extends McpTool {
  /// Creates a [ProposeOrchestrationTool].
  ProposeOrchestrationTool({
    required OrchestrationRepository orchestrations,
    required OrchestrationProposalValidator validator,
    required TicketRepository tickets,
    required TicketWorkflowService ticketWorkflow,
    required MessagingRepository messaging,
    required DomainEventBus eventBus,
    OrchestrationRevisionRepository? revisions,
    this.revisionCooldown = const Duration(minutes: 2),
  }) : _orchestrations = orchestrations,
       _validator = validator,
       _tickets = tickets,
       _ticketWorkflow = ticketWorkflow,
       _messaging = messaging,
       _eventBus = eventBus,
       _revisions = revisions;

  final OrchestrationRepository _orchestrations;
  final OrchestrationProposalValidator _validator;
  final TicketRepository _tickets;
  final TicketWorkflowService _ticketWorkflow;
  final MessagingRepository _messaging;
  final DomainEventBus _eventBus;
  final OrchestrationRevisionRepository? _revisions;

  /// Minimum spacing between agent-initiated revisions of one orchestration
  /// (PRD 17 adversarial review: replan storms flood the operator with
  /// diffs). Consecutive replans inside the window are told to coalesce.
  final Duration revisionCooldown;

  static const _uuid = Uuid();

  @override
  String get name => 'propose_orchestration';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Emit a structured multi-agent orchestration plan for one upfront user '
      'approval. Validates the plan and returns any violations to fix. On '
      'success the user reviews and approves; the system then hires agents, '
      'forms the team, creates the project + sub-tickets and runs everything. '
      'Call this exactly once per request (or with orchestration_id to revise).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'ticket_id': {
        'type': 'string',
        'description': 'The anchor ticket this orchestration plans for.',
      },
      'orchestration_id': {
        'type': 'string',
        'description': 'Set to revise an existing proposal.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The orchestrator agent id.',
      },
      'goal': {'type': 'string'},
      'roles': {
        'type': 'array',
        'description':
            'Roles needed. Each: {roleKey, title, existingAgentId? OR '
            'hireSpec:{name,title,skills[],persona,role?}}.',
        'items': {'type': 'object'},
      },
      'sub_tickets': {
        'type': 'array',
        'description':
            'Work DAG. Each: {key, title, roleKey, description, '
            'dependsOn[], expectedOutputSchema, priority, provenance[]}. '
            'provenance cites WHY the node exists — each ref: {kind: '
            'symbol|file|memory|message|goal|answer, ref, label?}. Cite '
            'real evidence (code-graph symbol ids, file paths, memory '
            'fact ids); provenance also powers blast-radius estimates.',
        'items': {'type': 'object'},
      },
      'research': {
        'type': 'object',
        'description': '{enabled, prompt, roleKey?}',
      },
      'discussion': {
        'type': 'object',
        'description': '{enabled, prompt} — a bounded position round.',
      },
      'synthesis': {
        'type': 'object',
        'description':
            '{roleKey, prompt, outputSchema} — outputSchema MUST include a '
            '"gaps" array.',
      },
      'budget': {
        'type': 'object',
        'description': '{estimatedCostCents?, maxCostCents?}',
      },
      'drift_policy': {
        'type': 'string',
        'enum': ['annotate', 'stopAndAsk'],
        'description':
            'How execution responds when a step drifts outside its '
            'declared scope (cost band / blast radius). Default annotate.',
      },
    },
    'required': [
      'workspace_id',
      'ticket_id',
      'goal',
      'roles',
      'sub_tickets',
      'synthesis',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }

    // Workspace-ownership: the anchor ticket must belong to this workspace.
    final ticket = await _tickets.getById(workspaceId, ticketId);
    if (ticket == null) {
      return CallResult.error('Ticket $ticketId not found.');
    }
    if (ticket.workspaceId != workspaceId) {
      return CallResult.error(
        'Ticket $ticketId belongs to a different workspace.',
      );
    }

    final OrchestrationProposal proposal;
    try {
      proposal = OrchestrationProposal.fromJson({
        'goal': arguments['goal'],
        'roles': arguments['roles'],
        'subTickets': arguments['sub_tickets'],
        'research': arguments['research'],
        'discussion': arguments['discussion'],
        'synthesis': arguments['synthesis'],
        'budget': arguments['budget'],
        'driftPolicy': arguments['drift_policy'],
      });
    } on Object catch (e) {
      return CallResult.error('Could not parse the proposal: $e');
    }

    final violations = _validator.validate(proposal);
    if (violations.isNotEmpty) {
      return CallResult.error(
        'The orchestration plan is not valid:\n'
        '${violations.map((v) => '- $v').join('\n')}\n'
        'Fix these and call propose_orchestration again.',
      );
    }

    final now = DateTime.now();
    final agentId = arguments['agent_id'] as String?;
    final existingId = arguments['orchestration_id'] as String?;

    Orchestration orchestration;
    final bool isRevision;
    if (existingId != null && existingId.isNotEmpty) {
      final existing = await _orchestrations.getById(workspaceId, existingId);
      if (existing == null) {
        return CallResult.error('Orchestration $existingId not found.');
      }
      if (existing.status != OrchestrationStatus.proposed) {
        return CallResult.error(
          'Orchestration $existingId is ${existing.status.name} and can no '
          'longer be revised.',
        );
      }
      // Replan-storm guard: consecutive agent revisions inside the cooldown
      // are refused so the operator reviews one coherent diff, not a flood.
      if (now.difference(existing.updatedAt) < revisionCooldown &&
          existing.revision > 1) {
        return CallResult.error(
          'You revised this plan ${now.difference(existing.updatedAt).inSeconds}s '
          'ago. Coalesce your changes and submit ONE revision after '
          '${revisionCooldown.inMinutes} minutes, or wait for the user to '
          'respond to the pending diff.',
        );
      }
      orchestration = existing.copyWith(
        proposal: proposal,
        revision: existing.revision + 1,
        estimatedCostCents: proposal.budget.estimatedCostCents,
        maxCostCents: proposal.budget.maxCostCents,
        updatedAt: now,
      );
      isRevision = true;
      await _orchestrations.update(orchestration);
    } else {
      orchestration = Orchestration(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        proposal: proposal,
        parentTicketId: ticketId,
        channelId: ticket.channelId,
        orchestratorAgentId: agentId,
        estimatedCostCents: proposal.budget.estimatedCostCents,
        maxCostCents: proposal.budget.maxCostCents,
        createdAt: now,
        updatedAt: now,
      );
      isRevision = false;
      await _orchestrations.insert(orchestration);
    }

    // Append the revision snapshot (PRD 17 §5 version timeline). The row is
    // idempotent per (orchestrationId, revision).
    await _revisions?.record(
      OrchestrationRevision(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        orchestrationId: orchestration.id,
        revision: orchestration.revision,
        proposal: proposal,
        authoredBy: agentId ?? 'unknown',
        authorKind: 'agent',
        createdAt: now,
      ),
    );

    // Park the anchor ticket on the user: blocked = waiting for approval.
    if (!ticket.isTerminal && ticket.status != TicketStatus.blocked) {
      await _ticketWorkflow.transitionStatus(
        ticketId,
        TicketStatus.blocked,
        workspaceId: workspaceId,
        force: true,
      );
    }

    // Post the proposal card into the ticket's channel (metadata is the id
    // only — the bubble watches the row live).
    final channelId = ticket.channelId;
    if (channelId != null && channelId.isNotEmpty) {
      await _messaging.sendMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        content:
            'Proposed an orchestration plan for: ${proposal.goal}\n\n'
            '${proposal.roles.length} roles (${proposal.hireCount} new hires), '
            '${proposal.subTickets.length} sub-tickets. Review and approve to run it.',
        senderId: agentId ?? 'system',
        senderType: 'agent',
        messageType: 'orchestration_proposal',
        metadata: {'orchestrationId': orchestration.id},
        id: _uuid.v4(),
      );
    }

    _eventBus.publish(
      isRevision
          ? OrchestrationRevised(
              orchestrationId: orchestration.id,
              workspaceId: workspaceId,
              revision: orchestration.revision,
              occurredAt: now,
            )
          : OrchestrationProposed(
              orchestrationId: orchestration.id,
              workspaceId: workspaceId,
              occurredAt: now,
            ),
    );

    return CallResult.success(
      jsonEncode({
        'orchestration_id': orchestration.id,
        'revision': orchestration.revision,
        'status': 'pending_approval',
        'message': 'Stop here — the user will review and approve your plan.',
      }),
    );
  }
}
