import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

Map<String, dynamic> _approvalJson(Approval a) => {
  'id': a.id,
  'title': a.title,
  'kind': a.kind.storage,
  'status': a.status.storage,
  'description': a.description,
  'requested_by': a.requestedById,
  'linked_ticket_ids': a.linkedTicketIds,
  'decision_reason': a.decisionReason,
  'created_at': a.createdAt.toIso8601String(),
  'decided_at': a.decidedAt?.toIso8601String(),
};

/// Opens a board approval — a durable governance gate with a comment history.
class CreateApprovalTool extends McpTool {
  /// Creates a [CreateApprovalTool].
  CreateApprovalTool({required ApprovalWorkflowService service})
    : _service = service;

  final ApprovalWorkflowService _service;

  @override
  String get name => 'create_approval';

  @override
  String get description =>
      'Opens a board approval for a governed action (plan exit, merge, '
      'release, hire, or custom). Returns a durable, reviewable approval that '
      'holds in pending until a decision is recorded.';

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Open approval',
        detail: 'Requesting approval: "${arguments['title'] ?? '(untitled)'}".',
      );

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'title': {'type': 'string', 'description': 'What needs approval.'},
      'kind': {
        'type': 'string',
        'enum': ['plan_exit', 'merge', 'release', 'hire', 'custom'],
        'description': 'Kind of governed action.',
      },
      'description': {'type': 'string', 'description': 'Rationale.'},
      'requested_by': {'type': 'string', 'description': 'Requesting agent id.'},
      'linked_ticket_ids': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Tickets this approval gates.',
      },
    },
    'required': ['workspace_id', 'title'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final title = arguments['title'];
    if (title is! String) {
      return CallResult.error('Missing or invalid argument: title');
    }
    final rawTickets = arguments['linked_ticket_ids'];
    final approval = await _service.createApproval(
      workspaceId: workspaceId,
      title: title,
      kind: ApprovalKind.fromStorage(arguments['kind'] as String?),
      description: arguments['description'] as String?,
      requestedById: arguments['requested_by'] as String?,
      linkedTicketIds: rawTickets is List
          ? rawTickets.map((e) => e.toString()).toList()
          : const [],
    );
    return CallResult.success(jsonEncode(_approvalJson(approval)));
  }
}

/// Lists approvals in a workspace, optionally filtered by status.
class ListApprovalsTool extends McpTool {
  /// Creates a [ListApprovalsTool].
  ListApprovalsTool({required ApprovalRepository repository})
    : _repository = repository;

  final ApprovalRepository _repository;

  @override
  String get name => 'list_approvals';

  @override
  String get description =>
      'Lists board approvals for a workspace, optionally filtered by status '
      '(pending, approved, rejected, revision_requested).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'status': {
        'type': 'string',
        'enum': ['pending', 'approved', 'rejected', 'revision_requested'],
        'description': 'Optional status filter.',
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final status = arguments['status'];
    final approvals = status is String
        ? await _repository.watchByStatus(workspaceId, status).first
        : await _repository.watchByWorkspace(workspaceId).first;
    return CallResult.success(
      jsonEncode({
        'approvals': approvals.map(_approvalJson).toList(),
        'count': approvals.length,
      }),
    );
  }
}

/// Records a decision on an approval, enforcing the state machine.
class DecideApprovalTool extends McpTool {
  /// Creates a [DecideApprovalTool].
  DecideApprovalTool({required ApprovalWorkflowService service})
    : _service = service;

  final ApprovalWorkflowService _service;

  @override
  String get name => 'decide_approval';

  @override
  String get description =>
      'Records a decision on a pending approval: approve, reject, '
      'request_revision, or resubmit (a revision-requested approval back to '
      'pending). Illegal transitions are rejected.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'approval_id': {'type': 'string', 'description': 'Approval id.'},
      'decision': {
        'type': 'string',
        'enum': ['approve', 'reject', 'request_revision', 'resubmit'],
        'description': 'The decision to apply.',
      },
      'decided_by': {'type': 'string', 'description': 'Deciding actor id.'},
      'reason': {'type': 'string', 'description': 'Decision rationale.'},
    },
    'required': ['workspace_id', 'approval_id', 'decision'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final approvalId = arguments['approval_id'];
    if (approvalId is! String) {
      return CallResult.error('Missing or invalid argument: approval_id');
    }
    final rawDecision = arguments['decision'];
    final decision = ApprovalDecision.tryParse(
      rawDecision is String ? rawDecision.replaceAll('_', '') : null,
    );
    if (decision == null) {
      return CallResult.error(
        'Missing or invalid argument: decision (expected approve, reject, '
        'request_revision, or resubmit)',
      );
    }
    final updated = await _service.decide(
      approvalId,
      workspaceId: workspaceId,
      decision: decision,
      decidedById: arguments['decided_by'] as String?,
      reason: arguments['reason'] as String?,
    );
    return CallResult.success(jsonEncode(_approvalJson(updated)));
  }
}

/// Adds a comment to an approval's review discussion.
class CommentApprovalTool extends McpTool {
  /// Creates a [CommentApprovalTool].
  CommentApprovalTool({required ApprovalWorkflowService service})
    : _service = service;

  final ApprovalWorkflowService _service;

  @override
  String get name => 'comment_approval';

  @override
  String get description => 'Adds a comment to a board approval\'s discussion.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'approval_id': {'type': 'string', 'description': 'Approval id.'},
      'body': {'type': 'string', 'description': 'Comment text.'},
      'author_id': {'type': 'string', 'description': 'Author id.'},
    },
    'required': ['workspace_id', 'approval_id', 'body'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final approvalId = arguments['approval_id'];
    if (approvalId is! String) {
      return CallResult.error('Missing or invalid argument: approval_id');
    }
    final body = arguments['body'];
    if (body is! String) {
      return CallResult.error('Missing or invalid argument: body');
    }
    final comment = await _service.comment(
      approvalId,
      workspaceId: workspaceId,
      body: body,
      authorId: arguments['author_id'] as String?,
    );
    return CallResult.success(
      jsonEncode({
        'id': comment.id,
        'approval_id': comment.approvalId,
        'created_at': comment.createdAt.toIso8601String(),
      }),
    );
  }
}
