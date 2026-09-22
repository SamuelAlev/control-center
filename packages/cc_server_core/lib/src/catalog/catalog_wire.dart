import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/agent_visibility.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_domain/features/model_routing/domain/repositories/provider_policy_repository.dart';
import 'package:cc_domain/features/model_routing/domain/services/usage_tracker.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_attempt.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_source.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show MessageReactionsTableData, PairedDevicesTableData, SpaceNotesTableData;
import 'package:path/path.dart' as p;

/// Maps a [Ticket] to the `TicketDto` wire shape (`cc_domain`).
///
/// The shape is LOSSLESS: every persisted field rides the wire so a thin client
/// can run the domain workflow (read-modify-write with `expectedVersion`)
/// without dropping anything. Enum fields travel as `.name`; timestamps as
/// ISO-8601.
Map<String, dynamic> ticketToWire(Ticket t) => {
  'ticket_id': t.id,
  'key': t.externalKey ?? '',
  'title': t.title,
  'status': t.status.name,
  'priority': t.priority.name,
  'provider': t.provider.name,
  'assignee': ?t.assignedAgentId,
  'url': ?t.url,
  'workspace_id': t.workspaceId,
  'description': ?t.description,
  'raw_status': ?t.rawStatus,
  'labels': t.labels,
  'parent_ticket_id': ?t.parentTicketId,
  'project_id': ?t.projectId,
  'assigned_team_id': ?t.assignedTeamId,
  'delegated_by_agent_id': ?t.delegatedByAgentId,
  'space_id': ?t.spaceId,
  'error_message': ?t.errorMessage,
  'linked_pr_ids': t.linkedPrIds,
  'metadata': t.metadata,
  'version': t.version,
  'origin_kind': t.originKind.name,
  'created_at': t.createdAt.toIso8601String(),
  'started_at': ?t.startedAt?.toIso8601String(),
  'blocked_at': ?t.blockedAt?.toIso8601String(),
  'cancelled_at': ?t.cancelledAt?.toIso8601String(),
  'completed_at': ?t.completedAt?.toIso8601String(),
  'finished_at': ?t.finishedAt?.toIso8601String(),
  'updated_at': t.updatedAt.toIso8601String(),
};

/// Rebuilds a [Ticket] from the `TicketDto` wire shape (the inverse of
/// [ticketToWire]), used by the `tickets.insert` / `tickets.update` ops. Enum
/// fields are decoded from their `.name` (unknown values fall back to a safe
/// default); a missing required timestamp falls back to the epoch so the entity
/// stays constructible.
Ticket ticketFromWire(Map<String, dynamic> w) {
  DateTime? parse(Object? iso) => iso is String ? DateTime.parse(iso) : null;
  DateTime parseOr(Object? iso) =>
      parse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final key = w['key'] as String?;
  return Ticket(
    id: w['ticket_id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    title: w['title'] as String? ?? '',
    externalKey: (key == null || key.isEmpty) ? null : key,
    url: w['url'] as String?,
    description: w['description'] as String?,
    status:
        TicketStatus.values.asNameMap()[w['status'] as String?] ??
        TicketStatus.open,
    rawStatus: w['raw_status'] as String?,
    priority:
        TicketPriority.values.asNameMap()[w['priority'] as String?] ??
        TicketPriority.none,
    provider:
        TicketProvider.values.asNameMap()[w['provider'] as String?] ??
        TicketProvider.local,
    labels: (w['labels'] as List?)?.whereType<String>().toList() ?? const [],
    parentTicketId: w['parent_ticket_id'] as String?,
    projectId: w['project_id'] as String?,
    assignedAgentId: w['assignee'] as String?,
    assignedTeamId: w['assigned_team_id'] as String?,
    delegatedByAgentId: w['delegated_by_agent_id'] as String?,
    spaceId: w['space_id'] as String?,
    errorMessage: w['error_message'] as String?,
    linkedPrIds:
        (w['linked_pr_ids'] as List?)?.whereType<String>().toList() ?? const [],
    metadata: (w['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    version: (w['version'] as num?)?.toInt() ?? 0,
    originKind:
        TicketOriginKind.values.asNameMap()[w['origin_kind'] as String?] ??
        TicketOriginKind.manual,
    createdAt: parseOr(w['created_at']),
    startedAt: parse(w['started_at']),
    blockedAt: parse(w['blocked_at']),
    cancelledAt: parse(w['cancelled_at']),
    completedAt: parse(w['completed_at']),
    finishedAt: parse(w['finished_at']),
    updatedAt: parseOr(w['updated_at']),
  );
}

/// Maps a [TicketCollaborator] to its wire shape (`role` as its stored name;
/// `joinedAt` as ISO-8601).
Map<String, dynamic> collaboratorToWire(TicketCollaborator c) => {
  'id': c.id,
  'ticket_id': c.ticketId,
  'principal_id': c.principalId,
  'collaborator_type': c.collaboratorType.wireName,
  'role': c.role.toStorageString(),
  'joined_at': c.joinedAt.toIso8601String(),
};

/// Rebuilds a [TicketCollaborator] from its wire shape (the inverse of
/// [collaboratorToWire]).
TicketCollaborator collaboratorFromWire(Map<String, dynamic> w) =>
    TicketCollaborator(
      id: w['id'] as String,
      ticketId: w['ticket_id'] as String,
      principalId: w['principal_id'] as String,
      collaboratorType:
          PrincipalType.fromWire(w['collaborator_type'] as String?) ??
          PrincipalType.agent,
      role: TicketCollaboratorRole.fromStorage(w['role'] as String?),
      joinedAt: w['joined_at'] is String
          ? DateTime.parse(w['joined_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Loads [ticketId] from [workspaceId] and fails loudly when it is not there —
/// the isolation chokepoint for the ticket-id-keyed collaborator ops.
///
/// The read is already scoped to [workspaceId]'s database, so a foreign ticket
/// is simply not found; this turns that into an explicit denial instead of an
/// empty collaborator list, which would read as "this ticket has no
/// collaborators" rather than "this ticket is not yours".
Future<void> assertTicketInWorkspace(
  TicketRepository repo,
  String ticketId,
  String workspaceId,
) async {
  final ticket = await repo.getById(workspaceId, ticketId);
  if (ticket == null) {
    throw const NotFoundException('Ticket not found');
  }
}

/// Query that opens code-server on conversation worktree [folderPath]
/// (and [rawPath] when it names a file inside). code-server web reads
/// `?folder=` / `?payload=` from the URL; CLI positionals are ignored at the
/// proxy root.
///
/// Folder always opens. File is best-effort: confined to the worktree (`..`
/// / out-of-tree dropped); `openFile` payload on `vscode-remote://remote`.
/// Positive 1-based [line] → `:<line>` suffix (`parseLineAndColumnAware`).
String codeServerOpenQuery(String folderPath, String? rawPath, {int? line}) {
  final params = <String>['folder=${Uri.encodeQueryComponent(folderPath)}'];
  if (rawPath != null && rawPath.isNotEmpty) {
    final resolved = p.normalize(
      p.isAbsolute(rawPath) ? rawPath : p.join(folderPath, rawPath),
    );
    if (p.equals(folderPath, resolved) || p.isWithin(folderPath, resolved)) {
      final suffix = (line != null && line > 0) ? ':$line' : '';
      final fileUri = 'vscode-remote://remote$resolved$suffix';
      final payload = jsonEncode([
        ['openFile', fileUri],
      ]);
      params.add('payload=${Uri.encodeQueryComponent(payload)}');
    }
  }
  return '?${params.join('&')}';
}

/// Streams a ticket's collaborators after verifying workspace ownership (see
/// [assertTicketInWorkspace]). An `async*` generator so the ownership check
/// runs before any row is yielded.
Stream<Map<String, dynamic>> watchCollaboratorsScoped(
  TicketRepository repo,
  String? ticketId,
  String workspaceId,
) async* {
  if (ticketId == null) {
    throw const NotFoundException('ticket_id is required');
  }
  await assertTicketInWorkspace(repo, ticketId, workspaceId);
  yield* repo
      .watchCollaborators(workspaceId, ticketId)
      .map((list) => {'collaborators': list.map(collaboratorToWire).toList()});
}

/// Maps an [Agent] to the `AgentDto` wire shape (enum fields as `.name`).
Map<String, dynamic> agentToWire(Agent a) => {
  'id': a.id,
  'name': a.name,
  'title': a.title,
  'agent_md_path': a.agentMdPath,
  'workspace_id': a.workspaceId,
  'skills': a.skills.toList(),
  'reports_to': ?a.reportsTo,
  'persona': ?a.persona,
  'system_prompt': ?a.systemPrompt,
  'adapter_id': ?a.adapterId,
  'model_id': ?a.modelId,
  'strict_mode': a.strictMode,
  'effort': ?a.effort,
  'context_size': ?a.contextSize,
  'role': ?a.role?.name,
  'capabilities': ?a.capabilities?.toJson(),
  'monthly_budget_cents': a.monthlyBudgetCents,
  'silence_timeout_minutes': ?a.silenceTimeoutMinutes,
  'max_concurrent_tasks': a.maxConcurrentTasks,
  'visibility': a.visibility.name,
  'lifecycle_status': a.lifecycleStatus.name,
  'budget_policy_id': ?a.budgetPolicyId,
  'runtime_profile_id': ?a.runtimeProfileId,
  'created_at': a.createdAt.toIso8601String(),
};

/// Reconstructs an [Agent] from an `AgentDto` wire map (the inverse of
/// [agentToWire]), used by the `agents.upsert` op.
Agent agentFromWire(Map<String, dynamic> w) {
  final caps = w['capabilities'];
  return Agent(
    id: w['id'] as String,
    name: w['name'] as String? ?? '',
    title: w['title'] as String? ?? '',
    agentMdPath: w['agent_md_path'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    skills: AgentSkills(
      ((w['skills'] as List?) ?? const []).map((s) => s.toString()).toList(),
    ),
    reportsTo: w['reports_to'] as String?,
    persona: w['persona'] as String?,
    systemPrompt: w['system_prompt'] as String?,
    adapterId: w['adapter_id'] as String?,
    modelId: w['model_id'] as String?,
    strictMode: w['strict_mode'] as bool? ?? false,
    effort: w['effort'] as String?,
    contextSize: (w['context_size'] as num?)?.toInt(),
    role: w['role'] == null ? null : AgentRole.values.asNameMap()[w['role']],
    capabilities: caps is Map
        ? AgentCapabilities.fromJson(caps.cast<String, dynamic>())
        : null,
    monthlyBudgetCents: (w['monthly_budget_cents'] as num?)?.toInt() ?? 0,
    silenceTimeoutMinutes: (w['silence_timeout_minutes'] as num?)?.toInt(),
    maxConcurrentTasks: (w['max_concurrent_tasks'] as num?)?.toInt() ?? 1,
    visibility: AgentVisibility.fromStorage(w['visibility'] as String?),
    lifecycleStatus: AgentLifecycleStatus.fromStorage(
      w['lifecycle_status'] as String?,
    ),
    budgetPolicyId: w['budget_policy_id'] as String?,
    runtimeProfileId: w['runtime_profile_id'] as String?,
    createdAt: w['created_at'] is String
        ? DateTime.parse(w['created_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Maps an [OrgGoal] to its wire shape (enum fields as `.name`).
Map<String, dynamic> orgGoalToWire(OrgGoal g) => {
  'id': g.id,
  'workspace_id': g.workspaceId,
  'title': g.title,
  'level': g.level.name,
  'parent_goal_id': ?g.parentGoalId,
  'description': ?g.description,
  'status': g.status.name,
  'owner_agent_id': ?g.ownerAgentId,
  'team_id': ?g.teamId,
  'target_ticket_id': ?g.targetTicketId,
  'progress': g.progress,
  'created_at': g.createdAt.toIso8601String(),
  'updated_at': g.updatedAt.toIso8601String(),
};

/// Maps a [TodoItem] to its wire shape.
Map<String, dynamic> todoItemToWire(TodoItem t) => {
  'id': t.id,
  'workspace_id': t.workspaceId,
  'conversation_id': t.conversationId,
  'content': t.content,
  'status': t.status.storage,
  'position': t.position,
  'created_at': t.createdAt.toIso8601String(),
  'updated_at': t.updatedAt.toIso8601String(),
};

/// Maps a [NotificationFeedItem] (one stored `notifications/*` frame) to its
/// wire shape. `params` travels verbatim — the client renders it through the
/// same frame mapper it uses for live pushes.
Map<String, dynamic> notificationFeedItemToWire(NotificationFeedItem n) => {
  'id': n.id,
  'workspace_id': n.workspaceId,
  'method': n.method,
  'params': n.params,
  'created_at': n.createdAt.toIso8601String(),
};

/// Maps a [NotificationReadMark] (one user's read/cleared watermarks) to its
/// wire shape.
Map<String, dynamic> notificationReadMarkToWire(NotificationReadMark m) => {
  'workspace_id': m.workspaceId,
  'user_id': m.userId,
  'last_seen_at': ?m.lastSeenAt?.toIso8601String(),
  'cleared_before': ?m.clearedBefore?.toIso8601String(),
};

/// Maps a [NotificationItemState] (one user's opinion about ONE feed item) to
/// its wire shape.
///
/// `read_at` is omitted rather than sent as null, and the client reconstructs
/// "explicitly unread" from the row's mere presence — the row existing is the
/// override, the stamp only says when.
Map<String, dynamic> notificationItemStateToWire(NotificationItemState s) => {
  'workspace_id': s.workspaceId,
  'user_id': s.userId,
  'item_id': s.itemId,
  'read_at': ?s.readAt?.toIso8601String(),
  'dismissed_at': ?s.dismissedAt?.toIso8601String(),
};

/// Maps a [ConversationGoal] to its wire shape.
Map<String, dynamic> goalToWire(ConversationGoal g) => {
  'conversation_id': g.conversationId,
  'workspace_id': g.workspaceId,
  'title': g.title,
  'created_at': g.createdAt.toIso8601String(),
  'updated_at': g.updatedAt.toIso8601String(),
};

/// Maps an [AgentGoalRun] (a durable supervised `/goal` or `/loop`) to its
/// wire shape (enum fields as their persisted wire names, timestamps ISO-8601
/// like [todoItemToWire]).
Map<String, dynamic> agentGoalRunToWire(AgentGoalRun g) => {
  'id': g.id,
  'workspace_id': g.workspaceId,
  'space_id': g.spaceId,
  'conversation_id': g.conversationId,
  'agent_id': g.agentId,
  'user_text': g.userText,
  'kind': g.kind.wire,
  'status': g.status.wire,
  'deadline_at': ?g.deadlineAt?.toIso8601String(),
  'cost_cap_cents': g.costCapCents,
  'cost_cents': g.costCents,
  'max_runs': ?g.maxRuns,
  'run_count': g.runCount,
  'consecutive_failures': g.consecutiveFailures,
  'active_run_id': ?g.activeRunId,
  'requested_by_user_id': ?g.requestedByUserId,
  'summary': ?g.summary,
  'created_at': g.createdAt.toIso8601String(),
  'updated_at': g.updatedAt.toIso8601String(),
};

/// Maps an [Approval] to its wire shape (enum fields as their storage keys).
Map<String, dynamic> approvalToWire(Approval a) => {
  'id': a.id,
  'workspace_id': a.workspaceId,
  'title': a.title,
  'description': ?a.description,
  'kind': a.kind.storage,
  'status': a.status.storage,
  'requested_by_actor_type': a.requestedByActorType,
  'requested_by_id': ?a.requestedById,
  'linked_ticket_ids': a.linkedTicketIds,
  'linked_entity_type': ?a.linkedEntityType,
  'linked_entity_id': ?a.linkedEntityId,
  'decided_by_actor_type': ?a.decidedByActorType,
  'decided_by_id': ?a.decidedById,
  'decision_reason': ?a.decisionReason,
  'created_at': a.createdAt.toIso8601String(),
  'decided_at': ?a.decidedAt?.toIso8601String(),
  'updated_at': a.updatedAt.toIso8601String(),
};

/// Maps an [ApprovalComment] to its wire shape.
Map<String, dynamic> approvalCommentToWire(ApprovalComment c) => {
  'id': c.id,
  'approval_id': c.approvalId,
  'workspace_id': c.workspaceId,
  'author_type': c.authorType,
  'author_id': ?c.authorId,
  'body': c.body,
  'created_at': c.createdAt.toIso8601String(),
};

/// Maps an [AgentPresence] to its wire shape (the availability × workload
/// dimensions as `.name`, plus the running / queued / capacity counts).
Map<String, dynamic> agentPresenceToWire(AgentPresence p) => {
  'availability': p.availability.name,
  'workload': p.workload.name,
  'running_count': p.runningCount,
  'queued_count': p.queuedCount,
  'capacity': p.capacity,
};

/// Maps a [MemoryFact] to the `MemoryFactDto` wire shape (enum field as `.name`).
Map<String, dynamic> memoryFactToWire(MemoryFact f) => {
  'id': f.id,
  'workspace_id': f.workspaceId,
  'domain': f.domain,
  'topic': f.topic,
  'content': f.content,
  'source_observation_ids': f.sourceObservationIds,
  'confidence': f.confidence,
  'superseded_by': ?f.supersededBy,
  'authored_by_agent_id': ?f.authoredByAgentId,
  'authored_by_role': ?f.authoredByRole?.name,
  'memory_type': f.memoryType.wireName,
  'veracity': f.veracity.wireName,
  'mention_count': f.mentionCount,
  'created_at': f.createdAt.toIso8601String(),
  'updated_at': f.updatedAt.toIso8601String(),
};

/// Reconstructs a [MemoryFact] from a `MemoryFactDto` wire map (the inverse of
/// [memoryFactToWire]), used by the `memory_fact.upsert` op.
MemoryFact memoryFactFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return MemoryFact(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    domain: w['domain'] as String? ?? '',
    topic: w['topic'] as String? ?? '',
    content: w['content'] as String? ?? '',
    sourceObservationIds: ((w['source_observation_ids'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList(),
    confidence: (w['confidence'] as num?)?.toDouble() ?? 1.0,
    supersededBy: w['superseded_by'] as String?,
    authoredByAgentId: w['authored_by_agent_id'] as String?,
    authoredByRole: w['authored_by_role'] == null
        ? null
        : AgentRole.values.asNameMap()[w['authored_by_role']],
    memoryType: MemoryType.parse(w['memory_type'] as String?),
    veracity: MemoryVeracity.parse(w['veracity'] as String?),
    mentionCount: (w['mention_count'] as num?)?.toInt() ?? 1,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps an [AgentRunLog] to the `AgentRunLogDto` wire shape (enum fields as
/// `.name`, timestamps as ISO-8601, cost flattened to token columns).
Map<String, dynamic> agentRunLogToWire(AgentRunLog l) => {
  'id': l.id,
  'agent_id': l.agentId,
  'workspace_id': ?l.workspaceId,
  'conversation_id': ?l.conversationId,
  'ticket_id': ?l.ticketId,
  'space_id': ?l.spaceId,
  'started_at': l.startedAt.toIso8601String(),
  'completed_at': ?l.completedAt?.toIso8601String(),
  'status': l.status.name,
  'summary': ?l.summary,
  'adapter': ?l.adapter,
  'model_id': ?l.modelId,
  'pid': ?l.pid,
  'log_path': ?l.logPath,
  'input_tokens': l.cost.inputTokens,
  'output_tokens': l.cost.outputTokens,
  'thought_tokens': l.cost.thoughtTokens,
  'cached_read_tokens': l.cost.cachedReadTokens,
  'cached_write_tokens': l.cost.cachedWriteTokens,
  'estimated_cost_cents': l.cost.estimatedCostCents,
  'child_cost_cents': l.childCostCents,
  'agent_role': l.role.name,
  'duration_ms': ?l.cost.durationMs,
  'time_to_first_token_ms': ?l.cost.timeToFirstTokenMs,
  'liveness': ?l.liveness?.name,
  'error_family': ?l.errorFamily?.name,
  'last_output_at': ?l.lastOutputAt?.toIso8601String(),
  'continuation_summary': ?l.continuationSummary,
  'context_snapshot_json': ?l.contextSnapshotJson,
  'pipeline_run_id': ?l.pipelineRunId,
  'pipeline_step_id': ?l.pipelineStepId,
  'error_code': ?l.errorCode,
  'expected_output_schema': ?l.expectedOutputSchema,
  'output_contract_mode': l.outputContractMode.toStorageString(),
  'output_json': ?l.outputJson,
  'output_rejections': l.outputRejections,
  'retry_of_run_id': ?l.retry.parentRunId,
  'retry_attempt': l.retry.attempt,
  'parent_run_id': ?l.parentRunId,
  'spawn_tool_call_id': ?l.spawnToolCallId,
};

/// Reconstructs an [AgentRunLog] from an `AgentRunLogDto` wire map (the inverse
/// of [agentRunLogToWire]), used by the `agent_run_log.upsert` op.
AgentRunLog agentRunLogFromWire(Map<String, dynamic> w) {
  final schema = w['expected_output_schema'];
  final output = w['output_json'];
  return AgentRunLog(
    id: w['id'] as String,
    agentId: w['agent_id'] as String? ?? '',
    workspaceId: w['workspace_id'] as String?,
    conversationId: w['conversation_id'] as String?,
    ticketId: w['ticket_id'] as String?,
    spaceId: w['space_id'] as String?,
    startedAt: w['started_at'] is String
        ? DateTime.parse(w['started_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
    completedAt: w['completed_at'] is String
        ? DateTime.parse(w['completed_at'] as String)
        : null,
    status: RunStatus.values.asNameMap()[w['status']] ?? RunStatus.pending,
    summary: w['summary'] as String?,
    adapter: w['adapter'] as String?,
    modelId: w['model_id'] as String?,
    pid: (w['pid'] as num?)?.toInt(),
    logPath: w['log_path'] as String?,
    cost: RunCost(
      inputTokens: (w['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (w['output_tokens'] as num?)?.toInt() ?? 0,
      thoughtTokens: (w['thought_tokens'] as num?)?.toInt() ?? 0,
      cachedReadTokens: (w['cached_read_tokens'] as num?)?.toInt() ?? 0,
      cachedWriteTokens: (w['cached_write_tokens'] as num?)?.toInt() ?? 0,
      estimatedCostCents: (w['estimated_cost_cents'] as num?)?.toInt() ?? 0,
      durationMs: (w['duration_ms'] as num?)?.toInt(),
      timeToFirstTokenMs: (w['time_to_first_token_ms'] as num?)?.toInt(),
    ),
    liveness: w['liveness'] == null
        ? null
        : RunLiveness.values.asNameMap()[w['liveness']],
    errorFamily: w['error_family'] == null
        ? null
        : RunErrorFamily.values.asNameMap()[w['error_family']],
    lastOutputAt: w['last_output_at'] is String
        ? DateTime.parse(w['last_output_at'] as String)
        : null,
    continuationSummary: w['continuation_summary'] as String?,
    contextSnapshotJson: w['context_snapshot_json'] as String?,
    pipelineRunId: w['pipeline_run_id'] as String?,
    pipelineStepId: w['pipeline_step_id'] as String?,
    errorCode: w['error_code'] as String?,
    expectedOutputSchema: schema is Map ? schema.cast<String, dynamic>() : null,
    outputContractMode: OutputContractMode.fromStorage(
      w['output_contract_mode'] as String?,
    ),
    outputJson: output is Map ? output.cast<String, dynamic>() : null,
    outputRejections: (w['output_rejections'] as num?)?.toInt() ?? 0,
    retry: RetryMeta(
      parentRunId: w['retry_of_run_id'] as String?,
      attempt: (w['retry_attempt'] as num?)?.toInt() ?? 0,
    ),
    role: AgentRunRole.tryParse(w['agent_role'] as String?),
    childCostCents: (w['child_cost_cents'] as num?)?.toInt() ?? 0,
    parentRunId: w['parent_run_id'] as String?,
    spawnToolCallId: w['spawn_tool_call_id'] as String?,
  );
}

/// Maps a [Team] to the `TeamDto` wire shape (timestamp as ISO-8601).
Map<String, dynamic> teamToWire(Team t) => {
  'id': t.id,
  'workspace_id': t.workspaceId,
  'name': t.name,
  if (t.description != null) 'description': t.description,
  if (t.leaderId != null) 'leader_id': t.leaderId,
  if (t.instructions != null) 'instructions': t.instructions,
  'created_at': t.createdAt.toIso8601String(),
};

/// Reconstructs a [Team] from a `TeamDto` wire map (the inverse of
/// [teamToWire]), used by the `team.insertTeam` / `team.updateTeam` ops.
Team teamFromWire(Map<String, dynamic> w) => Team(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  name: w['name'] as String? ?? '',
  description: w['description'] as String?,
  leaderId: w['leader_id'] as String?,
  instructions: w['instructions'] as String?,
  createdAt: w['created_at'] is String
      ? DateTime.parse(w['created_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
);

/// Maps a [TeamMember] to the `TeamMemberDto` wire shape (role as `.name`).
Map<String, dynamic> teamMemberToWire(TeamMember m) => {
  'team_id': m.teamId,
  'agent_id': m.agentId,
  'role': m.role.toStorageString(),
};

/// Reconstructs a [TeamMember] from a `TeamMemberDto` wire map (the inverse of
/// [teamMemberToWire]), used by the `team.addMember` op.
TeamMember teamMemberFromWire(Map<String, dynamic> w) => TeamMember(
  teamId: w['team_id'] as String? ?? '',
  agentId: w['agent_id'] as String? ?? '',
  role: TeamMemberRole.fromString(w['role'] as String? ?? 'member'),
);

/// Maps a [MemoryDomain] to the `MemoryDomainDto` wire shape.
Map<String, dynamic> memoryDomainToWire(MemoryDomain d) => {
  'id': d.id,
  'workspace_id': d.workspaceId,
  'name': d.name,
  'label': d.label,
  if (d.description != null) 'description': d.description,
  'created_by_role': d.createdByRole,
  'created_at': d.createdAt.toIso8601String(),
};

/// Reconstructs a [MemoryDomain] from a `MemoryDomainDto` wire map (the inverse
/// of [memoryDomainToWire]), used by the `memory_domain.upsert` op.
MemoryDomain memoryDomainFromWire(Map<String, dynamic> w) => MemoryDomain(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  name: w['name'] as String? ?? '',
  label: w['label'] as String? ?? '',
  description: w['description'] as String?,
  createdByRole: w['created_by_role'] as String? ?? '',
  createdAt: w['created_at'] is String
      ? DateTime.parse(w['created_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
);

/// Maps a [MemoryAccessGrant] to the `MemoryAccessGrantDto` wire shape (enum
/// fields as `.name`).
Map<String, dynamic> memoryAccessGrantToWire(MemoryAccessGrant g) => {
  'workspace_id': g.workspaceId,
  'agent_role': g.agentRole.name,
  'memory_domain': g.memoryDomain,
  'permission': g.permission.name,
};

/// Reconstructs a [MemoryAccessGrant] from a `MemoryAccessGrantDto` wire map
/// (the inverse of [memoryAccessGrantToWire]), used by the
/// `memory_access_grant.upsert` / `.upsertAll` ops.
MemoryAccessGrant memoryAccessGrantFromWire(Map<String, dynamic> w) =>
    MemoryAccessGrant(
      workspaceId: w['workspace_id'] as String? ?? '',
      agentRole:
          AgentRole.values.asNameMap()[w['agent_role']] ?? AgentRole.general,
      memoryDomain: w['memory_domain'] as String? ?? '',
      permission:
          MemoryPermission.values.asNameMap()[w['permission']] ??
          MemoryPermission.none,
    );

/// Maps a space read-cursor to the `SpaceReadDto` wire shape. The cursor is
/// a nullable ISO-8601 timestamp keyed by `space_id`.
Map<String, dynamic> spaceReadToWire(String spaceId, DateTime? lastReadAt) => {
  'space_id': spaceId,
  if (lastReadAt != null) 'last_read_at': lastReadAt.toIso8601String(),
};

/// Maps a [Repo] to the `RepoDto` wire shape.
///
/// The keys must stay in lockstep with `RepoDto.fromJson` — a mismatch is
/// silent: every repo arrives with an empty owner/name, `hasForgeRemote` reads
/// false, and the PR surfaces report "no repositories configured" for a
/// workspace that has plenty.
Map<String, dynamic> repoToWire(Repo r) => {
  'id': r.id,
  'name': r.name,
  'path': r.path,
  'forge': r.forge.wire,
  'remote_owner': r.remoteOwner,
  'remote_name': r.remoteName,
  'created_at': r.createdAt.toIso8601String(),
  'updated_at': r.updatedAt.toIso8601String(),
};

/// Maps an [IdeEditor] to the `IdeEditorDto` wire shape (`display_name` snake).
Map<String, dynamic> ideEditorToWire(IdeEditor e) => {
  'id': e.id,
  'display_name': e.displayName,
  'installed': e.installed,
};

/// Reconstructs an [Adapter] from the `adapter.*` request wire shape (the
/// client sends its predefined adapter spec for the host to probe).
Adapter adapterFromWire(Map<String, dynamic> w) {
  final id = w['id'] as String? ?? '';
  // Transport is a host-side concern (which backend drives the CLI), not sent
  // by the client. Resolve it from the host's predefined catalog; unknown ids
  // probe as the built-in loop (probing only needs id/name/cliName).
  final predefined = predefinedAdapters.where((a) => a.id == id).firstOrNull;
  return Adapter(
    id: id,
    name: w['name'] as String? ?? '',
    description: w['description'] as String? ?? '',
    cliName: w['cli_name'] as String? ?? '',
    transport: predefined?.transport ?? AdapterTransport.harness,
    acpArgs: predefined?.acpArgs,
  );
}

/// Maps a [DetectedAdapter] to the `adapter.*` response wire shape. Keyed by
/// `adapter_id` so a batched `adapter.detectAll` response can be re-paired with
/// the adapters the client sent.
Map<String, dynamic> detectedAdapterToWire(DetectedAdapter d) => {
  'adapter_id': d.adapter.id,
  'status': d.status.name,
  if (d.version != null) 'version': d.version,
  if (d.path != null) 'path': d.path,
  if (d.capabilities != null)
    'capabilities': {
      'supports_json_mode': d.capabilities!.supportsJsonMode,
      'supports_model_selection': d.capabilities!.supportsModelSelection,
    },
};

/// Maps a [BackupSnapshot] to the `server.listBackups` response wire shape.
///
/// Every path is the SERVER's, and the client says so rather than offering to
/// open one: a snapshot on a remote host is not on the operator's disk, and a
/// per-workspace `path` here is exactly what `workspace.import` takes back —
/// which is what makes "restore this workspace from this snapshot" the import
/// op rather than a second mechanism that could disagree with it.
Map<String, dynamic> backupSnapshotToWire(BackupSnapshot s) => {
  'path': s.path,
  'name': s.name,
  if (s.createdAt != null) 'created_at': s.createdAt!.toIso8601String(),
  'bytes': s.bytes,
  'complete': s.complete,
  'workspaces': [
    for (final w in s.workspaces)
      {'workspace_id': w.workspaceId, 'path': w.path, 'bytes': w.bytes},
  ],
  'skipped_workspace_ids': s.skippedWorkspaceIds,
};

/// Maps an [AcpModel] to the `acp.listModels` response wire shape.
Map<String, dynamic> acpModelToWire(AcpModel m) => {
  'id': m.id,
  'name': m.name,
  if (m.description != null) 'description': m.description,
  if (m.contextWindow != null) 'context_window': m.contextWindow,
  if (m.thinkingLevels != null)
    'thinking_levels': m.thinkingLevels!
        .map((l) => {'id': l.id, 'label': l.label})
        .toList(),
  if (m.defaultThinkingLevel != null)
    'default_thinking_level': m.defaultThinkingLevel,
};

/// Maps a [SandboxDetectionResult] to the `sandbox.detect` response wire shape.
///
/// The sandbox runs on the SERVER's machine, so this describes the HOST's
/// capabilities (detected OS, recommended backend, per-backend availability +
/// install hints) — a thin/web client renders these instead of probing its own
/// (on web: impossible) platform.
Map<String, dynamic> sandboxDetectionResultToWire(SandboxDetectionResult r) => {
  'platform': r.platform,
  'recommendation': r.recommendation.name,
  'capabilities': [
    for (final c in r.capabilities.values)
      {
        'backend': c.backend.name,
        'available': c.available,
        'requires_install': c.requiresInstall,
        if (c.installHint != null) 'install_hint': c.installHint,
        if (c.note != null) 'note': c.note,
      },
  ],
};

/// Maps an [ActiveProcessInfo] to the `process.detect` response wire shape.
Map<String, dynamic> activeProcessInfoToWire(ActiveProcessInfo p) => {
  'agent_name': p.agentName,
  'workspace_name': p.workspaceName,
  'pid': p.pid,
  'command': p.command,
  'start_time': p.startTime.toIso8601String(),
};

/// Maps a [DirectoryListing] to the `fs.browseDirectory` wire shape.
Map<String, dynamic> directoryListingToWire(DirectoryListing l) => {
  'path': l.path,
  'parent': l.parent,
  'is_git_repo': l.isGitRepo,
  'roots': l.roots,
  'entries': [
    for (final e in l.entries)
      {'name': e.name, 'path': e.path, 'is_git_repo': e.isGitRepo},
  ],
};

/// Reconstructs a [Repo] from a `RepoDto` wire map (inverse of [repoToWire]).
Repo repoFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return Repo(
    id: w['id'] as String,
    name: w['name'] as String? ?? '',
    path: w['path'] as String? ?? '',
    // An absent `forge` reads as GitHub, matching both `RepoDto` and the
    // column default. Falling back to `local` instead would make a repo look
    // like it has no forge at all, which reads downstream as "not configured".
    forge: w.containsKey('forge')
        ? ForgeHost.fromWire(w['forge'] as String?)
        : ForgeHost.github,
    remoteOwner: w['remote_owner'] as String? ?? '',
    remoteName: w['remote_name'] as String? ?? '',
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps a [Space] to the `SpaceDto` wire shape (mode as its db-string,
/// pipeline ownership + timestamps carried so a client can rebuild the entity).
Map<String, dynamic> spaceToWire(Space c) => {
  'id': c.id,
  'name': c.name,
  'workspace_id': c.workspaceId ?? '',
  'mode': c.mode.toDbValue(),
  'provisioning_status': c.provisioningStatus.toDbValue(),
  'provisioning_step': ?c.provisioningStep?.toDbValue(),
  'kind': c.kind.wire,
  'pipeline_run_id': ?c.pipelineRunId,
  'archived_at': ?c.archivedAt?.toIso8601String(),
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Maps a [Conversation] (message stream inside a space) to its wire shape.
Map<String, dynamic> conversationToWire(Conversation c) => {
  'id': c.id,
  'workspace_id': c.workspaceId ?? '',
  'space_id': c.spaceId,
  'title': c.title,
  'status': c.status.wire,
  'anchor_message_id': ?c.anchorMessageId,
  'created_by_principal_id': ?c.createdByPrincipalId,
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Serializes one thread rollup: what the feed needs to draw a "N replies"
/// row under the message a thread was branched from.
Map<String, dynamic> threadSummaryToWire(ThreadSummary t) => {
  'thread_id': t.threadId,
  'anchor_message_id': t.anchorMessageId,
  'title': t.title,
  'reply_count': t.replyCount,
  'last_reply_at': ?t.lastReplyAt?.toIso8601String(),
  'participant_ids': t.participantIds,
};

/// Serializes a space Notes doc row (PRD 16 §11).
Map<String, dynamic> spaceNoteToWire(SpaceNotesTableData n) => {
  'id': n.id,
  'workspace_id': n.workspaceId,
  'space_id': n.spaceId,
  'content': n.contentMarkdown,
  'updated_by': n.updatedByPrincipal,
  'updated_at': n.updatedAt.toIso8601String(),
  'version': n.version,
};

/// Redacts one transcript-segment JSON for a viewer without repo grants
/// (PRD 16 clarification: trace events referencing ungranted repo content
/// are filtered per-viewer AT THE SERVER). Structure survives — the viewer
/// sees WHAT happened (tool names, status, outcome); bodies (reasoning,
/// tool inputs/outputs, errors) are replaced, since they can embed file
/// contents from repos the viewer cannot open.
Map<String, dynamic> redactSegmentJson(Map<String, dynamic> seg) {
  const placeholder = '[restricted — you lack access to this repo]';
  final out = Map<String, dynamic>.of(seg);
  switch (seg['type']) {
    case 'tool':
      out['inputs'] = const <String, dynamic>{};
      out['outputs'] = placeholder;
    case 'text':
    case 'reasoning':
      if ((seg['text'] as String? ?? '').isNotEmpty) {
        out['text'] = placeholder;
      }
    case 'error':
      out['message'] = placeholder;
  }
  return out;
}

/// Redacts one update entry of a relay frame for a restricted viewer.
/// Deltas are suppressed (their text IS repo content); open/close segment
/// payloads are redacted; `finish` passes untouched.
Map<String, dynamic> _redactUpdateJson(Map<Object?, Object?> u) =>
    switch (u['t']) {
      'open' || 'close' => {
        ...u.cast<String, dynamic>(),
        if (u['seg'] is Map)
          'seg': redactSegmentJson((u['seg'] as Map).cast<String, dynamic>()),
      },
      'delta' => {...u.cast<String, dynamic>(), 'd': ''},
      _ => u.cast<String, dynamic>(),
    };

/// Reads [key] off [frame] as a list, tolerating a malformed value.
///
/// A cast would throw and a redaction path that throws fails the whole
/// subscription for the very viewer it exists to protect — degrade to empty.
List<Object?> _frameList(Map<String, dynamic> frame, String key) =>
    frame[key] is List ? frame[key] as List<Object?> : const [];

/// Redacts a run-activity relay frame (`agent_run_log.watchRunTranscript`) for a
/// restricted viewer. Same policy as [redactTurnFrame] over the run-scoped frame
/// shape, which carries one flat `segments` list instead of per-turn groups.
Map<String, dynamic> redactRunTranscriptFrame(Map<String, dynamic> frame) {
  switch (frame['kind']) {
    case 'seed':
      return {
        ...frame,
        'segments': [
          for (final seg in _frameList(frame, 'segments'))
            if (seg is Map) redactSegmentJson(seg.cast<String, dynamic>()),
        ],
      };
    case 'updates':
      return {
        ...frame,
        'updates': [
          for (final u in _frameList(frame, 'updates'))
            if (u is Map) _redactUpdateJson(u),
        ],
      };
    default:
      return frame;
  }
}

/// Presents a transcript left unfinalized by a crash as interrupted rather than
/// live: any tool segment still `running` gets the `interrupted` status.
///
/// A recording is finalized in the same code path that ends the run, so a
/// terminal run row next to `complete == false` means the process died mid-flush.
List<TranscriptSegment> normalizeInterrupted(
  List<TranscriptSegment> segments,
) => [
  for (final seg in segments)
    if (seg is ToolSegment && seg.status == ToolSegmentStatus.running)
      seg.copyWith(status: ToolSegmentStatus.interrupted)
    else
      seg,
];

/// Redacts a live turn-relay frame (`seed` snapshots + `updates` batches)
/// for a restricted viewer. Deltas are suppressed (their text IS repo
/// content); open/close segment payloads are redacted; `finish` passes.
Map<String, dynamic> redactTurnFrame(Map<String, dynamic> frame) {
  switch (frame['kind']) {
    case 'seed':
      return {
        ...frame,
        'turns': [
          for (final t in (frame['turns'] as List? ?? const []))
            if (t is Map)
              {
                ...t,
                'segments': [
                  for (final seg in (t['segments'] as List? ?? const []))
                    if (seg is Map)
                      redactSegmentJson(seg.cast<String, dynamic>()),
                ],
              },
        ],
      };
    case 'updates':
      return {
        ...frame,
        'updates': [
          for (final u in (frame['updates'] as List? ?? const []))
            if (u is Map)
              switch (u['t']) {
                'open' || 'close' => {
                  ...u,
                  if (u['seg'] is Map)
                    'seg': redactSegmentJson(
                      (u['seg'] as Map).cast<String, dynamic>(),
                    ),
                },
                'delta' => {...u, 'd': ''},
                _ => u.cast<String, dynamic>(),
              },
        ],
      };
    default:
      return frame;
  }
}

/// Serializes a message reaction row (PRD 16 §15).
Map<String, dynamic> reactionToWire(MessageReactionsTableData r) => {
  'id': r.id,
  'workspace_id': r.workspaceId,
  'space_id': r.spaceId,
  'message_id': r.messageId,
  'principal_id': r.principalId,
  'principal_type': r.principalType,
  'emoji': r.emoji,
  'created_at': r.createdAt.toIso8601String(),
};

/// Maps [Message] to `MessageDto` wire shape (parent/space ids + compacted).
///
/// List `messaging.watch*` passes `includeSegments: false`: elides the fat
/// `metadata['segments']` transcript (`segments_elided`); client pulls full
/// via `messaging.getMessageById` or the turn relay. One-shot reads keep full.
/// Elided rows carry `segment_count` so the feed can size rows before the
/// transcript lands (avoids scrollbar jump).
Map<String, dynamic> messageToWire(Message m, {bool includeSegments = true}) {
  var metadata = m.metadata;
  if (!includeSegments && metadata != null) {
    final segments = metadata['segments'];
    if (segments != null) {
      metadata = {
        ...metadata,
        'segments_elided': true,
        if (segments is List) 'segment_count': segments.length,
      }..remove('segments');
    }
  }
  return {
    'id': m.id,
    'content': m.content,
    'sender_id': m.senderId,
    'sender_type': m.senderType.name,
    'message_type': m.messageType.name,
    'metadata': metadata,
    'space_id': m.spaceId,
    'conversation_id': m.conversationId,
    'compacted': m.compacted,
    'created_at': m.createdAt.toIso8601String(),
  };
}

/// [messageToWire] in the lite list shape (`includeSegments: false`) — the
/// mapper every `messaging.watch*` list emission uses.
Map<String, dynamic> messageToWireLite(Message m) =>
    messageToWire(m, includeSegments: false);

/// Maps a [User] to the `UserDto` wire shape.
///
/// [includeOnboarding] is opt-in and belongs only to ops that return the
/// CALLER'S OWN user (`identity.me`, `users.updateProfile`). Whether someone
/// has finished first-run setup is their business, not directory data every
/// co-member receives, so `users.list` and the member rosters leave it off.
Map<String, dynamic> userToWire(User u, {bool includeOnboarding = false}) =>
    UserDto(
      id: u.id,
      handle: u.handle,
      displayName: u.displayName,
      email: u.email,
      avatarRef: u.avatarRef,
      gitAuthorName: u.gitAuthorName,
      gitAuthorEmail: u.gitAuthorEmail,
      onboardingFinishedAt: includeOnboarding ? u.onboardingFinishedAt : null,
      createdAt: u.createdAt,
    ).toJson();

/// Maps a [WorkspaceMember] to the `WorkspaceMemberDto` wire shape.
Map<String, dynamic> workspaceMemberToWire(WorkspaceMember m) =>
    WorkspaceMemberDto(
      id: m.id,
      workspaceId: m.workspaceId,
      userId: m.userId,
      role: m.role.wireName,
      // The raw stored value, so a client can show WHICH custom role a member
      // holds. `role` above stays the resolved preset for every existing
      // consumer.
      roleWire: m.roleWire,
      invitedBy: m.invitedBy,
      joinedAt: m.joinedAt,
      displayName: m.displayName,
      email: m.email,
      gitAuthorName: m.gitAuthorName,
      gitAuthorEmail: m.gitAuthorEmail,
    ).toJson();

/// Maps a [WorkspaceInvite] to the `WorkspaceInviteDto` wire shape (metadata
/// only — the one-time code is never re-derivable from this).
Map<String, dynamic> workspaceInviteToWire(WorkspaceInvite i) =>
    WorkspaceInviteDto(
      id: i.id,
      workspaceId: i.workspaceId,
      role: i.role.wireName,
      repoGrants: {
        for (final e in i.repoGrants.entries) e.key: e.value.wireName,
      },
      createdBy: i.createdBy,
      createdAt: i.createdAt,
      expiresAt: i.expiresAt,
      usedAt: i.usedAt,
      usedBy: i.usedBy,
      revokedAt: i.revokedAt,
    ).toJson();

/// Maps a [UserActivityEntry] to the `UserActivityDto` wire shape.
Map<String, dynamic> userActivityToWire(UserActivityEntry e) => UserActivityDto(
  id: e.id,
  workspaceId: e.workspaceId,
  userId: e.userId,
  action: e.action,
  targetType: e.targetType,
  targetId: e.targetId,
  deviceId: e.deviceId,
  ip: e.ip,
  countryCode: e.countryCode,
  details: e.details,
  createdAt: e.createdAt,
).toJson();

/// Maps a [SpaceParticipant] to the `SpaceParticipantDto` wire shape.
Map<String, dynamic> spaceParticipantToWire(SpaceParticipant p) => {
  'id': p.id,
  'space_id': p.spaceId,
  'principal_id': p.principalId,
  'participant_type': p.participantType.wireName,
  'role': p.role,
  'joined_at': p.joinedAt.toIso8601String(),
  'last_read_at': ?p.lastReadAt?.toIso8601String(),
};

/// Decodes the `dispatch.sendAndDispatch` `structured_mentions` arg (a list of
/// `{agent_id, raw}` maps) into [StructuredMention]s, dropping malformed
/// entries. Returns null when absent so the port's own default applies.
List<StructuredMention>? structuredMentionsFromWire(Object? raw) {
  if (raw is! List) {
    return null;
  }
  final out = <StructuredMention>[];
  for (final entry in raw) {
    if (entry is Map) {
      final agentId = entry['agent_id'];
      final mentionRaw = entry['raw'];
      if (agentId is String && mentionRaw is String) {
        out.add(StructuredMention(agentId: agentId, raw: mentionRaw));
      }
    }
  }
  return out;
}

/// Decodes the `dispatch.sendAndDispatch` `entity_refs` arg (a list of
/// [EntityRef] JSON maps) via [EntityRef.tryFromJson], dropping unrecognized
/// entries. Returns null when absent.
List<EntityRef>? entityRefsFromWire(Object? raw) {
  if (raw is! List) {
    return null;
  }
  final out = <EntityRef>[];
  for (final entry in raw) {
    if (entry is Map) {
      final ref = EntityRef.tryFromJson(entry.cast<String, dynamic>());
      if (ref != null) {
        out.add(ref);
      }
    }
  }
  return out;
}

/// Decodes `dispatch.sendAndDispatch` `metadata` to the one client-authored
/// key: `attachments`. Other metadata is server-written (forging risk).
/// Re-serialized through [MessageAttachment]; malformed entries dropped.
/// Null when nothing survives.
Map<String, dynamic>? userMessageMetadataFromWire(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final attachments = MessageAttachment.attachmentsFromMetadata(
    raw.cast<String, dynamic>(),
  );
  if (attachments.isEmpty) {
    return null;
  }
  return {
    'attachments': [for (final a in attachments) a.toJson()],
  };
}

/// Decodes the `dispatch.dispatchAgent` `wake_context` arg into a [WakeContext].
/// [WakeContext] carries no JSON (de)serializer, so the wire shape is mapped
/// inline here (and symmetrically on the client). Returns null when absent or
/// when the required `run_id`/`agent_id`/`workspace_id` fields are missing.
WakeContext? wakeContextFromWire(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final json = raw.cast<String, dynamic>();
  final runId = json['run_id'];
  final agentId = json['agent_id'];
  final workspaceId = json['workspace_id'];
  if (runId is! String || agentId is! String || workspaceId is! String) {
    return null;
  }
  final reasonName = json['wake_reason'] as String?;
  final wakeReason = WakeReason.values.firstWhere(
    (r) => r.name == reasonName,
    orElse: () => WakeReason.userMessage,
  );
  return WakeContext(
    runId: runId,
    agentId: agentId,
    workspaceId: workspaceId,
    wakeReason: wakeReason,
    ticketId: json['ticket_id'] as String?,
    spaceId: json['space_id'] as String?,
    messageId: json['message_id'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
  );
}

/// Maps a [PrDependencyDiff] to its wire shape.
///
/// The lockfile bodies never cross: only the computed delta does. A
/// `pnpm-lock.yaml` is routinely megabytes and the client has no use for it.
Map<String, dynamic> dependencyDiffToWire(PrDependencyDiff d) => {
  'id': d.id,
  'file_path': d.filePath,
  'ecosystem': d.ecosystem.wireName,
  if (d.baseSha != null) 'base_sha': d.baseSha,
  if (d.headSha != null) 'head_sha': d.headSha,
  'diff': d.diff.toJson(),
};

/// Ceiling on a logo served over the RPC channel.
///
/// The upload UI already caps a logo at 2 MB; this repeats the bound at the
/// read so a hand-edited `logo_path` pointing at something else cannot push an
/// arbitrary file through a JSON frame, where base64 inflates it by a third and
/// both ends buffer it whole.
const int kMaxLogoBytes = 2 * 1024 * 1024;

/// Sniffs an image's MIME type from its magic bytes.
///
/// Deliberately not the file EXTENSION the HTTP lane uses: the extension is
/// whatever the operator's file was called, while these bytes are what the
/// client has to decode. A logo saved as `.png` but actually JPEG is a
/// mislabel the browser would have to recover from.
String logoContentTypeOf(List<int> bytes) {
  bool startsWith(List<int> magic) {
    if (bytes.length < magic.length) {
      return false;
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) {
        return false;
      }
    }
    return true;
  }

  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) {
    return 'image/png';
  }
  if (startsWith(const [0xFF, 0xD8, 0xFF])) {
    return 'image/jpeg';
  }
  if (startsWith(const [0x47, 0x49, 0x46])) {
    return 'image/gif';
  }
  if (startsWith(const [0x52, 0x49, 0x46, 0x46])) {
    return 'image/webp';
  }
  return 'application/octet-stream';
}

/// Maps a [Workspace] to the `WorkspaceDto` wire shape (the richer shape needed
/// to rebuild the entity — list_workspaces returns only `{id, name}`).
Map<String, dynamic> workspaceToWire(Workspace w) => {
  'id': w.id,
  'name': w.name,
  'logo_path': ?w.logoPath,
  'owner_user_id': ?w.ownerUserId,
  'secret_exclude_globs': w.secretExcludeGlobs,
  'review_concurrency': w.reviewConcurrency,
  'auto_publish_review': w.autoPublishReview,
  'github_auth_mode': w.githubAuthMode.wireName,
  'github_app_id': w.githubAppId,
  'deleted_at': ?w.deletedAt?.toIso8601String(),
  'created_at': w.createdAt.toIso8601String(),
  'updated_at': w.updatedAt.toIso8601String(),
};

/// Reconstructs a [Workspace] from a `WorkspaceDto` wire map (the inverse of
/// [workspaceToWire]), used by the `workspace.upsert` op.
Workspace workspaceFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return Workspace(
    id: w['id'] as String,
    name: w['name'] as String? ?? '',
    logoPath: w['logo_path'] as String?,
    ownerUserId: w['owner_user_id'] as String?,
    secretExcludeGlobs:
        (w['secret_exclude_globs'] as List?)?.whereType<String>().toList() ??
        const [],
    reviewConcurrency: (w['review_concurrency'] as num?)?.toInt() ?? 3,
    autoPublishReview: w['auto_publish_review'] is bool
        ? w['auto_publish_review'] as bool
        : false,
    githubAuthMode: GithubAuthMode.fromWire(w['github_auth_mode'] as String?),
    githubAppId: w['github_app_id'] as String? ?? '',
    deletedAt: w['deleted_at'] is String
        ? DateTime.parse(w['deleted_at'] as String)
        : null,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps an [RssArticle] to the `ArticleDto` wire shape.
Map<String, dynamic> articleToWire(RssArticle a) => {
  'id': a.id,
  'feed_id': a.feedId,
  'title': a.title,
  'url': a.link,
  if (a.imageUrl.isNotEmpty) 'image_url': a.imageUrl,
  'summary': a.summary,
  if (a.author.isNotEmpty) 'author': a.author,
  if (a.publishedAt != null) 'published_at': a.publishedAt!.toIso8601String(),
  'is_read': a.read,
  'is_saved': a.saved,
};

/// Maps an [RssFeed] to its wire shape (the thin client's read-only feed row +
/// the per-feed status the newsfeed settings screen renders: enabled, last
/// fetch time, last error). Carries more than the lossy [FeedDto] so the client
/// can show fetch health, not just id/name/url.
Map<String, dynamic> feedToWire(RssFeed f) => {
  'id': f.id,
  'name': f.name,
  'url': f.url,
  'description': f.description,
  'icon_url': f.iconUrl,
  'user_agent': f.userAgent,
  'enabled': f.enabled,
  if (f.lastFetchedAt != null)
    'last_fetched_at': f.lastFetchedAt!.toIso8601String(),
  if (f.lastError != null) 'last_error': f.lastError,
};

/// Maps a [SkillSource] to its wire shape (the sources rail row + the sync
/// health the UI surfaces).
Map<String, dynamic> skillSourceToWire(SkillSource s) => {
  'id': s.id,
  'owner': s.owner,
  'repo': s.repo,
  'full_name': s.fullName,
  'url': s.url,
  'description': s.description,
  'default_branch': s.defaultBranch,
  'star_count': s.starCount,
  'skill_count': s.skillCount,
  'created_at': s.createdAt.toIso8601String(),
  if (s.lastSyncedAt != null)
    'last_synced_at': s.lastSyncedAt!.toIso8601String(),
  if (s.lastError != null) 'last_error': s.lastError,
};

/// The local install slug for a repo-relative `SKILL.md` path: the containing
/// directory's basename (the same derivation the source listings use). The
/// caller still validates the result as a slug before using it on disk.
String slugForSkillPath(String skillFilePath) {
  final slash = skillFilePath.lastIndexOf('/');
  if (slash == -1) {
    return 'skill';
  }
  final dir = skillFilePath.substring(0, slash);
  return dir.isEmpty ? 'skill' : dir.split('/').last;
}

/// Maps an [AgentWorkingMemory] to the `AgentWorkingMemoryDto` wire shape.
Map<String, dynamic> agentWorkingMemoryToWire(AgentWorkingMemory m) => {
  'id': m.id,
  'workspace_id': m.workspaceId,
  'agent_id': m.agentId,
  'content': m.content,
  'updated_at': m.updatedAt.toIso8601String(),
};

/// Reconstructs an [AgentWorkingMemory] from an `AgentWorkingMemoryDto` wire map
/// (the inverse of [agentWorkingMemoryToWire]), used by the
/// `agent_working_memory.upsert` op.
AgentWorkingMemory agentWorkingMemoryFromWire(Map<String, dynamic> w) =>
    AgentWorkingMemory(
      id: w['id'] as String,
      workspaceId: w['workspace_id'] as String? ?? '',
      agentId: w['agent_id'] as String? ?? '',
      content: w['content'] as String? ?? '',
      updatedAt: w['updated_at'] is String
          ? DateTime.parse(w['updated_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Maps a [MemoryPolicy] to the `MemoryPolicyDto` wire shape (`required_role`
/// as `.name`).
Map<String, dynamic> memoryPolicyToWire(MemoryPolicy p) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'domain': p.domain,
  'rule': p.rule,
  'source_fact_ids': p.sourceFactIds,
  'required_role': ?p.requiredRole?.name,
  'active': p.active,
  'created_at': p.createdAt.toIso8601String(),
  'updated_at': p.updatedAt.toIso8601String(),
};

/// Reconstructs a [MemoryPolicy] from a `MemoryPolicyDto` wire map (the inverse
/// of [memoryPolicyToWire]), used by the `memory_policy.upsert` op.
MemoryPolicy memoryPolicyFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return MemoryPolicy(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    domain: w['domain'] as String? ?? '',
    rule: w['rule'] as String? ?? '',
    sourceFactIds: ((w['source_fact_ids'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList(),
    requiredRole: w['required_role'] == null
        ? null
        : AgentRole.values.asNameMap()[w['required_role']],
    active: w['active'] as bool? ?? true,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps a [WorkspaceProviderPolicy] to the `ProviderPolicyDto` wire shape
/// (PRD 05 provider governance). The workspace is bound server-side, so the
/// client never reads `workspace_id` off a row; it is emitted empty.
Map<String, dynamic> providerPolicyToWire(WorkspaceProviderPolicy p) => {
  'id': p.id,
  'workspace_id': '',
  'action': p.statement.action,
  'resource': p.statement.resource,
  'effect': p.statement.effect.id,
  'layer': p.statement.layer.name,
};

/// Maps a cost summary to the `CostSummaryDto` wire shape (PRD 05 usage).
Map<String, dynamic> costSummaryToWire(CostSummary s) => {
  'total_usd': s.totalUsd,
  'request_count': s.requestCount,
  'window_start': s.windowStart.toIso8601String(),
  'next_reset_at': ?s.nextResetAt?.toIso8601String(),
  'by_provider': s.byProvider,
  'by_model': s.byModel,
};

/// Maps a [ReviewSpaceAssociation] to the `ReviewSpaceAssociationDto` wire
/// shape (enum `status` as `.name`).
Map<String, dynamic> reviewSpaceToWire(ReviewSpaceAssociation a) => {
  'id': a.id,
  'space_id': a.spaceId,
  'workspace_id': a.workspaceId,
  'pr_external_id': a.prExternalId,
  'pr_number': a.prNumber,
  'repo_full_name': a.repoFullName,
  'status': a.status.name,
  'created_at': a.createdAt.toIso8601String(),
  'updated_at': a.updatedAt.toIso8601String(),
};

/// Maps an [IsolatedRepo] to the `IsolatedRepoDto` wire shape (enum `backend`
/// as `.name`).
Map<String, dynamic> isolatedRepoToWire(IsolatedRepo r) => {
  'id': r.id,
  'workspace_id': r.workspaceId,
  'space_id': r.spaceId,
  'repo_id': r.repoId,
  'path': r.path,
  'branch': r.branch,
  'backend': r.backend.name,
  'source_path': r.sourcePath,
  'ticket_id': ?r.ticketId,
  'created_at': r.createdAt.toIso8601String(),
};

/// Reconstructs an [IsolatedRepo] from an `IsolatedRepoDto` wire map (the
/// inverse of [isolatedRepoToWire]), used by the `isolated_repo.upsert` op.
IsolatedRepo isolatedRepoFromWire(Map<String, dynamic> w) => IsolatedRepo(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  spaceId: w['space_id'] as String? ?? '',
  repoId: w['repo_id'] as String? ?? '',
  path: w['path'] as String? ?? '',
  branch: w['branch'] as String? ?? '',
  backend: RepoIsolationBackend.fromName(w['backend'] as String?),
  sourcePath: w['source_path'] as String? ?? '',
  ticketId: w['ticket_id'] as String?,
  createdAt: w['created_at'] is String
      ? DateTime.parse(w['created_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
);

/// Maps a [VoiceProfile] to the `VoiceProfileDto` wire shape.
Map<String, dynamic> voiceProfileToWire(VoiceProfile p) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'display_name': p.displayName,
  'embedding': p.embedding,
  'sample_count': p.sampleCount,
  'created_at': p.createdAt.toIso8601String(),
  'updated_at': p.updatedAt.toIso8601String(),
};

/// Reconstructs a [VoiceProfile] from a `VoiceProfileDto` wire map (the inverse
/// of [voiceProfileToWire]), used by the `voice_profile.upsert` op.
VoiceProfile voiceProfileFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return VoiceProfile(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    displayName: w['display_name'] as String? ?? '',
    embedding: ((w['embedding'] as List?) ?? const [])
        .map((e) => (e as num).toDouble())
        .toList(),
    sampleCount: (w['sample_count'] as num?)?.toInt() ?? 1,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

//
// Meetings are workspace-scoped at the repository. Enums travel as `.name`,
// timestamps as ISO-8601 and the speaker embedding as a raw `List<double>`.
// The reads/user-facing edits travel over RPC; the recorder-only writes
// (upsert/appendSegment/replace*) stay host-side, so only the wire SHAPES the
// thin client parses back are mapped here (entity → wire).

/// Maps a [Meeting] to its wire map (the inverse is [meetingFromWire]).
Map<String, dynamic> meetingToWire(Meeting m) => {
  'id': m.id,
  'workspace_id': m.workspaceId,
  'title': m.title,
  'status': m.status.name,
  'mode': m.mode.name,
  'source_app': ?m.sourceApp,
  'user_notes': m.userNotes,
  'enhanced_notes': ?m.enhancedNotes,
  'summary': ?m.summary,
  'summary_instructions': ?m.summaryInstructions,
  'audio_path': ?m.audioPath,
  'title_is_custom': m.titleIsCustom,
  'started_at': m.startedAt.toIso8601String(),
  'ended_at': ?m.endedAt?.toIso8601String(),
  'created_at': m.createdAt.toIso8601String(),
  'updated_at': m.updatedAt.toIso8601String(),
};

/// Reconstructs a [Meeting] from its wire map (the inverse of [meetingToWire]).
Meeting meetingFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return Meeting(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    title: w['title'] as String? ?? '',
    status: MeetingStatus.fromStorage(w['status'] as String?),
    mode: MeetingMode.fromStorage(w['mode'] as String?),
    sourceApp: w['source_app'] as String?,
    userNotes: w['user_notes'] as String? ?? '',
    enhancedNotes: w['enhanced_notes'] as String?,
    summary: w['summary'] as String?,
    summaryInstructions: w['summary_instructions'] as String?,
    audioPath: w['audio_path'] as String?,
    titleIsCustom: w['title_is_custom'] as bool? ?? false,
    startedAt: parse(w['started_at']),
    endedAt: w['ended_at'] is String
        ? DateTime.parse(w['ended_at'] as String)
        : null,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps a [MeetingSegment] to its wire map.
Map<String, dynamic> meetingSegmentToWire(MeetingSegment s) => {
  'id': s.id,
  'meeting_id': s.meetingId,
  'workspace_id': s.workspaceId,
  'speaker': s.speaker.name,
  'speaker_label': ?s.speakerLabel,
  'speaker_name_override': ?s.speakerNameOverride,
  'text': s.text,
  'start_ms': s.startMs,
  'end_ms': s.endMs,
  'created_at': s.createdAt.toIso8601String(),
};

/// Maps a [MeetingSpeakerLabel] to its wire map (embedding as a `List<double>`).
Map<String, dynamic> meetingSpeakerLabelToWire(MeetingSpeakerLabel s) => {
  'id': s.id,
  'meeting_id': s.meetingId,
  'workspace_id': s.workspaceId,
  'channel': s.channel.name,
  'label': s.label,
  'display_name': ?s.displayName,
  'embedding': ?s.embedding,
  'enrolled_profile_name': ?s.enrolledProfileName,
  'created_at': s.createdAt.toIso8601String(),
};

/// Maps a [MeetingActionItem] to its wire map.
Map<String, dynamic> meetingActionItemToWire(MeetingActionItem a) => {
  'id': a.id,
  'meeting_id': a.meetingId,
  'workspace_id': a.workspaceId,
  'content': a.content,
  'owner': ?a.owner,
  'done': a.done,
  'ticket_id': ?a.ticketId,
  'sort_order': a.sortOrder,
  'is_manual': a.isManual,
  'created_at': a.createdAt.toIso8601String(),
};

/// Reconstructs a [MeetingActionItem] from its wire map (the inverse of
/// [meetingActionItemToWire]), used by the `meeting.addActionItem` op.
MeetingActionItem meetingActionItemFromWire(Map<String, dynamic> w) =>
    MeetingActionItem(
      id: w['id'] as String,
      meetingId: w['meeting_id'] as String? ?? '',
      workspaceId: w['workspace_id'] as String? ?? '',
      content: w['content'] as String? ?? '',
      owner: w['owner'] as String?,
      done: w['done'] as bool? ?? false,
      ticketId: w['ticket_id'] as String?,
      sortOrder: (w['sort_order'] as num?)?.toInt() ?? 0,
      isManual: w['is_manual'] as bool? ?? false,
      createdAt: w['created_at'] is String
          ? DateTime.parse(w['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Maps a [MeetingDecision] to its wire map.
Map<String, dynamic> meetingDecisionToWire(MeetingDecision d) => {
  'id': d.id,
  'meeting_id': d.meetingId,
  'workspace_id': d.workspaceId,
  'content': d.content,
  'sort_order': d.sortOrder,
  'is_manual': d.isManual,
  'created_at': d.createdAt.toIso8601String(),
};

/// Reconstructs a [MeetingDecision] from its wire map (the inverse of
/// [meetingDecisionToWire]), used by the `meeting.addDecision` op.
MeetingDecision meetingDecisionFromWire(Map<String, dynamic> w) =>
    MeetingDecision(
      id: w['id'] as String,
      meetingId: w['meeting_id'] as String? ?? '',
      workspaceId: w['workspace_id'] as String? ?? '',
      content: w['content'] as String? ?? '',
      sortOrder: (w['sort_order'] as num?)?.toInt() ?? 0,
      isManual: w['is_manual'] as bool? ?? false,
      createdAt: w['created_at'] is String
          ? DateTime.parse(w['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Maps a `(meetingId → MeetingActionItemStats)` map to its wire object: a JSON
/// object keyed by meeting id whose values are `{total, done}`.
Map<String, dynamic> meetingActionItemStatsToWire(
  Map<String, MeetingActionItemStats> stats,
) => {
  for (final entry in stats.entries)
    entry.key: {'total': entry.value.total, 'done': entry.value.done},
};

//
// The calendar feature is workspace-scoped at the repository (the per-workspace
// Google account, not id uniqueness, is the isolation boundary). The thin
// client only READS this surface (synced events + connected accounts), so only
// the entity → wire direction is mapped here (mirrors the `CalendarEventDto`,
// `CalendarAttendeeDto`, `CalendarAccountDto` shapes in `cc_domain`). The
// per-shape maps carry NO `workspace_id` (the host binds it per session) and, by
// design, NO OAuth tokens (those live in the platform secure store, not the
// repository). Timestamps travel as ISO-8601.

/// Maps a [CalendarAttendee] to the `CalendarAttendeeDto` wire shape.
Map<String, dynamic> calendarAttendeeToWire(CalendarAttendee a) => {
  'email': a.email,
  'display_name': ?a.displayName,
  'response_status': ?a.responseStatus,
  'self': a.self,
  'organizer': a.organizer,
};

/// Whether a space's repo selection moved: `null` → every workspace repo,
/// `[]` → none, else those ids. Compared as a SET (order ignored).
/// `null` is never equal to a list — they disagree about future links.
bool spaceReposChanged(List<String>? before, List<String>? after) {
  if (before == null || after == null) {
    return (before == null) != (after == null);
  }
  final b = before.toSet();
  final a = after.toSet();
  return b.length != a.length || !b.containsAll(a);
}

/// Formats [d] as a bare `YYYY-MM-DD` civil date (its own calendar
/// components, no timezone conversion).
String isoCalendarDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Maps a [CalendarEvent] to the `CalendarEventDto` wire shape.
///
/// Timed events travel as ISO-8601 timestamps (instants). ALL-DAY events
/// travel as bare `YYYY-MM-DD` dates: an all-day event is a civil day, not an
/// instant — the host stores it as a HOST-local midnight, so emitting a
/// timestamp would let a client in another timezone shift it onto the wrong
/// day when it renders with `toLocal()`. A bare date parses as the CLIENT's
/// own local midnight, pinning the event to the same civil day everywhere.
Map<String, dynamic> calendarEventToWire(CalendarEvent e) => {
  'id': e.id,
  'account_id': e.accountId,
  'external_event_id': e.externalEventId,
  'calendar_id': e.calendarId,
  'title': e.title,
  'start_time': e.isAllDay
      ? isoCalendarDate(e.startTime)
      : e.startTime.toIso8601String(),
  'end_time': e.isAllDay
      ? isoCalendarDate(e.endTime)
      : e.endTime.toIso8601String(),
  'updated_at': e.updatedAt.toIso8601String(),
  'description': ?e.description,
  'location': ?e.location,
  'meeting_url': ?e.meetingUrl,
  'recurring_event_id': ?e.recurringEventId,
  'alerted_at': ?e.alertedAt?.toIso8601String(),
  'is_all_day': e.isAllDay,
  'status': e.status.toStorage(),
  'attendees': e.attendees.map(calendarAttendeeToWire).toList(),
};

/// Maps a [CalendarAccount] to the `CalendarAccountDto` wire shape (no OAuth
/// tokens — only the non-secret display/sync metadata).
Map<String, dynamic> calendarAccountToWire(CalendarAccount a) => {
  'id': a.id,
  'user_id': a.userId,
  'provider_id': a.providerId,
  'account_email': a.accountEmail,
  'display_name': ?a.displayName,
  'last_synced_at': ?a.lastSyncedAt?.toIso8601String(),
  'auth_expired_at': ?a.authExpiredAt?.toIso8601String(),
};

/// Maps a [CalendarSource] to the `CalendarSourceDto` wire shape — one of a
/// connected account's calendars (the sidebar's per-account list). Carries no
/// `workspace_id` (the host binds it per session); `account_id` is stamped
/// host→client so a viewer can group sources by owning account.
Map<String, dynamic> calendarSourceToWire(CalendarSource s) => {
  'account_id': s.accountId,
  'id': s.id,
  'summary': s.summary,
  'primary': s.primary,
  'writable': s.writable,
  'background_color': ?s.backgroundColor,
};

/// Coerces a wire arg to a `List<String>` (a JSON list of strings), dropping
/// non-string elements. Returns `const []` for a null/non-list arg.
List<String> stringListArg(Object? arg) =>
    (arg as List?)?.whereType<String>().toList() ?? const [];

//
// `PullRequests` is workspace-scoped. The wire shape stamps the AUTHORITATIVE
// `workspace_id` (host→client only — never accepted as a client arg) so the
// client can faithfully rebuild the (non-null-workspace) `PrGeneration` entity,
// including on the id-keyed `getById` path. The status travels as its plain
// name; timestamps are ISO-8601.

/// Maps a [PrGeneration] to the `PrGenerationDto` wire shape.
Map<String, dynamic> prGenerationToWire(PrGeneration p) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'status': p.status.name,
  'created_at': p.createdAt.toIso8601String(),
  'updated_at': p.updatedAt.toIso8601String(),
  'title': ?p.title,
  'body': ?p.body,
  'branch': ?p.branch,
};

//
// The `activity_log` table is workspace-scoped. The thin client only READS the
// audit trail for one entity, so only the entity → wire direction is mapped here
// (mirrors `ActivityEntryDto` in cc_domain). The wire shape carries NO
// `workspace_id` (the host binds it per session; the client refills it from the
// bound workspace it already holds). Timestamp travels as ISO-8601.

/// Maps an [ActivityEntry] to the `ActivityEntryDto` wire shape.
Map<String, dynamic> activityEntryToWire(ActivityEntry e) => {
  'id': e.id,
  'actor_type': e.actorType,
  'action': e.action,
  'entity_type': e.entityType,
  'created_at': e.createdAt.toIso8601String(),
  'actor_id': ?e.actorId,
  'entity_id': ?e.entityId,
  'details': ?e.details,
  'run_id': ?e.runId,
};

/// Maps a [Project] to the `ProjectDto` wire shape (enum fields as `.name`,
/// timestamps as ISO-8601).
Map<String, dynamic> projectToWire(Project p) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'name': p.name,
  'description': ?p.description,
  'color': p.color.toStorageString(),
  'status': p.status.toStorageString(),
  'created_at': p.createdAt.toIso8601String(),
  'updated_at': p.updatedAt.toIso8601String(),
};

/// Reconstructs a [Project] from a `ProjectDto` wire map (the inverse of
/// [projectToWire]), used by the `project.insert` / `project.update` ops.
Project projectFromWire(Map<String, dynamic> w) => Project(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  name: w['name'] as String? ?? '',
  description: w['description'] as String?,
  color: ProjectColor.fromStorage(w['color'] as String?),
  status: ProjectStatus.fromStorage(w['status'] as String?),
  createdAt: w['created_at'] is String
      ? DateTime.parse(w['created_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: w['updated_at'] is String
      ? DateTime.parse(w['updated_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
);

/// Maps a [TicketLink] to the `TicketLinkDto` wire shape. The `type` enum is
/// encoded as its stored snake_case string; `createdAt` is ISO-8601.
Map<String, dynamic> ticketLinkToWire(TicketLink l) => {
  'id': l.id,
  'workspace_id': l.workspaceId,
  'source_ticket_id': l.sourceTicketId,
  'target_ticket_id': l.targetTicketId,
  'type': l.type.toStorageString(),
  'created_at': l.createdAt.toIso8601String(),
};

/// Reconstructs a [TicketLink] from a `TicketLinkDto` wire map (the inverse of
/// [ticketLinkToWire]), used by the `ticket_link.insert` op.
TicketLink ticketLinkFromWire(Map<String, dynamic> w) => TicketLink(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  sourceTicketId: w['source_ticket_id'] as String? ?? '',
  targetTicketId: w['target_ticket_id'] as String? ?? '',
  type:
      TicketLinkType.fromStorage(w['type'] as String?) ??
      TicketLinkType.relatesTo,
  createdAt: DateTime.parse(w['created_at'] as String),
);

/// Maps a [PipelineRun] to the `PipelineRunDto` wire shape (enum `status` as
/// `.name`, timestamps as ISO-8601, `state`/`triggerPayload` as raw JSON maps).
Map<String, dynamic> pipelineRunToWire(PipelineRun r) => {
  'id': r.id,
  'template_id': r.templateId,
  'workspace_id': r.workspaceId,
  'status': r.status.name,
  'state': r.state,
  'trigger_event_type': ?r.triggerEventType,
  'trigger_payload': ?r.triggerPayload,
  'dedup_key': ?r.dedupKey,
  'started_at': r.startedAt.toIso8601String(),
  'attempt_started_at': ?r.attemptStartedAt?.toIso8601String(),
  'attempt_count': r.attemptCount,
  'finished_at': ?r.finishedAt?.toIso8601String(),
  'active_ms': r.activeMs,
  'last_resumed_at': ?r.lastResumedAt?.toIso8601String(),
  'error_message': ?r.errorMessage,
  'error_stack_trace': ?r.errorStackTrace,
  'parent_pipeline_run_id': ?r.parentPipelineRunId,
  'parent_step_id': ?r.parentStepId,
  'template_version': r.templateVersion,
  'total_cost_cents': r.totalCostCents,
  'total_tokens': r.totalTokens,
  'dry_run': r.dryRun,
};

/// Reconstructs a [PipelineRun] from a `PipelineRunDto` wire map (the inverse
/// of [pipelineRunToWire]), used by the `pipeline_run.insertRun`/`.updateRun`
/// ops.
PipelineRun pipelineRunFromWire(Map<String, dynamic> w) => PipelineRun(
  id: w['id'] as String,
  templateId: w['template_id'] as String? ?? '',
  workspaceId: w['workspace_id'] as String? ?? '',
  status: PipelineRunStatus.fromString(w['status'] as String? ?? 'pending'),
  state: w['state'] is Map
      ? (w['state'] as Map).cast<String, dynamic>()
      : <String, dynamic>{},
  triggerEventType: w['trigger_event_type'] as String?,
  triggerPayload: w['trigger_payload'] is Map
      ? (w['trigger_payload'] as Map).cast<String, dynamic>()
      : null,
  dedupKey: w['dedup_key'] as String?,
  startedAt: w['started_at'] is String
      ? DateTime.parse(w['started_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
  attemptStartedAt: w['attempt_started_at'] is String
      ? DateTime.parse(w['attempt_started_at'] as String)
      : null,
  // Absent from an older client's frame — a run nobody has re-run is on its
  // first attempt, which is what the default says.
  attemptCount: (w['attempt_count'] as num?)?.toInt() ?? 1,
  finishedAt: w['finished_at'] is String
      ? DateTime.parse(w['finished_at'] as String)
      : null,
  activeMs: (w['active_ms'] as num?)?.toInt() ?? 0,
  lastResumedAt: w['last_resumed_at'] is String
      ? DateTime.parse(w['last_resumed_at'] as String)
      : null,
  errorMessage: w['error_message'] as String?,
  errorStackTrace: w['error_stack_trace'] as String?,
  parentPipelineRunId: w['parent_pipeline_run_id'] as String?,
  parentStepId: w['parent_step_id'] as String?,
  templateVersion: (w['template_version'] as num?)?.toInt() ?? 1,
  totalCostCents: (w['total_cost_cents'] as num?)?.toInt() ?? 0,
  totalTokens: (w['total_tokens'] as num?)?.toInt() ?? 0,
  dryRun: w['dry_run'] as bool? ?? false,
);

/// Maps a [PipelineStepRun] to the `PipelineStepRunDto` wire shape (enum
/// `status` as `.name`, timestamps as ISO-8601).
Map<String, dynamic> pipelineStepRunToWire(PipelineStepRun s) => {
  'id': s.id,
  'pipeline_run_id': s.pipelineRunId,
  'step_id': s.stepId,
  'status': s.status.name,
  'input_json': ?s.inputJson,
  'output_json': ?s.outputJson,
  'space_id': ?s.spaceId,
  'error_message': ?s.errorMessage,
  'branch_index': ?s.branchIndex,
  'attempt_count': s.attemptCount,
  if (s.priorAttempts.isNotEmpty)
    'prior_attempts': [for (final a in s.priorAttempts) a.toJson()],
  'started_at': s.startedAt.toIso8601String(),
  'finished_at': ?s.finishedAt?.toIso8601String(),
};

/// Reconstructs a [PipelineStepRun] from a `PipelineStepRunDto` wire map (the
/// inverse of [pipelineStepRunToWire]), used by the
/// `pipeline_run.insertStepRun` op.
PipelineStepRun pipelineStepRunFromWire(Map<String, dynamic> w) =>
    PipelineStepRun(
      id: w['id'] as String,
      pipelineRunId: w['pipeline_run_id'] as String? ?? '',
      stepId: w['step_id'] as String? ?? '',
      status: PipelineStepStatus.fromString(
        w['status'] as String? ?? 'pending',
      ),
      inputJson: w['input_json'] as String?,
      outputJson: w['output_json'] as String?,
      spaceId: w['space_id'] as String?,
      errorMessage: w['error_message'] as String?,
      branchIndex: (w['branch_index'] as num?)?.toInt(),
      attemptCount: (w['attempt_count'] as num?)?.toInt() ?? 0,
      priorAttempts: [
        for (final a in (w['prior_attempts'] as List?) ?? const [])
          if (a is Map) PipelineStepAttempt.fromJson(a.cast<String, dynamic>()),
      ],
      startedAt: w['started_at'] is String
          ? DateTime.parse(w['started_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      finishedAt: w['finished_at'] is String
          ? DateTime.parse(w['finished_at'] as String)
          : null,
    );

/// Maps a [PipelineDefinition] to the `PipelineTemplateDto` wire shape. The
/// graph (`steps` with nested `triggers`/`config`) and declared `inputs`
/// serialize as inline maps; enum fields travel as `.name`.
Map<String, dynamic> pipelineTemplateToWire(PipelineDefinition d) => {
  'template_id': d.templateId,
  'workspace_id': d.workspaceId,
  'name': d.name,
  'description': ?d.description,
  'steps': d.steps.map(pipelineStepToWire).toList(),
  'inputs': d.inputs.map((i) => i.toJson()).toList(),
  'is_built_in': d.isBuiltIn,
  'is_enabled': d.isEnabled,
  'max_parallel_runs': ?d.maxParallelRuns,
  'version': d.version,
};

/// Maps a [PipelineStepDefinition] (one node in a [PipelineDefinition]) to its
/// wire map.
Map<String, dynamic> pipelineStepToWire(PipelineStepDefinition s) => {
  'id': s.id,
  'kind': s.kind.name,
  'bodyKey': s.bodyKey,
  if (s.triggers.isNotEmpty)
    'triggers': s.triggers.map(pipelineTriggerToWire).toList(),
  if (s.waitForStepIds.isNotEmpty) 'waitForStepIds': s.waitForStepIds,
  'config': s.config.toJson(),
  'x': ?s.x,
  'y': ?s.y,
};

/// Maps a [StepTrigger] (a step's inbound route within a pipeline) to its wire
/// map. Distinct from the [PipelineTrigger] entity (the trigger-node row).
Map<String, dynamic> pipelineTriggerToWire(StepTrigger t) => {
  'sourceStepIds': t.sourceStepIds,
  'routeKey': ?t.routeKey,
};

/// Reconstructs a [PipelineDefinition] from a `PipelineTemplateDto` wire map
/// (the inverse of [pipelineTemplateToWire]), used by the
/// `pipeline_template.upsert` op.
PipelineDefinition pipelineTemplateFromWire(Map<String, dynamic> w) {
  return PipelineDefinition(
    templateId: w['template_id'] as String,
    workspaceId: w['workspace_id'] as String,
    name: w['name'] as String? ?? '',
    description: w['description'] as String?,
    steps: ((w['steps'] as List?) ?? const [])
        .whereType<Map>()
        .map((s) => pipelineStepFromWire(s.cast<String, dynamic>()))
        .toList(),
    inputs: ((w['inputs'] as List?) ?? const [])
        .whereType<Map>()
        .map((i) => PipelineInput.fromJson(i.cast<String, dynamic>()))
        .toList(),
    isBuiltIn: w['is_built_in'] as bool? ?? false,
    isEnabled: w['is_enabled'] as bool? ?? true,
    maxParallelRuns: (w['max_parallel_runs'] as num?)?.toInt(),
    version: (w['version'] as num?)?.toInt() ?? 1,
  );
}

/// Reconstructs a [PipelineStepDefinition] from its wire map (the inverse of
/// [pipelineStepToWire]).
PipelineStepDefinition pipelineStepFromWire(Map<String, dynamic> s) {
  return PipelineStepDefinition(
    id: s['id'] as String,
    kind: StepKind.values.asNameMap()[s['kind'] as String?] ?? StepKind.listen,
    bodyKey: s['bodyKey'] as String,
    triggers: ((s['triggers'] as List?) ?? const [])
        .whereType<Map>()
        .map((t) => pipelineTriggerFromWire(t.cast<String, dynamic>()))
        .toList(),
    waitForStepIds: (s['waitForStepIds'] as List?)?.cast<String>() ?? const [],
    config: s['config'] is Map
        ? PipelineNodeConfig.fromJson(
            (s['config'] as Map).cast<String, dynamic>(),
          )
        : PipelineNodeConfig.empty,
    x: (s['x'] as num?)?.toDouble(),
    y: (s['y'] as num?)?.toDouble(),
  );
}

/// Reconstructs a [StepTrigger] from its wire map (the inverse of
/// [pipelineTriggerToWire]).
StepTrigger pipelineTriggerFromWire(Map<String, dynamic> t) {
  return StepTrigger(
    sourceStepIds: (t['sourceStepIds'] as List?)?.cast<String>() ?? const [],
    routeKey: t['routeKey'] as String?,
  );
}

/// Maps a [PipelineTrigger] to the `PipelineTriggerDto` wire shape (`match` as
/// a JSON object, timestamps as ISO-8601).
Map<String, dynamic> pipelineTriggerEntityToWire(PipelineTrigger t) => {
  'id': t.id,
  'event_type': t.eventType,
  'template_id': t.templateId,
  'workspace_id': t.workspaceId,
  'enabled': t.enabled,
  'cron_expression': ?t.cronExpression,
  'timezone': ?t.timezone,
  'next_run_at': ?t.nextRunAt?.toIso8601String(),
  'webhook_token': ?t.webhookToken,
  'event_filters': t.eventFilters,
  'match': t.match,
  'last_fired_at': ?t.lastFiredAt?.toIso8601String(),
  'catch_up_policy': t.catchUpPolicy.name,
  'created_at': t.createdAt.toIso8601String(),
};

/// Reconstructs a [PipelineTrigger] from a `PipelineTriggerDto` wire map (the
/// inverse of [pipelineTriggerEntityToWire]), used by the
/// `pipeline_trigger.insert` / `pipeline_trigger.update` ops.
PipelineTrigger pipelineTriggerEntityFromWire(Map<String, dynamic> w) {
  final match = w['match'];
  return PipelineTrigger(
    id: w['id'] as String,
    eventType: w['event_type'] as String? ?? '',
    templateId: w['template_id'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    enabled: w['enabled'] as bool? ?? false,
    cronExpression: w['cron_expression'] as String?,
    timezone: w['timezone'] as String?,
    nextRunAt: w['next_run_at'] is String
        ? DateTime.parse(w['next_run_at'] as String)
        : null,
    webhookToken: w['webhook_token'] as String?,
    eventFilters: w['event_filters'] is Map
        ? (w['event_filters'] as Map).cast<String, dynamic>()
        : const {},
    match: match is Map ? match.cast<String, dynamic>() : const {},
    lastFiredAt: w['last_fired_at'] is String
        ? DateTime.parse(w['last_fired_at'] as String)
        : null,
    catchUpPolicy: CronCatchUpPolicy.fromName(w['catch_up_policy'] as String?),
    createdAt: w['created_at'] is String
        ? DateTime.parse(w['created_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Maps a [TicketSyncConfig] to a read-only wire map for the sync-health
/// surface (§188). Secrets (`credentialRef`, `webhookSecret`) are intentionally
/// omitted — the client only needs identity + direction + enabled state.
Map<String, dynamic> ticketSyncConfigToWire(TicketSyncConfig c) => {
  'id': c.id,
  'workspace_id': c.workspaceId,
  'vendor': c.vendor,
  'vendor_project_id': c.vendorProjectId,
  'direction': c.direction.name,
  'enabled': c.enabled,
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Maps a [TicketSyncLogEntry] to its wire map (outcome/direction as `.name`).
Map<String, dynamic> ticketSyncLogToWire(TicketSyncLogEntry e) => {
  'id': e.id,
  'workspace_id': e.workspaceId,
  'ticket_id': ?e.ticketId,
  'vendor': e.vendor,
  'direction': e.direction.name,
  'outcome': e.outcome.name,
  'message': ?e.message,
  'created_at': e.createdAt.toIso8601String(),
};

/// Maps an [Orchestration] to the `OrchestrationDto` wire shape (proposal as
/// its canonical JSON string, status as `.name`, timestamps ISO-8601).
Map<String, dynamic> orchestrationToWire(Orchestration o) => {
  'id': o.id,
  'workspace_id': o.workspaceId,
  'proposal_json': o.proposal.toJsonString(),
  'parent_ticket_id': ?o.parentTicketId,
  'space_id': ?o.spaceId,
  'orchestrator_agent_id': ?o.orchestratorAgentId,
  'status': o.status.toStorageString(),
  'revision': o.revision,
  'approved_revision': ?o.approvedRevision,
  'pipeline_template_id': ?o.pipelineTemplateId,
  'pipeline_run_id': ?o.pipelineRunId,
  'team_id': ?o.teamId,
  'project_id': ?o.projectId,
  'estimated_cost_cents': ?o.estimatedCostCents,
  'max_cost_cents': ?o.maxCostCents,
  'hired_agent_ids': o.hiredAgentIds,
  'approved_node_keys': ?o.approvedNodeKeys,
  'error_message': ?o.errorMessage,
  'created_at': o.createdAt.toIso8601String(),
  'updated_at': o.updatedAt.toIso8601String(),
  'completed_at': ?o.completedAt?.toIso8601String(),
};

/// Reconstructs an [Orchestration] from an `OrchestrationDto` wire map (the
/// inverse of [orchestrationToWire]), used by the `orchestration.insert` /
/// `orchestration.update` ops.
Orchestration orchestrationFromWire(Map<String, dynamic> w) => Orchestration(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  proposal: OrchestrationProposal.fromJsonString(
    w['proposal_json'] as String? ?? '{}',
  ),
  parentTicketId: w['parent_ticket_id'] as String?,
  spaceId: w['space_id'] as String?,
  orchestratorAgentId: w['orchestrator_agent_id'] as String?,
  status: OrchestrationStatus.fromStorage(w['status'] as String?),
  revision: (w['revision'] as num?)?.toInt() ?? 1,
  approvedRevision: (w['approved_revision'] as num?)?.toInt(),
  pipelineTemplateId: w['pipeline_template_id'] as String?,
  pipelineRunId: w['pipeline_run_id'] as String?,
  teamId: w['team_id'] as String?,
  projectId: w['project_id'] as String?,
  estimatedCostCents: (w['estimated_cost_cents'] as num?)?.toInt(),
  maxCostCents: (w['max_cost_cents'] as num?)?.toInt(),
  hiredAgentIds:
      (w['hired_agent_ids'] as List?)?.whereType<String>().toList() ?? const [],
  approvedNodeKeys: (w['approved_node_keys'] as List?)
      ?.whereType<String>()
      .toList(),
  errorMessage: w['error_message'] as String?,
  createdAt: w['created_at'] is String
      ? DateTime.parse(w['created_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: w['updated_at'] is String
      ? DateTime.parse(w['updated_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0),
  completedAt: w['completed_at'] is String
      ? DateTime.parse(w['completed_at'] as String)
      : null,
);

/// Maps an [OrchestrationRevision] snapshot to its wire shape.
Map<String, dynamic> orchestrationRevisionToWire(OrchestrationRevision r) => {
  'id': r.id,
  'workspace_id': r.workspaceId,
  'orchestration_id': r.orchestrationId,
  'revision': r.revision,
  'proposal_json': r.proposal.toJsonString(),
  'authored_by': r.authoredBy,
  'author_kind': r.authorKind,
  'created_at': r.createdAt.toIso8601String(),
};

/// Maps a [PlanDocument] to its wire shape (body as canonical JSON string).
Map<String, dynamic> planDocumentToWire(PlanDocument d) => {
  'id': d.id,
  'workspace_id': d.workspaceId,
  'conversation_id': d.conversationId,
  'agent_id': d.agentId,
  'plan_json': d.bodyToJsonString(),
  'status': d.status.name,
  'revision': d.revision,
  'created_at': d.createdAt.toIso8601String(),
  'updated_at': d.updatedAt.toIso8601String(),
};

//
// The client had NO path to work products at all: the subsystem was complete
// server-side and unreachable, so an agent-published artifact could not be
// rendered. These are the bridge. Content travels as the raw revision string —
// the block envelope is parsed client-side by the same `cc_domain` codec the
// server validates with, so there is no second wire schema to drift.

/// Maps a [WorkProduct] to its wire shape.
Map<String, dynamic> workProductToWire(WorkProduct w) => {
  'id': w.id,
  'workspace_id': w.workspaceId,
  'title': w.title,
  'artifact_type': w.artifactType.name,
  'ticket_id': ?w.ticketId,
  'agent_id': ?w.agentId,
  'current_revision_id': ?w.currentRevisionId,
  'created_at': w.createdAt.toIso8601String(),
  'updated_at': w.updatedAt.toIso8601String(),
};

/// Maps a [WorkProductRevision] to its wire shape (content verbatim).
Map<String, dynamic> workProductRevisionToWire(WorkProductRevision r) => {
  'id': r.id,
  'work_product_id': r.workProductId,
  'workspace_id': r.workspaceId,
  'revision_number': r.revisionNumber,
  'content': r.content,
  'base_revision_id': ?r.baseRevisionId,
  'author_type': r.authorType,
  'author_id': ?r.authorId,
  'summary': ?r.summary,
  'created_at': r.createdAt.toIso8601String(),
};

/// Maps a [Playbook] to its wire shape.
Map<String, dynamic> playbookToWire(Playbook p) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'name': p.name,
  'description': p.description,
  'params_json': p.paramsToJsonString(),
  'source_proposal_json': p.sourceProposal.toJsonString(),
  'version': p.version,
  'created_at': p.createdAt.toIso8601String(),
  'updated_at': p.updatedAt.toIso8601String(),
};

//
// The PR-review surface is per-`(owner, repo)` rather than purely
// workspace-scoped: the host binds the workspace per session, but the GitHub
// coordinates travel in the op/watch args (a workspace reviews PRs across
// several repos). These map the `cc_domain` pr_review entities to the wire
// shapes the matching DTOs parse (`PullRequestDto`, `PrFileDto`, …). Read-only
// (entity → wire) — the client never sends entities back; PR mutations carry
// scalar args.

/// Maps a [PrUser] to the `PrUserDto` wire shape.
Map<String, dynamic> prUserToWire(PrUser u) => {
  'login': u.login,
  'avatar_url': u.avatarUrl,
  'name': ?u.name,
};

/// Maps a [PrLabel] to the `PrLabelDto` wire shape.
Map<String, dynamic> prLabelToWire(PrLabel l) => {
  'name': l.name,
  'color': l.color,
  if (l.description.isNotEmpty) 'description': l.description,
};

/// Maps a [ReactionGroup] to the `ReactionGroupDto` wire shape (the emoji is
/// derived client-side from `content`).
Map<String, dynamic> reactionGroupToWire(ReactionGroup g) => {
  'content': g.content,
  'count': g.count,
  'user_reacted': g.userReacted,
  'usernames': g.usernames,
};

/// Maps a [PullRequest] to the `PullRequestDto` wire shape (enum fields as
/// their `.name`/stored strings, timestamps ISO-8601, nested users/reactions).
Map<String, dynamic> pullRequestToWire(PullRequest pr) => {
  'id': pr.id,
  'number': pr.number,
  'title': pr.title,
  'body': pr.body,
  'state': pr.state.name,
  'is_draft': pr.isDraft,
  'repo_full_name': pr.repoFullName,
  'html_url': pr.htmlUrl,
  'author': ?(pr.author == null ? null : prUserToWire(pr.author!)),
  'created_at': ?pr.createdAt?.toIso8601String(),
  'updated_at': ?pr.updatedAt?.toIso8601String(),
  'merged_at': ?pr.mergedAt?.toIso8601String(),
  'external_id': pr.externalId,
  'head_sha': pr.headSha,
  'base_ref': pr.baseRef,
  'base_sha': pr.baseSha,
  'head_ref': pr.headRef,
  'requested_reviewers': pr.requestedReviewers.map(prUserToWire).toList(),
  'requested_team_slugs': pr.requestedTeamSlugs,
  'assignees': pr.assignees.map(prUserToWire).toList(),
  'labels': pr.labels.map(prLabelToWire).toList(),
  'reviewed_by_me': pr.reviewedByMe,
  'reactions': pr.reactions.map(reactionGroupToWire).toList(),
  'body_html': ?pr.bodyHtml,
  'changed_files': pr.changedFiles,
  'commits_count': pr.commitsCount,
  'additions': pr.additions,
  'deletions': pr.deletions,
  'comments_count': pr.commentsCount,
  'checks_status': pr.checksStatus.name,
  'mergeable_state': pr.mergeableState.name,
  'review_decision': pr.reviewDecision.name,
};

/// Maps a [PrStack] to the `PrStackDto` wire shape (timestamps ISO-8601,
/// entries bottom to top).
Map<String, dynamic> prStackToWire(PrStack stack) => {
  'id': stack.id,
  'number': stack.number,
  'external_id': stack.externalId,
  'url': stack.url,
  'base_ref': stack.baseRef,
  'open': stack.open,
  'created_at': ?stack.createdAt?.toIso8601String(),
  'pull_requests': [
    for (final e in stack.pullRequests)
      {
        'number': e.number,
        'state': e.state.name,
        'is_draft': e.isDraft,
        'head_ref': e.headRef,
        'head_sha': e.headSha,
        'merged_at': ?e.mergedAt?.toIso8601String(),
      },
  ],
};

/// Whether one open-PR wire map counts toward the "needs my review" badge for
/// [login] (expected already lowercased). Mirrors the inbox classifier's
/// `needsYourReview` rule (`prNeedsYourReview`): the review request must
/// name the operator or a team they belong to, drafts are not reviewable
/// yet and the operator's own PRs belong to the author-centric sections.
/// The badge must agree with the inbox — otherwise it counts rows the page
/// can never show (a draft requesting the operator lands in NO inbox
/// section).
bool prCountsTowardNeedsMyReview(
  Map<dynamic, dynamic> pr,
  String login, {
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  final author = pr['author'];
  final reviewers = (pr['requested_reviewers'] as List?) ?? const [];
  final teamSlugs = (pr['requested_team_slugs'] as List?) ?? const [];
  return prNeedsYourReview(
    isDraft: pr['is_draft'] == true,
    authorLogin: author is Map ? author['login'] as String? : null,
    viewerLogin: login,
    requestedUserLogins: [
      for (final r in reviewers)
        if (r is Map) (r['login'] as String?) ?? '',
    ].where((l) => l.isNotEmpty),
    requestedTeamSlugs: teamSlugs.whereType<String>(),
    repoFullName: pr['repo_full_name'] as String? ?? '',
    viewerTeamsByOrg: viewerTeamsByOrg,
  );
}

/// Maps a [PrFile] to the `PrFileDto` wire shape (`status` as `.name`,
/// `viewer_viewed_state` as its GraphQL wire name).
Map<String, dynamic> prFileToWire(PrFile f, {bool includePatch = true}) => {
  'filename': f.filename,
  'status': f.status.name,
  'additions': f.additions,
  'deletions': f.deletions,
  'patch': includePatch ? f.patch : '',
  'previous_filename': ?f.previousFilename,
  'viewer_viewed_state': f.viewerViewedState.wireName,
};

/// Maps a [PrCommit] to the `PrCommitDto` wire shape.
Map<String, dynamic> prCommitToWire(PrCommit c) => {
  'sha': c.sha,
  'message': c.message,
  'author': ?(c.author == null ? null : prUserToWire(c.author!)),
  'date': ?c.date?.toIso8601String(),
};

/// Maps a [PrReviewSubmission] to the `PrReviewSubmissionDto` wire shape.
Map<String, dynamic> prReviewSubmissionToWire(PrReviewSubmission r) => {
  'id': r.id,
  'state': r.state.name,
  'author': ?(r.author == null ? null : prUserToWire(r.author!)),
  'body': r.body,
  'submitted_at': ?r.submittedAt?.toIso8601String(),
  'reactions': [for (final g in r.reactions) reactionGroupToWire(g)],
};

/// Maps a [PrTimelineEvent] to the `PrTimelineEventDto` wire shape.
Map<String, dynamic> prTimelineEventToWire(PrTimelineEvent e) => {
  'kind': e.kind.name,
  'actor': ?(e.actor == null ? null : prUserToWire(e.actor!)),
  'reviewer_name': e.reviewerName,
  'reviewer_is_team': e.reviewerIsTeam,
  'reviewer_avatar_url': e.reviewerAvatarUrl,
  'label': ?(e.label == null ? null : prLabelToWire(e.label!)),
  'created_at': ?e.createdAt?.toIso8601String(),
};

/// Maps a [PrCodeReviewComment] to the `PrCodeReviewCommentDto` wire shape.
Map<String, dynamic> prCodeReviewCommentToWire(
  PrCodeReviewComment c, {
  bool includeHunk = true,
}) => {
  'id': c.id,
  'body': c.body,
  'path': c.path,
  'user': ?(c.user == null ? null : prUserToWire(c.user!)),
  'position': ?c.position,
  'created_at': ?c.createdAt?.toIso8601String(),
  'side': c.side,
  'in_reply_to_id': ?c.inReplyToId,
  'review_id': ?c.reviewId,
  'start_line': ?c.startLine,
  'diff_hunk': includeHunk ? c.diffHunk : '',
  'line': ?c.line,
  'original_line': ?c.originalLine,
  'thread_id': ?c.threadId,
  if (c.isResolved) 'is_resolved': true,
  'reactions': c.reactions.map(reactionGroupToWire).toList(),
};

/// Maps an [IssueComment] to the `IssueCommentDto` wire shape.
Map<String, dynamic> issueCommentToWire(IssueComment c) => {
  'id': c.id,
  'body': c.body,
  'user': ?(c.user == null ? null : prUserToWire(c.user!)),
  'created_at': ?c.createdAt?.toIso8601String(),
  'reactions': c.reactions.map(reactionGroupToWire).toList(),
};

/// Maps a [CheckRun] to the `CheckRunDto` wire shape (`status`/`conclusion` as
/// their `.name`s; the resolved parent workflow name rides along).
Map<String, dynamic> checkRunToWire(CheckRun c) => {
  'name': c.name,
  'status': c.status.name,
  'conclusion': ?c.conclusion?.name,
  'html_url': c.htmlUrl,
  'completed_at': ?c.completedAt?.toIso8601String(),
  'output': c.output,
  'workflow_name': ?c.workflowName,
  'check_suite_id': ?c.checkSuiteId,
  'job_id': ?c.jobId,
  'workflow_run_id': ?c.workflowRunId,
};

/// Maps a [JobRunStep] to the `JobRunStepDto` wire shape.
Map<String, dynamic> jobRunStepToWire(JobRunStep s) => {
  'number': s.number,
  'name': s.name,
  'status': s.status.name,
  'conclusion': ?s.conclusion?.name,
  'started_at': ?s.startedAt?.toIso8601String(),
  'completed_at': ?s.completedAt?.toIso8601String(),
};

/// Maps a [JobRunDetail] to the `JobRunDetailDto` wire shape.
Map<String, dynamic> jobRunDetailToWire(JobRunDetail d) => {
  'job_id': d.jobId,
  'status': d.status.name,
  'conclusion': ?d.conclusion?.name,
  'html_url': d.htmlUrl,
  'steps': d.steps.map(jobRunStepToWire).toList(),
  'logs': ?d.logs,
  'logs_truncated': d.logsTruncated,
};

/// Maps a [WorkflowJobNode] to the `WorkflowJobNodeDto` wire shape.
Map<String, dynamic> workflowJobNodeToWire(WorkflowJobNode n) => {
  'id': n.id,
  'name': n.name,
  'needs': n.needs,
};

/// Maps a [WorkflowGraph] to the `WorkflowGraphDto` wire shape.
Map<String, dynamic> workflowGraphToWire(WorkflowGraph g) => {
  'name': g.name,
  'jobs': g.jobs.map(workflowJobNodeToWire).toList(),
};

/// Maps a [CommitStatus] to the `CommitStatusDto` wire shape.
Map<String, dynamic> commitStatusToWire(CommitStatus s) => {
  'context': s.context,
  'state': s.state.name,
  'target_url': s.targetUrl,
  'description': s.description,
  'updated_at': ?s.updatedAt?.toIso8601String(),
};

/// Maps a [PrReviewer] (a user/team tagged union) to the `PrReviewerDto` wire
/// shape.
Map<String, dynamic> prReviewerToWire(PrReviewer r) {
  switch (r) {
    case PrUserReviewer():
      return {
        'kind': 'user',
        'is_code_owner': r.isCodeOwner,
        'state': r.state.name,
        'user': prUserToWire(r.user),
      };
    case PrTeamReviewer():
      return {
        'kind': 'team',
        'is_code_owner': r.isCodeOwner,
        'state': r.state.name,
        'name': r.name,
        'slug': r.slug,
        if (r.avatarUrl.isNotEmpty) 'avatar_url': r.avatarUrl,
        'reviewed_by': ?(r.reviewedBy == null
            ? null
            : prUserToWire(r.reviewedBy!)),
      };
  }
}

/// Maps a [PrReviewerCandidate] to the `PrReviewerCandidateDto` wire shape.
Map<String, dynamic> prReviewerCandidateToWire(PrReviewerCandidate c) => {
  'kind': c.kind == ReviewerKind.user ? 'user' : 'team',
  'key': c.key,
  'label': c.label,
  'avatar_url': ?c.avatarUrl,
};

/// Whether [error] is GitHub 422 because the inline comment anchor is outside
/// the PR diff (`pull_request_review_thread.path` / `.line`). Matched on that
/// field prefix (not message text). Other 422s stay failures.
bool isOutOfDiffAnchorRejection(Object error) {
  if (error is! NetworkException || error.statusCode != 422) {
    return false;
  }
  final body = error.responseBody;
  return body != null && body.contains('pull_request_review_thread.');
}

/// Fetches a lightweight PR preview (`{title, state, is_draft, is_merged,
/// html_url}` wire map) for `(owner, repo, number)`, or null when it can't be
/// resolved (404/network). Wired from the GitHub client by the composition
/// root; the catalog handles the SWR caching against the workspace cache.
typedef PrPreviewFetcher =
    Future<Map<String, dynamic>?> Function(
      String owner,
      String repo,
      int number,
    );

/// Fetches a lightweight commit preview (`{title, short_sha}` wire map) for
/// `(owner, repo, sha)`, or null when it can't be resolved.
typedef CommitPreviewFetcher =
    Future<Map<String, dynamic>?> Function(
      String owner,
      String repo,
      String sha,
    );

/// Fetches the open pull requests across a workspace's linked GitHub repos,
/// already enriched with checks and grouped per repo. Runs SERVER-SIDE on the
/// gh-authenticated GitHub client (the thin client holds no token); the
/// composition root wires it as a closure. Null when the server has no token —
/// `pr.listOpenForWorkspace` then reports `authenticated: false` so the client
/// shows a "connect GitHub on the server" state instead of an empty list.
typedef OpenPrListFetcher =
    Future<List<({Repo repo, List<PullRequest> prs, bool hasMore})>> Function(
      List<Repo> repos, {
      String? workspaceId,
    });

/// GitHub account for [actingUserId] (`{login, avatar_url, name}`), or null.
/// Who-am-I surfaces must name the session user (`RepoOpContext.userId`),
/// never a client-supplied id or a process-wide "server user".
typedef CurrentGitHubUserFetcher =
    Future<Map<String, dynamic>?> Function(String actingUserId);

/// [actingUserId]'s GitHub teams (org → slugs, already lower-cased), or null
/// when the lookup failed. Empty map = belongs to no teams. Drives
/// team-requested rows in Needs your review.
typedef ViewerGitHubTeamsFetcher =
    Future<Map<String, Set<String>>?> Function(String actingUserId);

/// Open PRs requesting [actingUserId]'s review across a workspace's linked
/// [repos] (the dashboard's priority reviews), grouped back to their [Repo].
/// Runs `review-requested:<their login>` on THEIR credential.
typedef ReviewRequestedFetcher =
    Future<List<({Repo repo, PullRequest pr})>> Function(
      List<Repo> repos,
      String actingUserId,
    );

/// The open PRs [actingUserId] has already reviewed across [repos], as
/// `"<owner/repo>#<number>"` keys (the PR list's "reviewed by me" overlay and
/// the inbox's "Waiting for author" section).
typedef ReviewedByFetcher =
    Future<Set<String>> Function(List<Repo> repos, String actingUserId);

/// Runs the PR-queue free-text search (the raw [query] string, parsed
/// server-side) across a workspace's linked [repos] on the SERVER's gh client,
/// grouped per repo.
typedef PrSearchFetcher =
    Future<List<({Repo repo, List<PullRequest> prs})>> Function(
      List<Repo> repos,
      String query,
    );

/// Counts the PRs authored by [login] across [repos] on the SERVER's gh client,
/// split into the profile rail's four buckets (open / draft / merged / closed).
typedef PrCountsByAuthorFetcher =
    Future<({int open, int draft, int merged, int closed})> Function(
      List<Repo> repos,
      String login,
    );

/// Fetches the public members of the GitHub orgs owning [owners] (resolved from
/// the bound workspace's repos) on the SERVER's gh client, as `GitHubUser` wire
/// maps (`{login, avatar_url, name}`).
typedef OrgMembersFetcher =
    Future<List<Map<String, dynamic>>> Function(List<String> owners);

/// Bundled SERVER-side GitHub read fetchers for the compose-PR / peek / profile
/// / pagination surfaces a thin client can no longer fetch itself (it holds no
/// gh token). Each runs on the host's gh client. The whole record is null when
/// the host has no gh token — those ops then degrade to empty results /
/// "connect GitHub on the server". Owner/repo args are validated against the
/// bound workspace's linked repos in the op handler BEFORE the fetch runs
/// (workspace isolation — a client cannot fan a query at a repo the bound
/// workspace doesn't own).
typedef GitHubReadFetchers = ({
  /// Branch names on `owner/repo`, ordered for the compose pickers (the server
  /// user's branches first, each group most-recent-commit first).
  Future<List<String>> Function(String owner, String repo) repoBranches,

  /// The default branch (e.g. `main`) of `owner/repo`.
  Future<String> Function(String owner, String repo) defaultBranch,

  /// The pull-request templates discovered in `owner/repo`.
  Future<List<({String name, String body, bool isDefault})>> Function(
    String owner,
    String repo,
  )
  prTemplates,

  /// The `base...head` comparison on `owner/repo`, or null when unresolvable.
  Future<
    ({
      List<PrFile> files,
      List<PrCommit> commits,
      int additions,
      int deletions,
      int totalCommits,
    })?
  >
  Function(String owner, String repo, String base, String head)
  compareBranches,

  /// A PR's description payload for the peek panel, or null when unresolvable.
  Future<({String body, String? bodyHtml, int changedFiles, int commitsCount})?>
  Function(String owner, String repo, int number)
  prContent,

  /// Issues/PRs in `owner/repo` matching `query` (the `#`-reference picker).
  Future<List<({int number, String title})>> Function(
    String owner,
    String repo,
    String query,
  )
  searchIssues,

  /// [actingUserId]'s own permission on `owner/repo` (admin/write/read/none),
  /// resolved on THEIR credential — the answer gates that person's merge/edit
  /// affordances, so the server's own access is the wrong thing to report.
  /// [workspaceId] selects that workspace's GitHub overlay token.
  Future<String> Function(
    String owner,
    String repo,
    String actingUserId, {
    String? workspaceId,
  })
  repoPermission,

  /// A GitHub user profile as a `GitHubUserProfile.toJson()` wire map, or null,
  /// read on [actingUserId]'s OWN credential. NOT workspace-scoped (keyed only
  /// by login).
  ///
  /// Per-user because part of the answer depends on who is asking: no GitHub
  /// App INSTALLATION token can read `organizations.nodes.teams`, so the
  /// no-caller lane — which resolves app identity first — got a FORBIDDEN
  /// "Resource not accessible by integration" on every hover. A user-to-server
  /// token reads the whole profile, orgs and teams included.
  Future<Map<String, dynamic>?> Function(String login, String actingUserId)
  userProfile,

  /// A GitHub team profile read on [actingUserId]'s own credential.
  Future<GitHubTeamProfile?> Function(
    String organization,
    String slug,
    String actingUserId,
  )
  teamProfile,

  /// Workspace-scoped PR activity for one or more GitHub authors.
  Future<GitHubProfileActivity> Function(
    List<Repo> repos,
    List<String> logins,
    String actingUserId,
  )
  profileActivity,

  /// A page of open PRs on `owner/repo` (the PR-list "load more").
  Future<({List<PullRequest> prs, bool hasMore})> Function(
    String owner,
    String repo,
    int page,
  )
  openPrPage,

  /// A page of `login`'s merged/closed PRs on `owner/repo` (profile "load
  /// more").
  Future<({List<PullRequest> prs, bool hasMore})> Function(
    String owner,
    String repo,
    String login,
    int page,
  )
  closedByAuthorPage,
});

/// Fetches the raw githubstatus.com `summary.json` map (the `github.serviceStatus`
/// op relays it for the thin client to parse with
/// `GitHubServiceStatus.fromSummaryJson`). Needs no gh token, so it is always
/// available — the browser just can't fetch githubstatus.com cross-origin.
typedef GitHubServiceStatusFetcher = Future<Map<String, dynamic>> Function();

/// Fetches the raw status.claude.com `summary.json` map (the
/// `claude.serviceStatus` op relays it for the thin client to parse with
/// `GitHubServiceStatus.fromSummaryJson` — same Statuspage v2 shape). Needs no
/// token, so it is always available.
typedef ClaudeServiceStatusFetcher = Future<Map<String, dynamic>> Function();

/// Fetches the raw status.openai.com `summary.json` map (the
/// `openai.serviceStatus` op relays it for the thin client to parse with
/// `GitHubServiceStatus.fromSummaryJson` — same Statuspage v2 shape). Needs no
/// token, so it is always available.
typedef OpenAIServiceStatusFetcher = Future<Map<String, dynamic>> Function();

/// Fetches the raw status.moonshot.cn `summary.json` map (the
/// `kimi.serviceStatus` op relays it for the thin client to parse with
/// `GitHubServiceStatus.fromSummaryJson` — same Statuspage v2 shape). Needs no
/// token, so it is always available.
typedef KimiServiceStatusFetcher = Future<Map<String, dynamic>> Function();

/// Fetches live subscription-usage quotas for the AI coding plans (Claude
/// Code, OpenAI Codex, Cursor, z.ai, Kimi Code) as `SubscriptionUsage` wire
/// maps, for the `subscriptions.usage` op behind the title-bar usage pill.
///
/// [accounts] is the shared multi-account input — one entry per connected
/// login, already refreshed. Claude Code accounts are merged in by the host
/// so every provider pages the same way. Null when the host wires no
/// fetcher → the op returns an empty list.
typedef SubscriptionUsageFetcher =
    Future<List<Map<String, dynamic>>> Function(
      List<SubscriptionUsageAccount> accounts,
    );

/// Fetches the 5h/weekly quota for ONE Claude Code account, by config dir.
///
/// Separate from [SubscriptionUsageFetcher] because it answers a different
/// question: that one reports the machine's overall usage for the title-bar
/// pill, this one reports a NAMED account's, so the picker can show the
/// operator which login still has headroom.
typedef ClaudeAccountUsageFetcher =
    Future<Map<String, dynamic>?> Function(String configDir);

/// Searches Klipy for GIFs matching a query (the composer's GIF picker), as
/// flat `GifResult` wire maps. Null when the host has no Klipy app key — the
/// `gif.search` op then returns no results.
typedef GifSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(String query);

/// Klipy's trending GIFs, as flat `GifResult` wire maps. Null when the host has
/// no Klipy app key — the `gif.trending` op then returns no results.
typedef GifTrendingFetcher = Future<List<Map<String, dynamic>>> Function();

/// Writes the connected user's RSVP ([responseStatus] = `accepted` /
/// `declined` / `tentative`) for the local calendar event [eventId] in
/// [workspaceId], SERVER-SIDE on the host's Google OAuth token. Backs the
/// `calendar.rsvp` op.
typedef CalendarRsvpFn =
    Future<void> Function({
      required String workspaceId,
      required String eventId,
      required String responseStatus,
    });

/// Triggers an immediate Google Calendar sync for [workspaceId] on the host
/// (the manual "refresh" button). Backs the `calendar.refreshNow` op.
typedef CalendarRefreshFn = Future<void> Function(String workspaceId);

/// Ensures events in `[from, to]` are loaded for [workspaceId] (the client
/// navigated outside the rolling sync window). Backs `calendar.ensureRangeLoaded`.
typedef CalendarEnsureRangeFn =
    Future<void> Function(String workspaceId, DateTime from, DateTime to);

/// Computes the uncommitted working-tree diff across a conversation's isolated
/// CoW worktrees, as a `List<PrFile>`. Wired from the composition root (it reads
/// the worktree registry + runs `git diff` on the SERVER's filesystem), so it is
/// only available on a host that owns those checkouts.
typedef ConversationChangesFetcher =
    Future<List<PrFile>> Function(String workspaceId, String spaceId);

/// Reverts a conversation to a message on the SERVER (undo): rolls back the
/// transcript (reverted messages are hidden but kept for unrevert) AND, when
/// the host can resolve the conversation's CoW worktree + per-turn git
/// snapshots, the filesystem to that turn's state. Returns the affected message
/// ids and whether the worktree was rolled back. Wired only by a host that owns
/// the DB + checkouts (the dispatch host); absent elsewhere, where the
/// `messaging.revertConversationTo` op falls back to a transcript-only revert.
typedef ConversationRevertFn =
    Future<({List<String> affectedMessageIds, bool filesystemRestored})>
    Function({
      required String workspaceId,
      required String spaceId,
      required String messageId,
      required bool inclusive,
    });

/// Undoes the most-recent revert (redo) on the SERVER — conversation-only (the
/// filesystem is NOT re-applied; the user can re-run the agent to regenerate
/// changes). Returns the restored message ids.
typedef ConversationUnrevertFn =
    Future<List<String>> Function({
      required String workspaceId,
      required String spaceId,
    });

/// Computes a linked repo's working-tree diff (vs HEAD, incl. untracked) WITH
/// patch hunks, as a `List<PrFile>`. Runs on the SERVER (owns the checkout) via
/// `git diff HEAD`. Workspace-scoped: the host must validate repo ownership.
typedef RepoChangesFetcher =
    Future<List<PrFile>> Function(
      String workspaceId,
      String repoId, {
      String? spaceId,
    });

/// Computes a repo's changes split into staged (index vs HEAD) and unstaged
/// (worktree vs index + untracked) buckets — the VS Code Source Control model.
///
/// `hasUpstream`, `ahead` and `behind` describe the branch against its
/// tracking ref, or against `origin/<branch>` when a push left that ref
/// without a tracking config. Only a branch the remote does not have falls
/// back to commits the remote default does not contain. `aheadOfBase` is
/// commits the default branch does not contain, which stays non-zero after
/// the branch is published and in sync with itself. Computed from local refs
/// only; a fetch is `worktree.syncBranch`.
typedef RepoChangesGroupedFetcher =
    Future<
      ({
        List<PrFile> staged,
        List<PrFile> unstaged,
        bool hasUpstream,
        int ahead,
        int behind,
        int aheadOfBase,
      })
    >
    Function(String workspaceId, String repoId, {String? spaceId});

/// Stages or unstages files in a conversation's isolated worktree index (`git
/// add` / `git reset HEAD`). Empty paths ⇒ all. Returns false when the space
/// owns no worktree for the repo.
typedef RepoStageMutator =
    Future<bool> Function(
      String workspaceId,
      String spaceId,
      String repoId,
      List<String> paths,
    );

/// Reads a file's bytes from a repo checkout on the SERVER — the conversation's
/// isolated CoW worktree when `spaceId` is given, else the linked checkout.
/// Returns the decoded text + a binary flag; rejects traversal outside the root.
typedef RepoFileContentFetcher =
    Future<({String content, bool binary})> Function(
      String workspaceId,
      String repoId,
      String path, {
      String? spaceId,
    });

/// Server-side fuzzy file search across a workspace's repo roots — the
/// conversation's isolated CoW worktrees when `spaceId` is given, else the
/// linked checkouts. Returns
/// raw wire maps (FileSearchHit fields + `repoId`) so cc_server_core stays free
/// of the cc_natives dependency — the client reconstructs `FileSearchHit`.
/// Pages through the ranked list: `offset` skips ahead and `limit` bounds the
/// page, so the cap bounds a response, never the reachable set.
typedef RepoFileSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String query, {
      int offset,
      int? limit,
      String? spaceId,
    });

/// One level of a repo checkout's directory tree, SERVER-SIDE, for the
/// IDE Explorer's lazy collapsible tree — the conversation's isolated CoW
/// worktree when `spaceId` is given, else the linked checkout.
/// Returns `{entries, has_more}` wire
/// maps (`relativePath` + `isDirectory` per entry) cursor-paginated in
/// repo-relative-path order: the client passes the last entry's `relativePath`
/// back as `cursor` and repeats until `has_more` is false, so a directory of
/// any size is fully enumerable without one giant response. A repo not linked to
/// the workspace is simply not found (empty page).
typedef RepoDirectoryListingFetcher =
    Future<Map<String, dynamic>> Function(
      String workspaceId,
      String repoId, {
      String path,
      String cursor,
      int? limit,
      String? spaceId,
    });

/// Server-side literal content search across a workspace's repo roots — the
/// conversation's isolated CoW worktrees when `spaceId` is given, else the
/// linked checkouts (the Explorer's "Content" mode). Returns raw wire maps
/// grouped per file —
/// `{repoId, relativePath, matches: [{line, text}]}` — so the client can render
/// VS Code-style grouped matches with highlighted lines. Empty query → empty.
typedef RepoContentSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String query, {
      Map<String, Object?> options,
      String? spaceId,
    });

/// Server-side literal/regex content search across ONE conversation's isolated
/// CoW worktree (e.g. the PR-head tree), backing the PR workbench sidebar's
/// "search in files" mode. Same grouped wire shape as [RepoContentSearchFetcher]
/// but scoped to a single `(spaceId, repoId)` worktree — the search never
/// leaks to the shared linked checkout. Empty query → empty; a foreign or
/// unprovisioned space → empty.
typedef WorktreeContentSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String spaceId,
      String repoId,
      String query, {
      Map<String, Object?> options,
    });

/// Server-side fuzzy file search across ONE conversation's isolated CoW
/// worktree (e.g. the PR-head tree), backing the PR workbench sidebar's file
/// finder. Same wire shape as [RepoFileSearchFetcher] (FileSearchHit fields +
/// `repoId`) but scoped to a single `(spaceId, repoId)` worktree — the finder
/// never leaks to the shared linked checkout. Pages exactly like it (offset +
/// limit); a foreign or unprovisioned space → empty.
typedef WorktreeFileSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String spaceId,
      String repoId,
      String query, {
      int offset,
      int? limit,
    });

/// Writes a draft file into a conversation's isolated worktree, SERVER-SIDE.
/// Backs the IDE's "untitled" draft save (⌘S). Returns `{repoId, path}` on
/// success or null when the space has no worktree for the repo / the path
/// escapes the worktree root / the payload is too large.
typedef WorktreeWriteFileFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      required String path,
      required String content,
    });

/// Reverts one or more working-tree files in a conversation's isolated
/// worktree to HEAD, SERVER-SIDE (tracked files only; untracked are skipped).
/// Returns `{repoId, reverted: int, skipped: List<String>}`, or null when the
/// space has no worktree for the repo.
typedef WorktreeRevertFilesFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      required List<String> paths,
    });

/// Reads a file from a conversation's isolated worktree (PR-head tree). Returns
/// null when the space has no worktree for the repo.
typedef WorktreeReadFileFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      required String path,
    });

/// Commits (and optionally pushes) changes in a conversation's isolated
/// worktree. Returns a result map ({committed, pushed, headSha?, error?}) or
/// null when the space has no worktree for the repo.
typedef WorktreeCommitAndPushFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      required String message,
      required List<String> paths,
      required bool push,
      bool amend,
      bool sync,
      String? pushBranch,
      String? authorName,
      String? authorEmail,
      String? actingUserId,
    });

/// Publishes a conversation worktree's branch to `origin` — a push only, no
/// commit. Returns a result map ({branch, headSha, pushed, uncommitted, error?})
/// or null when the space has no worktree for the repo.
typedef WorktreePublishBranchFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      String? branchOverride,
      String? actingUserId,
    });

/// VS Code's Sync for a conversation worktree: fetch the branch, rebase when
/// the remote moved, then push when this side is ahead or the branch has
/// never been published. Never commits. Returns
/// `{pulled, pushed, dirty, error?}` or null when the space has no worktree.
typedef WorktreeSyncBranchFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      String? actingUserId,
    });

/// Local branches, remote-tracking refs and tags in a conversation worktree.
/// Returns `{current, detached, refs}` or null when the space has no worktree.
typedef WorktreeListBranchesFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
    });

/// Checks a branch out in a conversation worktree, or creates one. Returns
/// `{ok, branch, detached, dirty, error?}` or null when the space has no
/// worktree. A detached checkout stores an empty branch.
typedef WorktreeCheckoutFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String spaceId,
      required String repoId,
      String? branch,
      String? startPoint,
      bool create,
      bool detach,
    });

/// Applies an orchestration action (approve / cancel) for `(workspaceId,
/// orchestrationId)`. Approving/cancelling hires agents + starts/cancels
/// pipelines via the concrete engine + use-cases, so it runs SERVER-SIDE; the
/// composition root wires it as a closure over the host's orchestration
/// use-cases. Only a host that owns the engine wires it (the desktop in-process
/// host); absent on a headless server.
typedef OrchestrationActionFn =
    Future<void> Function(String workspaceId, String orchestrationId);

/// Dispatches an agent to address PR-review findings in a space, executing
/// SERVER-SIDE (spawns a sandboxed agent process against the workspace's
/// on-disk checkout). The working directory is resolved by the host from the
/// bound `workspaceId` — it is NOT supplied by the client, so a thin client
/// cannot point the agent at an arbitrary server path. The composition root
/// wires this as a closure over the host's `AgentDispatchService`; only a host
/// that owns the dispatch stack wires it (the desktop in-process host), absent
/// on a headless server.
typedef ReviewDispatchFn =
    Future<void> Function({
      required String workspaceId,
      required String agentId,
      required String prompt,
      required String spaceId,
      // Optional parenthesis to run the fix in, so it doesn't clutter the
      // space's standing conversation. Null → the standing conversation.
      String? conversationId,
      // The session user the fix run executes for (commit co-author trailer +
      // per-user credential selection). Null attributes to the server owner.
      String? requestedByUserId,
    });

/// Sentinel scope id meaning "this remember has nowhere it may be written".
const String unscopedRemember = '\u0000none';

/// How long a standing approval lasts when the client names no window.
const int defaultRememberTtlSeconds = 8 * 60 * 60;

/// The hard ceiling on one. Longer than this is a policy decision, and policy
/// is written in the guardrail editor by an admin — not by answering a prompt.
const int maxRememberTtlSeconds = 7 * 24 * 60 * 60;

/// Maps a custom role to its wire shape.
Map<String, dynamic> roleDefinitionToWire(RoleDefinition role) => {
  'id': role.id,
  'name': role.name,
  'base_preset': role.basePreset.wireName,
  'denied_permissions': role.deniedPermissions.toList()..sort(),
  'wire': role.wire,
};

/// Maps one audit row to its wire shape.
///
/// The chain fields travel too: an export is only worth anything if the
/// recipient can re-derive the hashes themselves.
Map<String, dynamic> guardDecisionToWire(GuardDecision d) => {
  'id': d.id,
  'seq': d.seq,
  'occurred_at': d.occurredAt.toUtc().toIso8601String(),
  'actor_type': d.actorType,
  'actor_id': d.actorId,
  'on_behalf_of_user_id': ?d.onBehalfOfUserId,
  'delegation_chain_id': ?d.delegationChainId,
  'delegation_depth': ?d.delegationDepth,
  'space_id': ?d.spaceId,
  'run_id': ?d.runId,
  'device_id': ?d.deviceId,
  'ip': ?d.ip,
  'surface': d.surface.wire,
  'action_name': d.actionName,
  'action_classes': d.actionClasses,
  'permission': ?d.permission,
  'args_digest': ?d.argsDigest,
  'constraint_summary': ?d.constraintSummary,
  'decision': d.decision.wire,
  'enforcement': ?d.enforcement?.wire,
  'source_scope': ?d.sourceScope,
  'rule_id': ?d.ruleId,
  'prompted': d.prompted,
  'responder_user_id': ?d.responderUserId,
  'override_reason': ?d.overrideReason,
  'correlation_id': ?d.correlationId,
  'prev_hash': d.prevHash,
  'entry_hash': d.entryHash,
  'kind': d.kind,
};

/// Maps a paired-device row to the `pairing.*` wire shape. The PSK is NEVER
/// included — it is returned only once, by `pairing.mint` and otherwise lives
/// in the secrets store.
Map<String, dynamic> pairedDeviceToWire(
  PairedDevicesTableData d,
  String? workspaceName,
) => {
  'device_id': d.id,
  'label': d.label,
  'platform': d.platform,
  'status': d.status,
  'workspace_id': ?d.workspaceId,
  'workspace_name': ?workspaceName,
  'paired_at': d.pairedAt.toIso8601String(),
  'last_seen_at': ?d.lastSeenAt?.toIso8601String(),
  'remote_fingerprint': ?d.remoteFingerprint,
  'expires_at': ?d.expiresAt?.toIso8601String(),
};
