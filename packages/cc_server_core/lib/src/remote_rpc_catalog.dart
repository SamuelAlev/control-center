import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/activity_log_reader.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_domain/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/entities/workspace_health.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/meetings/meeting_audio_loader.dart';
import 'package:cc_infra/src/meetings/meeting_recording_session.dart';
import 'package:cc_persistence/database/app_database.dart'
    show PairedDevicesTableCompanion, PairedDevicesTableData;
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart'
    show PairedDeviceDao, PairedDeviceStatus;
import 'package:cc_rpc/cc_rpc.dart' show RemoteControlCrypto;
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// The repo-RPC + watch-query registries a server exposes to first-party
/// clients (desktop-remote / web). `ops` are request/response operations;
/// `watch` are reactive subscriptions.
typedef RemoteRpcCatalog = ({RepoOpRegistry ops, WatchQueryRegistry watch});

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
  'channel_id': ?t.channelId,
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
    channelId: w['channel_id'] as String?,
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
  'agent_id': c.agentId,
  'role': c.role.toStorageString(),
  'joined_at': c.joinedAt.toIso8601String(),
};

/// Rebuilds a [TicketCollaborator] from its wire shape (the inverse of
/// [collaboratorToWire]).
TicketCollaborator collaboratorFromWire(Map<String, dynamic> w) =>
    TicketCollaborator(
      id: w['id'] as String,
      ticketId: w['ticket_id'] as String,
      agentId: w['agent_id'] as String,
      role: TicketCollaboratorRole.fromStorage(w['role'] as String?),
      joinedAt: w['joined_at'] is String
          ? DateTime.parse(w['joined_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Loads [ticketId] and asserts it lives in [workspaceId] — the isolation
/// chokepoint for the ticket-id-keyed collaborator ops/subscription. The DAO
/// scopes collaborators by ticket id alone, so the id is not itself a boundary:
/// a foreign ticket is rejected loudly rather than leaking its collaborators.
Future<void> _assertTicketInWorkspace(
  TicketRepository repo,
  String ticketId,
  String? workspaceId,
) async {
  final ticket = await repo.getById(ticketId);
  if (ticket == null) {
    throw const NotFoundException('Ticket not found');
  }
  if (ticket.workspaceId != workspaceId) {
    throw const WorkspaceMismatchException(
      'Ticket belongs to a different workspace',
    );
  }
}

/// Streams a ticket's collaborators after verifying workspace ownership (see
/// [_assertTicketInWorkspace]). An `async*` generator so the ownership check
/// runs before any row is yielded.
Stream<Map<String, dynamic>> watchCollaboratorsScoped(
  TicketRepository repo,
  String? ticketId,
  String? workspaceId,
) async* {
  if (ticketId == null) {
    throw const NotFoundException('ticket_id is required');
  }
  await _assertTicketInWorkspace(repo, ticketId, workspaceId);
  yield* repo.watchCollaborators(ticketId).map(
    (list) => {'collaborators': list.map(collaboratorToWire).toList()},
  );
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
    createdAt: w['created_at'] is String
        ? DateTime.parse(w['created_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

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
    sourceObservationIds:
        ((w['source_observation_ids'] as List?) ?? const [])
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
  'channel_id': ?l.channelId,
  'started_at': l.startedAt.toIso8601String(),
  'completed_at': ?l.completedAt?.toIso8601String(),
  'status': l.status.name,
  'summary': ?l.summary,
  'adapter': ?l.adapter,
  'pid': ?l.pid,
  'log_path': ?l.logPath,
  'input_tokens': l.cost.inputTokens,
  'output_tokens': l.cost.outputTokens,
  'thought_tokens': l.cost.thoughtTokens,
  'cached_read_tokens': l.cost.cachedReadTokens,
  'cached_write_tokens': l.cost.cachedWriteTokens,
  'estimated_cost_cents': l.cost.estimatedCostCents,
  'duration_ms': ?l.cost.durationMs,
  'time_to_first_token_ms': ?l.cost.timeToFirstTokenMs,
  'liveness': ?l.liveness?.name,
  'error_family': ?l.errorFamily?.name,
  'last_output_at': ?l.lastOutputAt?.toIso8601String(),
  'continuation_summary': ?l.continuationSummary,
  'context_snapshot_json': ?l.contextSnapshotJson,
  'pipeline_run_id': ?l.pipelineRunId,
  'pipeline_step_run_id': ?l.pipelineStepRunId,
  'error_code': ?l.errorCode,
  'expected_output_schema': ?l.expectedOutputSchema,
  'output_contract_mode': l.outputContractMode.toStorageString(),
  'output_json': ?l.outputJson,
  'output_rejections': l.outputRejections,
  'retry_of_run_id': ?l.retry.parentRunId,
  'retry_attempt': l.retry.attempt,
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
    channelId: w['channel_id'] as String?,
    startedAt: w['started_at'] is String
        ? DateTime.parse(w['started_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
    completedAt: w['completed_at'] is String
        ? DateTime.parse(w['completed_at'] as String)
        : null,
    status: RunStatus.values.asNameMap()[w['status']] ?? RunStatus.pending,
    summary: w['summary'] as String?,
    adapter: w['adapter'] as String?,
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
    pipelineStepRunId: w['pipeline_step_run_id'] as String?,
    errorCode: w['error_code'] as String?,
    expectedOutputSchema: schema is Map
        ? schema.cast<String, dynamic>()
        : null,
    outputContractMode: OutputContractMode.fromStorage(
      w['output_contract_mode'] as String?,
    ),
    outputJson: output is Map ? output.cast<String, dynamic>() : null,
    outputRejections: (w['output_rejections'] as num?)?.toInt() ?? 0,
    retry: RetryMeta(
      parentRunId: w['retry_of_run_id'] as String?,
      attempt: (w['retry_attempt'] as num?)?.toInt() ?? 0,
    ),
  );
}

/// Maps a [Team] to the `TeamDto` wire shape (timestamp as ISO-8601).
Map<String, dynamic> teamToWire(Team t) => {
  'id': t.id,
  'workspace_id': t.workspaceId,
  'name': t.name,
  if (t.description != null) 'description': t.description,
  'created_at': t.createdAt.toIso8601String(),
};

/// Reconstructs a [Team] from a `TeamDto` wire map (the inverse of
/// [teamToWire]), used by the `team.insertTeam` / `team.updateTeam` ops.
Team teamFromWire(Map<String, dynamic> w) => Team(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  name: w['name'] as String? ?? '',
  description: w['description'] as String?,
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

/// Maps a channel read-cursor to the `ChannelReadDto` wire shape. The cursor is
/// a nullable ISO-8601 timestamp keyed by `channel_id`.
Map<String, dynamic> channelReadToWire(String channelId, DateTime? lastReadAt) =>
    {
      'channel_id': channelId,
      if (lastReadAt != null) 'last_read_at': lastReadAt.toIso8601String(),
    };

/// Reconstructs the cursor `DateTime?` from a `ChannelReadDto` wire map (the
/// inverse of [channelReadToWire]).
DateTime? channelReadFromWire(Map<String, dynamic> w) {
  final value = w['last_read_at'];
  return value is String ? DateTime.parse(value) : null;
}

/// Maps a [Repo] to the `RepoDto` wire shape.
Map<String, dynamic> repoToWire(Repo r) => {
  'id': r.id,
  'name': r.name,
  'path': r.path,
  'github_owner': r.githubOwner,
  'github_repo_name': r.githubRepoName,
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
  // by the client. Resolve it from the host's predefined catalog; fall back to
  // structuredCli when unknown (probing only needs id/name/cliName).
  final predefined = predefinedAdapters.where((a) => a.id == id).firstOrNull;
  return Adapter(
    id: id,
    name: w['name'] as String? ?? '',
    description: w['description'] as String? ?? '',
    cliName: w['cli_name'] as String? ?? '',
    transport: predefined?.transport ?? AdapterTransport.structuredCli,
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

/// Maps an [AcpModel] to the `acp.listModels` response wire shape.
Map<String, dynamic> acpModelToWire(AcpModel m) => {
  'id': m.id,
  'name': m.name,
  if (m.description != null) 'description': m.description,
  if (m.contextWindow != null) 'context_window': m.contextWindow,
  if (m.thinkingLevels != null)
    'thinking_levels':
        m.thinkingLevels!.map((l) => {'id': l.id, 'label': l.label}).toList(),
  if (m.defaultThinkingLevel != null)
    'default_thinking_level': m.defaultThinkingLevel,
};

/// Maps a [GitHubCliStatus] to the `github_cli.probe` response wire shape.
///
/// SECURITY: the resolved `gh` token is deliberately OMITTED — the host never
/// ships its machine's GitHub credentials to a (possibly remote) client. Only
/// the installed / authenticated / username display fields cross the wire.
Map<String, dynamic> githubCliStatusToWire(GitHubCliStatus s) => {
  'is_installed': s.isInstalled,
  'is_authenticated': s.isAuthenticated,
  'username': s.username,
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
    githubOwner: w['github_owner'] as String? ?? '',
    githubRepoName: w['github_repo_name'] as String? ?? '',
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps a [Channel] to the `ChannelDto` wire shape (mode as its db-string,
/// pipeline ownership + timestamps carried so a client can rebuild the entity).
Map<String, dynamic> channelToWire(Channel c) => {
  'id': c.id,
  'name': c.name,
  'is_dm': c.isDm,
  'workspace_id': c.workspaceId ?? '',
  'mode': c.mode.toDbValue(),
  'pipeline_run_id': ?c.pipelineRunId,
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Maps a [ChannelMessage] to the `MessageDto` wire shape (parent/channel ids +
/// compacted flag carried so the thread/timeline UI can rebuild the entity).
Map<String, dynamic> messageToWire(ChannelMessage m) => {
  'id': m.id,
  'content': m.content,
  'sender_id': m.senderId,
  'sender_type': m.senderType.name,
  'message_type': m.messageType.name,
  'metadata': m.metadata,
  'channel_id': m.channelId,
  'parent_message_id': ?m.parentMessageId,
  'compacted': m.compacted,
  'created_at': m.createdAt.toIso8601String(),
};

/// Maps a [ChannelParticipant] to the `ChannelParticipantDto` wire shape.
Map<String, dynamic> channelParticipantToWire(ChannelParticipant p) => {
  'id': p.id,
  'channel_id': p.channelId,
  'agent_id': p.agentId,
  'role': p.role,
  'joined_at': p.joinedAt.toIso8601String(),
  'last_read_at': ?p.lastReadAt?.toIso8601String(),
};

/// Decodes the `dispatch.sendAndDispatch` `structured_mentions` arg (a list of
/// `{agent_id, raw}` maps) into [StructuredMention]s, dropping malformed
/// entries. Returns null when absent so the port's own default applies.
List<StructuredMention>? _structuredMentionsFromWire(Object? raw) {
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
List<EntityRef>? _entityRefsFromWire(Object? raw) {
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

/// Decodes the `dispatch.dispatchAgent` `wake_context` arg into a [WakeContext].
/// [WakeContext] carries no JSON (de)serializer, so the wire shape is mapped
/// inline here (and symmetrically on the client). Returns null when absent or
/// when the required `run_id`/`agent_id`/`workspace_id` fields are missing.
WakeContext? _wakeContextFromWire(Object? raw) {
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
    channelId: json['channel_id'] as String?,
    messageId: json['message_id'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
  );
}

/// Maps a [Workspace] to the `WorkspaceDto` wire shape (the richer shape needed
/// to rebuild the entity — list_workspaces returns only `{id, name}`).
Map<String, dynamic> workspaceToWire(Workspace w) => {
  'id': w.id,
  'name': w.name,
  'logo_path': ?w.logoPath,
  'review_concurrency': w.reviewConcurrency,
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
    reviewConcurrency: (w['review_concurrency'] as num?)?.toInt() ?? 3,
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
    sourceFactIds:
        ((w['source_fact_ids'] as List?) ?? const [])
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

/// Maps a [ReviewChannelAssociation] to the `ReviewChannelAssociationDto` wire
/// shape (enum `status` as `.name`).
Map<String, dynamic> reviewChannelToWire(ReviewChannelAssociation a) => {
  'id': a.id,
  'channel_id': a.channelId,
  'workspace_id': a.workspaceId,
  'pr_node_id': a.prNodeId,
  'pr_number': a.prNumber,
  'repo_full_name': a.repoFullName,
  'status': a.status.name,
  'created_at': a.createdAt.toIso8601String(),
  'updated_at': a.updatedAt.toIso8601String(),
};

/// Reconstructs a [ReviewChannelAssociation] from a
/// `ReviewChannelAssociationDto` wire map (inverse of [reviewChannelToWire]).
ReviewChannelAssociation reviewChannelFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return ReviewChannelAssociation(
    id: w['id'] as String,
    channelId: w['channel_id'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    prNodeId: w['pr_node_id'] as String? ?? '',
    prNumber: (w['pr_number'] as num?)?.toInt() ?? 0,
    repoFullName: w['repo_full_name'] as String? ?? '',
    status:
        ReviewChannelStatus.values.asNameMap()[w['status']] ??
        ReviewChannelStatus.requested,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}


/// Maps an [IsolatedRepo] to the `IsolatedRepoDto` wire shape (enum `backend`
/// as `.name`).
Map<String, dynamic> isolatedRepoToWire(IsolatedRepo r) => {
  'id': r.id,
  'workspace_id': r.workspaceId,
  'channel_id': r.channelId,
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
  channelId: w['channel_id'] as String? ?? '',
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

// ---- Meetings wire helpers ----
//
// Meetings are workspace-scoped at the repository. Enums travel as `.name`,
// timestamps as ISO-8601, and the speaker embedding as a raw `List<double>`.
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

// ---- Analytics / achievements / streaks wire helpers ----
//
// The analytics cluster is workspace-scoped at the repository (every read JOINs
// Agents on the bound workspace). The thin client only READS this surface, so
// only the entity → wire direction is mapped here (mirrors the `AgentDailyStatsDto`,
// `AchievementDto`, `StreakDto`, `AgentScorecardDto`, `LeaderboardEntryDto`,
// `WorkspaceHealthDto` shapes in `cc_domain`). Timestamps travel as ISO-8601;
// the per-agent shapes carry no `workspace_id` (the host binds it per session).

/// Maps an [AgentDailyStats] to the `AgentDailyStatsDto` wire shape.
Map<String, dynamic> agentDailyStatsToWire(AgentDailyStats s) => {
  'id': s.id,
  'agent_id': s.agentId,
  'date': s.date.toIso8601String(),
  'runs_completed': s.runsCompleted,
  'runs_errored': s.runsErrored,
  'total_run_duration_ms': s.totalRunDurationMs,
  'prs_created': s.prsCreated,
  'prs_merged': s.prsMerged,
  'reviews_completed': s.reviewsCompleted,
  'blocking_comments': s.blockingComments,
  'lines_added': s.linesAdded,
  'lines_deleted': s.linesDeleted,
  'xp_earned': s.xpEarned,
  'created_at': s.createdAt.toIso8601String(),
};

/// Maps an [Achievement] to the `AchievementDto` wire shape.
Map<String, dynamic> achievementToWire(Achievement a) => {
  'id': a.id,
  'agent_id': a.agentId,
  'badge_key': a.badgeKey,
  'unlocked_at': a.unlockedAt.toIso8601String(),
  'metadata': ?a.metadata,
};

/// Maps a [Streak] to the `StreakDto` wire shape.
Map<String, dynamic> streakToWire(Streak s) => {
  'id': s.id,
  'agent_id': s.agentId,
  'streak_type': s.streakType,
  'current_count': s.currentCount,
  'best_count': s.bestCount,
  'last_date': ?s.lastDate?.toIso8601String(),
  'updated_at': s.updatedAt.toIso8601String(),
};

/// Maps an [AgentScorecard] to the `AgentScorecardDto` wire shape (nested
/// streaks/achievements travel as their own wire shapes).
Map<String, dynamic> agentScorecardToWire(AgentScorecard c) => {
  'agent_id': c.agentId,
  'agent_name': c.agentName,
  'total_runs': c.totalRuns,
  'total_errored': c.totalErrored,
  'success_rate': c.successRate,
  'avg_run_duration_ms': c.avgRunDurationMs,
  'total_prs_created': c.totalPrsCreated,
  'total_prs_merged': c.totalPrsMerged,
  'total_reviews': c.totalReviews,
  'total_blocking_comments': c.totalBlockingComments,
  'total_xp': c.totalXp,
  'level': c.level,
  'level_progress': c.levelProgress,
  'current_streaks': c.currentStreaks.map(streakToWire).toList(),
  'achievements': c.achievements.map(achievementToWire).toList(),
};

/// Maps a [LeaderboardEntry] to the `LeaderboardEntryDto` wire shape.
Map<String, dynamic> leaderboardEntryToWire(LeaderboardEntry e) => {
  'agent_id': e.agentId,
  'agent_name': e.agentName,
  'score': e.score,
  'rank': e.rank,
};

/// Maps a [WorkspaceHealth] to the `WorkspaceHealthDto` wire shape.
Map<String, dynamic> workspaceHealthToWire(WorkspaceHealth h) => {
  'workspace_id': h.workspaceId,
  'workspace_name': h.workspaceName,
  'score': h.score,
  'activity_score': h.activityScore,
  'throughput_score': h.throughputScore,
  'review_health_score': h.reviewHealthScore,
  'success_rate_score': h.successRateScore,
  'active_agents': h.activeAgents,
  'total_agents': h.totalAgents,
  'prs_merged_this_week': h.prsMergedThisWeek,
  'open_prs': h.openPRs,
  'stale_prs': h.stalePRs,
  'total_runs': h.totalRuns,
  'errored_runs': h.erroredRuns,
};

// ---- Calendar wire helpers ----
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

/// Maps a [CalendarEvent] to the `CalendarEventDto` wire shape.
Map<String, dynamic> calendarEventToWire(CalendarEvent e) => {
  'id': e.id,
  'account_id': e.accountId,
  'external_event_id': e.externalEventId,
  'calendar_id': e.calendarId,
  'title': e.title,
  'start_time': e.startTime.toIso8601String(),
  'end_time': e.endTime.toIso8601String(),
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

// ---- PR lifecycle wire helper ----
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

// ---- Activity-log wire helper ----
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
  'finished_at': ?r.finishedAt?.toIso8601String(),
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
  finishedAt: w['finished_at'] is String
      ? DateTime.parse(w['finished_at'] as String)
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
  'channel_id': ?s.channelId,
  'error_message': ?s.errorMessage,
  'branch_index': ?s.branchIndex,
  'attempt_count': s.attemptCount,
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
      status: PipelineStepStatus.fromString(w['status'] as String? ?? 'pending'),
      inputJson: w['input_json'] as String?,
      outputJson: w['output_json'] as String?,
      channelId: w['channel_id'] as String?,
      errorMessage: w['error_message'] as String?,
      branchIndex: (w['branch_index'] as num?)?.toInt(),
      attemptCount: (w['attempt_count'] as num?)?.toInt() ?? 0,
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
        ? PipelineNodeConfig.fromJson((s['config'] as Map).cast<String, dynamic>())
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
  'match': t.match,
  'last_fired_at': ?t.lastFiredAt?.toIso8601String(),
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
    match: match is Map ? match.cast<String, dynamic>() : const {},
    lastFiredAt: w['last_fired_at'] is String
        ? DateTime.parse(w['last_fired_at'] as String)
        : null,
    createdAt: w['created_at'] is String
        ? DateTime.parse(w['created_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Maps an [Orchestration] to the `OrchestrationDto` wire shape (proposal as
/// its canonical JSON string, status as `.name`, timestamps ISO-8601).
Map<String, dynamic> orchestrationToWire(Orchestration o) => {
  'id': o.id,
  'workspace_id': o.workspaceId,
  'proposal_json': o.proposal.toJsonString(),
  'parent_ticket_id': ?o.parentTicketId,
  'channel_id': ?o.channelId,
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
  channelId: w['channel_id'] as String?,
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
      (w['hired_agent_ids'] as List?)?.whereType<String>().toList() ??
      const [],
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

// ---- PR review wire helpers ----
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
  'node_id': pr.nodeId,
  'head_sha': pr.headSha,
  'base_ref': pr.baseRef,
  'base_sha': pr.baseSha,
  'head_ref': pr.headRef,
  'requested_reviewers': pr.requestedReviewers.map(prUserToWire).toList(),
  'assignees': pr.assignees.map(prUserToWire).toList(),
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
};

/// Maps a [PrFile] to the `PrFileDto` wire shape (`status` as `.name`,
/// `viewer_viewed_state` as its GraphQL wire name).
Map<String, dynamic> prFileToWire(PrFile f) => {
  'filename': f.filename,
  'status': f.status.name,
  'additions': f.additions,
  'deletions': f.deletions,
  'patch': f.patch,
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
  'state': r.state.name,
  'author': ?(r.author == null ? null : prUserToWire(r.author!)),
  'body': r.body,
};

/// Maps a [PrCodeReviewComment] to the `PrCodeReviewCommentDto` wire shape.
Map<String, dynamic> prCodeReviewCommentToWire(PrCodeReviewComment c) => {
  'id': c.id,
  'body': c.body,
  'path': c.path,
  'user': ?(c.user == null ? null : prUserToWire(c.user!)),
  'position': ?c.position,
  'created_at': ?c.createdAt?.toIso8601String(),
  'side': c.side,
  'in_reply_to_id': ?c.inReplyToId,
  'start_line': ?c.startLine,
  'diff_hunk': c.diffHunk,
  'line': ?c.line,
  'original_line': ?c.originalLine,
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
      List<Repo> repos,
    );

/// Returns the SERVER's authenticated GitHub user (`{login, avatar_url, name}`
/// wire map) or null. Lets a thin client resolve the current user (its `login`
/// drives review filters, attribution and the "review-requested:@me" dashboard)
/// without holding a token. Null when the server has no gh token.
typedef CurrentGitHubUserFetcher = Future<Map<String, dynamic>?> Function();

/// Searches the SERVER-side gh client for open PRs requesting the server user's
/// review across a workspace's linked [repos] (the dashboard's priority
/// reviews), grouped back to their [Repo]. Runs `review-requested:<server login>`.
typedef ReviewRequestedFetcher =
    Future<List<({Repo repo, PullRequest pr})>> Function(List<Repo> repos);

/// Searches the SERVER-side gh client for the open PRs the server user has
/// already reviewed across [repos], as `"<owner/repo>#<number>"` keys (the PR
/// list's "reviewed by me" overlay).
typedef ReviewedByFetcher = Future<Set<String>> Function(List<Repo> repos);

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

/// Fetches the merged/closed PRs authored by [login] across [repos] (first page
/// per repo) on the SERVER's gh client, grouped per repo.
typedef ClosedByAuthorFetcher =
    Future<List<({Repo repo, List<PullRequest> prs, bool hasMore})>> Function(
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
  Future<
    ({String body, String? bodyHtml, int changedFiles, int commitsCount})?
  >
  Function(String owner, String repo, int number)
  prContent,

  /// Issues/PRs in `owner/repo` matching `query` (the `#`-reference picker).
  Future<List<({int number, String title})>> Function(
    String owner,
    String repo,
    String query,
  )
  searchIssues,

  /// The server user's permission on `owner/repo` (admin/write/read/none).
  Future<String> Function(String owner, String repo) repoPermission,

  /// A public GitHub user profile as a `GitHubUserProfile.toJson()` wire map,
  /// or null. NOT workspace-scoped (public data, keyed only by login).
  Future<Map<String, dynamic>?> Function(String login) userProfile,

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
    Future<List<PrFile>> Function(String workspaceId, String channelId);

/// Computes a linked repo's working-tree diff (vs HEAD, incl. untracked) WITH
/// patch hunks, as a `List<PrFile>`. Runs on the SERVER (owns the checkout) via
/// `git diff HEAD`. Workspace-scoped: the host must validate repo ownership.
typedef RepoChangesFetcher =
    Future<List<PrFile>> Function(String workspaceId, String repoId);

/// Reads a file's bytes from a linked repo checkout on the SERVER. Returns the
/// decoded text + a binary flag; rejects traversal outside the repo root.
typedef RepoFileContentFetcher =
    Future<({String content, bool binary})> Function(
      String workspaceId,
      String repoId,
      String path,
    );

/// Server-side fuzzy file search across a workspace's linked repo roots. Returns
/// raw wire maps (FileSearchHit fields + `repoId`) so cc_server_core stays free
/// of the cc_natives dependency — the client reconstructs `FileSearchHit`. Empty
/// query yields the full cached entry tree; non-empty yields a scored list.
typedef RepoFileSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String query,
    );

/// Applies an orchestration action (approve / cancel) for `(workspaceId,
/// orchestrationId)`. Approving/cancelling hires agents + starts/cancels
/// pipelines via the concrete engine + use-cases, so it runs SERVER-SIDE; the
/// composition root wires it as a closure over the host's orchestration
/// use-cases. Only a host that owns the engine wires it (the desktop in-process
/// host); absent on a headless server.
typedef OrchestrationActionFn =
    Future<void> Function(String workspaceId, String orchestrationId);

/// Dispatches an agent to address PR-review findings in a channel, executing
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
      required String channelId,
    });

/// The four `models.<prefix>*` ops that expose one on-device model's lifecycle
/// over RPC, backed by a host-side [ModelControl].
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// every op is `workspaceScoped: false`. `<prefix>Status` returns the snapshot
/// wire map; each mutator (`install`/`cancel`/`uninstall`) applies the action
/// and returns the FRESH snapshot, so the thin client refreshes its UI without a
/// second round-trip — the same shape the desktop reads in-process.
List<RepoOp> modelControlOps({
  required String prefix,
  required ModelControl control,
}) {
  final capitalized = '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  return [
    RepoOp(
      name: 'models.${prefix}Status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => (await control.status()).toJson(),
    ),
    RepoOp(
      name: 'models.install$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await control.install();
        return (await control.status()).toJson();
      },
    ),
    RepoOp(
      name: 'models.cancel$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await control.cancel();
        return (await control.status()).toJson();
      },
    ),
    RepoOp(
      name: 'models.uninstall$capitalized',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await control.uninstall();
        return (await control.status()).toJson();
      },
    ),
  ];
}

/// The `models.watch<Prefix>` subscription that streams one on-device model's
/// lifecycle (status / progress / phase / error) as the SERVER downloads +
/// unpacks it, backed by a host-side [ModelControl].
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// `workspaceScoped: false`. Each emission is the snapshot wire map (the same
/// shape `models.<prefix>Status` returns); the thin client subscribes to animate
/// a live progress bar while the server does the work — the model-download
/// counterpart to `meeting.watchSegments`.
WatchQuery modelControlWatchQuery({
  required String prefix,
  required ModelControl control,
}) {
  final capitalized = '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  return WatchQuery(
    name: 'models.watch$capitalized',
    workspaceScoped: false,
    handler: (ctx) => control.watch().map((snapshot) => snapshot.toJson()),
  );
}

/// The two voice-only ops that expose the ASR model SELECTION over RPC, backed
/// by a host-side [SelectableModelControl]: `models.voiceCatalog` lists the
/// installable models + which is active, and `models.selectVoice` switches the
/// active one (returning the fresh status snapshot the now-selected model
/// reports, so the thin client refreshes its picker + status row without a
/// second round-trip).
///
/// Host-global (a model is a single device-local asset, not workspace data), so
/// both ops are `workspaceScoped: false`. Only voice is selectable — embedding &
/// diarization are single fixed models, so they wire only [modelControlOps].
/// These are added on top of the voice `modelControlOps` (status/install/…), so
/// a server that hosts a selectable voice control exposes the full surface.
List<RepoOp> voiceSelectionOps({required SelectableModelControl control}) {
  return [
    RepoOp(
      name: 'models.voiceCatalog',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => (await control.catalog()).toJson(),
    ),
    RepoOp(
      name: 'models.selectVoice',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: const ['model_id'],
      handler: (ctx) async {
        final modelId = ctx.args['model_id'] as String;
        return (await control.select(modelId)).toJson();
      },
    ),
  ];
}

/// Maps a paired-device row to the `pairing.*` wire shape. The PSK is NEVER
/// included — it is returned only once, by `pairing.mint`, and otherwise lives
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

/// Builds the live repo-RPC catalog from the real repositories/services — the
/// composition point that turns the protocol machinery into a concrete,
/// workspace-scoped surface covering tickets, messaging, and newsfeed.
///
/// Every workspace-scoped op/query sources its workspace from the session
/// binding, never from client args. Channels are workspace-scoped, but messages
/// are keyed only by `channel_id`, so message ops **validate channel ownership**
/// against the session's workspace before touching them — an ID-only lookup is
/// not a scoping boundary (workspace-isolation invariant). Newsfeed is global
/// (`workspaceScoped: false`), a declared exemption.
RemoteRpcCatalog buildRemoteRpcCatalog({
  required TicketRepository ticketRepository,
  required ProjectRepository projectRepository,
  required TicketWorkflowService ticketWorkflow,
  required MessagingRepository messagingRepository,
  required WorkspaceRepository workspaceRepository,
  required NewsfeedRepository newsfeedRepository,
  required AgentRepository agentRepository,
  required RepoRepository repoRepository,
  required ChannelReadRepository channelReadRepository,
  required MemoryDomainRepository memoryDomainRepository,
  required MemoryAccessGrantRepository memoryAccessGrantRepository,
  required AgentWorkingMemoryRepository agentWorkingMemoryRepository,
  required MemoryFactRepository memoryFactRepository,
  required MemoryPolicyRepository memoryPolicyRepository,
  required ReviewChannelRepository reviewChannelRepository,
  required AgentRunLogRepository agentRunLogRepository,
  required IsolatedRepoRepository isolatedRepoRepository,
  required VoiceProfileRepository voiceProfileRepository,
  required MeetingRepository meetingRepository,
  // ---- Meeting recording ingest (host runs the transcription stack) ----
  // Drives live, RPC-streamed meeting recording: a thin (web) client captures
  // mic + system audio in the browser and pushes 16 kHz PCM16 over
  // `meeting.startRecording` / `meeting.ingestAudio` / `meeting.stopRecording`;
  // this service transcribes on the host's Whisper stack and appends segments
  // the client watches via `meeting.watchSegments`. Optional: declared only on a
  // host that resolved a voice model (the desktop in-process host, or a headless
  // cc_server with a model installed). When null those three ops are absent
  // (default-deny) and the web recorder surfaces "recording unavailable".
  MeetingRecordingService? meetingRecording,
  required TicketLinkRepository ticketLinkRepository,
  required PipelineRunRepository pipelineRunRepository,
  required PipelineTemplateRepository pipelineTemplateRepository,
  required PipelineTriggerRepository pipelineTriggerRepository,
  required TeamRepository teamRepository,
  required OrchestrationRepository orchestrationRepository,
  // ---- Pairing management (the `pairing.*` ops) ----
  // Mint / list / rename / revoke paired devices so a first-party client (web
  // or desktop) can pair a phone that then dials THIS server directly. The PSK
  // is written to [pairedDeviceSecretsPort] (file on the headless server, OS
  // keychain on the desktop) and `pairing.mint` hands back [pairingServerUrl]
  // so the phone knows where to connect. These ops are `fullClient`-only (a
  // companion phone can never reach them). Paired devices are GLOBAL — a phone
  // spans all workspaces — so list/rename/revoke are `workspaceScoped: false`
  // (CROSS-WORKSPACE BY DESIGN); only `pairing.mint` is workspace-scoped (it
  // seeds the new device's initial workspace binding from the caller's).
  required PairedDeviceDao pairedDeviceDao,
  required PairedDeviceSecretsPort pairedDeviceSecretsPort,
  // The phone-reachable RPC WebSocket URL this server advertises in
  // `pairing.mint`. Empty when the host is not directly reachable (e.g. a
  // desktop that is not running its LAN WSS server) — the client then falls
  // back to WebRTC pairing instead of a direct-WS QR.
  required String pairingServerUrl,
  // The signaling broker (`wss://…`) advertised in `pairing.mint` for the relay
  // pairing path: when the server is not directly reachable from the phone, the
  // phone and cc_server rendezvous in a broker room (named by the device id) and
  // relay E2E-encrypted RPC. Empty disables advertising a relay endpoint. The
  // host's `RemoteRelayHost` watches the device table, so minting an `active`
  // phone is enough to make the server join the room — no callback needed here.
  String relaySignalingUrl = '',
  // ---- Analytics / achievements / streaks (workspace-scoped at the repo) ----
  // The thin client READS this surface only (scorecards, leaderboard, daily
  // stats, achievements, streaks, workspace health). The WRITE methods
  // (`AchievementRepository.unlock`, `StreakRepository.updateStreak`) are driven
  // server-side by the XpEngine reacting to `PrMerged` and are never reached
  // from a client, so no write ops are exposed here — only reads/watches.
  required AnalyticsRepository analyticsRepository,
  required AchievementRepository achievementRepository,
  required StreakRepository streakRepository,
  // ---- Calendar (workspace-scoped at the repo) ----
  // The thin client READS this surface (synced events + connected accounts) and
  // drives the GUI connect over [calendarConnect] (below). The sync reconciler,
  // token refresh, and alert sweep all run host-side against the host-resident
  // OAuth tokens + Google API client and are never reached from a client.
  required CalendarRepository calendarRepository,
  // Backs the GUI device-code connect (`calendar.beginConnect` /
  // `calendar.pollConnect` / `calendar.disconnect`): a thin (web/desktop) client
  // supplies a Google client id + secret, the host runs the device flow and
  // stores the refresh token server-side, then the host sync writes events the
  // client reads. Optional — when null those three ops are absent (default-deny)
  // and the connect form reports that the host owns calendar connection.
  CalendarConnectService? calendarConnect,
  // Backs the `calendar.rsvp` write: the host PATCHes the user's response to a
  // Google Calendar invitation on its own OAuth token (the thin client holds
  // none) and optimistically upserts the local event. Optional — null leaves
  // the op absent (the RSVP buttons report it is host-managed).
  CalendarRsvpFn? calendarRsvp,
  // Trigger an immediate sync / on-demand range load on the host (the thin
  // client holds no Google token, so the manual refresh + calendar navigation
  // drive the host's sync). Null leaves those ops as no-ops.
  CalendarRefreshFn? calendarRefresh,
  CalendarEnsureRangeFn? calendarEnsureRange,
  // ---- PR lifecycle (the local PR-draft → published → created record;
  // workspace-scoped at the `PullRequests` table) ----
  // The thin client BOTH reads (the compose-PR draft list + a draft by id) AND
  // writes (create / update / publish-to-GitHub / delete a draft) this surface
  // over RPC. Every op sources `ctx.workspaceId!`; the id-keyed ops validate the
  // row belongs to the bound workspace before mutating. Publishing runs against
  // the HOST-resident GitHub token (the desktop in-process host holds one; a
  // headless server's token-less client surfaces the GitHub failure, matching the
  // existing PR-review server-token follow-up).
  required PrLifecycleRepository prLifecycleRepository,
  // The audit trail for one entity (the `activity_log` table; workspace-scoped).
  // Optional: when null the `activity.watchForEntity` subscription is simply
  // absent (default-deny) and a client's entity-timeline view degrades to empty.
  // Wired on hosts that own the Drift `activity_log` DAO (the desktop in-process
  // host + the headless cc_server).
  ActivityLogReader? activityLogReader,
  // ---- PR review (per-(workspace, owner, repo); host binds the workspace) ----
  // The factory builds a (stateful, cache-backed) PrReviewRepository for a
  // given repo; the catalog caches one instance per (workspace, owner, repo)
  // so the SWR disk cache it owns survives across calls. Optional: when null
  // the pr_review.* ops/watches surface an empty repository (e.g. the headless
  // server has no GitHub token yet — see the server-side-token follow-up).
  VcsProviderFactory? vcsProviderFactory,
  PrPreviewFetcher? fetchPrPreview,
  CommitPreviewFetcher? fetchCommitPreview,
  // Fetches the workspace's open PRs across its linked GitHub repos (the PR-list
  // screen's data) on the SERVER's gh-authenticated client. Optional: when null
  // the `pr.listOpenForWorkspace` op reports `authenticated: false`.
  OpenPrListFetcher? fetchOpenPrList,
  // The SERVER's authenticated GitHub user (drives `github.currentUser`). Null
  // when the server holds no gh token → the op returns a null user.
  CurrentGitHubUserFetcher? fetchCurrentGitHubUser,
  // The dashboard's "review-requested:@me" PRs (server-side gh search). Null →
  // `pr.searchReviewRequestedForWorkspace` returns an empty list.
  ReviewRequestedFetcher? fetchReviewRequested,
  // The PR-list "reviewed by me" key set (server-side gh search). Null →
  // `pr.searchReviewedByForWorkspace` returns an empty set.
  ReviewedByFetcher? fetchReviewedBy,
  // PR-queue free-text search (server-side gh search). Null → empty results.
  PrSearchFetcher? fetchPrSearch,
  // Per-author PR counts for the profile rail. Null → all-zero counts.
  PrCountsByAuthorFetcher? fetchPrCountsByAuthor,
  // Per-author merged/closed PR history (first page). Null → empty.
  ClosedByAuthorFetcher? fetchClosedByAuthor,
  // GitHub org members (profile people picker). Null → empty.
  OrgMembersFetcher? fetchOrgMembers,
  // Bundled GitHub read fetchers for compose-PR / peek / profile / pagination
  // (server-side gh client). Null (no gh token) → those ops degrade to empty.
  GitHubReadFetchers? githubRead,
  // Fetches the raw githubstatus.com summary for `github.serviceStatus`. Needs
  // no token; null only when the host wires no status fetcher → null summary.
  GitHubServiceStatusFetcher? fetchGitHubServiceStatus,
  // Klipy GIF search / trending for the composer's GIF picker. Null (no Klipy
  // app key) → the `gif.*` ops return empty.
  GifSearchFetcher? gifSearch,
  GifTrendingFetcher? gifTrending,
  // The workspace-scoped cache backing the SWR PR/commit reference previews.
  // Optional: when null, previews skip caching and hit the fetcher directly.
  CacheDao? prPreviewCache,
  // ---- Server-host capabilities (device-local to the server that hosts this
  // catalog) ----
  // Inspecting + registering a repo runs `git` on the SERVER's filesystem, so
  // the op is declared only when the host wires a [GitRepoInspectorPort]
  // (desktop in-process host / headless cc_server). When null, `repos.addFromPath`
  // is simply absent (default-deny) and the client surfaces it as unavailable.
  GitRepoInspectorPort? gitRepoInspector,
  // Browses the SERVER's filesystem (scoped to allow-listed roots) so a thin/web
  // client — which has no local filesystem and so cannot offer a native folder
  // picker — can navigate the host's directories and pick a git checkout to
  // register via `repos.addFromPath`. Declared only when the host wires a
  // [DirectoryBrowserPort] (desktop in-process host / headless cc_server). When
  // null the `fs.browseDirectory` op is absent (default-deny) and the web
  // add-repo form falls back to a typed path. Not workspace data — the filesystem
  // is host-global; the repo is scoped to the bound workspace at registration.
  DirectoryBrowserPort? directoryBrowser,
  // Detects the agent-runner CLIs installed on the SERVER's machine (`which`,
  // `--version`) for Settings → Adapters. Host-local capability (not workspace
  // data), so `adapter.detectOne` / `adapter.detectAll` are declared
  // `workspaceScoped: false`. Declared only when the host wires the detector
  // (desktop in-process host / headless cc_server — both link cc_infra); when
  // null the ops are absent (default-deny) and the thin client degrades each
  // probe to "not found".
  AdapterRepository? adapterDetection,
  // Lists the models an adapter advertises, resolved on the SERVER (the host
  // owns the adapter CLIs / curated list). Host-local capability, so
  // `acp.listModels` is `workspaceScoped: false`. Absent when null → the thin
  // client gets an empty model list.
  AcpModelRepository? acpModels,
  // Probes the `gh` CLI on the SERVER (`gh auth status`) for the auth/settings
  // status display. Host-local capability, so `github_cli.probe` is
  // `workspaceScoped: false`. SECURITY: the op NEVER returns the host's resolved
  // `gh` token (see [githubCliStatusToWire]) — a remote client must not receive
  // the host machine's GitHub credentials. Absent when null → "not installed".
  GitHubCliPort? githubCli,
  // Detects the OS-native sandbox capabilities of the SERVER's machine (which
  // backends are available + the recommended one) for the Settings → Sandboxing
  // page. The sandbox runs on the host, so detection is a host-local capability
  // (not workspace data) → `sandbox.detect` is `workspaceScoped: false`.
  // Declared only when the host wires the detector (desktop in-process host /
  // headless cc_server — both link cc_infra); when null the op is absent
  // (default-deny) and the thin client degrades to a "No isolation only" result.
  SandboxDetectorPort? sandboxDetector,
  // Detects the agent processes running in the SERVER's OS process table (the
  // dashboard's "active processes" matrix) and stops one by pid. The process
  // table is host-global and the detection spans every workspace's agents (the
  // dashboard's cross-workspace overview), so `process.detect` / `process.kill`
  // are CROSS-WORKSPACE BY DESIGN (`workspaceScoped: false`). Killing a host
  // process is privileged, so both ops are `fullClient`-only (a companion phone
  // is denied). Absent when null → the client sees an empty process list.
  ProcessDetectionPort? processDetection,
  // Lets server-host capability ops publish domain events (e.g. `RepoAdded`,
  // which kicks off server-side code indexing). Optional — null on hosts with
  // no event-driven background pipeline.
  DomainEventBus? eventBus,
  // Opening a PR's branch in an editor materializes a copy-on-write worktree and
  // launches a GUI editor on the SERVER's machine, so the `ide.*` ops exist only
  // when the host wires these ports (a desktop / GUI host — in-process desktop or
  // a desktop-hosted server). A headless server leaves them null and the ops are
  // simply absent (the client's open-in-IDE button then hides itself).
  EditorLauncherPort? editorLauncher,
  PrWorktreePort? prWorktreePort,
  // Computes a conversation's working-tree diff on the SERVER (reads the CoW
  // worktree registry + runs `git diff`). Only a host that owns those checkouts
  // wires it; absent elsewhere (the web panel then shows "no changes").
  ConversationChangesFetcher? conversationChanges,
  // Working-tree diff (vs HEAD, incl. untracked) WITH patches for a linked
  // repo, computed SERVER-SIDE via `git diff HEAD` on the owned checkout. The
  // messaging IDE's Source Control panel renders these `PrFile`s. Absent on a
  // host that owns no checkouts (the panel then shows "no changes").
  RepoChangesFetcher? repoChanges,
  // Reads a file from a linked repo checkout SERVER-SIDE (text + binary flag),
  // rejecting traversal outside the repo root. Backs the IDE FileViewer tab.
  RepoFileContentFetcher? repoFileContent,
  // Server-side fuzzy file search across a workspace's linked repo roots
  // (returns wire maps; the client rebuilds FileSearchHit). Backs the IDE
  // Explorer panel (fff runs SERVER-SIDE over the CoW checkouts).
  RepoFileSearchFetcher? repoFileSearch,
  // Controls the MCP HTTP server the SERVER hosts (start/stop/reconfigure +
  // status). The MCP server is a host-global process-wide listener (NOT
  // workspace data), so the `mcp.*` ops are declared `workspaceScoped: false`.
  // Only a host that actually runs an MCP server wires it (desktop in-process
  // host / headless cc_server); when null the `mcp.*` ops are simply absent and
  // the web settings section degrades to "MCP not available on this server".
  McpServerControl? mcpControl,
  // Controls the host's EXTERNAL MCP client (PRD 01): the subsystem that
  // connects to OTHER MCP servers and bridges their tools into the agent tool
  // surface. Host-global (the external servers are a process-wide concern, NOT
  // workspace data), so the `mcp.client.*` ops are declared
  // `workspaceScoped: false`. Wired by any host that runs the client (desktop
  // in-process host / headless cc_server); when null the ops are absent and the
  // web settings section degrades to "external MCP not available on this
  // server". Interactive `authorize` only succeeds on a host that can reach the
  // user's browser + a local loopback callback (the desktop in-process host).
  McpClientControl? mcpClientControl,
  // Controls for the on-device ML models the SERVER hosts (embedding /
  // diarization / voice). Each is a single device-local asset (NOT workspace
  // data), so the `models.*` ops are declared `workspaceScoped: false`. Only a
  // host that actually runs these models wires them (the desktop in-process
  // host, which owns the cc_natives FFI controllers); a headless cc_server hosts
  // no models, so it leaves them null and the ops are simply absent — the web
  // settings sections then degrade to "managed on the server host".
  ModelControl? embeddingModelControl,
  ModelControl? diarizationModelControl,
  ModelControl? voiceModelControl,
  // Owns server-hosted interactive terminal sessions (a `flutter_pty` shell
  // inside the agent sandbox). The PTY runs on the SERVER's machine, so the
  // `terminal.*` ops + the `terminal.output` subscription exist only when the
  // host wires this port (the desktop in-process host, which links flutter_pty
  // via DesktopTerminalSessionPort). A pure-Dart headless cc_server does NOT
  // link flutter_pty, so it leaves this null and the ops are simply absent —
  // the web terminal panel then shows an honest "terminal runs on the server
  // host" state. Sessions are workspace-scoped (ownership validated per op).
  TerminalSessionPort? terminalSessions,
  // Owns the workspace on-disk layout (agents / skills / conversation dirs) on
  // the SERVER's filesystem. The `fs.*` ops let a thin/web client resolve those
  // server-side paths (it treats them as opaque tokens it hands back to other
  // server ops — e.g. `terminal.spawn`) and write through (create an agent dir,
  // persist a skill file, …). The ops exist only when the host wired a
  // [WorkspaceFilesystemPort] (the desktop in-process host's
  // `WorkspaceFilesystemService`, or the headless cc_server rooted at its data
  // dir). When null the `fs.*` ops are simply absent (default-deny) and the web
  // caller surfaces an honest failure. Every op is workspace-scoped: the host
  // injects the bound workspace, so a client can never reach another workspace's
  // directories (the workspace-isolation invariant).
  WorkspaceFilesystemPort? workspaceFilesystem,
  // Runs the channel-lifecycle + agent-dispatch service (the `MessagingService`,
  // exposed as a [MessagingPort]) on the SERVER so a thin/web client's composer
  // can send-and-dispatch, retry, refine, open a DM, create a group, etc. with
  // the work executing server-side. The dispatch path needs the flutter-bound
  // engine (sandbox / PTY / claude-relay), so only a host that links it wires
  // this (the desktop in-process host). A pure-Dart headless server leaves it
  // null → the `dispatch.*` ops are simply absent and the web client surfaces an
  // honest "agent dispatch runs on the server host" state. The streaming agent
  // reply needs NO new infra: the server-side `AgentStreamProcessor` persists
  // transcript segments onto the message rows, and the client is already
  // subscribed to `messaging.watchMessages` (which watches those rows), so the
  // reply streams in automatically — no new WatchQuery here. Every `dispatch.*`
  // op is workspace-scoped: it sources `ctx.workspaceId!` (never a client arg)
  // and asserts channel ownership before delegating (isolation invariant).
  MessagingPort? messagingDispatch,
  // Runs the pipeline EXECUTOR (the `PipelineEngine`) on the SERVER so a
  // thin/web client can start / cancel / retry a pipeline run and kill a single
  // step, with the work executing server-side. The engine owns run-state
  // persistence (the Drift DB) and drives the dispatch stack (sandbox / PTY /
  // claude-relay / cc_natives indexer), so only a host that constructs the
  // engine wires it (the desktop in-process host). A pure-Dart headless
  // cc_server does NOT construct the engine, so it leaves this null → the
  // `pipeline.*` ops are simply absent and a web client connected to it degrades
  // to "pipelines run on the server host". Every `pipeline.*` op is
  // workspace-scoped: it sources `ctx.workspaceId!` (never a client arg) and
  // validates run/step ownership via `loadOwnedPipelineRun` before acting
  // (workspace-isolation invariant).
  PipelineEnginePort? pipelineEngine,
  // Applies an orchestration approve / cancel on the SERVER. Approving hires
  // agents, creates teams, and starts pipelines (cancel does the inverse) via
  // the concrete engine + the orchestration use-cases over the local DB, so it
  // runs server-side; the composition root wires each as a closure over those
  // use-cases. Only a host that owns the engine wires them (the desktop
  // in-process host); a headless cc_server leaves them null → the
  // `orchestration.approve` / `orchestration.cancel` ops are absent and a web
  // client connected to it degrades to "orchestration runs on the server host".
  // Both ops are workspace-scoped: they source `ctx.workspaceId!` (never a
  // client arg); the use-cases re-validate the orchestration belongs to that
  // workspace (defense in depth).
  OrchestrationActionFn? approveOrchestration,
  OrchestrationActionFn? cancelOrchestration,
  // Dispatches a review-fix agent into a channel on the SERVER (see
  // [ReviewDispatchFn]). Wired only by a host that owns the dispatch stack (the
  // desktop in-process host); a headless cc_server leaves it null → the
  // `dispatch.reviewFeedbackAgent` op is absent and the web "send findings to
  // agent" action degrades to "runs on the server host". Workspace-scoped: the
  // handler sources `ctx.workspaceId!` and asserts channel ownership; the host
  // closure resolves the working directory from the bound workspace.
  ReviewDispatchFn? reviewDispatch,
  // ---- Remote agent-action approvals (the `confirmation.*` surface) ----
  // The phone (cc_remote) approves/declines destructive agent commands. The
  // host-side [PendingConfirmationRegistry] bridges the agent's blocking
  // `ConfirmationPort.requestApproval` to remote clients: a destructive tool
  // call registers here, `confirmation.watchPending` streams the pending list to
  // the phone, and `confirmation.respond` resolves it. Wired only by a host that
  // owns the dispatch stack + a remote approver (the desktop in-process host);
  // null on a headless cc_server (no dispatch) → both entries are absent.
  // CROSS-WORKSPACE BY DESIGN: approvals are host-global (a phone spans
  // workspaces); the `conversation_id` field routes them to the right thread.
  PendingConfirmationRegistry? pendingConfirmationRegistry,
}) {
  Future<bool> channelInWorkspace(String workspaceId, String channelId) async {
    final channels = await messagingRepository
        .watchChannelsByWorkspace(workspaceId)
        .first;
    return channels.any((c) => c.id == channelId);
  }

  Future<void> assertChannelOwned(String workspaceId, String channelId) async {
    if (!await channelInWorkspace(workspaceId, channelId)) {
      throw const WorkspaceMismatchException(
        'Channel belongs to a different workspace',
      );
    }
  }

  Future<PipelineRun> loadOwnedPipelineRun(
    String workspaceId,
    String runId,
  ) async {
    final run = await pipelineRunRepository.getRun(runId);
    if (run == null) {
      throw const NotFoundException('Pipeline run not found');
    }
    if (run.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Pipeline run belongs to a different workspace',
      );
    }
    return run;
  }

  Future<void> assertPipelineRunOwned(String workspaceId, String runId) async {
    await loadOwnedPipelineRun(workspaceId, runId);
  }

  // PR-lifecycle ownership chokepoint: the id-keyed mutations (`updateDraft` /
  // `createOnGitHub` / `delete`) take only a record id, which is NOT a boundary
  // (id uniqueness is not isolation). Load the row and assert it belongs to the
  // bound workspace before mutating; a foreign-workspace id is rejected loudly.
  Future<void> assertPrLifecycleOwned(String? workspaceId, String prId) async {
    final pr = await prLifecycleRepository.getById(prId);
    if (pr == null) {
      throw const NotFoundException('PR lifecycle record not found');
    }
    if (pr.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'PR lifecycle record belongs to a different workspace',
      );
    }
  }
  // Confine a client-supplied opaque path to the bound workspace's
  // own directory. The fs.* path accessors only ever return workspace-rooted
  // absolute paths, so a legitimate client path always passes; a traversal
  // (`..`, absolute escape, or a path outside the workspace) is rejected
  // loudly as a workspace-boundary violation. [root] is the workspace dir
  // resolved server-side (never client-supplied).
  String confineFsPath(String root, String clientPath) {
    final absRoot = p.normalize(p.absolute(root));
    final target = p.normalize(p.absolute(clientPath));
    if (target != absRoot && !p.isWithin(absRoot, target)) {
      throw const WorkspaceMismatchException(
        'Path escapes the workspace directory',
      );
    }
    return target;
  }

  // Reject slugs carrying path separators / traversal. A slug with
  // `..` escapes the workspace dir once p.join collapses it, so only a bare
  // filename (optionally dotted/dashed) is accepted.
  String validatedSlug(String slug) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(slug)) {
      throw const WorkspaceMismatchException('Invalid slug');
    }
    return slug;
  }

  // Privileged host-surface ops (filesystem, terminal, adapter/model
  // detection) must never be reachable by a companion phone — it is a
  // lower-privilege principal whose only legit surface is the ticket/messaging/
  // newsfeed catalog. Returns a copy gated to first-party full clients.
  RepoOp fullClientOnly(RepoOp op) => RepoOp(
        name: op.name,
        kind: op.kind,
        handler: op.handler,
        version: op.version,
        requiredArgs: op.requiredArgs,
        workspaceScoped: op.workspaceScoped,
        requiredCapability: SessionCapability.fullClient,
      );

  Future<void> assertPipelineStepRunOwned(
    String workspaceId,
    String stepRunId,
  ) async {
    final stepRun = await pipelineRunRepository.getStepRunById(stepRunId);
    if (stepRun == null) {
      throw const NotFoundException('Pipeline step run not found');
    }
    // Step runs carry no workspaceId — ownership flows through the parent run.
    await loadOwnedPipelineRun(workspaceId, stepRun.pipelineRunId);
  }

  // ---- PR review repository cache (per (workspace, owner, repo)) ----
  //
  // CachedPrReviewRepository is STATEFUL: it owns an SWR disk cache and emits
  // change-detected snapshots, so a fresh instance per call would defeat the
  // cache. Cache one instance per (workspace, owner, repo). The repo must be
  // LINKED to the bound workspace — an unlinked (owner, repo) is rejected so a
  // client can't read a foreign workspace's PR data (isolation invariant). The
  // local checkout path (for the >3000-file local-git fallback) is sourced from
  // the workspace's own linked repo row.
  final prRepoCache = <String, PrReviewRepository>{};

  // The bound workspace's linked, GitHub-backed repos — the server-side repo
  // set every PR-over-RPC op fans GitHub queries across (never a client-sent
  // list, so a foreign repo can't be smuggled in).
  Future<List<Repo>> linkedGitHubRepos(String workspaceId) async {
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    return [
      for (final r in linked)
        if (r.hasGitHubRemote) r,
    ];
  }

  // Validates that `(owner, repo)` is a GitHub repo linked to the bound
  // workspace before a client-supplied owner/repo is used in a server-side gh
  // fetch — so a thin client can only drive reads against repos its workspace
  // owns (workspace-isolation invariant). Denies loudly on a foreign repo.
  Future<void> requireWorkspaceGitHubRepo(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final repos = await linkedGitHubRepos(workspaceId);
    final owns = repos.any(
      (r) =>
          r.githubOwner.toLowerCase() == owner.toLowerCase() &&
          r.githubRepoName.toLowerCase() == repo.toLowerCase(),
    );
    if (!owns) {
      throw const WorkspaceMismatchException(
        'Repository is not linked to this workspace',
      );
    }
  }

  Future<PrReviewRepository> resolvePrReviewRepository(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    if (vcsProviderFactory == null) {
      return const EmptyPrReviewRepository();
    }
    final key = '$workspaceId|${owner.toLowerCase()}|${repo.toLowerCase()}';
    final existing = prRepoCache[key];
    if (existing != null) {
      return existing;
    }
    // Resolve the linked repo row for (owner, repo) in the bound workspace.
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    Repo? match;
    for (final r in linked) {
      if (r.githubOwner.toLowerCase() == owner.toLowerCase() &&
          r.githubRepoName.toLowerCase() == repo.toLowerCase()) {
        match = r;
        break;
      }
    }
    if (match == null) {
      throw const WorkspaceMismatchException(
        'Repository is not linked to this workspace',
      );
    }
    final created = vcsProviderFactory.create(
      VcsProviderContext(repo: match, workspaceId: workspaceId),
    );
    prRepoCache[key] = created;
    return created;
  }

  // Reads (owner, repo) from the op/watch args, rejecting a missing pair.
  ({String owner, String repo}) requireRepoCoords(Map<String, dynamic> args) {
    final owner = args['owner'];
    final repo = args['repo'];
    if (owner is! String || owner.isEmpty || repo is! String || repo.isEmpty) {
      throw const NotFoundException('Missing or invalid argument: owner/repo');
    }
    return (owner: owner, repo: repo);
  }

  // Stale-while-revalidate for a reference preview: serve the cached wire map
  // immediately when present (kicking off a background refresh), else fetch.
  // The cache is workspace-scoped; the preview is keyed by `owner/repo<sep>id`.
  Future<Map<String, dynamic>?> previewSwr({
    required String workspaceId,
    required String kind,
    required String key,
    required Future<Map<String, dynamic>?> Function() fetch,
  }) async {
    final cache = prPreviewCache;
    if (cache == null) {
      return fetch();
    }
    final cached = await cache.read(workspaceId, kind, key);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          // Background revalidation; ignore failures (keep the cached value).
          unawaited(
            fetch()
                .then((fresh) async {
                  if (fresh != null) {
                    await cache.put(workspaceId, kind, key, jsonEncode(fresh));
                  }
                })
                .catchError((_) {}),
          );
          return decoded;
        }
      } catch (_) {
        // Bad payload — treat as a miss and fetch fresh below.
      }
    }
    final fresh = await fetch();
    if (fresh != null) {
      await cache.put(workspaceId, kind, key, jsonEncode(fresh));
    }
    return fresh;
  }

  // Promote the optional server-host ports to final locals so the collection-if
  // guards below flow the non-null type into the ops' closures.
  final inspector = gitRepoInspector;
  final adapters = adapterDetection;
  final acp = acpModels;
  final ghCli = githubCli;
  final sandboxDetect = sandboxDetector;
  final processes = processDetection;
  final launcher = editorLauncher;
  final worktrees = prWorktreePort;
  final convChanges = conversationChanges;
  final repoCh = repoChanges;
  final repoFileC = repoFileContent;
  final repoFileS = repoFileSearch;
  final mcp = mcpControl;
  final mcpClient = mcpClientControl;
  final embeddingModel = embeddingModelControl;
  final diarizationModel = diarizationModelControl;
  final voiceModel = voiceModelControl;
  final terminals = terminalSessions;
  final fs = workspaceFilesystem;
  final dispatch = messagingDispatch;
  final pipeline = pipelineEngine;
  final approveOrch = approveOrchestration;
  final cancelOrch = cancelOrchestration;
  final reviewDispatcher = reviewDispatch;

  final ops = RepoOpRegistry([
    // ---- Pairing management (fullClient-only) ----
    // Mint / list / rename / revoke paired devices so a first-party client can
    // pair MORE clients to this server — additional web/remote/desktop clients
    // (each a fullClient) AND companion phones — that then dial THIS server
    // directly. Every op is gated to `SessionCapability.fullClient`, so a phone
    // (even one holding a valid PSK) is denied before the handler runs.
    // `pairing.mint` is workspace-scoped (it seeds the new device's initial
    // workspace from the caller's binding); list/rename/revoke are
    // CROSS-WORKSPACE BY DESIGN — paired devices are global (a client has a
    // workspace switcher), so scoping them to one workspace would hide devices.
    RepoOp(
      name: 'pairing.mint',
      kind: RepoOpKind.mutate,
      requiredArgs: ['label'],
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final workspaces = await workspaceRepository.watchAll().first;
        final names = {for (final w in workspaces) w.id: w.name};
        // The minted device's platform sets its privilege when it later
        // connects: 'web'/'desktop' → a first-party fullClient (it may itself
        // manage pairings — this is how you pair multiple web/remote/desktop
        // clients to one server); anything else → a restricted phone
        // (SessionCapability.fromPlatform fails closed). Defaults to 'web'.
        final rawPlatform = (ctx.args['platform'] as String?)?.trim();
        final platform = (rawPlatform == null || rawPlatform.isEmpty)
            ? 'web'
            : rawPlatform;
        final psk = RemoteControlCrypto.generatePsk();
        final deviceId = const Uuid().v4();
        // Time-box the credential (30 days) so a leaked QR is not a permanent
        // backdoor; the connect gate (`authenticatePairedPeer`) fails it closed
        // once expired. The phone re-pairs after that.
        final expiresAt = RemotePairingLifecycle.credentialExpiry(DateTime.now());
        await pairedDeviceDao.upsert(
          PairedDevicesTableCompanion(
            id: Value(deviceId),
            workspaceId: Value(workspaceId),
            label: Value(ctx.args['label'] as String),
            platform: Value(platform),
            pskRef: const Value('file'),
            status: const Value(PairedDeviceStatus.active),
            expiresAt: Value(expiresAt),
          ),
        );
        await pairedDeviceSecretsPort.writePsk(deviceId, psk);
        // A phone reaches a not-directly-reachable server through the broker.
        // The server's RemoteRelayHost watches this table, so inserting the
        // `active` phone above is what makes cc_server join the broker room
        // (named by the device id) and wait for the scan — the QR carries the
        // broker + room + psk.
        return {
          'device_id': deviceId,
          // The PSK is returned ONCE, here, so the client can build the pairing
          // QR/link; it is never read back over RPC afterwards.
          'psk': psk,
          'workspace_id': workspaceId,
          'workspace_name': ?names[workspaceId],
          'server_url': pairingServerUrl,
          // Relay rendezvous for a phone that can't reach the server directly:
          // it joins broker room `room` and relays E2E-encrypted RPC.
          'signaling_url': relaySignalingUrl,
          'room': deviceId,
          'platform': platform,
          'expires_at': expiresAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: paired devices are global; listing must show
    // every device regardless of the caller's workspace.
    RepoOp(
      name: 'pairing.list',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final devices = await pairedDeviceDao.getAll();
        final workspaces = await workspaceRepository.watchAll().first;
        final names = {for (final w in workspaces) w.id: w.name};
        final statusFilter = ctx.args['status'] as String?;
        final filtered = statusFilter == null
            ? devices
            : devices.where((d) => d.status == statusFilter).toList();
        return {
          'devices': [
            for (final d in filtered)
              pairedDeviceToWire(d, names[d.workspaceId]),
          ],
        };
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: rename targets a global device by id.
    RepoOp(
      name: 'pairing.rename',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['device_id', 'label'],
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final deviceId = ctx.args['device_id'] as String;
        final existing = await pairedDeviceDao.getById(deviceId);
        if (existing == null) {
          throw const NotFoundException('Paired device not found');
        }
        // Upsert with only id + label set: the conflict-update leaves every
        // other column (workspace, platform, status, PSK ref) untouched.
        await pairedDeviceDao.upsert(
          PairedDevicesTableCompanion(
            id: Value(deviceId),
            label: Value(ctx.args['label'] as String),
          ),
        );
        final updated = await pairedDeviceDao.getById(deviceId);
        final workspaces = await workspaceRepository.watchAll().first;
        final names = {for (final w in workspaces) w.id: w.name};
        return {
          'device': pairedDeviceToWire(updated!, names[updated.workspaceId]),
        };
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: revoke targets a global device by id.
    RepoOp(
      name: 'pairing.revoke',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['device_id'],
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final deviceId = ctx.args['device_id'] as String;
        // A client must not revoke its own session out from under itself.
        if (deviceId == ctx.deviceId) {
          throw const AuthException('Cannot revoke the calling device');
        }
        final existing = await pairedDeviceDao.getById(deviceId);
        if (existing == null) {
          throw const NotFoundException('Paired device not found');
        }
        // Delete the PSK FIRST so a mid-failure leaves the device unable to
        // authenticate (fail closed) rather than orphaning a live credential.
        await pairedDeviceSecretsPort.deletePsk(deviceId);
        await pairedDeviceDao.remove(deviceId);
        return {'ok': true};
      },
    ),
    // ---- Tickets (workspace-scoped at the repository) ----
    RepoOp(
      name: 'tickets.list',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final tickets = await ticketRepository
            .watchForWorkspace(ctx.workspaceId!)
            .first;
        return {'tickets': tickets.map(ticketToWire).toList()};
      },
    ),
    RepoOp(
      name: 'tickets.get',
      kind: RepoOpKind.read,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final ticket = await ticketRepository.getById(
          ctx.args['ticket_id'] as String,
        );
        if (ticket == null) {
          throw const NotFoundException('Ticket not found');
        }
        if (ticket.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Ticket belongs to a different workspace',
          );
        }
        return {'ticket': ticketToWire(ticket)};
      },
    ),
    RepoOp(
      name: 'tickets.assign',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final id = ctx.args['ticket_id'] as String;
        await ticketWorkflow.assign(
          id,
          workspaceId: ctx.workspaceId!,
          agentId: ctx.args['agent_id'] as String?,
          teamId: ctx.args['team_id'] as String?,
        );
        final ticket = await ticketRepository.getById(id);
        return {'ticket': ticket == null ? null : ticketToWire(ticket)};
      },
    ),
    RepoOp(
      name: 'tickets.insert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket'],
      handler: (ctx) async {
        final ticket = ticketFromWire(
          (ctx.args['ticket'] as Map).cast<String, dynamic>(),
        );
        // A client cannot create a ticket in a foreign workspace.
        if (ticket.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Ticket belongs to a different workspace',
          );
        }
        await ticketRepository.insert(ticket);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.update',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket'],
      handler: (ctx) async {
        final ticket = ticketFromWire(
          (ctx.args['ticket'] as Map).cast<String, dynamic>(),
        );
        if (ticket.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Ticket belongs to a different workspace',
          );
        }
        // `updateById` scopes by id only, so confirm the EXISTING row lives in
        // the bound workspace before writing — an id-only lookup is not an
        // isolation boundary.
        final existing = await ticketRepository.getById(ticket.id);
        if (existing == null) {
          throw const NotFoundException('Ticket not found');
        }
        if (existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Ticket belongs to a different workspace',
          );
        }
        final expected = ctx.args['expected_version'];
        // The DAO throws ConcurrencyConflictException on a version mismatch,
        // which the exception mapper surfaces as RpcErrorCodes.conflict so the
        // client's _mutate retry loop can re-read and try again.
        await ticketRepository.update(
          ticket,
          expectedVersion: expected is num ? expected.toInt() : null,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        // `delete` is scoped by workspaceId, so a ticket from another workspace
        // is simply not matched (no-op) rather than deleted.
        await ticketRepository.delete(
          ctx.args['ticket_id'] as String,
          workspaceId: ctx.workspaceId!,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.addCollaborator',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'ticket_id', 'agent_id', 'joined_at'],
      handler: (ctx) async {
        final ticketId = ctx.args['ticket_id'] as String;
        await _assertTicketInWorkspace(
          ticketRepository,
          ticketId,
          ctx.workspaceId,
        );
        await ticketRepository.addCollaborator(
          collaboratorFromWire(ctx.args.cast<String, dynamic>()),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.removeCollaborator',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket_id', 'agent_id'],
      handler: (ctx) async {
        final ticketId = ctx.args['ticket_id'] as String;
        await _assertTicketInWorkspace(
          ticketRepository,
          ticketId,
          ctx.workspaceId,
        );
        await ticketRepository.removeCollaborator(
          ticketId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.getCollaborators',
      kind: RepoOpKind.read,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final ticketId = ctx.args['ticket_id'] as String;
        await _assertTicketInWorkspace(
          ticketRepository,
          ticketId,
          ctx.workspaceId,
        );
        final list = await ticketRepository.getCollaborators(ticketId);
        return {'collaborators': list.map(collaboratorToWire).toList()};
      },
    ),

    // ---- Projects (workspace-scoped at the repository) ----
    RepoOp(
      name: 'project.insert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['project'],
      handler: (ctx) async {
        final project = projectFromWire(
          (ctx.args['project'] as Map).cast<String, dynamic>(),
        );
        // The project's own workspace must match the bound session — a client
        // can't write a project into a foreign workspace (isolation invariant).
        if (project.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Project belongs to a different workspace',
          );
        }
        await projectRepository.insert(project);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'project.update',
      kind: RepoOpKind.mutate,
      requiredArgs: ['project'],
      handler: (ctx) async {
        final project = projectFromWire(
          (ctx.args['project'] as Map).cast<String, dynamic>(),
        );
        // Reject writes whose payload targets a foreign workspace; the
        // repository update also scopes by workspaceId so a mismatch writes 0
        // rows, but deny loudly here rather than silently no-op.
        if (project.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Project belongs to a different workspace',
          );
        }
        final count = await projectRepository.update(project);
        return {'count': count};
      },
    ),
    RepoOp(
      name: 'project.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['project_id'],
      handler: (ctx) async {
        // The repository scopes the delete by workspaceId, so a project from
        // another workspace is simply not matched (count == 0).
        final count = await projectRepository.delete(
          ctx.args['project_id'] as String,
          workspaceId: ctx.workspaceId!,
        );
        return {'count': count};
      },
    ),
    RepoOp(
      name: 'project.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final project = await projectRepository.getById(
          ctx.args['id'] as String,
        );
        if (project == null) {
          throw const NotFoundException('Project not found');
        }
        // An ID-only lookup is not a scoping boundary, so reject any project
        // not owned by the bound session.
        if (project.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Project belongs to a different workspace',
          );
        }
        return {'project': projectToWire(project)};
      },
    ),
    RepoOp(
      name: 'project.getForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: [],
      handler: (ctx) async {
        final projects = await projectRepository.getForWorkspace(
          ctx.workspaceId!,
        );
        return {'projects': projects.map(projectToWire).toList()};
      },
    ),

    // ---- Agents (workspace-scoped at the repository) ----
    RepoOp(
      name: 'agents.get',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final agent = await agentRepository.getById(
          ctx.args['agent_id'] as String,
        );
        if (agent == null) {
          throw const NotFoundException('Agent not found');
        }
        if (agent.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent belongs to a different workspace',
          );
        }
        return {'agent': agentToWire(agent)};
      },
    ),
    RepoOp(
      name: 'agents.findByName',
      kind: RepoOpKind.read,
      requiredArgs: ['name'],
      handler: (ctx) async {
        final agent = await agentRepository.findByWorkspaceAndName(
          ctx.workspaceId!,
          ctx.args['name'] as String,
        );
        return {'agent': agent == null ? null : agentToWire(agent)};
      },
    ),
    RepoOp(
      name: 'agents.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['agent'],
      handler: (ctx) async {
        final agent = agentFromWire(
          (ctx.args['agent'] as Map).cast<String, dynamic>(),
        );
        // The agent's own workspace must match the bound session — a client
        // can't write an agent into a foreign workspace (isolation invariant).
        if (agent.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent belongs to a different workspace',
          );
        }
        await agentRepository.upsert(agent);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'agents.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final id = ctx.args['agent_id'] as String;
        // Verify ownership before deleting (ID-only lookup is not a boundary).
        final agent = await agentRepository.getById(id);
        if (agent != null && agent.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent belongs to a different workspace',
          );
        }
        await agentRepository.delete(id);
        return {'ok': true};
      },
    ),

    // ---- Repos (global — declared workspace exemption) ----
    RepoOp(
      name: 'repos.get',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final repo = await repoRepository.getById(ctx.args['repo_id'] as String);
        if (repo == null) {
          throw const NotFoundException('Repo not found');
        }
        return {'repo': repoToWire(repo)};
      },
    ),
    RepoOp(
      name: 'repos.upsert',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['repo'],
      handler: (ctx) async {
        final id = await repoRepository.upsert(
          repoFromWire((ctx.args['repo'] as Map).cast<String, dynamic>()),
        );
        return {'repo_id': id};
      },
    ),
    RepoOp(
      name: 'repos.delete',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        await repoRepository.delete(ctx.args['repo_id'] as String);
        return {'ok': true};
      },
    ),
    // Register a repo by pointing at a git checkout on the SERVER's filesystem.
    // Workspace-scoped: the inspected repo is linked into the session's bound
    // workspace via the `RepoAdded` event (server-side indexing keys off it).
    // The local `inspector` is promoted non-null by the guard, so the op only
    // exists when the host wired a [GitRepoInspectorPort].
    if (inspector != null)
      RepoOp(
        name: 'repos.addFromPath',
        kind: RepoOpKind.mutate,
        requiredArgs: ['path'],
        handler: (ctx) async {
          final useCase = AddRepoFromPathUseCase(
            repository: repoRepository,
            inspector: inspector,
            eventBus: eventBus,
          );
          final repo = await useCase.execute(
            ctx.args['path'] as String,
            workspaceId: ctx.workspaceId!,
          );
          return {'repo': repoToWire(repo)};
        },
      ),
    // Browses one level of the SERVER's filesystem (constrained to allow-listed
    // roots) so a web client can navigate to a git checkout and register it via
    // `repos.addFromPath`. Host-global filesystem, NOT workspace data, so it is
    // declared `workspaceScoped: false`; the browser refuses any path outside the
    // configured roots. Absent when the host wires no [DirectoryBrowserPort].
    if (directoryBrowser != null)
      RepoOp(
        name: 'fs.browseDirectory',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final path = ctx.args['path'] as String?;
          final listing = await directoryBrowser.browse(path: path);
          return directoryListingToWire(listing);
        },
      ),
    // Lists the editors the SERVER host can launch (each flagged installed).
    // Editors are host-global, not workspace data. Absent on a headless host.
    if (launcher != null)
      RepoOp(
        name: 'ide.detectEditors',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final editors = await launcher.detectEditors();
          return {'editors': editors.map(ideEditorToWire).toList()};
        },
      ),
    // ---- Server-host adapter / model / gh-CLI probing (host-global) ----
    //
    // These probe the agent-runner CLIs installed on the SERVER's machine (for
    // Settings → Adapters + the auth status display). They are device-local to
    // the host, not workspace data, so every op is `workspaceScoped: false`.
    // Absent when the host wires no detector (default-deny) → the thin client
    // degrades to "not found" / empty.
    if (adapters != null) ...[
      // Probe one adapter the client sent (its predefined spec). Returns only
      // the detection RESULT keyed by adapter id; the client re-attaches the
      // adapter it sent.
      RepoOp(
        name: 'adapter.detectOne',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['adapter'],
        handler: (ctx) async {
          final adapter = adapterFromWire(
            (ctx.args['adapter'] as Map).cast<String, dynamic>(),
          );
          final detected = await adapters.detectOne(adapter);
          return detectedAdapterToWire(detected);
        },
      ),
      // Probe every adapter the client sent, in one round trip.
      RepoOp(
        name: 'adapter.detectAll',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['adapters'],
        handler: (ctx) async {
          final specs = ((ctx.args['adapters'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => adapterFromWire(e.cast<String, dynamic>()))
              .toList();
          final detected = await adapters.detectAll(specs);
          return {'detected': detected.map(detectedAdapterToWire).toList()};
        },
      ),
    ].map(fullClientOnly),
    // The models an adapter advertises (resolved on the host).
    if (acp != null)
      RepoOp(
        name: 'acp.listModels',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['adapter_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final adapterId = ctx.args['adapter_id'] as String? ?? '';
          // Ignore any client-supplied `cli_path`. The host resolves
          // the adapter binary itself (PATH / known install dirs); accepting an
          // attacker-specified executable path is an arbitrary-execution vector.
          final models = await acp.listModels(adapterId);
          return {'models': models.map(acpModelToWire).toList()};
        },
      ),
    // The `gh` CLI status on the host (token redacted — see the wire helper).
    if (ghCli != null)
      RepoOp(
        name: 'github_cli.probe',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final status = await ghCli.probe();
          return githubCliStatusToWire(status);
        },
      ),
    // The OS-native sandbox capabilities of the host (which backends are
    // available + the recommended one). Host-local capability, so
    // `workspaceScoped: false`. The web/thin client renders this instead of
    // probing its own platform.
    if (sandboxDetect != null)
      RepoOp(
        name: 'sandbox.detect',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final result = await sandboxDetect.detect();
          return sandboxDetectionResultToWire(result);
        },
      ),
    // ---- Server-host process detection (CROSS-WORKSPACE BY DESIGN) ----
    //
    // The dashboard's "active agent processes" matrix reads the SERVER's OS
    // process table and can stop a process by pid. The process table is
    // host-global and the detection spans every workspace's agents (the
    // dashboard's cross-workspace overview), so both ops are
    // `workspaceScoped: false`. Killing a host process is privileged, so both
    // ops are `fullClient`-only — a companion phone is denied before the handler
    // runs. Absent when the host wires no detector → an empty process list.
    if (processes != null) ...[
      RepoOp(
        name: 'process.detect',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final found = await processes.detect();
          return {'processes': found.map(activeProcessInfoToWire).toList()};
        },
      ),
      RepoOp(
        name: 'process.kill',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        requiredArgs: ['pid'],
        handler: (ctx) async {
          await processes.killProcess((ctx.args['pid'] as num).toInt());
          return const {};
        },
      ),
    ],
    // Materializes the PR's branch into a CoW worktree on the SERVER (scoped to
    // the session's workspace) and opens it in the chosen editor on the host's
    // display. Returns the server-side worktree path (opaque to the client).
    if (launcher != null && worktrees != null)
      RepoOp(
        name: 'ide.openPrInEditor',
        kind: RepoOpKind.mutate,
        requiredArgs: ['repo', 'pr_number', 'pr_head_ref', 'editor_id'],
        handler: (ctx) async {
          final repo = repoFromWire(
            (ctx.args['repo'] as Map).cast<String, dynamic>(),
          );
          final path = await worktrees.ensureWorktree(
            workspaceId: ctx.workspaceId!,
            repo: repo,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prHeadRef: ctx.args['pr_head_ref'] as String,
          );
          await launcher.openDirectory(
            editorId: ctx.args['editor_id'] as String,
            directoryPath: path,
          );
          return {'path': path};
        },
      ),
    // Materializes the PR's branch into a worktree on the SERVER (scoped to the
    // session's workspace) and returns its absolute path WITHOUT launching an
    // editor. A GUI-attached client (the native desktop app) launches the
    // returned path in a LOCAL editor itself — the headless host can't pop a GUI
    // editor, but it owns the repo checkout + worktree filesystem. In the default
    // self-serve setup the host is the same machine, so the path is local. Gated
    // only on the worktree port (no editor launcher needed), so a headless server
    // still serves it.
    if (worktrees != null)
      RepoOp(
        name: 'ide.ensureWorktree',
        kind: RepoOpKind.mutate,
        requiredArgs: ['repo', 'pr_number', 'pr_head_ref'],
        handler: (ctx) async {
          final repo = repoFromWire(
            (ctx.args['repo'] as Map).cast<String, dynamic>(),
          );
          final path = await worktrees.ensureWorktree(
            workspaceId: ctx.workspaceId!,
            repo: repo,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prHeadRef: ctx.args['pr_head_ref'] as String,
          );
          return {'path': path};
        },
      ),
    // The uncommitted working-tree diff across a conversation's isolated
    // worktrees, computed on the SERVER. Workspace-scoped (the worktree lookup
    // is the isolation boundary). Files travel as the shared PrFile wire shape.
    if (convChanges != null)
      RepoOp(
        name: 'conversation.changes',
        kind: RepoOpKind.read,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final files = await convChanges(
            ctx.workspaceId!,
            ctx.args['channel_id'] as String,
          );
          return {'files': files.map(prFileToWire).toList()};
        },
      ),
    // ---- Repo data ops (workspace-scoped — IDE Explorer / Source Control) ----
    //
    // The messaging IDE view reads repo working-tree state from the SERVER (it
    // owns the checkouts). Each op is workspace-scoped + validates repo
    // ownership inside its fetcher, so a session cannot reach into another
    // workspace's repos. Absent on a host that owns no checkouts.
    if (repoCh != null)
      RepoOp(
        name: 'repos.changes',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'repo_id'],
        handler: (ctx) async {
          final files = await repoCh(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
          );
          return {'files': files.map(prFileToWire).toList()};
        },
      ),
    if (repoFileC != null)
      RepoOp(
        name: 'repos.readFile',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'repo_id', 'path'],
        handler: (ctx) async {
          final r = await repoFileC(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            ctx.args['path'] as String,
          );
          return {'content': r.content, 'binary': r.binary};
        },
      ),
    if (repoFileS != null)
      RepoOp(
        name: 'repos.searchFiles',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'query'],
        handler: (ctx) async {
          final hits = await repoFileS(
            ctx.workspaceId!,
            (ctx.args['query'] ?? '') as String,
          );
          return {'hits': hits};
        },
      ),

    // ---- MCP server control (HOST-GLOBAL — declared workspace exemption) ----
    //
    // The MCP HTTP server is a single process-wide listener the SERVER hosts;
    // it is not workspace data, so these ops are `workspaceScoped: false`. They
    // exist only when the host wired an [McpServerControl] (the guard promotes
    // `mcp` non-null into the closures). A headless server with no MCP server
    // leaves them absent and the web section shows "not available".
    if (mcp != null) ...[
      RepoOp(
        name: 'mcp.status',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final status = await mcp.status();
          return status.toJson();
        },
      ),
      RepoOp(
        name: 'mcp.start',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          await mcp.start();
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.stop',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          await mcp.stop();
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.setEnabled',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['enabled'],
        handler: (ctx) async {
          await mcp.setEnabled(enabled: ctx.args['enabled'] as bool);
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.setPort',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['port'],
        handler: (ctx) async {
          await mcp.setPort((ctx.args['port'] as num).toInt());
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.setToken',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          await mcp.setToken(ctx.args['token'] as String?);
          return (await mcp.status()).toJson();
        },
      ),
    ],

    // ---- External MCP client control (HOST-GLOBAL — declared workspace exemption) ----
    //
    // The external MCP servers the host connects to (and the standing approval
    // posture that gates their tools) are a process-wide concern, NOT workspace
    // data, so these ops are `workspaceScoped: false`. They exist only when the
    // host wired an [McpClientControl] (the guard promotes `mcpClient` non-null
    // into the closures). A host without the client subsystem leaves them absent
    // and the web section shows "external MCP not available on this server".
    // `mcp.client.authorize` runs an INTERACTIVE OAuth flow — it succeeds only on
    // a host that can reach the user's browser + a local loopback callback (the
    // desktop in-process host); a remote headless server rejects it and the
    // client relays the message.
    if (mcpClient != null) ...[
      RepoOp(
        name: 'mcp.client.servers',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final servers = await mcpClient.servers();
          return {'servers': [for (final s in servers) s.toJson()]};
        },
      ),
      RepoOp(
        name: 'mcp.client.approvalMode',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => {'mode': (await mcpClient.approvalMode()).wire},
      ),
      RepoOp(
        name: 'mcp.client.setApprovalMode',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['mode'],
        handler: (ctx) async {
          await mcpClient.setApprovalMode(
            ApprovalMode.fromWire(ctx.args['mode'] as String?),
          );
          return {'mode': (await mcpClient.approvalMode()).wire};
        },
      ),
      RepoOp(
        name: 'mcp.client.authorize',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['name'],
        handler: (ctx) async {
          await mcpClient.authorize(ctx.args['name'] as String);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'mcp.client.reconnect',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['name'],
        handler: (ctx) async {
          await mcpClient.reconnect(ctx.args['name'] as String);
          return {'ok': true};
        },
      ),
    ],

    // ---- On-device model control (HOST-GLOBAL — declared workspace exemption) ----
    //
    // Each model (embedding / diarization / voice) is a single device-local
    // asset the SERVER hosts, NOT workspace data, so these ops are
    // `workspaceScoped: false`. They exist only when the host wired the matching
    // [ModelControl] (the guard promotes it non-null into the closures). A
    // headless server that hosts no models leaves them null → the ops are absent
    // and the web sections show "managed on the server host". `*Status` returns
    // the snapshot wire map; the mutators return the fresh snapshot so the client
    // can refresh without a second round-trip.
    if (embeddingModel != null)
      ...modelControlOps(prefix: 'embedding', control: embeddingModel),
    if (diarizationModel != null)
      ...modelControlOps(prefix: 'diarization', control: diarizationModel),
    if (voiceModel != null)
      ...modelControlOps(prefix: 'voice', control: voiceModel),
    // Voice is the only SELECTABLE model (the user picks the active ASR build),
    // so when the host wired a selectable voice control we also expose the
    // catalog + select ops on top of its status/install/… surface. A fixed
    // (non-selectable) voice control omits these → the web picker hides itself.
    if (voiceModel is SelectableModelControl)
      ...voiceSelectionOps(control: voiceModel),

    // ---- Interactive terminal (server-hosted PTY; WORKSPACE-SCOPED) ----
    //
    // A `flutter_pty` shell runs inside the agent sandbox on the SERVER's
    // machine; the thin client drives it over these ops + the `terminal.output`
    // subscription. The PTY can only exist on a host that links flutter_pty, so
    // these ops exist only when the host wired a [TerminalSessionPort] (the
    // guard promotes `terminals` non-null into the closures). A pure-Dart
    // headless server leaves it null → the ops are absent and the web panel
    // shows "terminal runs on the server host". Every op is workspace-scoped:
    // `spawn` records the bound workspace and the port validates ownership on
    // `output`/`write`/`resize`/`kill`, so no session leaks across workspaces.
    if (terminals != null) ...[
      RepoOp(
        name: 'terminal.spawn',
        kind: RepoOpKind.mutate,
        requiredArgs: ['rows', 'cols'],
        handler: (ctx) async {
          final sessionId = await terminals.spawn(
            workspaceId: ctx.workspaceId!,
            rows: (ctx.args['rows'] as num).toInt(),
            cols: (ctx.args['cols'] as num).toInt(),
            channelId: ctx.args['channel_id'] as String?,
            cwd: ctx.args['cwd'] as String?,
            backend: ctx.args['backend'] as String?,
          );
          return {'session_id': sessionId};
        },
      ),
      RepoOp(
        name: 'terminal.write',
        kind: RepoOpKind.mutate,
        requiredArgs: ['session_id', 'data'],
        handler: (ctx) async {
          await terminals.write(
            workspaceId: ctx.workspaceId!,
            sessionId: ctx.args['session_id'] as String,
            // Bytes travel as a base64 string (the same framing the
            // `terminal.output` snapshots use), decoded back to raw bytes here.
            data: base64Decode(ctx.args['data'] as String),
          );
          return const {};
        },
      ),
      RepoOp(
        name: 'terminal.resize',
        kind: RepoOpKind.mutate,
        requiredArgs: ['session_id', 'rows', 'cols'],
        handler: (ctx) async {
          await terminals.resize(
            workspaceId: ctx.workspaceId!,
            sessionId: ctx.args['session_id'] as String,
            rows: (ctx.args['rows'] as num).toInt(),
            cols: (ctx.args['cols'] as num).toInt(),
          );
          return const {};
        },
      ),
      RepoOp(
        name: 'terminal.kill',
        kind: RepoOpKind.mutate,
        requiredArgs: ['session_id'],
        handler: (ctx) async {
          await terminals.kill(
            workspaceId: ctx.workspaceId!,
            sessionId: ctx.args['session_id'] as String,
          );
          return const {};
        },
      ),
    ].map(fullClientOnly),

    // ---- Workspace filesystem (server on-disk layout; WORKSPACE-SCOPED) ----
    //
    // The agents / skills / conversation directory tree lives on the SERVER's
    // filesystem; a thin/web client resolves its server-side paths (opaque
    // tokens) and writes through these ops. The tree can only exist on a host
    // with a real filesystem, so the ops exist only when the host wired a
    // [WorkspaceFilesystemPort] (the guard promotes `fs` non-null into the
    // closures). Every op is workspace-scoped: the dispatcher injects the bound
    // workspace and the handler reads `ctx.workspaceId!`, so a client can never
    // reach another workspace's directories. The two opaque-path ops
    // (`fs.ensureDir` / `fs.writeString`) take a server path rather than a
    // workspaceId, but stay workspace-scoped so an UNBOUND session cannot reach
    // them (defense in depth). Path methods return `{path}`; the slug listers
    // return `{slugs}`; `fs.readSkillFile` returns `{content}` (null when
    // absent); void mutations return `{ok: true}`.
    if (fs != null) ...[
      RepoOp(
        name: 'fs.workspaceDir',
        kind: RepoOpKind.read,
        handler: (ctx) async => {'path': await fs.workspaceDir(ctx.workspaceId!)},
      ),
      RepoOp(
        name: 'fs.conversationsDir',
        kind: RepoOpKind.read,
        handler: (ctx) async => {
          'path': await fs.conversationsDir(ctx.workspaceId!),
        },
      ),
      RepoOp(
        name: 'fs.conversationDir',
        kind: RepoOpKind.read,
        requiredArgs: ['conversation_id'],
        handler: (ctx) async => {
          'path': await fs.conversationDir(
            ctx.workspaceId!,
            ctx.args['conversation_id'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.ensureConversationDir',
        kind: RepoOpKind.mutate,
        requiredArgs: ['conversation_id'],
        handler: (ctx) async => {
          'path': await fs.ensureConversationDir(
            ctx.workspaceId!,
            ctx.args['conversation_id'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.skillsDir',
        kind: RepoOpKind.read,
        handler: (ctx) async => {'path': await fs.skillsDir(ctx.workspaceId!)},
      ),
      RepoOp(
        name: 'fs.skillDir',
        kind: RepoOpKind.read,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async => {
          'path': await fs.skillDir(
            ctx.workspaceId!,
            ctx.args['skill_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.skillFilePath',
        kind: RepoOpKind.read,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async => {
          'path': await fs.skillFilePath(
            ctx.workspaceId!,
            ctx.args['skill_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.agentsDir',
        kind: RepoOpKind.read,
        handler: (ctx) async => {'path': await fs.agentsDir(ctx.workspaceId!)},
      ),
      RepoOp(
        name: 'fs.agentDir',
        kind: RepoOpKind.read,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async => {
          'path': await fs.agentDir(
            ctx.workspaceId!,
            ctx.args['agent_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.agentFilePath',
        kind: RepoOpKind.read,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async => {
          'path': await fs.agentFilePath(
            ctx.workspaceId!,
            ctx.args['agent_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.agentSkillsLinkDir',
        kind: RepoOpKind.read,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async => {
          'path': await fs.agentSkillsLinkDir(
            ctx.workspaceId!,
            ctx.args['agent_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.prCloneDir',
        kind: RepoOpKind.read,
        requiredArgs: ['owner', 'repo'],
        handler: (ctx) async => {
          'path': await fs.prCloneDir(
            ctx.workspaceId!,
            ctx.args['owner'] as String,
            ctx.args['repo'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.readSkillFile',
        kind: RepoOpKind.read,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async => {
          'content': await fs.readSkillFile(
            ctx.workspaceId!,
            ctx.args['skill_slug'] as String,
          ),
        },
      ),
      RepoOp(
        name: 'fs.listAgentSlugs',
        kind: RepoOpKind.read,
        handler: (ctx) async => {
          'slugs': await fs.listAgentSlugs(ctx.workspaceId!),
        },
      ),
      RepoOp(
        name: 'fs.listSkillSlugs',
        kind: RepoOpKind.read,
        handler: (ctx) async => {
          'slugs': await fs.listSkillSlugs(ctx.workspaceId!),
        },
      ),
      RepoOp(
        name: 'fs.ensureWorkspaceDirs',
        kind: RepoOpKind.mutate,
        handler: (ctx) async {
          await fs.ensureWorkspaceDirs(ctx.workspaceId!);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.ensureAgentDir',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async {
          await fs.ensureAgentDir(
            ctx.workspaceId!,
            validatedSlug(ctx.args['agent_slug'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.ensureMcpSymlink',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async {
          await fs.ensureMcpSymlink(
            ctx.workspaceId!,
            validatedSlug(ctx.args['agent_slug'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.writeAgentFile',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_slug', 'content'],
        handler: (ctx) async {
          await fs.writeAgentFile(
            ctx.workspaceId!,
            validatedSlug(ctx.args['agent_slug'] as String),
            ctx.args['content'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.deleteAgentDir',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async {
          await fs.deleteAgentDir(
            ctx.workspaceId!,
            validatedSlug(ctx.args['agent_slug'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.syncAgentSkillLinks',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_slug'],
        handler: (ctx) async {
          await fs.syncAgentSkillLinks(
            ctx.workspaceId!,
            validatedSlug(ctx.args['agent_slug'] as String),
            ((ctx.args['skill_slugs'] as List?) ?? const [])
                .map((s) => validatedSlug(s.toString()))
                .toList(),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.writeSkillFile',
        kind: RepoOpKind.mutate,
        requiredArgs: ['skill_slug', 'content'],
        handler: (ctx) async {
          await fs.writeSkillFile(
            ctx.workspaceId!,
            validatedSlug(ctx.args['skill_slug'] as String),
            ctx.args['content'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.deleteSkillDir',
        kind: RepoOpKind.mutate,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async {
          await fs.deleteSkillDir(
            ctx.workspaceId!,
            validatedSlug(ctx.args['skill_slug'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.persistLogo',
        kind: RepoOpKind.mutate,
        requiredArgs: ['source_path'],
        handler: (ctx) async => {
          'path': await fs.persistLogo(
            ctx.workspaceId!,
            ctx.args['source_path'] as String,
          ),
        },
      ),
      // Opaque-path ops: the client passes a server path it obtained from a
      // path accessor above. Workspace-scoped (so an unbound session is
      // rejected) even though the path itself carries no workspaceId.
      RepoOp(
        name: 'fs.ensureDir',
        kind: RepoOpKind.mutate,
        requiredArgs: ['path'],
        handler: (ctx) async {
          final root = await fs.workspaceDir(ctx.workspaceId!);
          await fs.ensureDir(confineFsPath(root, ctx.args['path'] as String));
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'fs.writeString',
        kind: RepoOpKind.mutate,
        requiredArgs: ['path', 'content'],
        handler: (ctx) async {
          final root = await fs.workspaceDir(ctx.workspaceId!);
          await fs.writeString(
            confineFsPath(root, ctx.args['path'] as String),
            ctx.args['content'] as String,
          );
          return {'ok': true};
        },
      ),
    ].map(fullClientOnly),

    // ---- Messaging (channels workspace-scoped; messages ownership-checked) ----
    RepoOp(
      name: 'messaging.listChannels',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final channels = await messagingRepository
            .watchChannelsByWorkspace(ctx.workspaceId!)
            .first;
        return {'channels': channels.map(channelToWire).toList()};
      },
    ),
    RepoOp(
      name: 'messaging.getMessages',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        final messages = await messagingRepository.getMessages(channelId);
        return {'messages': messages.map(messageToWire).toList()};
      },
    ),
    RepoOp(
      name: 'messaging.sendMessage',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'content'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        // Default posture: stamp the sender server-side from the authenticated
        // device — a client-supplied `sender_id` is ignored so a phone can't
        // attribute a message to an arbitrary user/agent. The desktop's own
        // in-process client (same trust boundary) may post non-user system
        // messages (e.g. "hired X" notices), so the richer fields are honored
        // ONLY when explicitly supplied; absent ⇒ the secure user default.
        final senderType = ctx.args['sender_type'] as String? ?? 'user';
        final senderId = senderType == 'user'
            ? ctx.deviceId
            : (ctx.args['sender_id'] as String? ?? ctx.deviceId);
        final metadata = ctx.args['metadata'];
        final messageId = await messagingRepository.sendMessage(
          channelId: channelId,
          content: ctx.args['content'] as String,
          senderId: senderId,
          senderType: senderType,
          messageType: ctx.args['message_type'] as String? ?? 'text',
          metadata: metadata is Map
              ? metadata.cast<String, dynamic>()
              : null,
          id: ctx.args['id'] as String?,
          parentMessageId: ctx.args['parent_message_id'] as String?,
        );
        return {'message_id': messageId};
      },
    ),
    RepoOp(
      name: 'messaging.getMessageById',
      kind: RepoOpKind.read,
      requiredArgs: ['message_id'],
      handler: (ctx) async {
        final message = await messagingRepository.getMessageById(
          ctx.args['message_id'] as String,
        );
        if (message == null) {
          return {'message': null};
        }
        // Messages are keyed by id alone — validate the owning channel is in the
        // bound workspace so a foreign message can't leak (isolation invariant).
        await assertChannelOwned(ctx.workspaceId!, message.channelId);
        return {'message': messageToWire(message)};
      },
    ),
    RepoOp(
      name: 'messaging.channelExists',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        // Report existence only for a channel in the bound workspace — a
        // foreign channel reads as "does not exist" (no cross-workspace probe).
        final exists = await channelInWorkspace(
          ctx.workspaceId!,
          ctx.args['channel_id'] as String,
        );
        return {'exists': exists};
      },
    ),
    RepoOp(
      name: 'messaging.getParticipants',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        final participants = await messagingRepository.getParticipants(
          channelId,
        );
        return {
          'participants': participants.map(channelParticipantToWire).toList(),
        };
      },
    ),
    RepoOp(
      name: 'messaging.setChannelMode',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'mode'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await messagingRepository.setChannelMode(
          channelId,
          ConversationMode.fromDbValue(ctx.args['mode'] as String),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.addParticipant',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'agent_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await messagingRepository.addParticipant(
          channelId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.updateMessage',
      kind: RepoOpKind.mutate,
      requiredArgs: ['message_id'],
      handler: (ctx) async {
        final messageId = ctx.args['message_id'] as String;
        // Messages are keyed by id alone — load + validate the owning channel
        // is in the bound workspace before mutating (isolation invariant).
        final existing = await messagingRepository.getMessageById(messageId);
        if (existing == null) {
          throw const NotFoundException('Message not found');
        }
        await assertChannelOwned(ctx.workspaceId!, existing.channelId);
        final metadata = ctx.args['metadata'];
        await messagingRepository.updateMessage(
          messageId,
          content: ctx.args['content'] as String?,
          metadata: metadata is Map ? metadata.cast<String, dynamic>() : null,
        );
        return {'ok': true};
      },
    ),

    // ---- Messaging channel lifecycle (DB-backed; ALWAYS available) ----
    //
    // Opening a DM, creating a group, deleting/clearing a channel, and removing
    // a participant are pure persistence — they need no dispatch engine — so
    // they are served on EVERY host (including a pure-Dart headless server),
    // backed by the same [MessagingRepository] the in-process [MessagingService]
    // wraps. This keeps the thin/web client's "new DM / new group / clear /
    // remove participant" actions working with or without a wired dispatch
    // engine (previously these lived under `dispatch.*` and 404'd on a headless
    // server). Behaviour matches the old ops (which only delegated to the repo);
    // `deleteChannel` additionally re-publishes [ConversationDeleted] so worktree
    // GC still fires. Every op sources `ctx.workspaceId!` (never a client arg)
    // and asserts channel ownership (isolation invariant).
    RepoOp(
      name: 'messaging.openDm',
      kind: RepoOpKind.mutate,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        // Creates (or reuses) the DM channel in the BOUND workspace.
        final channel = await messagingRepository.openDm(
          ctx.args['agent_id'] as String,
          workspaceId: ctx.workspaceId,
        );
        return {'channel': channelToWire(channel)};
      },
    ),
    RepoOp(
      name: 'messaging.createGroup',
      kind: RepoOpKind.mutate,
      requiredArgs: ['name', 'agent_ids'],
      handler: (ctx) async {
        final channel = await messagingRepository.createGroup(
          ctx.args['name'] as String,
          (ctx.args['agent_ids'] as List).cast<String>(),
          mode: ConversationMode.fromDbValue(
            ctx.args['mode'] as String? ?? 'chat',
          ),
          workspaceId: ctx.workspaceId,
          pipelineRunId: ctx.args['pipeline_run_id'] as String?,
        );
        return {'channel': channelToWire(channel)};
      },
    ),
    RepoOp(
      name: 'messaging.deleteChannel',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await messagingRepository.deleteChannel(channelId);
        // Mirror MessagingService.deleteChannel: let listeners (e.g. worktree
        // GC) tear down per-conversation resources.
        eventBus?.publish(
          ConversationDeleted(channelId: channelId, occurredAt: DateTime.now()),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.clearChannelMessages',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await messagingRepository.clearChannelMessages(channelId);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.removeParticipant',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'agent_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await messagingRepository.removeParticipant(
          channelId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),

    // ---- Messaging dispatch (agent-run execution; SERVER-SIDE, conditional) ----
    //
    // Sending-and-dispatching, retrying, refining a plan, etc. actually EXECUTE
    // an agent run on the host (sandbox / PTY / claude-relay), so they exist
    // only when the host wired a [MessagingPort] dispatch engine (the guard
    // promotes `dispatch` non-null into the closures). A pure-Dart headless
    // server leaves it null → these ops are absent and the web composer shows
    // "agent dispatch runs on the server host". The agent reply streams back via
    // the existing `messaging.watch*` subscriptions (the server-side
    // `AgentStreamProcessor` persists segments to the message rows) — no new
    // WatchQuery is needed here. Every op is workspace-scoped: it sources
    // `ctx.workspaceId!` (never a client arg) and asserts channel ownership
    // before delegating (isolation invariant); the service enforces isolation
    // too (defense in depth).
    if (dispatch != null) ...[
      RepoOp(
        name: 'dispatch.sendUserMessage',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'content'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final metadata = ctx.args['metadata'];
          await dispatch.sendUserMessage(
            channelId,
            ctx.args['content'] as String,
            parentMessageId: ctx.args['parent_message_id'] as String?,
            metadata: metadata is Map
                ? metadata.cast<String, dynamic>()
                : null,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.addAgentToChannel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'agent_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await dispatch.addAgentToChannel(
            channelId,
            ctx.args['agent_id'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.sendAndDispatch',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'content'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await dispatch.sendAndDispatch(
            channelId,
            ctx.args['content'] as String,
            workspaceId: ctx.workspaceId,
            structuredMentions: _structuredMentionsFromWire(
              ctx.args['structured_mentions'],
            ),
            entityRefs: _entityRefsFromWire(ctx.args['entity_refs']),
            parentMessageId: ctx.args['parent_message_id'] as String?,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.dispatchAgent',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'agent_id', 'prompt'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final schema = ctx.args['expected_output_schema'];
          final runId = await dispatch.dispatchAgent(
            channelId: channelId,
            agentId: ctx.args['agent_id'] as String,
            prompt: ctx.args['prompt'] as String,
            workspaceId: ctx.workspaceId,
            ticketId: ctx.args['ticket_id'] as String?,
            pipelineRunId: ctx.args['pipeline_run_id'] as String?,
            pipelineStepId: ctx.args['pipeline_step_id'] as String?,
            inReplyToAgentId: ctx.args['in_reply_to_agent_id'] as String?,
            wakeContext: _wakeContextFromWire(ctx.args['wake_context']),
            parentMessageId: ctx.args['parent_message_id'] as String?,
            expectedOutputSchema: schema is Map
                ? schema.cast<String, dynamic>()
                : null,
            outputContractMode: OutputContractMode.fromStorage(
              ctx.args['output_contract_mode'] as String?,
            ),
          );
          return {'run_id': runId};
        },
      ),
      RepoOp(
        name: 'dispatch.refinePlan',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'feedback'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await dispatch.refinePlan(
            channelId: channelId,
            feedback: ctx.args['feedback'] as String,
            workspaceId: ctx.workspaceId,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.retryAgentTurn',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'failed_message_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await dispatch.retryAgentTurn(
            channelId: channelId,
            failedMessageId: ctx.args['failed_message_id'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.stopRun',
        kind: RepoOpKind.mutate,
        requiredArgs: ['run_id'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          // Ownership: the run log carries the workspace; reject a run that is
          // not the caller's (workspace isolation invariant — an id alone never
          // proves ownership). Deny loudly on mismatch.
          final log = await agentRunLogRepository.getById(runId);
          if (log == null || log.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Run belongs to a different workspace.',
            );
          }
          await dispatch.stopRun(runId);
          return {'ok': true};
        },
      ),
    ],

    // ---- Review-fix agent dispatch (server-hosted dispatch stack) ----
    //
    // Sends selected PR-review findings to an agent that fixes them, posting
    // into the channel. The agent process spawns on the SERVER; the working
    // directory is resolved host-side from the bound workspace (NOT a client
    // path), so a thin client can't aim the agent at an arbitrary directory.
    // Present only when the host wired a [ReviewDispatchFn] (desktop in-process
    // host); a headless server leaves it absent. Channel ownership is asserted
    // before dispatch (isolation invariant).
    if (reviewDispatcher != null)
      RepoOp(
        name: 'dispatch.reviewFeedbackAgent',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_id', 'prompt', 'channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await reviewDispatcher(
            workspaceId: ctx.workspaceId!,
            agentId: ctx.args['agent_id'] as String,
            prompt: ctx.args['prompt'] as String,
            channelId: channelId,
          );
          return {'ok': true};
        },
      ),

    // ---- Newsfeed (global — declared workspace exemption) ----
    RepoOp(
      name: 'newsfeed.listArticles',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final articles = await newsfeedRepository.watchArticles().first;
        return {'articles': articles.map(articleToWire).toList()};
      },
    ),
    RepoOp(
      name: 'newsfeed.setArticleRead',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['article_id', 'read'],
      handler: (ctx) async {
        await newsfeedRepository.setArticleRead(
          ctx.args['article_id'] as String,
          read: ctx.args['read'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.setArticleSaved',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['article_id', 'saved'],
      handler: (ctx) async {
        await newsfeedRepository.setArticleSaved(
          ctx.args['article_id'] as String,
          saved: ctx.args['saved'] as bool,
        );
        return {'ok': true};
      },
    ),
    // Feed management + refresh (global). RSS fetching runs server-side; these
    // let a thin client SEE the feeds, manage them, and trigger a host-side
    // fetch. The refreshed rows stream back over `newsfeed.watchArticles` /
    // `newsfeed.watchFeeds`.
    RepoOp(
      name: 'newsfeed.refreshAll',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await newsfeedRepository.refreshAll();
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.refreshFeed',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['feed_id'],
      handler: (ctx) async {
        await newsfeedRepository.refreshFeed(ctx.args['feed_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.addFeed',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['name', 'url'],
      handler: (ctx) async {
        final feed = await newsfeedRepository.addFeed(
          name: ctx.args['name'] as String,
          url: ctx.args['url'] as String,
          description: ctx.args['description'] as String? ?? '',
          userAgent: ctx.args['user_agent'] as String? ?? '',
        );
        return {'feed': feedToWire(feed)};
      },
    ),
    RepoOp(
      name: 'newsfeed.setFeedEnabled',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['feed_id', 'enabled'],
      handler: (ctx) async {
        await newsfeedRepository.setFeedEnabled(
          ctx.args['feed_id'] as String,
          enabled: ctx.args['enabled'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.deleteFeed',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['feed_id'],
      handler: (ctx) async {
        await newsfeedRepository.deleteFeed(ctx.args['feed_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.markAllRead',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await newsfeedRepository.markAllRead();
        return {'ok': true};
      },
    ),

    // ---- Channel read-cursors (channels workspace-scoped; cursor keyed by
    // channel_id, so ownership-checked against the bound workspace) ----
    RepoOp(
      name: 'channel_read.markChannelRead',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await channelReadRepository.markChannelRead(channelId);
        return {'ok': true};
      },
    ),

    // ---- Memory domains (workspace-scoped at the repository) ----
    RepoOp(
      name: 'memory_domain.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final domains = await memoryDomainRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'domains': domains.map(memoryDomainToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_domain.findByName',
      kind: RepoOpKind.read,
      requiredArgs: ['name'],
      handler: (ctx) async {
        final domain = await memoryDomainRepository.findByName(
          ctx.workspaceId!,
          ctx.args['name'] as String,
        );
        return {
          'domain': domain == null ? null : memoryDomainToWire(domain),
        };
      },
    ),
    RepoOp(
      name: 'memory_domain.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['domain'],
      handler: (ctx) async {
        final domain = memoryDomainFromWire(
          (ctx.args['domain'] as Map).cast<String, dynamic>(),
        );
        // The domain's own workspace must match the bound session — a client
        // can't write a domain into a foreign workspace (isolation invariant).
        if (domain.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Memory domain belongs to a different workspace',
          );
        }
        await memoryDomainRepository.upsert(domain);
        return {'ok': true};
      },
    ),

    // ---- Memory access grants (workspace-scoped at the repository) ----
    RepoOp(
      name: 'memory_access_grant.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final grants = await memoryAccessGrantRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'grants': grants.map(memoryAccessGrantToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_access_grant.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['grant'],
      handler: (ctx) async {
        final grant = memoryAccessGrantFromWire(
          (ctx.args['grant'] as Map).cast<String, dynamic>(),
        );
        // The grant's own workspace must match the bound session — a client
        // can't write a grant into a foreign workspace (isolation invariant).
        if (grant.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Memory access grant belongs to a different workspace',
          );
        }
        await memoryAccessGrantRepository.upsert(grant);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'memory_access_grant.upsertAll',
      kind: RepoOpKind.mutate,
      requiredArgs: ['grants'],
      handler: (ctx) async {
        final grants = ((ctx.args['grants'] as List?) ?? const [])
            .whereType<Map>()
            .map((g) => memoryAccessGrantFromWire(g.cast<String, dynamic>()))
            .toList();
        // Every grant must belong to the bound session's workspace — reject the
        // whole batch on any foreign row (isolation invariant).
        for (final grant in grants) {
          if (grant.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Memory access grant belongs to a different workspace',
            );
          }
        }
        await memoryAccessGrantRepository.upsertAll(grants);
        return {'ok': true};
      },
    ),
    // ---- Agent working memory (workspace-scoped at the repository) ----
    RepoOp(
      name: 'agent_working_memory.getByAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final memory = await agentWorkingMemoryRepository.getByAgent(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {
          'memory': memory == null ? null : agentWorkingMemoryToWire(memory),
        };
      },
    ),
    RepoOp(
      name: 'agent_working_memory.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['memory'],
      handler: (ctx) async {
        final memory = agentWorkingMemoryFromWire(
          (ctx.args['memory'] as Map).cast<String, dynamic>(),
        );
        // The memory's own workspace must match the bound session — a client
        // can't write into a foreign workspace (isolation invariant).
        if (memory.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent working memory belongs to a different workspace',
          );
        }
        await agentWorkingMemoryRepository.upsert(memory);
        return {'ok': true};
      },
    ),

    // ---- Memory facts (workspace-scoped at the repository) ----
    RepoOp(
      name: 'memory_fact.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final facts = await memoryFactRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'facts': facts.map(memoryFactToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_fact.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['fact_id'],
      handler: (ctx) async {
        // Scoped by workspace at the repository — a foreign fact is simply not
        // found (ids are global UUIDs, the workspace is the boundary).
        final fact = await memoryFactRepository.getById(
          ctx.workspaceId!,
          ctx.args['fact_id'] as String,
        );
        if (fact == null) {
          throw const NotFoundException('Memory fact not found');
        }
        return {'fact': memoryFactToWire(fact)};
      },
    ),
    RepoOp(
      name: 'memory_fact.getActiveByTopic',
      kind: RepoOpKind.read,
      requiredArgs: ['topic'],
      handler: (ctx) async {
        final facts = await memoryFactRepository.getActiveByTopic(
          ctx.workspaceId!,
          ctx.args['topic'] as String,
        );
        return {'facts': facts.map(memoryFactToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_fact.getByAuthor',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final facts = await memoryFactRepository.getByAuthor(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {'facts': facts.map(memoryFactToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_fact.search',
      kind: RepoOpKind.read,
      requiredArgs: ['query'],
      handler: (ctx) async {
        // FTS5-only over RPC: the thin client cannot ship a query embedding, so
        // hybrid BM25+vector search stays host-internal.
        final facts = await memoryFactRepository.search(
          ctx.workspaceId!,
          ctx.args['query'] as String,
        );
        return {'facts': facts.map(memoryFactToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_fact.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['fact'],
      handler: (ctx) async {
        final fact = memoryFactFromWire(
          (ctx.args['fact'] as Map).cast<String, dynamic>(),
        );
        // The fact's own workspace must match the bound session — a client
        // can't write a fact into a foreign workspace (isolation invariant).
        if (fact.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Memory fact belongs to a different workspace',
          );
        }
        await memoryFactRepository.upsert(fact);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'memory_fact.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['fact_id'],
      handler: (ctx) async {
        // delete() is itself workspace-scoped — a foreign fact is a no-op there,
        // so passing the bound workspace is the boundary (no ID-only delete).
        await memoryFactRepository.delete(
          ctx.workspaceId!,
          ctx.args['fact_id'] as String,
        );
        return {'ok': true};
      },
    ),

    // ---- Memory policies (workspace-scoped at the repository) ----
    RepoOp(
      name: 'memory_policy.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final policies = await memoryPolicyRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'policies': policies.map(memoryPolicyToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_policy.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        // Scoped lookup: a policy owned by another workspace is simply not
        // found (ids are global UUIDs; the workspace is the isolation
        // boundary, not id uniqueness).
        final policy = await memoryPolicyRepository.getById(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        if (policy == null) {
          throw const NotFoundException('Memory policy not found');
        }
        return {'policy': memoryPolicyToWire(policy)};
      },
    ),
    RepoOp(
      name: 'memory_policy.getActiveByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final policies = await memoryPolicyRepository.getActiveByWorkspace(
          ctx.workspaceId!,
          domain: ctx.args['domain'] as String?,
        );
        return {'policies': policies.map(memoryPolicyToWire).toList()};
      },
    ),
    RepoOp(
      name: 'memory_policy.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['policy'],
      handler: (ctx) async {
        final policy = memoryPolicyFromWire(
          (ctx.args['policy'] as Map).cast<String, dynamic>(),
        );
        // The policy's own workspace must match the bound session — a client
        // can't write a policy into a foreign workspace (isolation invariant).
        if (policy.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Memory policy belongs to a different workspace',
          );
        }
        await memoryPolicyRepository.upsert(policy);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'memory_policy.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        // Scoped delete: the repository filters by workspaceId, so one
        // workspace can never delete another's policy.
        await memoryPolicyRepository.delete(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        return {'ok': true};
      },
    ),
    // ---- Review channels (workspace-scoped at the repository) ----
    RepoOp(
      name: 'review_channel.create',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'pr_node_id', 'pr_number', 'repo_full_name'],
      handler: (ctx) async {
        // The association is stamped with the bound session workspace — a
        // client can't create one in a foreign workspace (isolation invariant).
        final association = await reviewChannelRepository.create(
          channelId: ctx.args['channel_id'] as String,
          workspaceId: ctx.workspaceId!,
          prNodeId: ctx.args['pr_node_id'] as String,
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          repoFullName: ctx.args['repo_full_name'] as String,
        );
        return {'association': reviewChannelToWire(association)};
      },
    ),
    RepoOp(
      name: 'review_channel.updateStatus',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'status'],
      handler: (ctx) async {
        final id = ctx.args['id'] as String;
        // Verify ownership before mutating (ID-only lookup is not a boundary):
        // the association must already be visible in the bound workspace.
        final owned = await reviewChannelRepository
            .watchByWorkspace(ctx.workspaceId!)
            .first;
        if (!owned.any((a) => a.id == id)) {
          throw const WorkspaceMismatchException(
            'Review channel association belongs to a different workspace',
          );
        }
        final status =
            ReviewChannelStatus.values.asNameMap()[ctx.args['status']];
        if (status == null) {
          throw const NotFoundException('Unknown review channel status');
        }
        await reviewChannelRepository.updateStatus(id, status);
        return {'ok': true};
      },
    ),
    // ---- Agent run logs (workspace-scoped at the repository) ----
    RepoOp(
      name: 'agent_run_log.get',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final log = await agentRunLogRepository.getById(
          ctx.args['id'] as String,
        );
        if (log == null) {
          throw const NotFoundException('Agent run log not found');
        }
        // Run logs carry a nullable workspaceId; an ID-only lookup is not a
        // scoping boundary, so reject any row not owned by the bound session.
        if (log.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent run log belongs to a different workspace',
          );
        }
        return {'log': agentRunLogToWire(log)};
      },
    ),
    RepoOp(
      name: 'agent_run_log.activeRunForAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final log = await agentRunLogRepository.activeRunForAgent(
          ctx.args['agent_id'] as String,
        );
        // Validate ownership before returning (ID-only lookup is not a
        // boundary); a foreign agent's run must not surface here.
        if (log != null && log.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent run log belongs to a different workspace',
          );
        }
        return {'log': log == null ? null : agentRunLogToWire(log)};
      },
    ),
    RepoOp(
      name: 'agent_run_log.forPipelineRun',
      kind: RepoOpKind.read,
      requiredArgs: ['pipeline_run_id'],
      handler: (ctx) async {
        final logs = await agentRunLogRepository.forPipelineRun(
          ctx.workspaceId!,
          ctx.args['pipeline_run_id'] as String,
        );
        return {'logs': logs.map(agentRunLogToWire).toList()};
      },
    ),
    RepoOp(
      name: 'agent_run_log.forPipelineStep',
      kind: RepoOpKind.read,
      requiredArgs: ['pipeline_run_id', 'pipeline_step_id'],
      handler: (ctx) async {
        final logs = await agentRunLogRepository.forPipelineStep(
          ctx.workspaceId!,
          ctx.args['pipeline_run_id'] as String,
          ctx.args['pipeline_step_id'] as String,
        );
        return {'logs': logs.map(agentRunLogToWire).toList()};
      },
    ),
    RepoOp(
      name: 'agent_run_log.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['log'],
      handler: (ctx) async {
        final log = agentRunLogFromWire(
          (ctx.args['log'] as Map).cast<String, dynamic>(),
        );
        // The run's own workspace must match the bound session — a client can't
        // write a run log into a foreign workspace (isolation invariant).
        if (log.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent run log belongs to a different workspace',
          );
        }
        await agentRunLogRepository.upsert(log);
        return {'ok': true};
      },
    ),

    // ---- Teams (workspace-scoped; members ownership-checked via their team) ----
    RepoOp(
      name: 'team.insertTeam',
      kind: RepoOpKind.mutate,
      requiredArgs: ['team'],
      handler: (ctx) async {
        final team = teamFromWire(
          (ctx.args['team'] as Map).cast<String, dynamic>(),
        );
        // A client cannot create a team in a foreign workspace.
        if (team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.insertTeam(team);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.updateTeam',
      kind: RepoOpKind.mutate,
      requiredArgs: ['team'],
      handler: (ctx) async {
        final team = teamFromWire(
          (ctx.args['team'] as Map).cast<String, dynamic>(),
        );
        // The incoming team must belong to the bound workspace, AND the
        // persisted row must too — block re-homing a foreign team.
        if (team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        final existing = await teamRepository.getTeam(team.id);
        if (existing != null && existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.updateTeam(team);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.deleteTeam',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final id = ctx.args['id'] as String;
        // ID-only delete is not a boundary: load + validate ownership first.
        final existing = await teamRepository.getTeam(id);
        if (existing != null && existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.deleteTeam(id);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.getTeam',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final team = await teamRepository.getTeam(ctx.args['id'] as String);
        if (team == null) {
          throw const NotFoundException('Team not found');
        }
        // ID-only lookup is not a scoping boundary; reject foreign rows.
        if (team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        return {'team': teamToWire(team)};
      },
    ),
    RepoOp(
      name: 'team.teamsForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: [],
      handler: (ctx) async {
        final teams = await teamRepository.teamsForWorkspace(ctx.workspaceId!);
        return {'teams': teams.map(teamToWire).toList()};
      },
    ),
    RepoOp(
      name: 'team.addMember',
      kind: RepoOpKind.mutate,
      requiredArgs: ['member'],
      handler: (ctx) async {
        final member = teamMemberFromWire(
          (ctx.args['member'] as Map).cast<String, dynamic>(),
        );
        // Members are keyed only by team_id; validate the team is owned by the
        // bound workspace before linking an agent to it.
        final team = await teamRepository.getTeam(member.teamId);
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.addMember(member);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.removeMember',
      kind: RepoOpKind.mutate,
      requiredArgs: ['team_id', 'agent_id'],
      handler: (ctx) async {
        final teamId = ctx.args['team_id'] as String;
        final team = await teamRepository.getTeam(teamId);
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.removeMember(teamId, ctx.args['agent_id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.membersOf',
      kind: RepoOpKind.read,
      requiredArgs: ['team_id'],
      handler: (ctx) async {
        final teamId = ctx.args['team_id'] as String;
        final team = await teamRepository.getTeam(teamId);
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        final members = await teamRepository.membersOf(teamId);
        return {'members': members.map(teamMemberToWire).toList()};
      },
    ),

    // ---- Isolated repos (CoW worktrees; workspace-scoped at the repository) ----
    RepoOp(
      name: 'isolated_repo.forUnitRepo',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id', 'repo_id'],
      handler: (ctx) async {
        final repo = await isolatedRepoRepository.forUnitRepo(
          ctx.workspaceId!,
          ctx.args['channel_id'] as String,
          ctx.args['repo_id'] as String,
        );
        return {'repo': repo == null ? null : isolatedRepoToWire(repo)};
      },
    ),
    RepoOp(
      name: 'isolated_repo.forChannel',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forChannel(
          ctx.workspaceId!,
          ctx.args['channel_id'] as String,
        );
        return {'repos': repos.map(isolatedRepoToWire).toList()};
      },
    ),
    RepoOp(
      name: 'isolated_repo.forTicket',
      kind: RepoOpKind.read,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forTicket(
          ctx.workspaceId!,
          ctx.args['ticket_id'] as String,
        );
        return {'repos': repos.map(isolatedRepoToWire).toList()};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique channel id;
    // each returned row carries its own workspaceId (mirrors the documented
    // IsolatedRepoRepository.forChannelAcrossWorkspaces exemption).
    RepoOp(
      name: 'isolated_repo.forChannelAcrossWorkspaces',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forChannelAcrossWorkspaces(
          ctx.args['channel_id'] as String,
        );
        return {'repos': repos.map(isolatedRepoToWire).toList()};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id (ticket events
    // carry no workspaceId); each row carries its own (mirrors the documented
    // IsolatedRepoRepository.forTicketAcrossWorkspaces exemption).
    RepoOp(
      name: 'isolated_repo.forTicketAcrossWorkspaces',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forTicketAcrossWorkspaces(
          ctx.args['ticket_id'] as String,
        );
        return {'repos': repos.map(isolatedRepoToWire).toList()};
      },
    ),
    RepoOp(
      name: 'isolated_repo.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo'],
      handler: (ctx) async {
        final repo = isolatedRepoFromWire(
          (ctx.args['repo'] as Map).cast<String, dynamic>(),
        );
        // The row's own workspace must match the bound session — a client can't
        // write a worktree into a foreign workspace (isolation invariant).
        if (repo.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Isolated repo belongs to a different workspace',
          );
        }
        await isolatedRepoRepository.upsert(repo);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'isolated_repo.deleteById',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await isolatedRepoRepository.deleteById(ctx.args['id'] as String);
        return {'ok': true};
      },
    ),
    // ---- Voice profiles (workspace-scoped at the repository) ----
    RepoOp(
      name: 'voice_profile.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final profiles = await voiceProfileRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'profiles': profiles.map(voiceProfileToWire).toList()};
      },
    ),
    RepoOp(
      name: 'voice_profile.getByName',
      kind: RepoOpKind.read,
      requiredArgs: ['display_name'],
      handler: (ctx) async {
        final profile = await voiceProfileRepository.getByName(
          ctx.workspaceId!,
          ctx.args['display_name'] as String,
        );
        return {
          'profile': profile == null ? null : voiceProfileToWire(profile),
        };
      },
    ),
    RepoOp(
      name: 'voice_profile.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['profile'],
      handler: (ctx) async {
        final profile = voiceProfileFromWire(
          (ctx.args['profile'] as Map).cast<String, dynamic>(),
        );
        // The profile's own workspace must match the bound session — a client
        // can't write a profile into a foreign workspace (isolation invariant).
        if (profile.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Voice profile belongs to a different workspace',
          );
        }
        await voiceProfileRepository.upsert(profile);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'voice_profile.enroll',
      kind: RepoOpKind.mutate,
      requiredArgs: ['display_name', 'sample_embedding'],
      handler: (ctx) async {
        await voiceProfileRepository.enroll(
          workspaceId: ctx.workspaceId!,
          displayName: ctx.args['display_name'] as String,
          sampleEmbedding: ((ctx.args['sample_embedding'] as List?) ?? const [])
              .map((e) => (e as num).toDouble())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'voice_profile.unenroll',
      kind: RepoOpKind.mutate,
      requiredArgs: ['display_name', 'sample_embedding'],
      handler: (ctx) async {
        await voiceProfileRepository.unenroll(
          workspaceId: ctx.workspaceId!,
          displayName: ctx.args['display_name'] as String,
          sampleEmbedding: ((ctx.args['sample_embedding'] as List?) ?? const [])
              .map((e) => (e as num).toDouble())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'voice_profile.rename',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'display_name'],
      handler: (ctx) async {
        // The repository scopes the rename by workspace, so a foreign id is a
        // no-op (an ID-only lookup is not a scoping boundary).
        await voiceProfileRepository.rename(
          workspaceId: ctx.workspaceId!,
          id: ctx.args['id'] as String,
          displayName: ctx.args['display_name'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'voice_profile.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        // The repository scopes the delete by workspace, so a foreign id is a
        // no-op (an ID-only lookup is not a scoping boundary).
        await voiceProfileRepository.delete(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        return {'ok': true};
      },
    ),
    // ---- Meetings (workspace-scoped at the repository) ----
    //
    // Reads + the user-facing edits the web meeting screens reach (per-segment
    // / whole-speaker rename, voice-profile enrollment provenance, action-item /
    // decision CRUD). The recorder-only writes (upsert, appendSegment,
    // replace*, getUnfinalized) stay host-side — the desktop recorder owns them
    // — so they have no RPC op. Every method below scopes by `ctx.workspaceId!`
    // (the bound session, never a client arg), and the DAO filters on it, so a
    // meeting/segment/item owned by another workspace is simply not matched.
    RepoOp(
      name: 'meeting.getByWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final meetings = await meetingRepository.getByWorkspace(
          ctx.workspaceId!,
        );
        return {'meetings': meetings.map(meetingToWire).toList()};
      },
    ),
    RepoOp(
      name: 'meeting.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        // Scoped lookup: a meeting owned by another workspace is simply not
        // found (the workspace binding is the boundary, not id uniqueness).
        final meeting = await meetingRepository.getById(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'meeting': meeting == null ? null : meetingToWire(meeting)};
      },
    ),
    RepoOp(
      name: 'meeting.getSegments',
      kind: RepoOpKind.read,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        final segments = await meetingRepository.getSegments(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'segments': segments.map(meetingSegmentToWire).toList()};
      },
    ),
    RepoOp(
      name: 'meeting.getSpeakers',
      kind: RepoOpKind.read,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        final speakers = await meetingRepository.getSpeakers(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'speakers': speakers.map(meetingSpeakerLabelToWire).toList()};
      },
    ),
    RepoOp(
      name: 'meeting.audioClip',
      kind: RepoOpKind.read,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        // Playback metadata for the meeting's retained audio: the scrubber
        // waveform + total duration. Workspace-scoped via getById (a foreign
        // meeting is simply not found). Folds the per-channel WAVs into
        // `mixed.wav` as a side effect, so the subsequent `/meeting/audio` byte
        // fetch finds an assembled file even before the summary pipeline's
        // assemble-playback step has run. `available: false` when the meeting
        // kept no audio or its files are gone (the client then hides the bar).
        final meeting = await meetingRepository.getById(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        final dir = meeting?.audioPath;
        if (meeting == null || dir == null || dir.isEmpty) {
          return {'available': false};
        }
        final clip =
            await loadMeetingAudioClip(MeetingAudioRequest(audioDirPath: dir));
        if (clip == null) {
          return {'available': false};
        }
        return {
          'available': true,
          'waveform': clip.waveform,
          'duration_ms': clip.durationMs,
        };
      },
    ),
    RepoOp(
      name: 'meeting.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        // delete() is itself workspace-scoped — a foreign meeting is a no-op
        // there, so passing the bound workspace is the boundary.
        await meetingRepository.delete(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.updateTitle',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'title'],
      handler: (ctx) async {
        // updateTitle is itself workspace-scoped — a foreign meeting matches
        // nothing (no-op), so the bound workspace is the boundary. Only the
        // title is written; the recorder-owned fields stay untouched.
        await meetingRepository.updateTitle(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          title: ctx.args['title'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.updateNotes',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'notes'],
      handler: (ctx) async {
        // updateNotes is itself workspace-scoped — a foreign meeting matches
        // nothing (no-op), so the bound workspace is the boundary. Only the
        // user notes are written; the recorder-owned fields stay untouched.
        await meetingRepository.updateNotes(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          notes: ctx.args['notes'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.setSegmentSpeakerName',
      kind: RepoOpKind.mutate,
      requiredArgs: ['segment_id'],
      handler: (ctx) async {
        await meetingRepository.setSegmentSpeakerName(
          ctx.workspaceId!,
          ctx.args['segment_id'] as String,
          ctx.args['name'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.renameSpeakerByLabel',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'channel', 'label'],
      handler: (ctx) async {
        await meetingRepository.renameSpeakerByLabel(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
          label: ctx.args['label'] as String,
          displayName: ctx.args['display_name'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.clearSpeakerNameOverridesForLabel',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'channel', 'label'],
      handler: (ctx) async {
        await meetingRepository.clearSpeakerNameOverridesForLabel(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
          label: ctx.args['label'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.setSpeakerEnrolledProfile',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'channel', 'label'],
      handler: (ctx) async {
        await meetingRepository.setSpeakerEnrolledProfile(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
          label: ctx.args['label'] as String,
          profileName: ctx.args['profile_name'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.addActionItem',
      kind: RepoOpKind.mutate,
      requiredArgs: ['item'],
      handler: (ctx) async {
        final item = meetingActionItemFromWire(
          (ctx.args['item'] as Map).cast<String, dynamic>(),
        );
        // The item's own workspace must match the bound session — a client
        // can't seed a row into a foreign workspace (isolation invariant).
        if (item.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Meeting action item belongs to a different workspace',
          );
        }
        await meetingRepository.addActionItem(item);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.updateActionItem',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'content'],
      handler: (ctx) async {
        await meetingRepository.updateActionItem(
          workspaceId: ctx.workspaceId!,
          id: ctx.args['id'] as String,
          content: ctx.args['content'] as String,
          owner: ctx.args['owner'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.deleteActionItem',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await meetingRepository.deleteActionItem(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.setActionItemDone',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'done'],
      handler: (ctx) async {
        await meetingRepository.setActionItemDone(
          workspaceId: ctx.workspaceId!,
          id: ctx.args['id'] as String,
          done: ctx.args['done'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.setActionItemTicket',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'ticket_id'],
      handler: (ctx) async {
        await meetingRepository.setActionItemTicket(
          workspaceId: ctx.workspaceId!,
          id: ctx.args['id'] as String,
          ticketId: ctx.args['ticket_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.addDecision',
      kind: RepoOpKind.mutate,
      requiredArgs: ['decision'],
      handler: (ctx) async {
        final decision = meetingDecisionFromWire(
          (ctx.args['decision'] as Map).cast<String, dynamic>(),
        );
        // The decision's own workspace must match the bound session.
        if (decision.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Meeting decision belongs to a different workspace',
          );
        }
        await meetingRepository.addDecision(decision);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.updateDecision',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'content'],
      handler: (ctx) async {
        await meetingRepository.updateDecision(
          workspaceId: ctx.workspaceId!,
          id: ctx.args['id'] as String,
          content: ctx.args['content'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.deleteDecision',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await meetingRepository.deleteDecision(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        return {'ok': true};
      },
    ),
    // ---- Meeting recording ingest (host transcribes RPC-streamed audio) ----
    //
    // Live recording from a thin (web) client: the browser captures mic +
    // system audio, downsamples to 16 kHz mono PCM16, and streams frames here;
    // the host runs the same windowed transcription + echo-dedup the desktop
    // recorder runs and appends segments the client watches via
    // `meeting.watchSegments`. Declared only when [meetingRecording] is wired
    // (a host that resolved a voice model). Every op scopes by `ctx.workspaceId!`
    // (the bound session, never a client arg); the recording-session map is keyed
    // by `(workspaceId, meetingId)`, so ingest/stop for a foreign or
    // already-stopped meeting throws rather than touching another workspace.
    if (meetingRecording != null) ...[
      RepoOp(
        name: 'meeting.startRecording',
        kind: RepoOpKind.mutate,
        requiredArgs: ['title', 'mode'],
        handler: (ctx) async {
          // The SERVER mints the meeting id (never a client value) so a client
          // can't collide with / clobber a foreign workspace's meeting via
          // upsert's insert-or-replace. The client uses the returned id for
          // ingest/stop and the `meeting.watchSegments` subscription.
          final meetingId = await meetingRecording.start(
            workspaceId: ctx.workspaceId!,
            title: ctx.args['title'] as String,
            mode: ctx.args['mode'] as String,
          );
          return {'ok': true, 'meeting_id': meetingId};
        },
      ),
      RepoOp(
        name: 'meeting.ingestAudio',
        kind: RepoOpKind.mutate,
        requiredArgs: ['meeting_id', 'channel', 'seq', 'pcm'],
        handler: (ctx) async {
          await meetingRecording.ingest(
            workspaceId: ctx.workspaceId!,
            meetingId: ctx.args['meeting_id'] as String,
            channel: ctx.args['channel'] as String,
            seq: (ctx.args['seq'] as num).toInt(),
            // PCM16 frames travel base64-encoded in the JSON-RPC envelope (the
            // transport has no raw-binary frame; see the terminal PTY ops).
            pcm: base64Decode(ctx.args['pcm'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'meeting.stopRecording',
        kind: RepoOpKind.mutate,
        requiredArgs: ['meeting_id'],
        handler: (ctx) async {
          await meetingRecording.stop(
            workspaceId: ctx.workspaceId!,
            meetingId: ctx.args['meeting_id'] as String,
            summaryInstructions:
                ctx.args['summary_instructions'] as String?,
          );
          return {'ok': true};
        },
      ),
    ],
    // ---- Analytics / achievements / streaks (workspace-scoped) ----
    //
    // READ surface only. Every per-agent / leaderboard read sources
    // `ctx.workspaceId!` (the bound session, never a client arg) as the leading
    // `workspaceId` — the impl JOINs Agents on it, so a foreign agent simply
    // yields no rows. The WRITE methods (`unlock`/`updateStreak`) run server-side
    // via the XpEngine and are intentionally NOT exposed here.
    RepoOp(
      name: 'analytics.agentScorecard',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final card = await analyticsRepository.getAgentScorecard(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {'scorecard': card == null ? null : agentScorecardToWire(card)};
      },
    ),
    RepoOp(
      name: 'analytics.allAgentScorecards',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final cards = await analyticsRepository.getAllAgentScorecards(
          ctx.workspaceId!,
        );
        return {'scorecards': cards.map(agentScorecardToWire).toList()};
      },
    ),
    RepoOp(
      name: 'analytics.leaderboard',
      kind: RepoOpKind.read,
      requiredArgs: ['start', 'end'],
      handler: (ctx) async {
        final entries = await analyticsRepository.getLeaderboard(
          ctx.workspaceId!,
          DateTime.parse(ctx.args['start'] as String),
          DateTime.parse(ctx.args['end'] as String),
        );
        return {'entries': entries.map(leaderboardEntryToWire).toList()};
      },
    ),
    RepoOp(
      name: 'analytics.workspaceHealth',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        // Return the BOUND workspace's health (ignore any client arg).
        final health = await analyticsRepository.getWorkspaceHealth(
          ctx.workspaceId!,
        );
        return {'health': health == null ? null : workspaceHealthToWire(health)};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: the cross-org dashboard "workspace pulse" view
    // intentionally spans every workspace (mirrors
    // AnalyticsRepository.getAllWorkspaceHealth, the documented exemption). For a
    // single workspace's health use `analytics.workspaceHealth`.
    RepoOp(
      name: 'analytics.allWorkspaceHealth',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final all = await analyticsRepository.getAllWorkspaceHealth();
        return {'health': all.map(workspaceHealthToWire).toList()};
      },
    ),
    RepoOp(
      name: 'achievements.getByAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final list = await achievementRepository.getByAgent(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {'achievements': list.map(achievementToWire).toList()};
      },
    ),
    RepoOp(
      name: 'achievements.isUnlocked',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id', 'badge_key'],
      handler: (ctx) async {
        final unlocked = await achievementRepository.isUnlocked(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
          ctx.args['badge_key'] as String,
        );
        return {'unlocked': unlocked};
      },
    ),
    RepoOp(
      name: 'streaks.getByAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final list = await streakRepository.getByAgent(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {'streaks': list.map(streakToWire).toList()};
      },
    ),
    RepoOp(
      name: 'streaks.getCurrent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id', 'streak_type'],
      handler: (ctx) async {
        final count = await streakRepository.getCurrentStreak(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
          ctx.args['streak_type'] as String,
        );
        return {'count': count};
      },
    ),
    // ---- Calendar (workspace-scoped) ----
    //
    // READ surface only. Every read sources `ctx.workspaceId!` (the bound
    // session, never a client arg) as the leading `workspaceId` — the impl
    // scopes every query by it, so a foreign-workspace row simply yields
    // nothing. The WRITE surface (account connect/disconnect, RSVP, the sync
    // reconciler, the alert sweep, meeting linking) depends on the host-resident
    // OAuth tokens + Google API client and is intentionally NOT exposed here.
    RepoOp(
      name: 'calendar.getAccounts',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final accounts = await calendarRepository.getAccounts(ctx.workspaceId!);
        return {'accounts': accounts.map(calendarAccountToWire).toList()};
      },
    ),
    RepoOp(
      name: 'calendar.getEventForMeeting',
      kind: RepoOpKind.read,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        final event = await calendarRepository.getEventForMeeting(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'event': event == null ? null : calendarEventToWire(event)};
      },
    ),
    RepoOp(
      name: 'calendar.getMeetingIdForEvent',
      kind: RepoOpKind.read,
      requiredArgs: ['calendar_event_id'],
      handler: (ctx) async {
        final meetingId = await calendarRepository.getMeetingIdForEvent(
          ctx.workspaceId!,
          ctx.args['calendar_event_id'] as String,
        );
        return {'meeting_id': meetingId};
      },
    ),
    // Meeting↔event linking is a pure junction-table write (no OAuth / Google
    // API), so unlike the rest of the calendar WRITE surface it IS served. Both
    // the meeting and the event are workspace-scoped host-side, so binding
    // `ctx.workspaceId!` is the isolation boundary (a foreign row is a no-op).
    RepoOp(
      name: 'calendar.linkMeetingToEvent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'calendar_event_id'],
      handler: (ctx) async {
        await calendarRepository.linkMeetingToEvent(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          calendarEventId: ctx.args['calendar_event_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'calendar.unlinkMeeting',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        await calendarRepository.unlinkMeeting(
          ctx.workspaceId!,
          ctx.args['meeting_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // RSVP write: the host PATCHes the response on its own Google OAuth token
    // (the thin client holds none) and optimistically upserts the event. The
    // event id is the LOCAL id, looked up workspace-scoped (a foreign id is
    // simply not found — the isolation boundary).
    RepoOp(
      name: 'calendar.rsvp',
      kind: RepoOpKind.mutate,
      requiredArgs: ['event_id', 'response'],
      handler: (ctx) async {
        final fn = calendarRsvp;
        if (fn == null) {
          throw const NotFoundException(
            'Calendar RSVP is managed on the server host',
          );
        }
        await fn(
          workspaceId: ctx.workspaceId!,
          eventId: ctx.args['event_id'] as String,
          responseStatus: ctx.args['response'] as String,
        );
        return {'ok': true};
      },
    ),
    // Manual "refresh now" — sync the bound workspace on the host immediately.
    RepoOp(
      name: 'calendar.refreshNow',
      kind: RepoOpKind.mutate,
      handler: (ctx) async {
        await calendarRefresh?.call(ctx.workspaceId!);
        return {'ok': true};
      },
    ),
    // On-demand range load when the client navigates outside the rolling sync
    // window. Bound workspace is server-supplied (`ctx.workspaceId!`).
    RepoOp(
      name: 'calendar.ensureRangeLoaded',
      kind: RepoOpKind.mutate,
      requiredArgs: ['from', 'to'],
      handler: (ctx) async {
        final from = DateTime.tryParse(ctx.args['from'] as String);
        final to = DateTime.tryParse(ctx.args['to'] as String);
        if (from != null && to != null) {
          await calendarEnsureRange?.call(ctx.workspaceId!, from, to);
        }
        return {'ok': true};
      },
    ),
    // ---- Calendar GUI connect (device-code OAuth, host-owned tokens) ----
    //
    // A thin (web/desktop) client connects a Google account by supplying a
    // client id + secret; the HOST runs the device-code flow, stores the refresh
    // token server-side, and syncs. `beginConnect` returns a code + URL + an
    // opaque handle; the client polls `pollConnect` until approved. Every op
    // sources `ctx.workspaceId!` (the bound session) — the handle is bound to
    // the workspace that began it, and `disconnect`'s account id embeds its
    // workspace, so a foreign-workspace handle/account is rejected. Declared
    // only when [calendarConnect] is wired (a host with the Google stack).
    if (calendarConnect != null) ...[
      RepoOp(
        name: 'calendar.beginConnect',
        kind: RepoOpKind.mutate,
        requiredArgs: ['client_id', 'client_secret'],
        handler: (ctx) async {
          final begin = await calendarConnect.begin(
            workspaceId: ctx.workspaceId!,
            clientId: ctx.args['client_id'] as String,
            clientSecret: ctx.args['client_secret'] as String,
          );
          return {
            'handle': begin.handle,
            'user_code': begin.userCode,
            'verification_url': begin.verificationUrl,
            'interval_seconds': begin.intervalSeconds,
            'expires_in_seconds': begin.expiresInSeconds,
          };
        },
      ),
      RepoOp(
        name: 'calendar.pollConnect',
        kind: RepoOpKind.mutate,
        requiredArgs: ['handle'],
        handler: (ctx) async {
          final poll = await calendarConnect.poll(
            workspaceId: ctx.workspaceId!,
            handle: ctx.args['handle'] as String,
          );
          return {
            'status': poll.status.name,
            if (poll.accountEmail != null) 'account_email': poll.accountEmail,
          };
        },
      ),
      RepoOp(
        name: 'calendar.disconnect',
        kind: RepoOpKind.mutate,
        requiredArgs: ['account_id'],
        handler: (ctx) async {
          await calendarConnect.disconnect(
            workspaceId: ctx.workspaceId!,
            accountId: ctx.args['account_id'] as String,
          );
          return {'ok': true};
        },
      ),
    ],
    // ---- PR lifecycle (workspace-scoped at the `PullRequests` table) ----
    //
    // The thin client BOTH reads and writes this surface. Every op sources
    // `ctx.workspaceId!` (the bound session, never a client arg). `createDraft`
    // stamps that workspace on the new row. The id-keyed ops (`getById` /
    // `updateDraft` / `createOnGitHub` / `delete`) are NOT a boundary on their
    // own — id uniqueness is not isolation — so each first loads the row via
    // `getById` and asserts it belongs to the bound workspace before acting; a
    // foreign-workspace id is rejected with `WorkspaceMismatchException` (read
    // paths simply return null). Publishing runs against the host-resident GitHub
    // token.
    RepoOp(
      name: 'pr_lifecycle.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final pr = await prLifecycleRepository.getById(ctx.args['id'] as String);
        // ID-only lookup is not a boundary — drop a row owned by another
        // workspace so it never surfaces (isolation invariant).
        if (pr == null || pr.workspaceId != ctx.workspaceId) {
          return {'pr': null};
        }
        return {'pr': prGenerationToWire(pr)};
      },
    ),
    RepoOp(
      name: 'pr_lifecycle.createDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['title', 'body'],
      handler: (ctx) async {
        final id = await prLifecycleRepository.createDraft(
          workspaceId: ctx.workspaceId!,
          title: ctx.args['title'] as String,
          body: ctx.args['body'] as String,
          diffSummary: ctx.args['diff_summary'] as String?,
        );
        return {'id': id};
      },
    ),
    RepoOp(
      name: 'pr_lifecycle.updateDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['pr_id'],
      handler: (ctx) async {
        final prId = ctx.args['pr_id'] as String;
        await assertPrLifecycleOwned(ctx.workspaceId, prId);
        await prLifecycleRepository.updateDraft(
          prId,
          title: ctx.args['title'] as String?,
          body: ctx.args['body'] as String?,
          status: ctx.args['status'] as String?,
          githubPrNumber: (ctx.args['github_pr_number'] as num?)?.toInt(),
          githubPrUrl: ctx.args['github_pr_url'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_lifecycle.createOnGitHub',
      kind: RepoOpKind.mutate,
      requiredArgs: ['pr_id', 'owner', 'repo', 'title', 'body', 'head', 'base'],
      handler: (ctx) async {
        final prId = ctx.args['pr_id'] as String;
        await assertPrLifecycleOwned(ctx.workspaceId, prId);
        final result = await prLifecycleRepository.createOnGitHub(
          prId: prId,
          owner: ctx.args['owner'] as String,
          repo: ctx.args['repo'] as String,
          title: ctx.args['title'] as String,
          body: ctx.args['body'] as String,
          head: ctx.args['head'] as String,
          base: ctx.args['base'] as String,
          draft: ctx.args['draft'] as bool? ?? false,
          assignees: stringListArg(ctx.args['assignees']),
          reviewerUsers: stringListArg(ctx.args['reviewer_users']),
          reviewerTeams: stringListArg(ctx.args['reviewer_teams']),
        );
        return {'result': result};
      },
    ),
    RepoOp(
      name: 'pr_lifecycle.delete',
      kind: RepoOpKind.destructive,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final id = ctx.args['id'] as String;
        await assertPrLifecycleOwned(ctx.workspaceId, id);
        await prLifecycleRepository.delete(id);
        return {'ok': true};
      },
    ),
    // ---- Open PR list (the PR-list screen's data; workspace-scoped) ----
    // Fetched SERVER-SIDE on the gh-authenticated client: the thin client holds
    // no GitHub token, so it reads the workspace's open PRs (grouped per linked
    // repo, checks already overlaid) over this op instead of hitting GitHub
    // itself. The linked repos are resolved from the BOUND workspace — never a
    // client-sent list. `authenticated:false` means the server has no gh token.
    RepoOp(
      name: 'pr.listOpenForWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final fetch = fetchOpenPrList;
        if (fetch == null) {
          return {'authenticated': false, 'repos': <Map<String, dynamic>>[]};
        }
        final linked = await workspaceRepository
            .watchReposForWorkspace(ctx.workspaceId!)
            .first;
        final ghRepos = [
          for (final r in linked)
            if (r.hasGitHubRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'authenticated': true, 'repos': <Map<String, dynamic>>[]};
        }
        final groups = await fetch(ghRepos);
        return {
          'authenticated': true,
          'repos': [
            for (final g in groups)
              {
                'repo_id': g.repo.id,
                'repo_full_name': g.repo.fullName,
                'github_owner': g.repo.githubOwner,
                'github_repo_name': g.repo.githubRepoName,
                'has_more': g.hasMore,
                'prs': [for (final pr in g.prs) pullRequestToWire(pr)],
              },
          ],
        };
      },
    ),
    // The SERVER's authenticated GitHub user (global — not workspace data). The
    // thin client holds no token, so its `login`/avatar resolve from the host.
    RepoOp(
      name: 'github.currentUser',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final user = await fetchCurrentGitHubUser?.call();
        return {'user': user};
      },
    ),
    // The dashboard's priority reviews: open PRs requesting the server user's
    // review across the BOUND workspace's linked repos (server-side gh search).
    RepoOp(
      name: 'pr.searchReviewRequestedForWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final fetch = fetchReviewRequested;
        if (fetch == null) {
          return {'reviews': <Map<String, dynamic>>[]};
        }
        final linked = await workspaceRepository
            .watchReposForWorkspace(ctx.workspaceId!)
            .first;
        final ghRepos = [
          for (final r in linked)
            if (r.hasGitHubRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'reviews': <Map<String, dynamic>>[]};
        }
        final results = await fetch(ghRepos);
        return {
          'reviews': [
            for (final r in results)
              {
                'repo_id': r.repo.id,
                'repo_full_name': r.repo.fullName,
                'pr': pullRequestToWire(r.pr),
              },
          ],
        };
      },
    ),
    // The PR-list "reviewed by me" overlay: `"<owner/repo>#<number>"` keys of the
    // open PRs the server user has reviewed across the bound workspace's repos.
    RepoOp(
      name: 'pr.searchReviewedByForWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final fetch = fetchReviewedBy;
        if (fetch == null) {
          return {'keys': <String>[]};
        }
        final linked = await workspaceRepository
            .watchReposForWorkspace(ctx.workspaceId!)
            .first;
        final ghRepos = [
          for (final r in linked)
            if (r.hasGitHubRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'keys': <String>[]};
        }
        final keys = await fetch(ghRepos);
        return {'keys': keys.toList()};
      },
    ),
    // The PR-queue free-text search across the bound workspace's linked repos.
    RepoOp(
      name: 'pr.searchForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: ['query'],
      handler: (ctx) async {
        final fetch = fetchPrSearch;
        if (fetch == null) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        final ghRepos = await linkedGitHubRepos(ctx.workspaceId!);
        if (ghRepos.isEmpty) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        final groups = await fetch(ghRepos, ctx.args['query'] as String);
        return {
          'repos': [
            for (final g in groups)
              {
                'repo_id': g.repo.id,
                'prs': [for (final pr in g.prs) pullRequestToWire(pr)],
              },
          ],
        };
      },
    ),
    // Per-author PR counts (profile rail) across the bound workspace's repos.
    RepoOp(
      name: 'pr.countsByAuthorForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: ['login'],
      handler: (ctx) async {
        final fetch = fetchPrCountsByAuthor;
        final ghRepos = fetch == null
            ? const <Repo>[]
            : await linkedGitHubRepos(ctx.workspaceId!);
        if (fetch == null || ghRepos.isEmpty) {
          return {'open': 0, 'draft': 0, 'merged': 0, 'closed': 0};
        }
        final c = await fetch(ghRepos, ctx.args['login'] as String);
        return {
          'open': c.open,
          'draft': c.draft,
          'merged': c.merged,
          'closed': c.closed,
        };
      },
    ),
    // Per-author merged/closed PR history (first page) across the bound
    // workspace's repos.
    RepoOp(
      name: 'pr.closedByAuthorForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: ['login'],
      handler: (ctx) async {
        final fetch = fetchClosedByAuthor;
        if (fetch == null) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        final ghRepos = await linkedGitHubRepos(ctx.workspaceId!);
        if (ghRepos.isEmpty) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        final groups = await fetch(ghRepos, ctx.args['login'] as String);
        return {
          'repos': [
            for (final g in groups)
              {
                'repo_id': g.repo.id,
                'has_more': g.hasMore,
                'prs': [for (final pr in g.prs) pullRequestToWire(pr)],
              },
          ],
        };
      },
    ),
    // GitHub org members (profile people picker). Owners are derived SERVER-SIDE
    // from the bound workspace's linked repos — never a client-sent list.
    RepoOp(
      name: 'github.orgMembers',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final fetch = fetchOrgMembers;
        if (fetch == null) {
          return {'members': <Map<String, dynamic>>[]};
        }
        final ghRepos = await linkedGitHubRepos(ctx.workspaceId!);
        final owners = {
          for (final r in ghRepos)
            if (r.githubOwner.isNotEmpty) r.githubOwner,
        }.toList();
        if (owners.isEmpty) {
          return {'members': <Map<String, dynamic>>[]};
        }
        return {'members': await fetch(owners)};
      },
    ),
    // ---- GitHub read surfaces (compose PR / peek / # search / repo perm /
    // profile / PR-list + profile pagination) ----
    // Run SERVER-SIDE on the host's gh client; the thin client holds no token.
    // Every owner/repo arg is validated against the bound workspace's linked
    // repos before the fetch (workspace isolation). Null `githubRead` (no gh
    // token) → empty/degraded results, mirroring the PR-list `authenticated`
    // gate.
    RepoOp(
      name: 'github.repoBranches',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'branches': <String>[]};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        return {'branches': await read.repoBranches(owner, repo)};
      },
    ),
    RepoOp(
      name: 'github.defaultBranch',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'branch': ''};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        return {'branch': await read.defaultBranch(owner, repo)};
      },
    ),
    RepoOp(
      name: 'github.prTemplates',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'templates': <Map<String, dynamic>>[]};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final templates = await read.prTemplates(owner, repo);
        return {
          'templates': [
            for (final t in templates)
              {'name': t.name, 'body': t.body, 'is_default': t.isDefault},
          ],
        };
      },
    ),
    RepoOp(
      name: 'github.compareBranches',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'base', 'head'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'comparison': null};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final c = await read.compareBranches(
          owner,
          repo,
          ctx.args['base'] as String,
          ctx.args['head'] as String,
        );
        if (c == null) {
          return {'comparison': null};
        }
        return {
          'comparison': {
            'files': [for (final f in c.files) prFileToWire(f)],
            'commits': [for (final cm in c.commits) prCommitToWire(cm)],
            'additions': c.additions,
            'deletions': c.deletions,
            'total_commits': c.totalCommits,
          },
        };
      },
    ),
    RepoOp(
      name: 'github.prContent',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'number'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'content': null};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final pc = await read.prContent(
          owner,
          repo,
          (ctx.args['number'] as num).toInt(),
        );
        if (pc == null) {
          return {'content': null};
        }
        return {
          'content': {
            'body': pc.body,
            'body_html': ?pc.bodyHtml,
            'changed_files': pc.changedFiles,
            'commits_count': pc.commitsCount,
          },
        };
      },
    ),
    RepoOp(
      name: 'github.searchIssues',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'query'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'issues': <Map<String, dynamic>>[]};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final issues = await read.searchIssues(
          owner,
          repo,
          ctx.args['query'] as String,
        );
        return {
          'issues': [
            for (final i in issues) {'number': i.number, 'title': i.title},
          ],
        };
      },
    ),
    RepoOp(
      name: 'github.repoPermission',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'permission': 'none'};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        return {'permission': await read.repoPermission(owner, repo)};
      },
    ),
    // A public GitHub user profile — global public data keyed only by login, so
    // NOT workspace-scoped (mirrors `github.currentUser`).
    RepoOp(
      name: 'github.userProfile',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['login'],
      handler: (ctx) async {
        final read = githubRead;
        return {'profile': await read?.userProfile(ctx.args['login'] as String)};
      },
    ),
    // The githubstatus.com summary, relayed raw for the client to parse. Global
    // (not workspace data) and token-less.
    RepoOp(
      name: 'github.serviceStatus',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchGitHubServiceStatus;
        if (fetch == null) {
          return {'summary': null};
        }
        return {'summary': await fetch()};
      },
    ),
    // ---- GIF picker (Klipy, server-side; global, not workspace data) ----
    // The composer's GIF picker. Run on the host's Klipy app key (the thin
    // client holds none, and the browser can't reach Klipy cross-origin). Null
    // fetchers (no app key) → empty results.
    RepoOp(
      name: 'gif.search',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['query'],
      handler: (ctx) async {
        final fetch = gifSearch;
        if (fetch == null) {
          return {'gifs': <Map<String, dynamic>>[]};
        }
        return {'gifs': await fetch(ctx.args['query'] as String)};
      },
    ),
    RepoOp(
      name: 'gif.trending',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = gifTrending;
        if (fetch == null) {
          return {'gifs': <Map<String, dynamic>>[]};
        }
        return {'gifs': await fetch()};
      },
    ),
    // The PR-list "load more": the next REST page of open PRs on `owner/repo`.
    RepoOp(
      name: 'pr.openPageForRepo',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'page'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'prs': <Map<String, dynamic>>[], 'has_more': false};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final page = await read.openPrPage(
          owner,
          repo,
          (ctx.args['page'] as num).toInt(),
        );
        return {
          'prs': [for (final pr in page.prs) pullRequestToWire(pr)],
          'has_more': page.hasMore,
        };
      },
    ),
    // The profile "load more": the next page of `login`'s merged/closed PRs on
    // `owner/repo`.
    RepoOp(
      name: 'pr.closedByAuthorPageForRepo',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'login', 'page'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {'prs': <Map<String, dynamic>>[], 'has_more': false};
        }
        final owner = ctx.args['owner'] as String;
        final repo = ctx.args['repo'] as String;
        await requireWorkspaceGitHubRepo(ctx.workspaceId!, owner, repo);
        final page = await read.closedByAuthorPage(
          owner,
          repo,
          ctx.args['login'] as String,
          (ctx.args['page'] as num).toInt(),
        );
        return {
          'prs': [for (final pr in page.prs) pullRequestToWire(pr)],
          'has_more': page.hasMore,
        };
      },
    ),
    // ---- Ticket links (workspace-scoped at the repository) ----
    RepoOp(
      name: 'ticket_link.insert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['link'],
      handler: (ctx) async {
        final link = ticketLinkFromWire(
          (ctx.args['link'] as Map).cast<String, dynamic>(),
        );
        // The link's own workspace must match the bound session — a client
        // can't write a link into a foreign workspace (isolation invariant).
        if (link.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Ticket link belongs to a different workspace',
          );
        }
        await ticketLinkRepository.insert(link);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'ticket_link.deleteById',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        // deleteById is scoped by workspaceId in the WHERE clause, so a
        // foreign-workspace row simply isn't matched (isolation invariant).
        final deleted = await ticketLinkRepository.deleteById(
          ctx.args['id'] as String,
          workspaceId: ctx.workspaceId!,
        );
        return {'deleted': deleted};
      },
    ),
    RepoOp(
      name: 'ticket_link.deleteByEndpoints',
      kind: RepoOpKind.mutate,
      requiredArgs: ['source_ticket_id', 'target_ticket_id', 'type'],
      handler: (ctx) async {
        final type = TicketLinkType.fromStorage(ctx.args['type'] as String?);
        if (type == null) {
          throw const NotFoundException('Unknown ticket link type');
        }
        // Scoped by workspaceId in the WHERE clause (isolation invariant).
        final deleted = await ticketLinkRepository.deleteByEndpoints(
          workspaceId: ctx.workspaceId!,
          sourceTicketId: ctx.args['source_ticket_id'] as String,
          targetTicketId: ctx.args['target_ticket_id'] as String,
          type: type,
        );
        return {'deleted': deleted};
      },
    ),
    RepoOp(
      name: 'ticket_link.getForTicket',
      kind: RepoOpKind.read,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final links = await ticketLinkRepository.getForTicket(
          ctx.workspaceId!,
          ctx.args['ticket_id'] as String,
        );
        return {'links': links.map(ticketLinkToWire).toList()};
      },
    ),
    // ---- Pipeline runs (runs are workspace-scoped; step runs are owned
    // through their parent run, so ID-only step ops validate ownership by
    // loading the parent run and checking its workspaceId) ----
    //
    // The PipelineRun DAO exposes ID-only lookups (getRun/watchRun) and step
    // ops keyed only by run/step id — an ID is NOT a scoping boundary, so each
    // op below fetches the owning run and asserts run.workspaceId ==
    // ctx.workspaceId, denying foreign access loudly (workspace-isolation
    // invariant). These two helpers are the single ownership chokepoint.
    RepoOp(
      name: 'pipeline_run.insertRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run'],
      handler: (ctx) async {
        final run = pipelineRunFromWire(
          (ctx.args['run'] as Map).cast<String, dynamic>(),
        );
        if (run.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline run belongs to a different workspace',
          );
        }
        await pipelineRunRepository.insertRun(run);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.updateRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run'],
      handler: (ctx) async {
        final run = pipelineRunFromWire(
          (ctx.args['run'] as Map).cast<String, dynamic>(),
        );
        if (run.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline run belongs to a different workspace',
          );
        }
        // Guard against retargeting an existing foreign run via the wire id.
        await assertPipelineRunOwned(ctx.workspaceId!, run.id);
        await pipelineRunRepository.updateRun(run);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.getRun',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final run = await pipelineRunRepository.getRun(ctx.args['id'] as String);
        if (run == null) {
          throw const NotFoundException('Pipeline run not found');
        }
        // ID-only lookup is not a boundary — reject a foreign run.
        if (run.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline run belongs to a different workspace',
          );
        }
        return {'run': pipelineRunToWire(run)};
      },
    ),
    RepoOp(
      name: 'pipeline_run.updateRunState',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id', 'state'],
      handler: (ctx) async {
        await assertPipelineRunOwned(
          ctx.workspaceId!,
          ctx.args['run_id'] as String,
        );
        await pipelineRunRepository.updateRunState(
          ctx.args['run_id'] as String,
          (ctx.args['state'] as Map).cast<String, dynamic>(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.incrementCost',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id', 'cents', 'tokens'],
      handler: (ctx) async {
        await assertPipelineRunOwned(
          ctx.workspaceId!,
          ctx.args['run_id'] as String,
        );
        await pipelineRunRepository.incrementCost(
          ctx.args['run_id'] as String,
          (ctx.args['cents'] as num).toInt(),
          (ctx.args['tokens'] as num).toInt(),
        );
        return {'ok': true};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: the resume-on-startup reconciler needs every
    // non-terminal run across all workspaces (mirrors
    // PipelineRunRepository.nonTerminalRuns, a documented startup-reconciler
    // exemption). The server still authenticates the device.
    RepoOp(
      name: 'pipeline_run.nonTerminalRuns',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final runs = await pipelineRunRepository.nonTerminalRuns();
        return {'runs': runs.map(pipelineRunToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pipeline_run.activeForDedupKey',
      kind: RepoOpKind.read,
      requiredArgs: ['template_id', 'dedup_key'],
      handler: (ctx) async {
        final run = await pipelineRunRepository.activeForDedupKey(
          templateId: ctx.args['template_id'] as String,
          workspaceId: ctx.workspaceId!,
          dedupKey: ctx.args['dedup_key'] as String,
        );
        return {'run': run == null ? null : pipelineRunToWire(run)};
      },
    ),
    RepoOp(
      name: 'pipeline_run.deleteRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id'],
      handler: (ctx) async {
        // The repository delete is already scoped by (workspaceId, runId), so a
        // foreign run is simply not matched.
        await pipelineRunRepository.deleteRun(
          ctx.workspaceId!,
          ctx.args['run_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.insertStepRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['step_run'],
      handler: (ctx) async {
        final stepRun = pipelineStepRunFromWire(
          (ctx.args['step_run'] as Map).cast<String, dynamic>(),
        );
        // The parent run must belong to the bound workspace.
        await assertPipelineRunOwned(ctx.workspaceId!, stepRun.pipelineRunId);
        await pipelineRunRepository.insertStepRun(stepRun);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.updateStepRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['step_run_id'],
      handler: (ctx) async {
        await assertPipelineStepRunOwned(
          ctx.workspaceId!,
          ctx.args['step_run_id'] as String,
        );
        final status = ctx.args['status'];
        await pipelineRunRepository.updateStepRun(
          ctx.args['step_run_id'] as String,
          status: status is String
              ? PipelineStepStatus.fromString(status)
              : null,
          inputJson: ctx.args['input_json'] as String?,
          outputJson: ctx.args['output_json'] as String?,
          channelId: ctx.args['channel_id'] as String?,
          errorMessage: ctx.args['error_message'] as String?,
          errorStackTrace: ctx.args['error_stack_trace'] as String?,
          finishedAt: ctx.args['finished_at'] is String
              ? DateTime.parse(ctx.args['finished_at'] as String)
              : null,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.deleteStepRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['step_run_id'],
      handler: (ctx) async {
        await assertPipelineStepRunOwned(
          ctx.workspaceId!,
          ctx.args['step_run_id'] as String,
        );
        await pipelineRunRepository.deleteStepRun(
          ctx.args['step_run_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_run.stepRunsForPipeline',
      kind: RepoOpKind.read,
      requiredArgs: ['pipeline_run_id'],
      handler: (ctx) async {
        await assertPipelineRunOwned(
          ctx.workspaceId!,
          ctx.args['pipeline_run_id'] as String,
        );
        final stepRuns = await pipelineRunRepository.stepRunsForPipeline(
          ctx.args['pipeline_run_id'] as String,
        );
        return {'step_runs': stepRuns.map(pipelineStepRunToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pipeline_run.getStepRunById',
      kind: RepoOpKind.read,
      requiredArgs: ['step_run_id'],
      handler: (ctx) async {
        final stepRun = await pipelineRunRepository.getStepRunById(
          ctx.args['step_run_id'] as String,
        );
        if (stepRun == null) {
          return {'step_run': null};
        }
        // Step runs carry no workspaceId — validate through the parent run.
        await assertPipelineRunOwned(ctx.workspaceId!, stepRun.pipelineRunId);
        return {'step_run': pipelineStepRunToWire(stepRun)};
      },
    ),
    // ---- Pipeline EXECUTOR actions (`pipeline.*`) — server-side run control ----
    //
    // These are NOT the data-layer `pipeline_run.*` ops above (which read/write
    // run rows); they drive the live `PipelineEngine` (start/cancel/retry a run,
    // kill a step). The engine runs only on a host that constructs it (the
    // desktop in-process host), so the whole block is gated on `pipeline != null`
    // and is simply absent on a headless server (web-against-headless degrades to
    // "pipelines run on the server host"). Each op is workspace-scoped: it uses
    // `ctx.workspaceId!` (never a client arg) and validates run/step ownership
    // via `loadOwnedPipelineRun` before touching the engine (isolation
    // invariant). `resumeAll` is deliberately NOT exposed — it is a global
    // startup reconciler the host runs on its OWN startup, not a client action.
    if (pipeline != null) ...[
      RepoOp(
        name: 'pipeline.start',
        kind: RepoOpKind.mutate,
        requiredArgs: ['template_id'],
        handler: (ctx) async {
          // Starts a run for the bound workspace — the workspace is server-bound,
          // never sourced from a client arg.
          final triggerPayload = ctx.args['trigger_payload'];
          final run = await pipeline.start(
            ctx.args['template_id'] as String,
            workspaceId: ctx.workspaceId!,
            triggerEventType: ctx.args['trigger_event_type'] as String?,
            triggerPayload: triggerPayload is Map
                ? triggerPayload.cast<String, dynamic>()
                : null,
            dedupKey: ctx.args['dedup_key'] as String?,
            parentPipelineRunId: ctx.args['parent_pipeline_run_id'] as String?,
            parentStepId: ctx.args['parent_step_id'] as String?,
            dryRun: ctx.args['dry_run'] as bool? ?? false,
          );
          return {'run': run == null ? null : pipelineRunToWire(run)};
        },
      ),
      RepoOp(
        name: 'pipeline.cancel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['pipeline_run_id'],
        handler: (ctx) async {
          final runId = ctx.args['pipeline_run_id'] as String;
          // ID-only lookup is not a boundary — assert the run is ours first.
          await loadOwnedPipelineRun(ctx.workspaceId!, runId);
          await pipeline.cancel(runId);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'pipeline.retry',
        kind: RepoOpKind.mutate,
        requiredArgs: ['pipeline_run_id'],
        handler: (ctx) async {
          final runId = ctx.args['pipeline_run_id'] as String;
          await loadOwnedPipelineRun(ctx.workspaceId!, runId);
          await pipeline.retry(runId);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'pipeline.killStep',
        kind: RepoOpKind.mutate,
        requiredArgs: ['step_run_id'],
        handler: (ctx) async {
          final stepRunId = ctx.args['step_run_id'] as String;
          // Step runs carry no workspaceId — resolve the parent run and assert
          // OWNERSHIP through it before killing (the chokepoint loads the step,
          // reads its `pipelineRunId`, then `loadOwnedPipelineRun`).
          await assertPipelineStepRunOwned(ctx.workspaceId!, stepRunId);
          await pipeline.killStep(stepRunId);
          return {'ok': true};
        },
      ),
    ],
    // ---- Orchestration EXECUTOR actions (`orchestration.*`) — server-side ----
    //
    // Approving/cancelling an orchestration hires agents + starts/cancels
    // pipelines via the concrete engine, so it runs on the host that owns the
    // engine (the desktop in-process host); absent on a headless server. Both
    // ops are workspace-scoped (`ctx.workspaceId!`, never a client arg); the
    // use-cases re-validate the orchestration belongs to that workspace.
    if (approveOrch != null)
      RepoOp(
        name: 'orchestration.approve',
        kind: RepoOpKind.mutate,
        requiredArgs: ['orchestration_id'],
        handler: (ctx) async {
          await approveOrch(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
          );
          return {'ok': true};
        },
      ),
    if (cancelOrch != null)
      RepoOp(
        name: 'orchestration.cancel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['orchestration_id'],
        handler: (ctx) async {
          await cancelOrch(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
          );
          return {'ok': true};
        },
      ),
    // ---- Pipeline templates (workspace-scoped at the repository) ----
    RepoOp(
      name: 'pipeline_template.forWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final templates = await pipelineTemplateRepository.forWorkspace(
          ctx.workspaceId!,
        );
        return {'templates': templates.map(pipelineTemplateToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pipeline_template.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['template_id'],
      handler: (ctx) async {
        // The repository scopes by (workspaceId, templateId), so a foreign
        // template is simply not found — the workspace binding is the boundary.
        final template = await pipelineTemplateRepository.getById(
          ctx.workspaceId!,
          ctx.args['template_id'] as String,
        );
        if (template == null) {
          throw const NotFoundException('Pipeline template not found');
        }
        return {'template': pipelineTemplateToWire(template)};
      },
    ),
    RepoOp(
      name: 'pipeline_template.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['template'],
      handler: (ctx) async {
        final definition = pipelineTemplateFromWire(
          (ctx.args['template'] as Map).cast<String, dynamic>(),
        );
        // The template's own workspace must match the bound session — a client
        // can't write a template into a foreign workspace (isolation invariant).
        if (definition.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline template belongs to a different workspace',
          );
        }
        await pipelineTemplateRepository.upsert(definition);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_template.deleteById',
      kind: RepoOpKind.mutate,
      requiredArgs: ['template_id'],
      handler: (ctx) async {
        // deleteById scopes by (workspaceId, templateId), so a foreign row's id
        // deletes nothing (returns 0) — the workspace binding is the boundary.
        final deleted = await pipelineTemplateRepository.deleteById(
          ctx.workspaceId!,
          ctx.args['template_id'] as String,
        );
        return {'deleted': deleted};
      },
    ),
    // ---- Pipeline triggers (workspace-scoped at the repository) ----
    RepoOp(
      name: 'pipeline_trigger.insert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['trigger'],
      handler: (ctx) async {
        final trigger = pipelineTriggerEntityFromWire(
          (ctx.args['trigger'] as Map).cast<String, dynamic>(),
        );
        // The trigger's own workspace must match the bound session — a client
        // can't write a trigger into a foreign workspace (isolation invariant).
        if (trigger.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline trigger belongs to a different workspace',
          );
        }
        await pipelineTriggerRepository.insert(trigger);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_trigger.update',
      kind: RepoOpKind.mutate,
      requiredArgs: ['trigger'],
      handler: (ctx) async {
        final trigger = pipelineTriggerEntityFromWire(
          (ctx.args['trigger'] as Map).cast<String, dynamic>(),
        );
        if (trigger.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline trigger belongs to a different workspace',
          );
        }
        await pipelineTriggerRepository.update(trigger);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_trigger.deleteById',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id'],
      handler: (ctx) async {
        // ID-only lookup is not a scoping boundary; load + validate ownership
        // before deleting so a foreign trigger can't be removed.
        final existing = await pipelineTriggerRepository.getById(
          ctx.args['id'] as String,
        );
        if (existing == null) {
          throw const NotFoundException('Pipeline trigger not found');
        }
        if (existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline trigger belongs to a different workspace',
          );
        }
        await pipelineTriggerRepository.deleteById(existing.id);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pipeline_trigger.forWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: const [],
      handler: (ctx) async {
        final triggers = await pipelineTriggerRepository.forWorkspace(
          ctx.workspaceId!,
        );
        return {'triggers': triggers.map(pipelineTriggerEntityToWire).toList()};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: the trigger dispatcher fans a domain event out
    // to every workspace's matching triggers, then filters each candidate by
    // the event's own workspaceId before firing. Mirrors
    // PipelineTriggerRepository.enabledForEvent (the documented exemption).
    RepoOp(
      name: 'pipeline_trigger.enabledForEvent',
      kind: RepoOpKind.read,
      requiredArgs: ['event_type'],
      workspaceScoped: false,
      handler: (ctx) async {
        final triggers = await pipelineTriggerRepository.enabledForEvent(
          ctx.args['event_type'] as String,
        );
        return {'triggers': triggers.map(pipelineTriggerEntityToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pipeline_trigger.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final trigger = await pipelineTriggerRepository.getById(
          ctx.args['id'] as String,
        );
        if (trigger == null) {
          throw const NotFoundException('Pipeline trigger not found');
        }
        // ID-only lookup is not a scoping boundary; reject any trigger not
        // owned by the bound session.
        if (trigger.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline trigger belongs to a different workspace',
          );
        }
        return {'trigger': pipelineTriggerEntityToWire(trigger)};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: the scheduler enumerates all enabled scheduled
    // triggers across every workspace, then fires each against its own
    // workspace. Mirrors PipelineTriggerRepository.scheduled (the documented
    // exemption).
    RepoOp(
      name: 'pipeline_trigger.scheduled',
      kind: RepoOpKind.read,
      requiredArgs: const [],
      workspaceScoped: false,
      handler: (ctx) async {
        final triggers = await pipelineTriggerRepository.scheduled();
        return {'triggers': triggers.map(pipelineTriggerEntityToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pipeline_trigger.markFired',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'when'],
      handler: (ctx) async {
        // ID-only lookup is not a scoping boundary; load + validate ownership
        // before mutating the fired-at cursor.
        final existing = await pipelineTriggerRepository.getById(
          ctx.args['id'] as String,
        );
        if (existing == null) {
          throw const NotFoundException('Pipeline trigger not found');
        }
        if (existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Pipeline trigger belongs to a different workspace',
          );
        }
        await pipelineTriggerRepository.markFired(
          existing.id,
          DateTime.parse(ctx.args['when'] as String),
        );
        return {'ok': true};
      },
    ),
    // ---- Orchestrations (workspace-scoped at the repository) ----
    RepoOp(
      name: 'orchestration.insert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['orchestration'],
      handler: (ctx) async {
        final o = orchestrationFromWire(
          (ctx.args['orchestration'] as Map).cast<String, dynamic>(),
        );
        // A client can't insert an orchestration into a foreign workspace
        // (isolation invariant).
        if (o.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Orchestration belongs to a different workspace',
          );
        }
        await orchestrationRepository.insert(o);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'orchestration.update',
      kind: RepoOpKind.mutate,
      requiredArgs: ['orchestration'],
      handler: (ctx) async {
        final o = orchestrationFromWire(
          (ctx.args['orchestration'] as Map).cast<String, dynamic>(),
        );
        // The orchestration's own workspace must match the bound session — a
        // client can't move/write a row across workspaces (isolation invariant).
        if (o.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Orchestration belongs to a different workspace',
          );
        }
        await orchestrationRepository.update(o);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'orchestration.getById',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final o = await orchestrationRepository.getById(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
        return {'orchestration': o == null ? null : orchestrationToWire(o)};
      },
    ),
    RepoOp(
      name: 'orchestration.forParentTicket',
      kind: RepoOpKind.read,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final o = await orchestrationRepository.forParentTicket(
          ctx.workspaceId!,
          ctx.args['ticket_id'] as String,
        );
        return {'orchestration': o == null ? null : orchestrationToWire(o)};
      },
    ),
    RepoOp(
      name: 'orchestration.forPipelineRun',
      kind: RepoOpKind.read,
      requiredArgs: ['pipeline_run_id'],
      handler: (ctx) async {
        final o = await orchestrationRepository.forPipelineRun(
          ctx.workspaceId!,
          ctx.args['pipeline_run_id'] as String,
        );
        return {'orchestration': o == null ? null : orchestrationToWire(o)};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: event routers receive only a pipeline run id
    // (events carry no workspaceId); the returned row carries its own
    // workspaceId (mirrors the documented
    // OrchestrationRepository.forPipelineRunAnyWorkspace exemption).
    RepoOp(
      name: 'orchestration.forPipelineRunAnyWorkspace',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['pipeline_run_id'],
      handler: (ctx) async {
        final o = await orchestrationRepository.forPipelineRunAnyWorkspace(
          ctx.args['pipeline_run_id'] as String,
        );
        return {'orchestration': o == null ? null : orchestrationToWire(o)};
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: startup materialization-resume scans approved
    // orchestrations across all workspaces; each row carries its own
    // workspaceId (mirrors the documented
    // OrchestrationRepository.approvedNeedingMaterialization exemption).
    RepoOp(
      name: 'orchestration.approvedNeedingMaterialization',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: [],
      handler: (ctx) async {
        final list =
            await orchestrationRepository.approvedNeedingMaterialization();
        return {
          'orchestrations': list.map(orchestrationToWire).toList(),
        };
      },
    ),

    // ---- Workspaces (the workspace entity itself is the unit of isolation, so
    // its CRUD + the workspace-switcher list legitimately span workspaces; the
    // repo-LINK ops below are keyed by an explicit workspace id and the entity
    // carries no nested workspace-scoped data) ----
    //
    // CROSS-WORKSPACE BY DESIGN: create_workspace / list_workspaces are the
    // declared isolation exemptions (a workspace can't be scoped to itself
    // before it exists). Mirrors WorkspaceRepository.{upsert,delete,watchAll}.
    RepoOp(
      name: 'workspace.upsert',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace'],
      handler: (ctx) async {
        final incoming = workspaceFromWire(
          (ctx.args['workspace'] as Map).cast<String, dynamic>(),
        );
        // Detect a CREATE (vs an update) so the server can bootstrap the new
        // workspace exactly once. WorkspaceRepository has no get-by-id, so check
        // the (small) workspace set for the incoming id before upserting.
        final isNew = !(await workspaceRepository.watchAll().first)
            .any((w) => w.id == incoming.id);
        final id = await workspaceRepository.upsert(incoming);
        if (isNew) {
          // Drives the server-side WorkspaceSeeder (CEO + specialist agents +
          // built-in pipeline templates) wired in `runCcServer`. The thin
          // client's own `WorkspaceCreated` fires on its bus, where the seeder
          // is absent — the server is the sole DB owner, so it seeds here.
          eventBus?.publish(
            WorkspaceCreated(workspaceId: id, occurredAt: DateTime.now()),
          );
        }
        return {'workspace_id': id};
      },
    ),
    RepoOp(
      name: 'workspace.delete',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await workspaceRepository.delete(ctx.args['id'] as String);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.setReposForWorkspace',
      kind: RepoOpKind.mutate,
      // Stateless: the target workspace comes from the request, never from a
      // per-session binding — multiple clients share one server and each
      // request carries its own workspace. Repos are global; the link rows
      // carry no workspace-scoped content. Mirrors watchReposForWorkspace.
      workspaceScoped: false,
      requiredArgs: ['workspace_id', 'repo_ids'],
      handler: (ctx) async {
        final repoIds = ((ctx.args['repo_ids'] as List?) ?? const [])
            .map((r) => r.toString())
            .toList();
        await workspaceRepository.setReposForWorkspace(
          ctx.args['workspace_id'] as String,
          repoIds,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.linkRepoToWorkspace',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace_id', 'repo_id'],
      handler: (ctx) async {
        await workspaceRepository.linkRepoToWorkspace(
          ctx.args['workspace_id'] as String,
          ctx.args['repo_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.unlinkRepoFromWorkspace',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace_id', 'repo_id'],
      handler: (ctx) async {
        await workspaceRepository.unlinkRepoFromWorkspace(
          ctx.args['workspace_id'] as String,
          ctx.args['repo_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.isRepoLinkedToWorkspace',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['workspace_id', 'repo_id'],
      handler: (ctx) async {
        final linked = await workspaceRepository.isRepoLinkedToWorkspace(
          ctx.args['workspace_id'] as String,
          ctx.args['repo_id'] as String,
        );
        return {'linked': linked};
      },
    ),

    // ---- PR review (per-(workspace, owner, repo); host binds the workspace) --
    // Every op carries `owner`/`repo` (and prNumber/path/sha/... as needed) in
    // its args; the workspace comes from the session binding. The repository is
    // resolved from the bound workspace's LINKED repo, so an (owner, repo) the
    // workspace doesn't own is rejected (resolvePrReviewRepository).
    RepoOp(
      name: 'pr_review.getDraft',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final draft = await repo.getDraft(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'draft': draft};
      },
    ),
    RepoOp(
      name: 'pr_review.upsertDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'text'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.upsertDraft(
          (ctx.args['pr_number'] as num).toInt(),
          ctx.args['text'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.clearDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.clearDraft((ctx.args['pr_number'] as num).toInt());
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.listAssignableUsers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final users = await repo.listAssignableUsers();
        return {'users': users.map(prUserToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pr_review.listRequestableReviewers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final candidates = await repo.listRequestableReviewers();
        return {
          'candidates': candidates.map(prReviewerCandidateToWire).toList(),
        };
      },
    ),
    RepoOp(
      name: 'pr_review.invalidatePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.invalidatePullRequest(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.invalidateDiff',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.invalidateDiff((ctx.args['pr_number'] as num).toInt());
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.markFileAsViewed',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'node_id', 'path', 'viewed'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.markFileAsViewed(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          nodeId: ctx.args['node_id'] as String,
          path: ctx.args['path'] as String,
          viewed: ctx.args['viewed'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.postReviewComment',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'commit_sha',
        'path',
        'line',
        'side',
        'body',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final result = await repo.postReviewComment(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          commitSha: ctx.args['commit_sha'] as String,
          path: ctx.args['path'] as String,
          line: (ctx.args['line'] as num).toInt(),
          side: ctx.args['side'] as String,
          body: ctx.args['body'] as String,
          startLine: (ctx.args['start_line'] as num?)?.toInt(),
          startSide: ctx.args['start_side'] as String?,
        );
        return {'result': result};
      },
    ),
    RepoOp(
      name: 'pr_review.replyToReviewComment',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'parent_comment_id', 'body'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.replyToReviewComment(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          parentCommentId: (ctx.args['parent_comment_id'] as num).toInt(),
          body: ctx.args['body'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.uploadContent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'path', 'base64_content', 'message'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final url = await repo.uploadContent(
          ctx.args['path'] as String,
          ctx.args['base64_content'] as String,
          ctx.args['message'] as String,
        );
        return {'url': url};
      },
    ),
    RepoOp(
      name: 'pr_review.toggleReviewCommentReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'comment_id',
        'content',
        'add',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.toggleReviewCommentReaction(
          commentId: (ctx.args['comment_id'] as num).toInt(),
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.toggleIssueCommentReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'comment_id',
        'content',
        'add',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.toggleIssueCommentReaction(
          commentId: (ctx.args['comment_id'] as num).toInt(),
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.togglePullRequestReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'content', 'add'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.togglePullRequestReaction(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.submitReview',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'event'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.submitReview(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          event: ctx.args['event'] as String,
          body: ctx.args['body'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.mergePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'merge_method'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        final result = await repo.mergePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          mergeMethod: ctx.args['merge_method'] as String,
          commitTitle: ctx.args['commit_title'] as String?,
          commitMessage: ctx.args['commit_message'] as String?,
        );
        return {'result': result};
      },
    ),
    RepoOp(
      name: 'pr_review.closePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.closePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.updatePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.updatePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          title: ctx.args['title'] as String?,
          body: ctx.args['body'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.addAssignees',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'logins'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.addAssignees(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          logins: ((ctx.args['logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.removeAssignees',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'logins'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.removeAssignees(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          logins: ((ctx.args['logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.requestReviewers',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.requestReviewers(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userLogins: ((ctx.args['user_logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          teamSlugs: ((ctx.args['team_slugs'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.removeRequestedReviewers',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        await repo.removeRequestedReviewers(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userLogins: ((ctx.args['user_logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          teamSlugs: ((ctx.args['team_slugs'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    // ---- PR / commit reference previews (SWR-cached server-side) ----
    // The host fetches via the GitHub client (the desktop holds the token) and
    // SWR-caches the lightweight preview against the workspace's cache. Returns
    // `null` when the ref can't be resolved (the chip falls back to a link).
    RepoOp(
      name: 'pr_review.prPreview',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        if (fetchPrPreview == null) {
          return {'preview': null};
        }
        final number = (ctx.args['number'] as num).toInt();
        final preview = await previewSwr(
          workspaceId: ctx.workspaceId!,
          kind: 'prPreview',
          key: '${c.owner}/${c.repo}#$number',
          fetch: () => fetchPrPreview(c.owner, c.repo, number),
        );
        return {'preview': preview};
      },
    ),
    RepoOp(
      name: 'pr_review.commitPreview',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'sha'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        if (fetchCommitPreview == null) {
          return {'preview': null};
        }
        final sha = ctx.args['sha'] as String;
        final preview = await previewSwr(
          workspaceId: ctx.workspaceId!,
          kind: 'commitPreview',
          key: '${c.owner}/${c.repo}@$sha',
          fetch: () => fetchCommitPreview(c.owner, c.repo, sha),
        );
        return {'preview': preview};
      },
    ),
    // ---- Remote agent-action approvals (confirmation.*) ----
    // CROSS-WORKSPACE BY DESIGN: approvals are host-global (a phone spans
    // workspaces). Absent entirely when the host wired no
    // [PendingConfirmationRegistry] (headless cc_server has no dispatch).
    if (pendingConfirmationRegistry != null)
      RepoOp(
        name: 'confirmation.respond',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          final id = ctx.args['id'] as String;
          final approved = ctx.args['approved'] == true;
          final ok = pendingConfirmationRegistry.respond(id, approved);
          return {'ok': ok};
        },
      ),
  ], catalogVersion: 7);

  final watch = WatchQueryRegistry([
    // ---- On-device model download progress (HOST-GLOBAL) ----
    //
    // Streams each model's lifecycle as the SERVER downloads + unpacks it, so a
    // thin client animates a live progress bar via `models.watch*` while the
    // server does the work. Registered only when the host wired the matching
    // [ModelControl] (same null-guard as the `models.*` ops); absent on a
    // headless host that hosts no models. See `modelControlWatchQuery`.
    if (embeddingModel != null)
      modelControlWatchQuery(prefix: 'embedding', control: embeddingModel),
    if (diarizationModel != null)
      modelControlWatchQuery(prefix: 'diarization', control: diarizationModel),
    if (voiceModel != null)
      modelControlWatchQuery(prefix: 'voice', control: voiceModel),
    WatchQuery(
      name: 'tickets.watchForWorkspace',
      handler: (ctx) => ticketRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {'tickets': list.map(ticketToWire).toList()}),
    ),
    WatchQuery(
      name: 'tickets.watchCollaborators',
      handler: (ctx) => watchCollaboratorsScoped(
        ticketRepository,
        ctx.args['ticket_id'] as String?,
        ctx.workspaceId,
      ),
    ),
    WatchQuery(
      name: 'project.watchForWorkspace',
      handler: (ctx) => projectRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {'projects': list.map(projectToWire).toList()}),
    ),
    WatchQuery(
      name: 'agents.watchForWorkspace',
      handler: (ctx) => agentRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'agents': list.map(agentToWire).toList()}),
    ),
    // CROSS-WORKSPACE BY DESIGN: the dashboard's global all-agents view. The
    // server still authenticates the device; this is the declared all-workspace
    // surface (mirrors AgentRepository.watchAll, the documented exemption).
    WatchQuery(
      name: 'agents.watchAll',
      workspaceScoped: false,
      handler: (ctx) => agentRepository
          .watchAll()
          .map((list) => {'agents': list.map(agentToWire).toList()}),
    ),
    // CROSS-WORKSPACE BY DESIGN: repos are global (workspace links live in
    // WorkspaceRepos); mirrors RepoRepository.watchAll.
    WatchQuery(
      name: 'repos.watchAll',
      workspaceScoped: false,
      handler: (ctx) => repoRepository
          .watchAll()
          .map((list) => {'repos': list.map(repoToWire).toList()}),
    ),
    WatchQuery(
      name: 'messaging.watchChannels',
      handler: (ctx) => messagingRepository
          .watchChannelsByWorkspace(ctx.workspaceId!)
          .map((list) => {'channels': list.map(channelToWire).toList()}),
    ),
    WatchQuery(
      name: 'messaging.watchMessages',
      handler: (ctx) async* {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        // Validate ownership once, before streaming any rows.
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* messagingRepository
            .watchMessages(channelId)
            .map((list) => {'messages': list.map(messageToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'messaging.watchTopLevelMessages',
      handler: (ctx) async* {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* messagingRepository
            .watchTopLevelMessages(channelId)
            .map((list) => {'messages': list.map(messageToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'messaging.watchThread',
      handler: (ctx) async* {
        final parentMessageId = ctx.args['parent_message_id'] as String?;
        if (parentMessageId == null) {
          throw const NotFoundException('Missing parent_message_id');
        }
        // The thread is keyed by parent message id; validate the parent's
        // channel is in the bound workspace before streaming replies.
        final parent = await messagingRepository.getMessageById(
          parentMessageId,
        );
        if (parent != null) {
          await assertChannelOwned(ctx.workspaceId!, parent.channelId);
        }
        yield* messagingRepository
            .watchThread(parentMessageId)
            .map((list) => {'messages': list.map(messageToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'messaging.watchParticipants',
      handler: (ctx) async* {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* messagingRepository.watchParticipants(channelId).map(
          (list) => {
            'participants': list.map(channelParticipantToWire).toList(),
          },
        );
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: the workspace switcher + dashboard see every
    // workspace (the workspace is itself the unit of isolation). Mirrors
    // WorkspaceRepository.watchAll, the documented all-workspace exemption.
    WatchQuery(
      name: 'workspace.watchAll',
      workspaceScoped: false,
      handler: (ctx) => workspaceRepository
          .watchAll()
          .map((list) => {'workspaces': list.map(workspaceToWire).toList()}),
    ),
    // CROSS-WORKSPACE BY DESIGN: the repo-link join is queryable for any
    // workspace id — the GitHub-link router and startup reconciler resolve a
    // repo→workspace mapping by scanning every workspace's links, so this
    // honors the explicit `workspace_id` arg (falling back to the bound one).
    // Repos are global and the link rows carry no workspace-scoped content;
    // mirrors WorkspaceRepository.watchReposForWorkspace.
    WatchQuery(
      name: 'workspace.watchReposForWorkspace',
      workspaceScoped: false,
      handler: (ctx) {
        final workspaceId =
            ctx.args['workspace_id'] as String? ?? ctx.workspaceId;
        if (workspaceId == null) {
          throw const NotFoundException('Missing workspace_id');
        }
        return workspaceRepository
            .watchReposForWorkspace(workspaceId)
            .map((list) => {'repos': list.map(repoToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'newsfeed.watchArticles',
      workspaceScoped: false,
      handler: (ctx) => newsfeedRepository.watchArticles().map(
        (list) => {'articles': list.map(articleToWire).toList()},
      ),
    ),
    WatchQuery(
      name: 'newsfeed.watchFeeds',
      workspaceScoped: false,
      handler: (ctx) => newsfeedRepository.watchFeeds().map(
        (list) => {'feeds': list.map(feedToWire).toList()},
      ),
    ),
    WatchQuery(
      name: 'channel_read.watchUserLastReadAt',
      handler: (ctx) async* {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        // Validate ownership once, before streaming any cursor updates.
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* channelReadRepository
            .watchUserLastReadAt(channelId)
            .map((lastReadAt) => channelReadToWire(channelId, lastReadAt));
      },
    ),
    WatchQuery(
      name: 'memory_domain.watchForWorkspace',
      handler: (ctx) => memoryDomainRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'domains': list.map(memoryDomainToWire).toList()}),
    ),
    WatchQuery(
      name: 'memory_access_grant.watchByWorkspace',
      handler: (ctx) => memoryAccessGrantRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'grants': list.map(memoryAccessGrantToWire).toList()}),
    ),
    WatchQuery(
      name: 'agent_working_memory.watchByAgent',
      handler: (ctx) {
        final agentId = ctx.args['agent_id'] as String?;
        if (agentId == null) {
          throw const NotFoundException('Missing agent_id');
        }
        return agentWorkingMemoryRepository
            .watchByAgent(ctx.workspaceId!, agentId)
            .map(
              (memory) => {
                'memory':
                    memory == null ? null : agentWorkingMemoryToWire(memory),
              },
            );
      },
    ),
    WatchQuery(
      name: 'agent_working_memory.watchByWorkspace',
      handler: (ctx) => agentWorkingMemoryRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'memories': list.map(agentWorkingMemoryToWire).toList()}),
    ),
    WatchQuery(
      name: 'memory_fact.watchForWorkspace',
      handler: (ctx) => memoryFactRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'facts': list.map(memoryFactToWire).toList()}),
    ),
    WatchQuery(
      name: 'memory_policy.watchForWorkspace',
      handler: (ctx) => memoryPolicyRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'policies': list.map(memoryPolicyToWire).toList()}),
    ),
    WatchQuery(
      name: 'review_channel.watchByWorkspace',
      handler: (ctx) => reviewChannelRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map(
            (list) => {
              'associations': list.map(reviewChannelToWire).toList(),
            },
          ),
    ),
    WatchQuery(
      name: 'review_channel.watchByPr',
      handler: (ctx) {
        final prNodeId = ctx.args['pr_node_id'] as String?;
        if (prNodeId == null) {
          throw const NotFoundException('Missing pr_node_id');
        }
        // PR node ids are global; scope to the bound workspace server-side.
        return reviewChannelRepository
            .watchByPr(ctx.workspaceId!, prNodeId)
            .map(
              (a) => {'association': a == null ? null : reviewChannelToWire(a)},
            );
      },
    ),
    WatchQuery(
      name: 'review_channel.watchByChannel',
      handler: (ctx) {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        // The interface keys by channel_id alone; enforce ownership on the
        // emitted row — a foreign-workspace association is filtered to null so
        // an ID-only lookup can't leak across workspaces (isolation invariant).
        return reviewChannelRepository.watchByChannel(channelId).map(
          (a) => {
            'association': (a == null || a.workspaceId != ctx.workspaceId)
                ? null
                : reviewChannelToWire(a),
          },
        );
      },
    ),
    WatchQuery(
      name: 'agent_run_log.watchByAgent',
      handler: (ctx) => agentRunLogRepository
          .watchByAgent(ctx.workspaceId!, ctx.args['agent_id'] as String)
          .map((list) => {'logs': list.map(agentRunLogToWire).toList()}),
    ),
    WatchQuery(
      name: 'agent_run_log.watchActiveByConversation',
      handler: (ctx) => agentRunLogRepository
          .watchActiveByConversation(
            ctx.workspaceId!,
            ctx.args['conversation_id'] as String,
          )
          .map((list) => {'logs': list.map(agentRunLogToWire).toList()}),
    ),
    // CROSS-WORKSPACE BY DESIGN: the dashboard's global all-runs view. The
    // server still authenticates the device; this is the declared all-workspace
    // surface (mirrors AgentRunLogRepository.watchAll, the documented exemption).
    WatchQuery(
      name: 'agent_run_log.watchAll',
      workspaceScoped: false,
      handler: (ctx) => agentRunLogRepository
          .watchAll()
          .map((list) => {'logs': list.map(agentRunLogToWire).toList()}),
    ),
    WatchQuery(
      name: 'team.watchTeamsForWorkspace',
      handler: (ctx) => teamRepository
          .watchTeamsForWorkspace(ctx.workspaceId!)
          .map((list) => {'teams': list.map(teamToWire).toList()}),
    ),
    WatchQuery(
      name: 'team.watchMembersOf',
      handler: (ctx) {
        final teamId = ctx.args['team_id'] as String;
        return Stream.fromFuture(teamRepository.getTeam(teamId)).asyncExpand((
          team,
        ) {
          if (team == null || team.workspaceId != ctx.workspaceId) {
            return Stream<Map<String, dynamic>>.error(
              const WorkspaceMismatchException(
                'Team belongs to a different workspace',
              ),
            );
          }
          return teamRepository
              .watchMembersOf(teamId)
              .map((list) => {'members': list.map(teamMemberToWire).toList()});
        });
      },
    ),
    WatchQuery(
      name: 'isolated_repo.watchForWorkspace',
      handler: (ctx) => isolatedRepoRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {'repos': list.map(isolatedRepoToWire).toList()}),
    ),
    WatchQuery(
      name: 'voice_profile.watchForWorkspace',
      handler: (ctx) => voiceProfileRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'profiles': list.map(voiceProfileToWire).toList()}),
    ),
    // ---- Meetings (workspace-scoped at the repository) ----
    WatchQuery(
      name: 'meeting.watchByWorkspace',
      handler: (ctx) => meetingRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'meetings': list.map(meetingToWire).toList()}),
    ),
    WatchQuery(
      name: 'meeting.watchSegments',
      handler: (ctx) {
        final meetingId = ctx.args['meeting_id'] as String?;
        if (meetingId == null) {
          throw const NotFoundException('Missing meeting_id');
        }
        // Scoped by (workspaceId, meetingId) at the DAO — a foreign meeting's
        // segments never stream through.
        return meetingRepository
            .watchSegments(ctx.workspaceId!, meetingId)
            .map((list) => {'segments': list.map(meetingSegmentToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'meeting.watchSpeakers',
      handler: (ctx) {
        final meetingId = ctx.args['meeting_id'] as String?;
        if (meetingId == null) {
          throw const NotFoundException('Missing meeting_id');
        }
        return meetingRepository.watchSpeakers(ctx.workspaceId!, meetingId).map(
          (list) => {'speakers': list.map(meetingSpeakerLabelToWire).toList()},
        );
      },
    ),
    WatchQuery(
      name: 'meeting.watchActionItems',
      handler: (ctx) {
        final meetingId = ctx.args['meeting_id'] as String?;
        if (meetingId == null) {
          throw const NotFoundException('Missing meeting_id');
        }
        return meetingRepository
            .watchActionItems(ctx.workspaceId!, meetingId)
            .map((list) => {'items': list.map(meetingActionItemToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'meeting.watchDecisions',
      handler: (ctx) {
        final meetingId = ctx.args['meeting_id'] as String?;
        if (meetingId == null) {
          throw const NotFoundException('Missing meeting_id');
        }
        return meetingRepository
            .watchDecisions(ctx.workspaceId!, meetingId)
            .map((list) => {'decisions': list.map(meetingDecisionToWire).toList()});
      },
    ),
    // Per-meeting action-item stats, keyed by meeting id — serialized as a JSON
    // object `{meetingId: {total, done}}`.
    WatchQuery(
      name: 'meeting.watchActionItemStats',
      handler: (ctx) => meetingRepository
          .watchActionItemStats(ctx.workspaceId!)
          .map((stats) => {'stats': meetingActionItemStatsToWire(stats)}),
    ),
    // Per-meeting decision counts, keyed by meeting id — serialized as a JSON
    // object `{meetingId: count}`.
    WatchQuery(
      name: 'meeting.watchDecisionCounts',
      handler: (ctx) => meetingRepository
          .watchDecisionCounts(ctx.workspaceId!)
          .map((counts) => {'counts': counts}),
    ),
    // ---- Analytics / achievements / streaks (workspace-scoped) ----
    //
    // Every watch sources `ctx.workspaceId!` (the bound session, never a client
    // arg) as the leading `workspaceId`; the impl JOINs Agents on it, so a
    // foreign agent's rows never stream through. Agent-keyed watches read the
    // `agent_id` from the args; the date-range watches read ISO-8601 `start`/`end`.
    WatchQuery(
      name: 'analytics.watchByAgent',
      handler: (ctx) {
        final agentId = ctx.args['agent_id'] as String?;
        if (agentId == null) {
          throw const NotFoundException('Missing agent_id');
        }
        return analyticsRepository
            .watchByAgent(ctx.workspaceId!, agentId)
            .map((list) => {'stats': list.map(agentDailyStatsToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'analytics.watchByAgentDateRange',
      handler: (ctx) {
        final agentId = ctx.args['agent_id'] as String?;
        if (agentId == null) {
          throw const NotFoundException('Missing agent_id');
        }
        return analyticsRepository
            .watchByAgentDateRange(
              ctx.workspaceId!,
              agentId,
              DateTime.parse(ctx.args['start'] as String),
              DateTime.parse(ctx.args['end'] as String),
            )
            .map((list) => {'stats': list.map(agentDailyStatsToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'analytics.watchAllByDateRange',
      handler: (ctx) => analyticsRepository
          .watchAllByDateRange(
            ctx.workspaceId!,
            DateTime.parse(ctx.args['start'] as String),
            DateTime.parse(ctx.args['end'] as String),
          )
          .map((list) => {'stats': list.map(agentDailyStatsToWire).toList()}),
    ),
    WatchQuery(
      name: 'achievements.watchByAgent',
      handler: (ctx) {
        final agentId = ctx.args['agent_id'] as String?;
        if (agentId == null) {
          throw const NotFoundException('Missing agent_id');
        }
        return achievementRepository
            .watchByAgent(ctx.workspaceId!, agentId)
            .map(
              (list) => {'achievements': list.map(achievementToWire).toList()},
            );
      },
    ),
    WatchQuery(
      name: 'streaks.watchByAgent',
      handler: (ctx) {
        final agentId = ctx.args['agent_id'] as String?;
        if (agentId == null) {
          throw const NotFoundException('Missing agent_id');
        }
        return streakRepository
            .watchByAgent(ctx.workspaceId!, agentId)
            .map((list) => {'streaks': list.map(streakToWire).toList()});
      },
    ),
    // ---- Calendar (workspace-scoped) ----
    //
    // Every watch sources `ctx.workspaceId!` (the bound session, never a client
    // arg) as the leading `workspaceId`; the impl scopes every query by it, so a
    // foreign-workspace row never streams through. The range watch reads ISO-8601
    // `from`/`to`; the single-event watch reads the `event_id` from the args.
    WatchQuery(
      name: 'calendar.watchAccounts',
      handler: (ctx) => calendarRepository
          .watchAccounts(ctx.workspaceId!)
          .map((list) => {'accounts': list.map(calendarAccountToWire).toList()}),
    ),
    WatchQuery(
      name: 'calendar.watchSources',
      handler: (ctx) {
        final accountId = ctx.args['account_id'] as String?;
        if (accountId == null) {
          throw const NotFoundException('Missing account_id');
        }
        return calendarRepository
            .watchSources(ctx.workspaceId!, accountId)
            .map(
              (list) => {'sources': list.map(calendarSourceToWire).toList()},
            );
      },
    ),
    WatchQuery(
      name: 'calendar.watchEventsInRange',
      handler: (ctx) => calendarRepository
          .watchEventsInRange(
            ctx.workspaceId!,
            DateTime.parse(ctx.args['from'] as String),
            DateTime.parse(ctx.args['to'] as String),
          )
          .map((list) => {'events': list.map(calendarEventToWire).toList()}),
    ),
    WatchQuery(
      name: 'calendar.watchEventById',
      handler: (ctx) {
        final eventId = ctx.args['event_id'] as String?;
        if (eventId == null) {
          throw const NotFoundException('Missing event_id');
        }
        return calendarRepository
            .watchEventById(ctx.workspaceId!, eventId)
            .map(
              (event) => {
                'event': event == null ? null : calendarEventToWire(event),
              },
            );
      },
    ),
    // ---- PR lifecycle (workspace-scoped) ----
    //
    // The compose-PR draft list for the bound workspace. Sources
    // `ctx.workspaceId!` (the bound session, never a client arg); the impl scopes
    // the query by it, so a foreign-workspace row never streams through.
    WatchQuery(
      name: 'pr_lifecycle.watchByWorkspace',
      handler: (ctx) => prLifecycleRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'prs': list.map(prGenerationToWire).toList()}),
    ),
    // ---- Activity log (workspace-scoped audit trail for one entity) ----
    //
    // Present only when the host wired an [ActivityLogReader] (the desktop
    // in-process host + the headless cc_server own the Drift `activity_log` DAO);
    // a host without one leaves it absent (default-deny) and the client's
    // entity-timeline view degrades to empty. Sources `ctx.workspaceId!` (the
    // bound session, never a client arg); the DAO query filters by it, so a
    // foreign-workspace row never streams through. `entity_type`/`entity_id` come
    // from the args.
    if (activityLogReader != null)
      WatchQuery(
        name: 'activity.watchForEntity',
        handler: (ctx) {
          final entityType = ctx.args['entity_type'] as String?;
          final entityId = ctx.args['entity_id'] as String?;
          if (entityType == null || entityId == null) {
            throw const NotFoundException('Missing entity_type or entity_id');
          }
          return activityLogReader
              .watchForEntity(ctx.workspaceId!, entityType, entityId)
              .map(
                (list) => {
                  'entries': list.map(activityEntryToWire).toList(),
                },
              );
        },
      ),
    WatchQuery(
      name: 'ticket_link.watchForTicket',
      handler: (ctx) => ticketLinkRepository
          .watchForTicket(ctx.workspaceId!, ctx.args['ticket_id'] as String)
          .map((list) => {'links': list.map(ticketLinkToWire).toList()}),
    ),
    WatchQuery(
      name: 'pipeline_run.watchRun',
      handler: (ctx) => pipelineRunRepository
          .watchRun(ctx.args['id'] as String)
          // ID-only watch is not a boundary — drop a run owned by another
          // workspace so a foreign run never streams through.
          .map(
            (run) => {
              'run': run == null || run.workspaceId != ctx.workspaceId
                  ? null
                  : pipelineRunToWire(run),
            },
          ),
    ),
    // CROSS-WORKSPACE BY DESIGN: the global all-runs view (mirrors
    // PipelineRunRepository.watchAll, the documented all-workspace exemption).
    // The server still authenticates the device.
    WatchQuery(
      name: 'pipeline_run.watchAll',
      workspaceScoped: false,
      handler: (ctx) => pipelineRunRepository
          .watchAll()
          .map((list) => {'runs': list.map(pipelineRunToWire).toList()}),
    ),
    WatchQuery(
      name: 'pipeline_run.watchForWorkspace',
      handler: (ctx) => pipelineRunRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {'runs': list.map(pipelineRunToWire).toList()}),
    ),
    WatchQuery(
      name: 'pipeline_run.watchStepRunsForPipeline',
      handler: (ctx) async* {
        // Validate parent-run ownership before opening the step stream.
        await assertPipelineRunOwned(
          ctx.workspaceId!,
          ctx.args['pipeline_run_id'] as String,
        );
        yield* pipelineRunRepository
            .watchStepRunsForPipeline(ctx.args['pipeline_run_id'] as String)
            .map(
              (list) => {
                'step_runs': list.map(pipelineStepRunToWire).toList(),
              },
            );
      },
    ),
    WatchQuery(
      name: 'pipeline_template.watchForWorkspace',
      handler: (ctx) => pipelineTemplateRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {
                'templates': list.map(pipelineTemplateToWire).toList(),
              }),
    ),
    WatchQuery(
      name: 'pipeline_trigger.watchForWorkspace',
      handler: (ctx) => pipelineTriggerRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map(
            (list) =>
                {'triggers': list.map(pipelineTriggerEntityToWire).toList()},
          ),
    ),
    WatchQuery(
      name: 'orchestration.watchForWorkspace',
      handler: (ctx) => orchestrationRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map(
            (list) => {
              'orchestrations': list.map(orchestrationToWire).toList(),
            },
          ),
    ),
    WatchQuery(
      name: 'orchestration.watchById',
      handler: (ctx) => orchestrationRepository
          .watchById(ctx.workspaceId!, ctx.args['id'] as String)
          .map(
            (o) => {'orchestration': o == null ? null : orchestrationToWire(o)},
          ),
    ),

    // ---- PR review (per-(workspace, owner, repo); host binds the workspace) --
    // Each watch carries `owner`/`repo` (+ prNumber/path/sha) in its args; the
    // repository is resolved from the bound workspace's LINKED repo, so a watch
    // over an (owner, repo) the workspace doesn't own errors before streaming.
    WatchQuery(
      name: 'pr_review.watchPullRequest',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchPullRequest((ctx.args['pr_number'] as num).toInt())
            .map(
              (pr) => {'pull_request': pr == null ? null : pullRequestToWire(pr)},
            );
      },
    ),
    WatchQuery(
      name: 'pr_review.watchDiff',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchDiff((ctx.args['pr_number'] as num).toInt())
            .map((diff) => {'diff': diff});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchFiles',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchFiles((ctx.args['pr_number'] as num).toInt())
            .map((files) => {'files': files.map(prFileToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchFileContent',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchFileContent(
              ctx.args['path'] as String,
              ctx.args['ref'] as String,
            )
            .map((content) => {'content': content});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchCommits',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchCommits((ctx.args['pr_number'] as num).toInt())
            .map((commits) => {'commits': commits.map(prCommitToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchCommitFiles',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchCommitFiles(ctx.args['sha'] as String)
            .map((files) => {'files': files.map(prFileToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchReviews',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchReviews((ctx.args['pr_number'] as num).toInt())
            .map(
              (reviews) => {
                'reviews': reviews.map(prReviewSubmissionToWire).toList(),
              },
            );
      },
    ),
    WatchQuery(
      name: 'pr_review.watchReviewComments',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchReviewComments((ctx.args['pr_number'] as num).toInt())
            .map(
              (comments) => {
                'comments': comments.map(prCodeReviewCommentToWire).toList(),
              },
            );
      },
    ),
    WatchQuery(
      name: 'pr_review.watchIssueComments',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchIssueComments((ctx.args['pr_number'] as num).toInt())
            .map(
              (comments) => {
                'comments': comments.map(issueCommentToWire).toList(),
              },
            );
      },
    ),
    WatchQuery(
      name: 'pr_review.watchCheckRuns',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchCheckRuns((ctx.args['pr_number'] as num).toInt())
            .map((runs) => {'check_runs': runs.map(checkRunToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchReviewers',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
        );
        yield* repo
            .watchReviewers((ctx.args['pr_number'] as num).toInt())
            .map(
              (reviewers) => {
                'reviewers': reviewers.map(prReviewerToWire).toList(),
              },
            );
      },
    ),
    // ---- Interactive terminal output (server-hosted PTY; WORKSPACE-SCOPED) ----
    //
    // Streams a session's raw PTY output, base64-framed per emission, to the
    // thin client. Present only when the host wired a [TerminalSessionPort]
    // (guard promotes `terminals` non-null); a headless server leaves it absent
    // alongside the `terminal.*` ops. The port validates that `session_id`
    // belongs to the bound workspace before yielding any bytes (the isolation
    // boundary) — a foreign/missing session surfaces a `sub/error` immediately.
    if (terminals != null)
      WatchQuery(
        name: 'terminal.output',
        handler: (ctx) {
          final sessionId = ctx.args['session_id'] as String?;
          if (sessionId == null) {
            throw const NotFoundException('Missing session_id');
          }
          return terminals
              .output(workspaceId: ctx.workspaceId!, sessionId: sessionId)
              .map((bytes) => {'chunk': base64Encode(bytes)});
        },
      ),
    // ---- Remote agent-action approvals (confirmation.*) ----
    // CROSS-WORKSPACE BY DESIGN: approvals are host-global; the `conversation_id`
    // field in the snapshot routes each to the right thread. Absent when the
    // host wired no [PendingConfirmationRegistry] (headless cc_server).
    if (pendingConfirmationRegistry != null)
      WatchQuery(
        name: 'confirmation.watchPending',
        workspaceScoped: false,
        handler: (ctx) => pendingConfirmationRegistry.pending.map(
          (list) => {'pending': list.map(pendingConfirmationToWire).toList()},
        ),
      ),
  ]);

  return (ops: ops, watch: watch);
}
