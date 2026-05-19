import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// The link metadata that ties a `plan_exit` [Approval] to its conversation.
const String _planExitLinkType = 'conversation';

/// The hard approval gate for leaving plan mode (PRD 09).
///
/// In plan mode the conversation-mode guard blocks every mutating/execution
/// tool, so an agent can plan but cannot act. To begin executing, the agent
/// calls `exit_plan_mode`, which is the ONLY sanctioned exit:
///
///  1. First call (no prior request) → opens a durable `plan_exit` [Approval]
///     linked to the conversation and returns `pending`. The conversation stays
///     in plan mode; the agent must NOT execute.
///  2. While pending → returns `pending` again (idempotent; no duplicate gate).
///  3. After a human approves (via `decide_approval` or the approvals UI) → the
///     next call flips the conversation out of plan mode (`plan → chat`) and
///     returns `approved`; the agent may now execute.
///  4. After a rejection / revision request → the agent may call again to open a
///     fresh request for the revised plan.
///
/// The conversation + workspace are resolved server-side from the agent's
/// active run (the same resolution the mode guard uses), so an agent cannot
/// exit a conversation it is not actually working in.
class ExitPlanModeTool extends McpTool {
  /// Creates an [ExitPlanModeTool].
  ExitPlanModeTool({
    required AgentRunLogRepository runLogRepository,
    required ApprovalWorkflowService approvalWorkflow,
    required ApprovalRepository approvalRepository,
    required MessagingRepository messagingRepository,
  }) : _runLogs = runLogRepository,
       _workflow = approvalWorkflow,
       _approvals = approvalRepository,
       _messaging = messagingRepository;

  final AgentRunLogRepository _runLogs;
  final ApprovalWorkflowService _workflow;
  final ApprovalRepository _approvals;
  final MessagingRepository _messaging;

  @override
  String get name => 'exit_plan_mode';

  @override
  String get description =>
      'Request to leave plan mode and begin executing your plan. This is a '
      'HARD GATE: it opens a board approval that a human must approve before '
      'you may act. Call it once when your plan is ready, then STOP and wait — '
      'do not execute. Call it again to check the decision: while pending you '
      'must keep waiting; once approved the conversation leaves plan mode and '
      'you may execute; if rejected, revise the plan and call again.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (resolves the active run).',
      },
      'summary': {
        'type': 'string',
        'description':
            'A short summary of the plan being submitted for '
            'approval (shown to the human reviewer).',
      },
    },
    'required': ['workspace_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final agentId = arguments['agent_id'] as String?;
    if (workspaceId == null || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (agentId == null || agentId.isEmpty) {
      return CallResult.error('Missing agent_id.');
    }

    final run = await _runLogs.activeRunForAgent(workspaceId, agentId);
    if (run == null) {
      return CallResult.error(
        'No active run found for agent $agentId — exit_plan_mode applies to '
        'the conversation your current run is working in.',
      );
    }
    if (run.workspaceId != workspaceId) {
      return CallResult.error(
        'The active run belongs to a different workspace.',
      );
    }
    // No aliasing: a conversation id is always its own uuid, so a run that
    // recorded only a space names no conversation row to address.
    final conversationId = run.conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      return CallResult.error(
        'Your active run is not tied to a conversation, so there is no plan '
        'mode to exit.',
      );
    }

    // The latest plan-exit request for this conversation (if any).
    final all = await _approvals.watchByWorkspace(workspaceId).first;
    final planExits =
        all
            .where(
              (a) =>
                  a.kind == ApprovalKind.planExit &&
                  a.linkedEntityType == _planExitLinkType &&
                  a.linkedEntityId == conversationId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = planExits.isEmpty ? null : planExits.first;

    // Approved → consume the gate: flip the SPACE out of plan mode so the mode
    // guard now permits execution tools. Mode is one column on the space row
    // (every conversation in the space shares it), so this cannot be applied
    // with a conversation id — which is what it used to be handed.
    if (latest != null && latest.status == ApprovalStatus.approved) {
      final spaceId = run.spaceId;
      if (spaceId == null || spaceId.isEmpty) {
        return CallResult.error(
          'Your active run is not tied to a space, so its mode cannot be '
          'changed.',
        );
      }
      await _messaging.setSpaceMode(workspaceId, spaceId, Mode.chat);
      return CallResult.success(
        jsonEncode({
          'status': 'approved',
          'approval_id': latest.id,
          'message':
              'Plan exit approved — the conversation has left plan mode. '
              'You may now execute the plan.',
        }),
      );
    }

    // Still pending → keep waiting (idempotent, no duplicate approval).
    if (latest != null && latest.status == ApprovalStatus.pending) {
      return CallResult.success(
        jsonEncode({
          'status': 'pending',
          'approval_id': latest.id,
          'message':
              'Your plan exit is awaiting human approval. Do not execute '
              'yet — call exit_plan_mode again to check the decision.',
        }),
      );
    }

    // No request yet, or the last one was rejected / sent back for revision →
    // open a fresh plan-exit approval for the (possibly revised) plan.
    final summary = (arguments['summary'] as String?)?.trim();
    final approval = await _workflow.createApproval(
      workspaceId: workspaceId,
      title: 'Exit plan mode',
      description: summary == null || summary.isEmpty ? null : summary,
      kind: ApprovalKind.planExit,
      requestedByActorType: 'agent',
      requestedById: agentId,
      linkedEntityType: _planExitLinkType,
      linkedEntityId: conversationId,
    );
    final resubmitted =
        latest != null && latest.status != ApprovalStatus.pending;
    return CallResult.success(
      jsonEncode({
        'status': 'pending',
        'approval_id': approval.id,
        'message': resubmitted
            ? 'Opened a new plan exit approval for your revised plan. Do not '
                  'execute yet — wait for the human decision.'
            : 'Plan submitted for approval. Do not execute yet — wait for a '
                  'human to approve before you act, then call exit_plan_mode again.',
      }),
    );
  }
}
