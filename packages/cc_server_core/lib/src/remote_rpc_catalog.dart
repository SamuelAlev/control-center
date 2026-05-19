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
import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/activity_log_reader.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/services/secret_exclusion.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/agent_visibility.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/ide/domain/code_server_port.dart';
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
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/save_orchestration_revision_use_case.dart';
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
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
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
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_registry_port.dart';
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
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show
        ChannelNotesTableData,
        MessageReactionsTableData,
        PairedDevicesTableCompanion,
        PairedDevicesTableData,
        TicketsTableCompanion,
        WorkspaceDatabaseManager;
import 'package:cc_persistence/database/daos/paired_device_dao.dart'
    show PairedDeviceDao, PairedDeviceStatus;
import 'package:cc_rpc/cc_rpc.dart' show RemoteControlCrypto;
import 'package:cc_server_core/src/collab/checker_listener.dart';
import 'package:cc_server_core/src/collab/takeover_service.dart';
import 'package:cc_server_core/src/connection/network_runtime.dart';
import 'package:cc_server_core/src/connection/server_descriptor_service.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/approval_escalation_sweeper.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:cc_server_core/src/sync/sync_feed_service.dart';
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
Future<void> _assertTicketInWorkspace(
  TicketRepository repo,
  String ticketId,
  String workspaceId,
) async {
  final ticket = await repo.getById(workspaceId, ticketId);
  if (ticket == null) {
    throw const NotFoundException('Ticket not found');
  }
}

/// Builds the code-server workbench URL query that opens the conversation
/// worktree [folderPath] (and, when [rawPath] names a file inside it, deep-links
/// that file into an editor). code-server web reads `?folder=` / `?payload=`
/// from `window.location` on load — the CLI positional folder/file are ignored
/// once the workbench is served at the proxy root, so the folder + file must
/// ride the URL or the editor opens on an empty window.
///
/// The folder always opens. The file is best-effort: it is confined to the
/// worktree (a `..` escape or an out-of-tree absolute path is dropped, and the
/// folder still opens), and encoded as an `openFile` payload against the
/// `vscode-remote://remote` authority code-server web uses (see the workbench
/// `remoteAuthority` in its bootstrap config). A malformed payload is ignored by
/// the workbench, degrading to folder-only — never a hard failure.
///
/// When [line] is a positive 1-based line number, it is appended to the file
/// URI as a `:<line>` suffix — the same `code -g file:line` convention the
/// workbench parses via `parseLineAndColumnAware`. That parser only strips a
/// trailing `:<number>` and otherwise keeps the whole path, so an unrecognised
/// suffix degrades to opening the file at its top rather than failing.
String _codeServerOpenQuery(String folderPath, String? rawPath, {int? line}) {
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
/// [_assertTicketInWorkspace]). An `async*` generator so the ownership check
/// runs before any row is yielded.
Stream<Map<String, dynamic>> watchCollaboratorsScoped(
  TicketRepository repo,
  String? ticketId,
  String workspaceId,
) async* {
  if (ticketId == null) {
    throw const NotFoundException('ticket_id is required');
  }
  await _assertTicketInWorkspace(repo, ticketId, workspaceId);
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
  'channel_id': g.channelId,
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
  'channel_id': ?l.channelId,
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
  'pipeline_step_run_id': ?l.pipelineStepRunId,
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
    pipelineStepRunId: w['pipeline_step_run_id'] as String?,
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

/// Maps a channel read-cursor to the `ChannelReadDto` wire shape. The cursor is
/// a nullable ISO-8601 timestamp keyed by `channel_id`.
Map<String, dynamic> channelReadToWire(
  String channelId,
  DateTime? lastReadAt,
) => {
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
    'thinking_levels': m.thinkingLevels!
        .map((l) => {'id': l.id, 'label': l.label})
        .toList(),
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
  'workspace_id': c.workspaceId ?? '',
  'mode': c.mode.toDbValue(),
  'provisioning_status': c.provisioningStatus.toDbValue(),
  'provisioning_step': ?c.provisioningStep?.toDbValue(),
  'origin': c.origin.wire,
  'pipeline_run_id': ?c.pipelineRunId,
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Maps a [Conversation] (message stream inside a channel) to its wire shape.
Map<String, dynamic> conversationToWire(Conversation c) => {
  'id': c.id,
  'workspace_id': c.workspaceId ?? '',
  'channel_id': c.channelId,
  'title': c.title,
  'kind': c.kind.wire,
  'status': c.status.wire,
  'created_by_principal_id': ?c.createdByPrincipalId,
  'created_at': c.createdAt.toIso8601String(),
  'updated_at': c.updatedAt.toIso8601String(),
};

/// Serializes a channel Notes doc row (PRD 16 §11).
Map<String, dynamic> channelNoteToWire(ChannelNotesTableData n) => {
  'id': n.id,
  'workspace_id': n.workspaceId,
  'channel_id': n.channelId,
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
/// A cast would throw, and a redaction path that throws fails the whole
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
  'channel_id': r.channelId,
  'message_id': r.messageId,
  'principal_id': r.principalId,
  'principal_type': r.principalType,
  'emoji': r.emoji,
  'created_at': r.createdAt.toIso8601String(),
};

/// Maps a [ChannelMessage] to the `MessageDto` wire shape (parent/channel ids +
/// compacted flag carried so the thread/timeline UI can rebuild the entity).
///
/// LIST emissions (every `messaging.watch*` subscription) pass
/// `includeSegments: false`: the `metadata['segments']` transcript — the fat
/// payload, potentially megabytes of tool outputs re-sent on every DB write —
/// is elided and flagged (`segments_elided`). The client renders the answer
/// from `content` immediately and pulls the full transcript once per message
/// via `messaging.getMessageById` (finalized transcripts are immutable), or
/// takes it live from the turn relay. One-shot reads keep the full shape.
Map<String, dynamic> messageToWire(
  ChannelMessage m, {
  bool includeSegments = true,
}) {
  var metadata = m.metadata;
  if (!includeSegments && metadata != null && metadata['segments'] != null) {
    metadata = {...metadata, 'segments_elided': true}..remove('segments');
  }
  return {
    'id': m.id,
    'content': m.content,
    'sender_id': m.senderId,
    'sender_type': m.senderType.name,
    'message_type': m.messageType.name,
    'metadata': metadata,
    'channel_id': m.channelId,
    'conversation_id': m.conversationId,
    'compacted': m.compacted,
    'created_at': m.createdAt.toIso8601String(),
  };
}

/// [messageToWire] in the lite list shape (`includeSegments: false`) — the
/// mapper every `messaging.watch*` list emission uses.
Map<String, dynamic> messageToWireLite(ChannelMessage m) =>
    messageToWire(m, includeSegments: false);

/// Maps a [User] to the `UserDto` wire shape.
Map<String, dynamic> userToWire(User u) => UserDto(
  id: u.id,
  handle: u.handle,
  displayName: u.displayName,
  email: u.email,
  avatarRef: u.avatarRef,
  gitAuthorName: u.gitAuthorName,
  gitAuthorEmail: u.gitAuthorEmail,
  createdAt: u.createdAt,
).toJson();

/// Maps a [WorkspaceMember] to the `WorkspaceMemberDto` wire shape.
Map<String, dynamic> workspaceMemberToWire(WorkspaceMember m) =>
    WorkspaceMemberDto(
      id: m.id,
      workspaceId: m.workspaceId,
      userId: m.userId,
      role: m.role.wireName,
      invitedBy: m.invitedBy,
      joinedAt: m.joinedAt,
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
  createdAt: e.createdAt,
).toJson();

/// Maps a [ChannelParticipant] to the `ChannelParticipantDto` wire shape.
Map<String, dynamic> channelParticipantToWire(ChannelParticipant p) => {
  'id': p.id,
  'channel_id': p.channelId,
  'principal_id': p.principalId,
  'participant_type': p.participantType.wireName,
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
  'owner_user_id': ?w.ownerUserId,
  'secret_exclude_globs': w.secretExcludeGlobs,
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
    ownerUserId: w['owner_user_id'] as String?,
    secretExcludeGlobs:
        (w['secret_exclude_globs'] as List?)?.whereType<String>().toList() ??
        const [],
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
      status: PipelineStepStatus.fromString(
        w['status'] as String? ?? 'pending',
      ),
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

// ---- Plan Studio wire helpers (PRD 17) ----

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

// ---- Work product / artifact wire helpers (PRD 09 + artifacts) ----
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
  'name': ?u.name,
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
  'requested_team_slugs': pr.requestedTeamSlugs,
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
  'review_decision': pr.reviewDecision.name,
};

/// Whether one open-PR wire map counts toward the "needs my review" badge for
/// [login] (expected already lowercased). Mirrors the inbox classifier's
/// `needsYourReview` rule (`prNeedsYourReview`): the review request must
/// name the operator or a team they belong to, drafts are not reviewable
/// yet, and the operator's own PRs belong to the author-centric sections.
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
  'id': r.id,
  'state': r.state.name,
  'author': ?(r.author == null ? null : prUserToWire(r.author!)),
  'body': r.body,
  'submitted_at': ?r.submittedAt?.toIso8601String(),
};

/// Maps a [PrTimelineEvent] to the `PrTimelineEventDto` wire shape.
Map<String, dynamic> prTimelineEventToWire(PrTimelineEvent e) => {
  'kind': e.kind.name,
  'actor': ?(e.actor == null ? null : prUserToWire(e.actor!)),
  'reviewer_name': e.reviewerName,
  'reviewer_is_team': e.reviewerIsTeam,
  'reviewer_avatar_url': e.reviewerAvatarUrl,
  'created_at': ?e.createdAt?.toIso8601String(),
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
  'review_id': ?c.reviewId,
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

/// The SERVER user's GitHub teams (org → slugs, already lower-cased), or
/// null when the lookup failed. Empty map = belongs to no teams. Drives
/// team-requested rows in Needs your review.
typedef ViewerGitHubTeamsFetcher = Future<Map<String, Set<String>>?> Function();

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
/// Code, OpenAI Codex, z.ai, Kimi Code) as `SubscriptionUsage` wire maps, for
/// the `subscriptions.usage` op behind the title-bar usage pill. Runs
/// server-side (where the CLIs and their credentials live). z.ai and Kimi Code
/// have no local credential file, so the op resolves their credentials from the
/// harness provider credential store (Settings → Adapters → Providers &
/// models) and passes them in. Null when the host wires no fetcher → the op
/// returns an empty list.
typedef SubscriptionUsageFetcher =
    Future<List<Map<String, dynamic>>> Function({
      String? zaiApiKey,
      String? zaiBaseUrl,
      String? kimiAccessToken,
      String? kimiBaseUrl,
      String? kimiDeviceId,
    });

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
      required String channelId,
      required String messageId,
      required bool inclusive,
    });

/// Undoes the most-recent revert (redo) on the SERVER — conversation-only (the
/// filesystem is NOT re-applied; the user can re-run the agent to regenerate
/// changes). Returns the restored message ids.
typedef ConversationUnrevertFn =
    Future<List<String>> Function({
      required String workspaceId,
      required String channelId,
    });

/// Computes a linked repo's working-tree diff (vs HEAD, incl. untracked) WITH
/// patch hunks, as a `List<PrFile>`. Runs on the SERVER (owns the checkout) via
/// `git diff HEAD`. Workspace-scoped: the host must validate repo ownership.
typedef RepoChangesFetcher =
    Future<List<PrFile>> Function(
      String workspaceId,
      String repoId, {
      String? channelId,
    });

/// Computes a repo's changes split into staged (index vs HEAD) and unstaged
/// (worktree vs index + untracked) buckets — the VS Code Source Control model.
typedef RepoChangesGroupedFetcher =
    Future<({List<PrFile> staged, List<PrFile> unstaged})> Function(
      String workspaceId,
      String repoId, {
      String? channelId,
    });

/// Stages or unstages files in a conversation's isolated worktree index (`git
/// add` / `git reset HEAD`). Empty paths ⇒ all. Returns false when the channel
/// owns no worktree for the repo.
typedef RepoStageMutator =
    Future<bool> Function(
      String workspaceId,
      String channelId,
      String repoId,
      List<String> paths,
    );

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

/// Server-side literal content search across a workspace's linked repo roots
/// (the Explorer's "Content" mode). Returns raw wire maps grouped per file —
/// `{repoId, relativePath, matches: [{line, text}]}` — so the client can render
/// VS Code-style grouped matches with highlighted lines. Empty query → empty.
typedef RepoContentSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String query, {
      Map<String, Object?> options,
    });

/// Server-side literal/regex content search across ONE conversation's isolated
/// CoW worktree (e.g. the PR-head tree), backing the PR workbench sidebar's
/// "search in files" mode. Same grouped wire shape as [RepoContentSearchFetcher]
/// but scoped to a single `(channelId, repoId)` worktree — the search never
/// leaks to the shared linked checkout. Empty query → empty; a foreign or
/// unprovisioned channel → empty.
typedef WorktreeContentSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String channelId,
      String repoId,
      String query, {
      Map<String, Object?> options,
    });

/// Server-side fuzzy file search across ONE conversation's isolated CoW
/// worktree (e.g. the PR-head tree), backing the PR workbench sidebar's file
/// finder. Same wire shape as [RepoFileSearchFetcher] (FileSearchHit fields +
/// `repoId`) but scoped to a single `(channelId, repoId)` worktree — the finder
/// never leaks to the shared linked checkout. Empty query → full tree; a foreign
/// or unprovisioned channel → empty.
typedef WorktreeFileSearchFetcher =
    Future<List<Map<String, dynamic>>> Function(
      String workspaceId,
      String channelId,
      String repoId,
      String query,
    );

/// Writes a draft file into a conversation's isolated worktree, SERVER-SIDE.
/// Backs the IDE's "untitled" draft save (⌘S). Returns `{repoId, path}` on
/// success or null when the channel has no worktree for the repo / the path
/// escapes the worktree root / the payload is too large.
typedef WorktreeWriteFileFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String channelId,
      required String repoId,
      required String path,
      required String content,
    });

/// Reverts one or more working-tree files in a conversation's isolated
/// worktree to HEAD, SERVER-SIDE (tracked files only; untracked are skipped).
/// Returns `{repoId, reverted: int, skipped: List<String>}`, or null when the
/// channel has no worktree for the repo.
typedef WorktreeRevertFilesFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String channelId,
      required String repoId,
      required List<String> paths,
    });

/// Reads a file from a conversation's isolated worktree (PR-head tree). Returns
/// null when the channel has no worktree for the repo.
typedef WorktreeReadFileFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String channelId,
      required String repoId,
      required String path,
    });

/// Commits (and optionally pushes) changes in a conversation's isolated
/// worktree. Returns a result map ({committed, pushed, headSha?, error?}) or
/// null when the channel has no worktree for the repo.
typedef WorktreeCommitAndPushFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String channelId,
      required String repoId,
      required String message,
      required List<String> paths,
      required bool push,
      bool amend,
      bool sync,
      String? pushBranch,
      String? authorName,
      String? authorEmail,
    });

/// Publishes a conversation worktree's branch to `origin` — a push only, no
/// commit. Returns a result map ({branch, headSha, pushed, uncommitted, error?})
/// or null when the channel has no worktree for the repo.
typedef WorktreePublishBranchFn =
    Future<Map<String, Object?>?> Function({
      required String workspaceId,
      required String channelId,
      required String repoId,
      String? branchOverride,
    });

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
      // Optional parenthesis to run the fix in, so it doesn't clutter the main
      // review conversation. Null → the channel's main conversation.
      String? conversationId,
      // The session user the fix run executes for (commit co-author trailer +
      // per-user credential selection). Null attributes to the server owner.
      String? requestedByUserId,
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

/// One durable-goal lifecycle control (`pause` / `resume` / `cancel`), wired
/// by the caller to the server's `GoalSupervisor` (tear-offs keep this file
/// agnostic of the dispatch machinery).
typedef GoalControl = Future<void> Function(String workspaceId, String goalId);

/// The `resume` control: resumes a paused goal, or a `budgetExhausted` one
/// when [raiseCostCapCents] lifts the cost cap above the spend that tripped
/// it (budget exhaustion is not completion — the goal resumes only by
/// raising the budget).
typedef GoalResumeControl =
    Future<void> Function(
      String workspaceId,
      String goalId, {
      int? raiseCostCapCents,
    });

/// Durable supervised goals (`/goal` + `/loop`): the pause / resume / cancel
/// controls a thin client drives over repo-RPC. Each op is a thin delegation
/// to the server's goal supervisor.
List<RepoOp> agentGoalRunOps({
  required GoalControl pauseGoal,
  required GoalResumeControl resumeGoal,
  required GoalControl cancelGoal,
}) => [
  RepoOp(
    name: 'agentGoalRuns.pause',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await pauseGoal(ctx.workspaceId!, ctx.args['goal_id'] as String);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'agentGoalRuns.resume',
    kind: RepoOpKind.mutate,
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await resumeGoal(
        ctx.workspaceId!,
        ctx.args['goal_id'] as String,
        raiseCostCapCents: (ctx.args['raise_cost_cap_cents'] as num?)?.toInt(),
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'agentGoalRuns.cancel',
    kind: RepoOpKind.mutate,
    // Cancel is destructive with no inverse op (a cancelled goal never runs
    // again): like the `*.delete` ops, undoClass stays undeclared →
    // irreversible, so it never enters the undo stack.
    requiredArgs: ['goal_id'],
    handler: (ctx) async {
      await cancelGoal(ctx.workspaceId!, ctx.args['goal_id'] as String);
      return {'ok': true};
    },
  ),
];

/// The watch counterpart to [agentGoalRunOps]: the workspace's durable goals
/// (newest first) filtered to the client's `conversation_id` arg.
WatchQuery agentGoalRunsWatchQuery({
  required AgentGoalRunRepository agentGoalRunRepository,
}) => WatchQuery(
  name: 'agentGoalRuns.watchForConversation',
  handler: (ctx) => agentGoalRunRepository
      .watchByWorkspace(ctx.workspaceId!)
      .map(
        (list) => {
          'goals': [
            for (final g in list.where(
              (g) => g.conversationId == ctx.args['conversation_id'],
            ))
              agentGoalRunToWire(g),
          ],
        },
      ),
);

/// Builds the live repo-RPC catalog from the real repositories/services — the
/// composition point that turns the protocol machinery into a concrete,
/// workspace-scoped surface covering tickets, messaging, and newsfeed.
///
/// Builds the workspace-scoped RPC catalog.
///
/// Every workspace-scoped op/query sources its workspace from the session
/// binding, never from client args. Channels are workspace-scoped, but messages
/// are keyed only by `channel_id`, so message ops **validate channel ownership**
/// against the session's workspace before touching them — an ID-only lookup is
/// not a scoping boundary (workspace-isolation invariant). Newsfeed is global
/// (`workspaceScoped: false`), a declared exemption.
RemoteRpcCatalog buildRemoteRpcCatalog({
  // ---- Identity & membership (multi-user access; the `identity.*` /
  // `users.*` / `members.*` / `invites.*` / `prefs.*` / `activity.*` ops) ----
  // Users are global; membership + roles + invites + per-repo grants +
  // the audit trail are workspace-scoped. Optional as a group: when null the
  // identity ops are absent (bare test catalogs); production always wires
  // them.
  UserRepository? userRepository,
  WorkspaceMembershipRepository? membershipRepository,
  WorkspaceInviteRepository? inviteRepository,
  UserActivityRepository? userActivityRepository,
  UserPreferencesRepository? userPreferencesRepository,
  WorkspaceInviteService? inviteService,
  // Per-user credentials (the `credentials.*` ops): each member stores their
  // OWN GitHub token so runs they request act under their GitHub identity.
  // The token is write-only over RPC — set/clear + a configured flag; the
  // value itself is never returned to any client. Optional: when null the
  // `credentials.*` ops are absent.
  UserCredentialsStore? userCredentials,
  // Approval routing (per-workspace policy storage + escalation state). When
  // null the `approvals.getRoutingPolicy` / `approvals.setRoutingPolicy` ops
  // are absent.
  ApprovalEscalationSweeper? approvalRouting,
  // The bootstrap owner's user id. Server-global surfaces with no workspace
  // role to consult (the device registry) treat this user as their admin:
  // everyone manages their OWN devices; the owner manages all of them.
  String? serverOwnerUserId,
  required TicketRepository ticketRepository,
  required ProjectRepository projectRepository,
  // ---- Ticket sync health (§188) ----
  // Read-only visibility into the multi-vendor sync configs + the append-only
  // attempt log, so the client can show per-vendor last-sync + error streak.
  // Optional: when null the `ticket_sync_config.watchForWorkspace` /
  // `ticket_sync_log.watchForWorkspace` ops are absent and the surface is empty.
  TicketSyncConfigRepository? syncConfigRepository,
  TicketSyncLogRepository? syncLogRepository,
  // Manual "sync now" trigger for the sync health card (§188). A deferred
  // callback (not the engine directly) because the engine is constructed after
  // this catalog during bootstrap; the closure is only invoked at request time.
  // Optional: when null the `ticket_sync.syncNow` op is absent.
  Future<PullSummary> Function({required String workspaceId, String? vendor})?
  ticketSyncNow,
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
  // ---- Provider governance (PRD 05; the `provider_policy.*` ops) ----
  // Per-workspace allow/deny statements the model catalog's finalize consults
  // to drop denied providers. Optional: when null the ops are absent
  // (default-deny) and the governance UI degrades to read-only catalog browsing.
  ProviderPolicyRepository? providerPolicyRepository,
  // Unified action-guardrail policy store (PRD 24 §4): backs the agent-
  // permissions matrix + what-if probe ops. Optional — when null the ops are
  // absent (the policy surface degrades) and enforcement runs on built-in
  // defaults only.
  ActionPolicyRepository? actionPolicyRepository,
  WorkspaceSettingsRepository? workspaceSettingsRepository,
  ServerSettingsRepository? serverSettingsRepository,
  // Skill bundle service + registry (PRD 23 §1/§3): back the `skills.*` browse/
  // preview/install ops for the Skills settings surface. Install always routes
  // through the mandatory scan gate inside the service. Optional — absent when
  // no registry is wired.
  SkillBundlePort? skillBundles,
  SkillRegistryPort? skillRegistry,
  // Built-in harness provider/credential brain (PRD 13): the server-owned
  // credential store + OAuth broker back the `providers.*` ops so every client
  // (desktop/web/remote) manages API keys, browser logins, and the live model
  // list over RPC. Optional: when null the `providers.*` ops are absent.
  ProviderCredentialStore? harnessCredentialStore,
  HarnessOAuthBroker? harnessOAuthBroker,
  HarnessProviderFactory harnessProviderFactory =
      const HarnessProviderFactory(),
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
  // Voice dictation over RPC (PRD 25 §2): reuses the host's windowed
  // transcriber to stream finalized text back to the composer. Optional —
  // declared only when a voice model is installed (same gate as meeting.*).
  DictationService? dictationService,
  required TicketLinkRepository ticketLinkRepository,
  required PipelineRunRepository pipelineRunRepository,
  required PipelineTemplateRepository pipelineTemplateRepository,
  required PipelineTriggerRepository pipelineTriggerRepository,
  required TeamRepository teamRepository,
  required OrchestrationRepository orchestrationRepository,
  // ---- Governance (PRD 09; workspace-scoped at the repos/service) ----
  // The thin client READS this surface only: the goal hierarchy, board
  // approvals + their comment threads, and computed agent presence (availability
  // × workload). Writes (create/decide approvals, set goal progress, heartbeat)
  // run through the MCP tools server-side, never these ops — so only reads /
  // watches are exposed here.
  required GoalRepository goalRepository,
  required ApprovalRepository approvalRepository,
  required AgentPresenceService agentPresenceService,
  // Per-conversation todo lists (read + mutate + watch). Unlike governance,
  // the thin client both reads and writes these so `/todo` works offline of
  // the agent; the agent-facing writes go through the MCP `todo_write` tool.
  required TodoRepository todoRepository,
  // The durable notification feed (per-workspace rows, per-user read marks).
  // The feed is written ONLY by the server's `NotificationFeedRecorder`;
  // clients watch it and acknowledge their own read state.
  required NotificationFeedRepository notificationFeedRepository,
  // Durable supervised goals (`/goal` + `/loop`): the thin client lists a
  // conversation's `AgentGoalRun`s (watch) and drives pause / resume /
  // cancel through the supervisor (thin delegations — the lifecycle itself
  // lives server-side).
  required AgentGoalRunRepository agentGoalRunRepository,
  required GoalSupervisor goalSupervisor,
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
  // pairing path: when the server is not directly reachable from the client,
  // both rendezvous in the server's N-way relay room and exchange
  // E2E-encrypted RPC. Empty disables advertising a relay endpoint. The
  // host's `RemoteRelayHost` watches the device table, so minting an `active`
  // device is enough to admit it to the room — no callback needed here.
  String relaySignalingUrl = '',
  // ---- Connectivity (PRD 15; the `connection.*` ops) ----
  // Builds the server's live ConnectionDescriptor (every reachable path +
  // the pinned identity fingerprint). When null, `connection.describe` is
  // absent and `pairing.mint`/invites omit the descriptor (bare test
  // catalogs); production always wires it.
  ServerDescriptorService? descriptorService,
  // The network runtime behind the `connectivity.*` ops: share-this-server
  // tunnel control, mDNS state, and relay-usage accounting. A deferred
  // closure (like [ticketSyncNow]) because the runtime is constructed after
  // this catalog during bootstrap; resolved per request. Optional: when null
  // those ops are absent (bare test catalogs).
  NetworkRuntime? Function()? networkRuntime,
  // ---- Presence (PRD 16; the ephemeral awareness lane) ----
  // The in-memory hub behind `presence.update` / `presence.watch`. Presence
  // is NEVER persisted — no repository, no table, no DAO. Optional: when
  // null the presence ops are absent (bare test catalogs).
  PresenceHub? presenceHub,
  // ---- Deterministic sync (PRD 16 §6; the delta lane) ----
  // The authoritative delta feed behind `sync.watch` / `sync.pull`, plus the
  // DAOs backing the per-column LWW ticket patch and the channel extras
  // (Notes doc, autonomy dial, reactions). Optional as a group: when null
  // those ops are absent and every store stays in snapshot mode.
  SyncFeedService? syncFeed,
  // The per-workspace databases, for the handful of ops that reach a DAO
  // directly rather than through a repository (channel notes / reactions /
  // autonomy). Each resolves `workspaceDbs.of(ctx.workspaceId!)`, so the bound
  // workspace picks the database file before any SQL runs.
  WorkspaceDatabaseManager? workspaceDbs,
  // ---- Take-over / hand-back + checker role (PRD 16 §8/§13) ----
  // Optional as a group: absent in bare test catalogs.
  TakeoverService? takeoverService,
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
  // The open-PR poller behind the live PR list: `pr.watchOpenForWorkspace`
  // streams its snapshot and `pr.refreshOpenForWorkspace` forces a sweep.
  // Optional: when null the watch reports `authenticated: false` (no gh token).
  OpenPrPollingService? openPrPoller,
  // The SERVER's authenticated GitHub user (drives `github.currentUser`). Null
  // when the server holds no gh token → the op returns a null user.
  CurrentGitHubUserFetcher? fetchCurrentGitHubUser,
  // The SERVER user's GitHub team membership (org → slugs). Null → inbox /
  // badge stay user-only (today's matching).
  ViewerGitHubTeamsFetcher? fetchViewerGitHubTeams,
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
  // Fetches the raw status.claude.com summary for `claude.serviceStatus`.
  // Needs no token; null only when the host wires no fetcher → null summary.
  ClaudeServiceStatusFetcher? fetchClaudeServiceStatus,
  // Fetches the raw status.openai.com summary for `openai.serviceStatus`.
  // Needs no token; null only when the host wires no fetcher → null summary.
  OpenAIServiceStatusFetcher? fetchOpenAIServiceStatus,
  // Fetches the raw status.moonshot.cn summary for `kimi.serviceStatus`.
  // Needs no token; null only when the host wires no fetcher → null summary.
  KimiServiceStatusFetcher? fetchKimiServiceStatus,
  // Fetches live subscription-usage quotas (Claude/Codex/z.ai) for the
  // `subscriptions.usage` op. Null → the op returns an empty list.
  SubscriptionUsageFetcher? fetchSubscriptionUsage,
  // Klipy GIF search / trending for the composer's GIF picker. Null (no Klipy
  // app key) → the `gif.*` ops return empty.
  GifSearchFetcher? gifSearch,
  GifTrendingFetcher? gifTrending,
  // The workspace-scoped cache backing the SWR PR/commit reference previews.
  // Optional: when null, previews skip caching and hit the fetcher directly.
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
  // Opening a PR's branch in an editor launches a GUI editor on the SERVER's
  // machine, so the launch op exists only when the host wires the launcher (a
  // desktop / GUI host). A headless server leaves it null and the op is simply
  // absent (the client's open-in-IDE button then hides itself).
  EditorLauncherPort? editorLauncher,
  // Resolves a PR's on-disk worktree path — the SAME channel worktree the
  // workbench edits (there is no separate `pr_worktrees/` checkout). Ensures the
  // PR channel + provisioning, then returns the checkout path. Absent on a host
  // that owns no worktrees.
  Future<String> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prNodeId,
    String title,
    String? repoId,
  })?
  ensurePrWorktree,
  // Re-syncs a PR channel's worktree to the latest PR head (commits pushed after
  // it was provisioned). No-ops on a dirty tree. Absent on a host that owns no
  // worktrees.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String channelId,
    required String repoId,
  })?
  syncPrWorktree,
  // Computes a conversation's working-tree diff on the SERVER (reads the CoW
  // worktree registry + runs `git diff`). Only a host that owns those checkouts
  // wires it; absent elsewhere (the web panel then shows "no changes").
  ConversationChangesFetcher? conversationChanges,
  // Generic workspace-scoped key/value cache the SERVER owns (the Drift `cache`
  // table). Backs the `cache.read` / `cache.write` ops, which the messaging IDE
  // layout uses to persist + restore its editor split-tree per conversation —
  // server-side storage is what lets a layout saved on one client (desktop) be
  // restored on another (web) and vice versa. Always present on a host that owns
  // the database (desktop in-process host / headless cc_server); the ops are
  // workspace-scoped (the workspace filter is the isolation boundary).
  CacheRepository? cacheRepository,
  // Conversation revert/unrevert (undo/redo) executed on the SERVER. The two
  // `messaging.revertConversationTo` / `messaging.unrevertConversation` ops are
  // ALWAYS present (DB-backed transcript rollback via [messagingRepository]);
  // these closures ADD the worktree filesystem rollback, so they are wired only
  // by the host that owns BOTH the DB and the conversation's CoW worktrees (the
  // dispatch host — the in-process desktop host or the spawned cc_server). When
  // null the ops fall back to a transcript-only revert (`filesystem_restored`
  // is false). Workspace-scoped: the ops source `ctx.workspaceId!` and assert
  // channel ownership before delegating (isolation invariant).
  ConversationRevertFn? conversationRevert,
  ConversationUnrevertFn? conversationUnrevert,
  // Re-runs background channel-workspace provisioning (repo worktrees +
  // per-agent overlay + `.mcp.json`) after a failure, so the UI's Retry button
  // can unblock a `failed` channel. Server-side only; null ⇒ the op is omitted.
  // Workspace-scoped: asserts channel ownership before retrying.
  Future<void> Function({
    required String workspaceId,
    required String channelId,
  })?
  retryChannelProvisioning,
  // Working-tree diff (vs HEAD, incl. untracked) WITH patches for a linked
  // repo, computed SERVER-SIDE via `git diff HEAD` on the owned checkout. The
  // messaging IDE's Source Control panel renders these `PrFile`s. Absent on a
  // host that owns no checkouts (the panel then shows "no changes").
  RepoChangesFetcher? repoChanges,
  // Staged/unstaged split of a repo's changes (real git index) for the VS
  // Code-style Source Control view. Absent on a host that owns no checkouts.
  RepoChangesGroupedFetcher? repoChangesGrouped,
  // Stage / unstage files in a conversation's isolated worktree index. Absent on
  // a host that owns no worktrees.
  RepoStageMutator? repoStage,
  RepoStageMutator? repoUnstage,
  // Reads a file from a linked repo checkout SERVER-SIDE (text + binary flag),
  // rejecting traversal outside the repo root. Backs the IDE FileViewer tab.
  RepoFileContentFetcher? repoFileContent,
  // Server-side fuzzy file search across a workspace's linked repo roots
  // (returns wire maps; the client rebuilds FileSearchHit). Backs the IDE
  // Explorer panel (fff runs SERVER-SIDE over the CoW checkouts).
  RepoFileSearchFetcher? repoFileSearch,
  // Server-side literal content search across a workspace's linked repo roots
  // (grouped file+line matches). Backs the IDE Explorer's "Content" mode.
  RepoContentSearchFetcher? repoContentSearch,
  // Server-side content search across ONE conversation's isolated CoW worktree
  // (grouped file+line matches). Backs the PR workbench sidebar's "search in
  // files" mode. Absent on a host that owns no worktrees.
  WorktreeContentSearchFetcher? worktreeContentSearch,
  // Server-side fuzzy file search across ONE conversation's isolated CoW
  // worktree (wire maps; the client rebuilds FileSearchHit). Backs the PR
  // workbench sidebar's file finder. Absent on a host that owns no worktrees.
  WorktreeFileSearchFetcher? worktreeFileSearch,
  // Writes a draft into a conversation's isolated worktree, SERVER-SIDE. Backs
  // the IDE "untitled" draft save (⌘S). Absent on a host that owns no
  // worktrees. Workspace-scoped + channel-owned: the worktree is resolved via
  // the isolation registry, so a foreign channel is simply not found.
  WorktreeWriteFileFn? worktreeWriteFile,
  // Reverts working-tree files in a conversation's isolated worktree to HEAD,
  // SERVER-SIDE. Backs the IDE Source Control "Revert" action. Absent on a host
  // that owns no worktrees. Workspace-scoped + channel-owned.
  WorktreeRevertFilesFn? worktreeRevertFiles,
  // Reads a file from a conversation's isolated worktree (PR-head tree), and
  // commits/pushes worktree changes. PR workbench file view/edit + commit&push.
  WorktreeReadFileFn? worktreeReadFile,
  WorktreeCommitAndPushFn? worktreeCommitAndPush,
  // Publishes a conversation worktree's branch to origin (push only). Lets the
  // compose-PR screen open a PR from a chat's local-only worktree branch.
  WorktreePublishBranchFn? worktreePublishBranch,
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
  // Owns server-hosted code-server (VS Code in the browser) processes — one per
  // conversation worktree, loopback-bound, ref-counted + idle-GC'd. The
  // `codeServer.open` op mints a high-entropy capability bound to the caller's
  // `(workspaceId, deviceId)`; the `/proxy/vscode/<sid>/` reverse proxy
  // authorizes each request against it. The ops exist only when the host wired
  // a [CodeServerPort] (the headless cc_server); sessions are workspace-scoped
  // (ownership validated per op, worktree resolved strictly from the caller's
  // workspace).
  CodeServerPort? codeServer,
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
  // the work executing server-side. The dispatch path needs the sandbox engine,
  // so only a host that links it wires
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
  // persistence (the Drift DB) and drives the dispatch stack (sandbox /
  // cc_natives indexer), so only a host that constructs the
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
  // ---- Plan Studio (PRD 17) ----
  // The plan surface: revision history + operator edits (`orchestration.
  // saveRevision` / `revisions`), partial approval (`approve` with
  // `approved_node_keys`, `approveNodes`), plan-mode documents (`plan.*`),
  // playbooks (`playbook.*`), estimates (`plan.estimate`), and plan-drift
  // markers (`orchestration.divergence` / `continueNode`). All optional —
  // absent on a host without the engine/services (default-deny). Every op is
  // workspace-scoped via `ctx.workspaceId!` + repository scoping.
  OrchestrationRevisionRepository? orchestrationRevisionRepository,
  PlanDocumentRepository? planDocumentRepository,
  PlaybookRepository? playbookRepository,
  SaveOrchestrationRevisionUseCase? saveOrchestrationRevision,
  // ---- Work products / artifacts ----
  // The `workProduct.*` ops: agent-published block artifacts + every other
  // versioned deliverable. Optional (absent → the client's artifact surface is
  // empty rather than half-wired). Workspace-scoped through the repository,
  // which requires `workspaceId` on every read.
  WorkProductRepository? workProductRepository,
  Future<void> Function(
    String workspaceId,
    String orchestrationId,
    Set<String>? approvedNodeKeys,
  )?
  approveOrchestrationScoped,
  Future<void> Function(
    String workspaceId,
    String orchestrationId,
    Set<String> nodeKeys,
  )?
  approveOrchestrationNodes,
  Future<Map<String, dynamic>> Function(
    String workspaceId,
    String orchestrationId,
  )?
  planDivergenceMarkers,
  Future<void> Function(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  )?
  continuePlanNode,
  Future<Map<String, dynamic>> Function(String workspaceId, String id)?
  estimateOrchestration,
  Future<Map<String, dynamic>> Function(String workspaceId, String id)?
  estimatePlanDocument,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String planId,
    Set<String>? approvedNodeKeys,
    int? maxCostCents,
  })?
  approvePlanDocument,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String ticketId,
    required String playbookId,
    required Map<String, String> args,
    String? userId,
  })?
  runPlaybook,
  // ---- Review Studio (PRD 18) ----
  // The review-studio read surface (semantic cohorts, API-contract diffs, UI
  // visual diffs, per-axis results) + two mutate gates (per-change contract
  // decision, visual "approve intended change"), all workspace-scoped via the
  // repositories. The compute closures ([computeReviewStudio],
  // [reviewBlastRadius]) run on a host that owns the code graph + git + PR
  // fetch; a headless server without them leaves the ops absent (default-deny).
  ReviewCohortRepository? reviewCohortRepository,
  ApiContractDiffRepository? apiContractDiffRepository,
  VisualDiffRepository? visualDiffRepository,
  ReviewAxisResultRepository? reviewAxisResultRepository,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String userId,
  })?
  computeReviewStudio,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String owner,
    required String repo,
    required String filePath,
    required String userId,
    int depth,
  })?
  reviewBlastRadius,
  // Publishes a finalized review to GitHub (user-gated: the client "Publish to
  // GitHub" button). Delegates to the [ReviewPublisherPort]; wired only by a
  // host that owns the GitHub PR client. Declares `prPublish`, so the guardrail
  // chokepoint gates it like any mutating action.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String channelId,
    required String selection,
    required bool approveOnShip,
  })?
  publishReview,
  // Resolves a PR's canonical review-studio key — its real GitHub node id
  // (migration 46) — for the studio read ops. Wired alongside the studio repos.
  ReviewPrNodeIdResolver? resolveStudioKey,
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
  // ---- Live turn relay (`messaging.watchChannelTurns`) ----
  // The dispatch stack's in-flight turn registry. When wired, a thin client
  // subscribes per open channel and receives a seed snapshot of every active
  // turn plus coalesced per-segment updates — genuinely live streaming,
  // decoupled from the (crash-insurance) DB flush cadence. Null on a host
  // without the dispatch stack → the op is absent and clients fall back to
  // rendering persisted rows.
  ActiveStreamRegistry? streamRegistry,
  // Per-run activity transcripts (`agent_run_log.getTranscript` /
  // `.watchRunTranscript`): the durable store behind a subagent's activity tab.
  // The live lane rides [streamRegistry]; this backs replay of a finished run
  // and crash recovery. Null leaves the read op absent (default-deny) and makes
  // the watch op seed empty for anything not currently streaming.
  RunTranscriptRepository? runTranscriptRepository,
  // ---- Server-computed messaging aggregates ----
  // A SQL read-model projection (on DaoMessagingRepository, not the shared
  // repository interface): per-channel activity signals so the sidebar doesn't
  // hold one full message-list subscription PER CHANNEL ROW. Null leaves the op
  // absent (default-deny).
  Stream<List<ChannelActivity>> Function(String workspaceId)?
  watchChannelActivity,
  // ---- Conversations (parallel streams inside a channel; PR-workbench) ----
  // The conversation repository backs the `conversation.*` mutate ops and the
  // `conversation.watchForChannel` subscription. Null leaves those ops absent.
  ConversationRepository? conversationRepository,
  Stream<List<Conversation>> Function(String workspaceId, String channelId)?
  watchConversationsForChannel,
  // ---- PR workbench: ensure a PR's backing channel (chat/terminal/files) ----
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prNodeId,
    String? createdByUserId,
    String title,
  })?
  ensurePrChannel,
  // ---- Database backup / workspace export-import ----
  // Backs `server.backupNow` (a whole-install snapshot directory: global.db
  // plus one file per workspace and a manifest) and the per-workspace
  // `workspace.export` / `workspace.import` pair, which exist because one
  // workspace is one file — exporting it is a single VACUUM INTO rather than a
  // table-by-table dump. All three are `fullClient`-only so a companion phone
  // can never trigger them. Null leaves the ops absent (default-deny).
  DatabaseBackupPort? databaseBackup,
  // ---- Fleet ops & reactive queries (PRD 20) ----
  // Built in the runtime (which owns the scheduler + fleet repository) and
  // spliced into the closed registries here, so this hub stays agnostic of the
  // fleet wiring. Empty on a host with no fleet surface.
  List<RepoOp> extraOps = const [],
  List<WatchQuery> extraWatchQueries = const [],
}) {
  Future<bool> channelInWorkspace(String workspaceId, String channelId) async {
    final channels = await messagingRepository
        .watchChannelsByWorkspace(workspaceId)
        .first;
    return channels.any((c) => c.id == channelId);
  }

  /// Whether [userId]'s view of this conversation's agent traces must be
  /// redacted: true when any repo linked to the conversation carries no
  /// grant for them (PRD 16 §follow-mode clarification). Admins and
  /// repo-less conversations are never redacted; absent identity wiring
  /// (single-user test catalogs) means no redaction.
  Future<bool> viewerTraceRestricted(
    String workspaceId,
    String channelId,
    String userId,
  ) async {
    if (membershipRepository == null) {
      return false;
    }
    final member = await membershipRepository.getMember(workspaceId, userId);
    if (member == null) {
      return true; // Fail closed: no membership row, no trace bodies.
    }
    if (member.role.isAdmin) {
      return false;
    }
    final repos = await isolatedRepoRepository.forChannel(
      workspaceId,
      channelId,
    );
    if (repos.isEmpty) {
      return false;
    }
    final grants = await membershipRepository.getRepoGrants(
      workspaceId,
      userId,
    );
    for (final r in repos) {
      if ((grants[r.repoId] ?? RepoGrantLevel.none) == RepoGrantLevel.none) {
        return true;
      }
    }
    return false;
  }

  Future<void> assertChannelOwned(String workspaceId, String channelId) async {
    if (!await channelInWorkspace(workspaceId, channelId)) {
      throw const WorkspaceMismatchException(
        'Channel belongs to a different workspace',
      );
    }
  }

  /// One run's recorded activity for REPLAY, from whichever store holds it.
  ///
  /// Two kinds of run persist their timeline in two different places, and a
  /// replay that knows only one of them reads as "nothing recorded":
  ///
  ///   * a SUBAGENT run has no message of its own, so `RunTranscriptRecorder`
  ///     flushes it to `run_transcripts` keyed by the child run id;
  ///   * a TOP-LEVEL run's turn IS a channel message — `MessagingService`
  ///     posts the `agent_turn` placeholder under `messageId == runLog.id` and
  ///     the stream processor folds its segments into that row's
  ///     `metadata['segments']`. Nothing is written to `run_transcripts`.
  ///
  /// While either kind streams, `ActiveStreamRegistry` covers both (it too is
  /// keyed by that shared id), which is why a live activity tab works and only
  /// replay after a restart went blank.
  ///
  /// Returns the `run_transcripts` row when there is one — its `complete` flag
  /// drives crash normalization — else the message-backed segments with no row.
  Future<({List<TranscriptSegment> segments, RunTranscript? row})>
  loadRunReplay(String workspaceId, String runId) async {
    final row = await runTranscriptRepository?.getForRun(workspaceId, runId);
    if (row != null) {
      return (segments: row.segments, row: row);
    }
    final message = await messagingRepository.getMessageById(
      workspaceId,
      runId,
    );
    // Keyed by id alone, so the owning channel is the isolation check — the
    // same rule `messaging.getMessageById` applies.
    if (message == null ||
        !await channelInWorkspace(workspaceId, message.channelId)) {
      return (segments: const <TranscriptSegment>[], row: null);
    }
    return (
      segments: decodeTranscript(message.metadata?['segments']),
      row: null,
    );
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
  Future<void> assertPrLifecycleOwned(String workspaceId, String prId) async {
    final pr = await prLifecycleRepository.getById(workspaceId, prId);
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
  // Promoted locals for the optional identity dependency group (final locals
  // null-check-promote into the op closures; the raw params do not).
  final identityUsers = userRepository;
  final identityMembers = membershipRepository;
  final identityInvites = inviteRepository;
  final identityActivity = userActivityRepository;
  final identityPrefs = userPreferencesRepository;
  final identityInviteService = inviteService;
  final identityCredentials = userCredentials;
  // The HTTP redemption endpoint derived from the advertised RPC URL
  // (ws(s)://host:port/rpc → http(s)://host:port/invites/redeem). Empty when
  // the host advertises no reachable URL — the client then composes the link
  // from its own connection endpoint.
  final inviteRedeemUrl = _redeemUrlFrom(pairingServerUrl);

  RepoOp fullClientOnly(RepoOp op) => RepoOp(
    name: op.name,
    kind: op.kind,
    handler: op.handler,
    version: op.version,
    requiredArgs: op.requiredArgs,
    workspaceScoped: op.workspaceScoped,
    requiredCapability: SessionCapability.fullClient,
    minRole: op.minRole,
    repoAccess: op.repoAccess,
    repoArg: op.repoArg,
  );

  Future<void> assertPipelineStepRunOwned(
    String workspaceId,
    String stepRunId,
  ) async {
    final stepRun = await pipelineRunRepository.getStepRunById(
      workspaceId,
      stepRunId,
    );
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

  /// Refuses a caller who is not the operator of this INSTALL.
  ///
  /// Server-scoped ops cannot rely on `minRole`: `RepoOpDispatcher` evaluates
  /// the role gate only when `op.workspaceScoped` is true, so a `minRole` on a
  /// global op reads as protection in the source and enforces nothing. Every
  /// paired device would be able to write install-wide settings — including
  /// the sandbox posture and the argv agents launch with.
  ///
  /// The operator is the recorded server owner. A catalog built without
  /// identity wiring (bare tests) has no owner to compare against and skips the
  /// check, matching how the other hand-rolled guards here behave.
  void requireServerAdmin(RepoOpContext ctx) {
    if (serverOwnerUserId == null) {
      return;
    }
    if (ctx.userId != serverOwnerUserId) {
      throw const AuthException(
        'This setting affects every workspace on this server and can only be '
        'changed by its operator.',
      );
    }
  }

  // Per-repo grant chokepoint: workspace membership must never silently
  // out-privilege the forge, so every code-bearing surface resolves the
  // caller's grant on the repo it exposes. Owners/admins hold every grant
  // implicitly; a catalog built without identity wiring (bare tests) skips
  // the check. Denies loudly, never silently.
  Future<void> requireRepoReadGrant({
    required String workspaceId,
    required String userId,
    required String repoId,
  }) async {
    final members = identityMembers;
    if (members == null) {
      return;
    }
    final member = await members.getMember(workspaceId, userId);
    if (member == null) {
      throw const AuthException('Not a member of this workspace');
    }
    if (member.role.isAdmin) {
      return;
    }
    final grants = await members.getRepoGrants(workspaceId, userId);
    if (!(grants[repoId] ?? RepoGrantLevel.none).allowsRead) {
      throw const AuthException('No read access to this repo');
    }
  }

  // Secret exclusion: a per-workspace glob list (`.env`, `id_rsa`, `.npmrc`,
  // etc., from [SecretExclusionPolicy.defaultGlobs] + per-workspace overrides)
  // hard-blocks matching paths from guest/viewer visibility on code-bearing
  // surfaces.
  //
  // SCOPE — these globs are enforced ONLY for viewer/guest (read-only) roles.
  // A `member` (or `admin`) with a repo grant CAN read secret files: this is
  // by design because they hold write access to the repo anyway. If a
  // consulting / multi-client setup needs to protect secrets from `member`
  // seats, that requires a policy change — not the current design.
  //
  // Identity-less catalogs skip the check (return null).
  Future<SecretExclusionPolicy?> secretPolicyForReadOnlyCaller(
    String workspaceId,
    String userId,
  ) async {
    final members = identityMembers;
    if (members == null) {
      return null;
    }
    final member = await members.getMember(workspaceId, userId);
    if (member == null || !member.role.isReadOnly) {
      return null;
    }
    final workspaces = await workspaceRepository.watchAll().first;
    final workspace = workspaces.where((w) => w.id == workspaceId).firstOrNull;
    return SecretExclusionPolicy([
      ...SecretExclusionPolicy.defaultGlobs,
      ...?workspace?.secretExcludeGlobs,
    ]);
  }

  Future<void> assertPathNotSecretExcluded(
    RepoOpContext ctx,
    String path,
  ) async {
    final policy = await secretPolicyForReadOnlyCaller(
      ctx.workspaceId!,
      ctx.userId,
    );
    if (policy != null && policy.isExcluded(path)) {
      throw const AuthException('This path is excluded for your role');
    }
  }

  // Fan-out code search sweeps EVERY linked repo, so a partial grant cannot
  // be honored without per-hit filtering — fail closed instead: non-admin
  // callers need a read grant on every linked repo to use the fan-out
  // surface (per-repo surfaces remain available for granted repos).
  Future<void> requireAllRepoReadGrants({
    required String workspaceId,
    required String userId,
  }) async {
    final members = identityMembers;
    if (members == null) {
      return;
    }
    final member = await members.getMember(workspaceId, userId);
    if (member == null) {
      throw const AuthException('Not a member of this workspace');
    }
    if (member.role.isAdmin) {
      return;
    }
    final grants = await members.getRepoGrants(workspaceId, userId);
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    for (final repo in linked) {
      if (!(grants[repo.id] ?? RepoGrantLevel.none).allowsRead) {
        throw const AuthException(
          'Workspace-wide code search requires read access to every linked '
          'repo',
        );
      }
    }
  }

  // Validates that `(owner, repo)` is a GitHub repo linked to the bound
  // workspace before a client-supplied owner/repo is used in a server-side gh
  // fetch — so a thin client can only drive reads against repos its workspace
  // owns (workspace-isolation invariant) — AND that the calling [userId]
  // holds a read grant on it (membership ≠ code access). Denies loudly on a
  // foreign or ungranted repo.
  Future<void> requireWorkspaceGitHubRepo(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
  }) async {
    final repos = await linkedGitHubRepos(workspaceId);
    Repo? match;
    for (final r in repos) {
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
    await requireRepoReadGrant(
      workspaceId: workspaceId,
      userId: userId,
      repoId: match.id,
    );
  }

  Future<PrReviewRepository> resolvePrReviewRepository(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
  }) async {
    if (vcsProviderFactory == null) {
      return const EmptyPrReviewRepository();
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
    // The grant gate runs BEFORE the cache: the cached repository instance is
    // shared across members, but access is re-checked per call.
    await requireRepoReadGrant(
      workspaceId: workspaceId,
      userId: userId,
      repoId: match.id,
    );
    final key = '$workspaceId|${owner.toLowerCase()}|${repo.toLowerCase()}';
    final existing = prRepoCache[key];
    if (existing != null) {
      return existing;
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
    final dbs = workspaceDbs;
    if (dbs == null) {
      return fetch();
    }
    final cache = dbs.of(workspaceId).cacheDao;

    // Wrap the cached preview in a timestamped envelope so the background
    // revalidation fires only when the value has aged past this TTL — NOT on
    // every hit. The old code re-fetched from GitHub on every cache hit; a
    // burst of preview lookups (many `#`-reference chips re-rendering, or a
    // re-subscribe storm) then fired one GitHub call PER hit and flooded the
    // API. Within the TTL a burst collapses to at most one background fetch.
    // A title/state/draft/merged chip does not need sub-minute freshness.
    const revalidateTtl = Duration(seconds: 60);

    Future<void> writeFresh(Map<String, dynamic> value) => cache.put(
      workspaceId,
      kind,
      key,
      jsonEncode({
        '__swr_ts': DateTime.now().toIso8601String(),
        '__swr_val': value,
      }),
    );

    final cached = await cache.read(workspaceId, kind, key);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          // Unwrap the envelope. A legacy (un-timestamped) row has no
          // `__swr_val`; treat it as immediately stale so it upgrades on the
          // next write.
          final wrapped = decoded.containsKey('__swr_val');
          final rawValue = wrapped ? decoded['__swr_val'] : decoded;
          final tsRaw = decoded['__swr_ts'];
          final ts = tsRaw is String ? DateTime.tryParse(tsRaw) : null;
          final isStale =
              ts == null || DateTime.now().difference(ts) >= revalidateTtl;
          if (isStale) {
            // Background revalidation; ignore failures (keep the cached value).
            unawaited(
              fetch()
                  .then((fresh) async {
                    if (fresh != null) {
                      await writeFresh(fresh);
                    }
                  })
                  .catchError((_) {}),
            );
          }
          if (rawValue is Map) {
            return rawValue.cast<String, dynamic>();
          }
        }
      } catch (_) {
        // Bad payload — treat as a miss and fetch fresh below.
      }
    }
    final fresh = await fetch();
    if (fresh != null) {
      await writeFresh(fresh);
    }
    return fresh;
  }

  // Promote the optional server-host ports to final locals so the collection-if
  // guards below flow the non-null type into the ops' closures.
  final inspector = gitRepoInspector;
  final adapters = adapterDetection;
  final harnessCreds = harnessCredentialStore;
  final oauthBroker = harnessOAuthBroker;
  final acp = acpModels;
  final providerPolicy = providerPolicyRepository;
  final ghCli = githubCli;
  final sandboxDetect = sandboxDetector;
  final processes = processDetection;
  final launcher = editorLauncher;
  final convChanges = conversationChanges;
  final cacheRepo = cacheRepository;
  final repoCh = repoChanges;
  final repoChGrouped = repoChangesGrouped;
  final repoStageFn = repoStage;
  final repoUnstageFn = repoUnstage;
  final repoFileC = repoFileContent;
  final repoFileS = repoFileSearch;
  final repoContentS = repoContentSearch;
  final worktreeContentS = worktreeContentSearch;
  final worktreeFileS = worktreeFileSearch;
  final worktreeWrite = worktreeWriteFile;
  final worktreeRevert = worktreeRevertFiles;
  final worktreeRead = worktreeReadFile;
  final worktreeCommit = worktreeCommitAndPush;
  final worktreePublish = worktreePublishBranch;
  final mcp = mcpControl;
  final mcpClient = mcpClientControl;
  final embeddingModel = embeddingModelControl;
  final diarizationModel = diarizationModelControl;
  final voiceModel = voiceModelControl;
  final terminals = terminalSessions;
  final vscode = codeServer;
  final fs = workspaceFilesystem;
  final dispatch = messagingDispatch;
  final pipeline = pipelineEngine;
  final approveOrch = approveOrchestration;
  final cancelOrch = cancelOrchestration;
  final reviewDispatcher = reviewDispatch;
  final revisionsRepo = orchestrationRevisionRepository;
  final plansRepo = planDocumentRepository;
  final playbooksRepo = playbookRepository;
  final workProductsRepo = workProductRepository;
  final saveRevision = saveOrchestrationRevision;
  final approveScoped = approveOrchestrationScoped;
  final approveNodes = approveOrchestrationNodes;
  final divergenceMarkers = planDivergenceMarkers;
  final continueNode = continuePlanNode;
  final estimateOrch = estimateOrchestration;
  final estimatePlan = estimatePlanDocument;
  final approvePlan = approvePlanDocument;
  final playbookRun = runPlaybook;

  final ops = RepoOpRegistry([
    // ---- Server maintenance: on-demand database backup (fullClient-only) ----
    // Writes a consistent snapshot of every database (VACUUM INTO per file) and
    // returns the snapshot DIRECTORY's path. NOT workspace-scoped — it captures
    // the whole install — and fullClient-only so a companion phone can never
    // trigger it. Absent when no backup port is wired (default-deny).
    if (databaseBackup != null)
      RepoOp(
        name: 'server.backupNow',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final path = await databaseBackup.backupNow();
          return {'ok': true, 'path': path};
        },
      ),
    // Exports ONE workspace as a single file. Workspace-scoped (the operator
    // exports the workspace they are in) and fullClient-only: the file contains
    // that workspace's entire history, so handing out its path is an operator
    // action, not something a companion phone does.
    if (databaseBackup != null)
      RepoOp(
        name: 'workspace.export',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.admin,
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final path = await databaseBackup.exportWorkspace(ctx.workspaceId!);
          return {'ok': true, 'path': path};
        },
      ),
    // Adopts a previously exported file as this workspace's database, REPLACING
    // whatever is there. Destructive and irreversible for the target workspace,
    // so it is owner-only on top of fullClient. The file is validated as a
    // workspace database before anything is replaced.
    if (databaseBackup != null)
      RepoOp(
        name: 'workspace.import',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.owner,
        requiredCapability: SessionCapability.fullClient,
        requiredArgs: ['source_path'],
        handler: (ctx) async {
          final id = await databaseBackup.importWorkspace(
            workspaceId: ctx.workspaceId!,
            sourcePath: ctx.args['source_path'] as String,
          );
          return {'ok': true, 'workspace_id': id};
        },
      ),
    // ---- Connectivity (PRD 15) ----
    // `connection.ping` is the resolver's health probe on the LIVE session
    // (any path, incl. the relay, where an out-of-band /healthz GET can't
    // reach). Unscoped and capability-free: every authenticated session may
    // check its own liveness. Returns the server time so the pill can show
    // round-trip latency.
    RepoOp(
      name: 'connection.ping',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => {'t': DateTime.now().toIso8601String()},
    ),
    // `connection.describe` re-publishes the server's CURRENT descriptor over
    // any live path, so clients keep their stored copy fresh as tunnel URLs
    // rotate and LAN addresses move (PRD 15 clarification: the descriptor is
    // a set of paths; the fingerprint, not any address, is the identity).
    if (descriptorService != null)
      RepoOp(
        name: 'connection.describe',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => {
          'descriptor': (await descriptorService.describe()).toJson(),
        },
      ),
    // ---- Sharing & network state (PRD 15 §5) ----
    // `connectivity.status` shows the share/tunnel/mDNS/relay state (incl.
    // relay bytes this month — TURN-style relaying costs the operator real
    // bandwidth). `connectivity.setTunnel` is the EXPLICIT public-exposure
    // opt-in: server-owner only, persisted so a restart resumes sharing.
    if (networkRuntime != null) ...[
      RepoOp(
        name: 'connectivity.status',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final runtime = networkRuntime();
          if (runtime == null) {
            throw const NotFoundException('Network runtime is not available');
          }
          return runtime.status();
        },
      ),
      RepoOp(
        name: 'connectivity.setTunnel',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          final runtime = networkRuntime();
          if (runtime == null) {
            throw const NotFoundException('Network runtime is not available');
          }
          if (serverOwnerUserId != null && ctx.userId != serverOwnerUserId) {
            throw const AuthException(
              'Only the server owner can change how this server is shared.',
            );
          }
          final provider = ctx.args['provider'];
          const allowed = {'off', 'cloudflared', 'ngrok', 'tailscale'};
          if (provider is! String || !allowed.contains(provider)) {
            throw ValidationException(
              'provider must be one of ${allowed.join(', ')}',
            );
          }
          return runtime.setTunnelProvider(provider);
        },
      ),
    ],
    // ---- Deterministic sync (PRD 16 §6) ----
    // `sync.pull` is the gap-fill for the `sync.watch` delta stream: a
    // client whose frame contiguity broke pulls `(from_seq, now]`; a
    // `snapshot_required` answer (range pruned) drops that store back to
    // snapshot mode — the kill-switch path, exercised automatically.
    if (syncFeed != null)
      RepoOp(
        name: 'sync.pull',
        kind: RepoOpKind.read,
        requiredArgs: ['store', 'from_seq'],
        handler: (ctx) async {
          final store = ctx.args['store'];
          final fromSeq = ctx.args['from_seq'];
          if (store is! String || fromSeq is! int) {
            throw const ValidationException(
              'store must be a string, from_seq an int',
            );
          }
          return syncFeed.pull(ctx.workspaceId!, store, fromSeq);
        },
      ),
    // Per-column LWW field edits (PRD 16 §6): concurrent edits to DIFFERENT
    // ticket fields both land in server receipt order — neither clobbers the
    // other, and no client clock is consulted. Workflow/status transitions
    // deliberately stay on the optimistic-locked `tickets.update` path.
    if (workspaceDbs != null)
      RepoOp(
        name: 'tickets.patch',
        kind: RepoOpKind.mutate,
        // Reversible: the prior field values are captured client-side and
        // re-applied by the inverse patch.
        undoClass: UndoClass.reversible,
        requiredArgs: ['ticket_id', 'fields'],
        handler: (ctx) async {
          final ticketId = ctx.args['ticket_id'];
          final fields = ctx.args['fields'];
          if (ticketId is! String || fields is! Map) {
            throw const ValidationException(
              'ticket_id must be a string, fields an object',
            );
          }
          var companion = const TicketsTableCompanion();
          const allowed = {'title', 'description', 'priority', 'labels'};
          for (final key in fields.keys) {
            if (!allowed.contains(key)) {
              throw ValidationException(
                'field "$key" is not patchable (allowed: ${allowed.join(', ')})',
              );
            }
          }
          if (fields.containsKey('title')) {
            final v = fields['title'];
            if (v is! String || v.trim().isEmpty) {
              throw const ValidationException(
                'title must be a non-empty string',
              );
            }
            companion = companion.copyWith(title: Value(v));
          }
          if (fields.containsKey('description')) {
            final v = fields['description'];
            if (v != null && v is! String) {
              throw const ValidationException(
                'description must be a string or null',
              );
            }
            companion = companion.copyWith(description: Value(v as String?));
          }
          if (fields.containsKey('priority')) {
            final v = fields['priority'];
            if (v is! int) {
              throw const ValidationException('priority must be an int');
            }
            companion = companion.copyWith(priority: Value(v));
          }
          if (fields.containsKey('labels')) {
            final v = fields['labels'];
            if (v is! List) {
              throw const ValidationException(
                'labels must be a list of strings',
              );
            }
            companion = companion.copyWith(
              labels: Value(jsonEncode(v.map((e) => '$e').toList())),
            );
          }
          final matched = await workspaceDbs
              .of(ctx.workspaceId!)
              .ticketDao
              .patchFields(ctx.workspaceId!, ticketId, companion);
          if (matched == 0) {
            // Scoped write: a foreign ticket is simply not found — never a
            // silent cross-workspace edit.
            throw const NotFoundException('Ticket not found');
          }
          final updated = await ticketRepository.getById(
            ctx.workspaceId!,
            ticketId,
          );
          return {'ticket': updated == null ? null : ticketToWire(updated)};
        },
      ),
    // ---- Channel notes + reactions (PRD 16 §11/§15) ----
    if (workspaceDbs != null) ...[
      RepoOp(
        name: 'notes.get',
        kind: RepoOpKind.read,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final note = await workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .noteForChannel(ctx.workspaceId!, channelId);
          return {'note': note == null ? null : channelNoteToWire(note)};
        },
      ),
      // The shared handoff doc: authoritative LWW in server receipt order
      // (no expected version — the whole doc is one column; soft-claims on
      // the presence lane make concurrent editing VISIBLE instead of locked).
      RepoOp(
        name: 'notes.update',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'content'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          final content = ctx.args['content'];
          if (content is! String) {
            throw const ValidationException('content must be a string');
          }
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final row = await workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .upsertNote(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                channelId: channelId,
                contentMarkdown: content,
                updatedByPrincipal: ctx.principal.wire,
              );
          return {'note': channelNoteToWire(row)};
        },
      ),
      RepoOp(
        name: 'reactions.toggle',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'message_id', 'emoji'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          final messageId = ctx.args['message_id'] as String;
          final emoji = ctx.args['emoji'];
          if (emoji is! String || emoji.isEmpty || emoji.length > 16) {
            throw const ValidationException('emoji must be a short string');
          }
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final message = await messagingRepository.getMessageById(
            ctx.workspaceId!,
            messageId,
          );
          if (message == null || message.channelId != channelId) {
            throw const NotFoundException('Message not found in this channel');
          }
          final added = await workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .toggleReaction(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                channelId: channelId,
                messageId: messageId,
                principalId: ctx.userId,
                principalType: 'user',
                emoji: emoji,
              );
          return {'added': added};
        },
      ),
    ],
    // ---- Presence lane (PRD 16 §1) ----
    // `presence.update` applies the calling USER's own ephemeral presence —
    // identity comes from the session (never client args), the payload is a
    // compact awareness delta, and nothing is persisted or audited (a
    // cursor-cadence update must not flood `user_activity`; `read`-class
    // keeps it off the audit path while membership is still enforced).
    if (presenceHub != null)
      RepoOp(
        name: 'presence.update',
        kind: RepoOpKind.read,
        requiredArgs: ['presence'],
        handler: (ctx) async {
          final update = ctx.args['presence'];
          if (update is! Map) {
            throw const ValidationException('presence must be an object');
          }
          String displayName = ctx.userId;
          if (userRepository != null) {
            final cached = _presenceNameCache[ctx.userId];
            if (cached != null) {
              displayName = cached;
            } else {
              final user = await userRepository.getById(ctx.userId);
              displayName = user?.displayName ?? ctx.userId;
              _presenceNameCache[ctx.userId] = displayName;
            }
          }
          presenceHub.publishHuman(
            workspaceId: ctx.workspaceId!,
            userId: ctx.userId,
            displayName: displayName,
            update: update.cast<String, dynamic>(),
          );
          return const {'ok': true};
        },
      ),
    // ---- Take-over / hand-back (PRD 16 §8) ----
    if (takeoverService != null) ...[
      RepoOp(
        name: 'takeover.begin',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          String displayName = ctx.userId;
          if (userRepository != null) {
            displayName =
                (await userRepository.getById(ctx.userId))?.displayName ??
                ctx.userId;
          }
          final marker = await takeoverService.begin(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
            userId: ctx.userId,
            displayName: displayName,
          );
          return {'takeover': marker};
        },
      ),
      RepoOp(
        name: 'takeover.handBack',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          String displayName = ctx.userId;
          if (userRepository != null) {
            displayName =
                (await userRepository.getById(ctx.userId))?.displayName ??
                ctx.userId;
          }
          return takeoverService.handBack(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
            userId: ctx.userId,
            displayName: displayName,
            note: ctx.args['note'] as String? ?? '',
          );
        },
      ),
      RepoOp(
        name: 'takeover.status',
        kind: RepoOpKind.read,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          return {
            'takeover': await takeoverService.status(
              ctx.workspaceId!,
              channelId,
            ),
          };
        },
      ),
    ],
    // ---- Per-channel agent autonomy dial (PRD 16 §12) ----
    if (workspaceDbs != null)
      RepoOp(
        name: 'autonomy.setForChannel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'agent_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          final agentId = ctx.args['agent_id'] as String;
          final level = ctx.args['level'];
          const allowed = {'proposeOnly', 'actWithApproval', 'actFreely'};
          if (level != null && (level is! String || !allowed.contains(level))) {
            throw ValidationException(
              'level must be one of ${allowed.join(', ')} or null',
            );
          }
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .setAutonomy(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                channelId: channelId,
                agentId: agentId,
                autonomyLevel: level as String?,
              );
          return {'ok': true};
        },
      ),
    // ---- Checker role (PRD 16 §13) ----
    if (workspaceDbs != null) ...[
      RepoOp(
        name: 'checker.setForChannel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          final agentId = ctx.args['agent_id'];
          await assertChannelOwned(ctx.workspaceId!, channelId);
          if (agentId is String && agentId.isNotEmpty) {
            await workspaceDbs
                .of(ctx.workspaceId!)
                .cacheDao
                .put(
                  ctx.workspaceId!,
                  CheckerDispatchListener.cacheKind,
                  channelId,
                  jsonEncode({'agent_id': agentId}),
                );
          } else {
            await workspaceDbs
                .of(ctx.workspaceId!)
                .cacheDao
                .deleteEntry(
                  ctx.workspaceId!,
                  CheckerDispatchListener.cacheKind,
                  channelId,
                );
          }
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'checker.get',
        kind: RepoOpKind.read,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final raw = await workspaceDbs
              .of(ctx.workspaceId!)
              .cacheDao
              .read(
                ctx.workspaceId!,
                CheckerDispatchListener.cacheKind,
                channelId,
              );
          if (raw == null) {
            return {'agent_id': null};
          }
          try {
            final decoded = jsonDecode(raw);
            return {'agent_id': decoded is Map ? decoded['agent_id'] : null};
          } catch (_) {
            return {'agent_id': null};
          }
        },
      ),
    ],
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
        final expiresAt = RemotePairingLifecycle.credentialExpiry(
          DateTime.now(),
        );
        await pairedDeviceDao.upsert(
          PairedDevicesTableCompanion(
            id: Value(deviceId),
            // The minted device authenticates as the CALLER's user — pairing
            // your own extra device never mints someone else's credential.
            // (New collaborators get theirs through invite redemption.)
            userId: Value(ctx.userId),
            workspaceId: Value(workspaceId),
            label: Value(ctx.args['label'] as String),
            platform: Value(platform),
            pskRef: const Value('file'),
            status: const Value(PairedDeviceStatus.active),
            expiresAt: Value(expiresAt),
          ),
        );
        await pairedDeviceSecretsPort.writePsk(deviceId, psk);
        // A client that can't reach the server directly rendezvous in the
        // server's N-way relay room. The server's RemoteRelayHost watches
        // this table, so inserting the `active` device above is what admits
        // it to the room — the QR carries the full connection descriptor
        // (every path + the identity fingerprint) plus the credential.
        final descriptor = await descriptorService?.describe();
        return {
          'device_id': deviceId,
          // The PSK is returned ONCE, here, so the client can build the pairing
          // QR/link; it is never read back over RPC afterwards.
          'psk': psk,
          'workspace_id': workspaceId,
          'workspace_name': ?names[workspaceId],
          'server_url': pairingServerUrl,
          // Relay rendezvous: the broker URL + the SERVER's relay room
          // (invite-gated; admission is derived from the device PSK).
          'signaling_url': relaySignalingUrl,
          'room': descriptorService?.identity.relayRoom ?? '',
          if (descriptor != null) 'descriptor': descriptor.toJson(),
          'platform': platform,
          'expires_at': expiresAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };
      },
    ),
    // CROSS-WORKSPACE BY DESIGN: paired devices are global (a device spans
    // every workspace) — but the registry is PER USER: everyone lists their
    // own devices; only the server owner sees the whole fleet.
    RepoOp(
      name: 'pairing.list',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final isOwner = ctx.userId == serverOwnerUserId;
        final devices = isOwner
            ? await pairedDeviceDao.getAll()
            : await pairedDeviceDao.getForUser(ctx.userId);
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
    // CROSS-WORKSPACE BY DESIGN: rename targets a global device by id — the
    // caller's own device, or any device when the caller is the server owner.
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
        if (existing.userId != ctx.userId && ctx.userId != serverOwnerUserId) {
          throw const AuthException('Device belongs to a different user');
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
    // CROSS-WORKSPACE BY DESIGN: revoke targets a global device by id — the
    // caller's own device, or any device when the caller is the server owner.
    // Revocation is LIVE: the server's device watcher drops the revoked
    // device's open sessions within seconds, not on next reconnect.
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
        if (existing.userId != ctx.userId && ctx.userId != serverOwnerUserId) {
          throw const AuthException('Device belongs to a different user');
        }
        // Delete the PSK FIRST so a mid-failure leaves the device unable to
        // authenticate (fail closed) rather than orphaning a live credential.
        await pairedDeviceSecretsPort.deletePsk(deviceId);
        await pairedDeviceDao.remove(deviceId);
        if (existing.userId != null) {
          eventBus?.publish(
            UserDeviceRevoked(
              deviceId: deviceId,
              userId: existing.userId!,
              occurredAt: DateTime.now(),
            ),
          );
        }
        return {'ok': true};
      },
    ),

    // ---- Identity & membership (multi-user access) ----
    //
    // Users are global identities; membership (role), invites, per-repo
    // grants, and the audit trail are workspace-scoped. Reads are open to any
    // member (the role floor for reads is viewer); member/invite/grant
    // mutations are explicitly admin-gated via `minRole`. Preferences are
    // user-scoped: a session only ever reaches its OWN rows (`ctx.userId`,
    // never a client arg).
    if (identityUsers != null &&
        identityMembers != null &&
        identityInvites != null &&
        identityActivity != null &&
        identityPrefs != null &&
        identityInviteService != null) ...[
      // Who am I: the session's resolved user + their memberships. Global by
      // nature (identity spans workspaces).
      RepoOp(
        name: 'identity.me',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final user = await identityUsers.getById(ctx.userId);
          if (user == null) {
            throw const NotFoundException('User not found');
          }
          final memberships = await identityMembers.getForUser(ctx.userId);
          return {
            'user': userToWire(user),
            'device_id': ctx.deviceId,
            'is_server_owner': ctx.userId == serverOwnerUserId,
            'memberships': memberships.map(workspaceMemberToWire).toList(),
          };
        },
      ),
      // Users visible to the caller: themselves + everyone they share a
      // workspace with (the server owner sees all). CROSS-WORKSPACE BY
      // DESIGN — identity is global; visibility is bounded by co-membership.
      RepoOp(
        name: 'users.list',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final all = await identityUsers.getAll();
          if (ctx.userId == serverOwnerUserId) {
            return {'users': all.map(userToWire).toList()};
          }
          final visible = <String>{ctx.userId};
          for (final membership in await identityMembers.getForUser(
            ctx.userId,
          )) {
            final coMembers = await identityMembers.getForWorkspace(
              membership.workspaceId,
            );
            visible.addAll(coMembers.map((m) => m.userId));
          }
          return {
            'users': [
              for (final u in all)
                if (visible.contains(u.id)) userToWire(u),
            ],
          };
        },
      ),
      // Edit your OWN profile (display name, email, avatar, git identity).
      // The target is always `ctx.userId` — no principal can edit another.
      RepoOp(
        name: 'users.updateProfile',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          final user = await identityUsers.getById(ctx.userId);
          if (user == null) {
            throw const NotFoundException('User not found');
          }
          String? optional(String key) {
            final value = ctx.args[key];
            return value is String && value.isNotEmpty ? value : null;
          }

          final displayName = optional('display_name');
          final updated = user.copyWith(
            displayName: displayName,
            email: optional('email'),
            avatarRef: optional('avatar_ref'),
            gitAuthorName: optional('git_author_name'),
            gitAuthorEmail: optional('git_author_email'),
          );
          await identityUsers.upsert(updated);
          return {'user': userToWire(updated)};
        },
      ),
      // Per-user GitHub credentials. Strictly self-service: the target is
      // always `ctx.userId` — no principal can set or probe another member's
      // token. Write-only: the stored value is NEVER returned (only a
      // configured flag), and it is never logged. User-scoped like `prefs.*`,
      // so the ops are global (`workspaceScoped: false`).
      if (identityCredentials != null) ...[
        // Stores the CALLER's own GitHub token; an empty/absent `token`
        // deletes it (the member reverts to the server's broker credential).
        RepoOp(
          name: 'credentials.setGitHubToken',
          kind: RepoOpKind.mutate,
          workspaceScoped: false,
          handler: (ctx) async {
            final token = ctx.args['token'];
            await identityCredentials.setGitHubToken(
              ctx.userId,
              token is String ? token : '',
            );
            return {'ok': true};
          },
        ),
        // Whether the CALLER has a token configured. Presence only — the
        // value itself never crosses the wire.
        RepoOp(
          name: 'credentials.gitHubTokenStatus',
          kind: RepoOpKind.read,
          workspaceScoped: false,
          handler: (ctx) async => {
            'configured': await identityCredentials.hasGitHubToken(ctx.userId),
          },
        ),
      ],
      // Members of the bound workspace (any member may see the roster).
      RepoOp(
        name: 'members.listForWorkspace',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final members = await identityMembers.getForWorkspace(
            ctx.workspaceId!,
          );
          return {'members': members.map(workspaceMemberToWire).toList()};
        },
      ),
      // Change a member's role. Admin-gated; ownership is transferred
      // explicitly (never via this op), so the owner's row is immutable here
      // and `owner` is not grantable.
      RepoOp(
        name: 'members.setRole',
        kind: RepoOpKind.mutate,
        requiredArgs: ['user_id', 'role'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          final role = WorkspaceRole.fromWire(ctx.args['role'] as String?);
          if (role == null || role == WorkspaceRole.owner) {
            throw const ValidationException('Invalid role');
          }
          final target = await identityMembers.getMember(
            workspaceId,
            targetUserId,
          );
          if (target == null) {
            throw const NotFoundException('Member not found');
          }
          if (target.role == WorkspaceRole.owner) {
            throw const AuthException(
              'The workspace owner\'s role cannot be changed',
            );
          }
          await identityMembers.setRole(workspaceId, targetUserId, role);
          eventBus?.publish(
            WorkspaceMemberRoleChanged(
              workspaceId: workspaceId,
              userId: targetUserId,
              role: role,
              occurredAt: DateTime.now(),
            ),
          );
          return {'ok': true};
        },
      ),
      // Remove a member (their repo grants go with them). Admin-gated; the
      // owner cannot be removed. Denial of further access is immediate: the
      // role gate re-resolves membership on every op.
      RepoOp(
        name: 'members.remove',
        kind: RepoOpKind.mutate,
        requiredArgs: ['user_id'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          final target = await identityMembers.getMember(
            workspaceId,
            targetUserId,
          );
          if (target == null) {
            throw const NotFoundException('Member not found');
          }
          if (target.role == WorkspaceRole.owner) {
            throw const AuthException('The workspace owner cannot be removed');
          }
          await identityMembers.remove(workspaceId, targetUserId);
          eventBus?.publish(
            WorkspaceMemberRemoved(
              workspaceId: workspaceId,
              userId: targetUserId,
              occurredAt: DateTime.now(),
            ),
          );
          return {'ok': true};
        },
      ),
      // A member's per-repo grants (admins read anyone's; members their own).
      RepoOp(
        name: 'members.getRepoGrants',
        kind: RepoOpKind.read,
        requiredArgs: ['user_id'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          if (targetUserId != ctx.userId && !(ctx.role?.isAdmin ?? false)) {
            throw const AuthException(
              'Only admins may read another member\'s repo grants',
            );
          }
          final grants = await identityMembers.getRepoGrants(
            workspaceId,
            targetUserId,
          );
          return {
            'grants': {for (final e in grants.entries) e.key: e.value.wireName},
          };
        },
      ),
      // Set a member's grant on one linked repo. Admin-gated; the repo must
      // actually be linked to the workspace (no grants on foreign repos).
      RepoOp(
        name: 'members.setRepoGrant',
        kind: RepoOpKind.mutate,
        requiredArgs: ['user_id', 'repo_id', 'level'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          final repoId = ctx.args['repo_id'] as String;
          final level = RepoGrantLevel.fromWire(ctx.args['level'] as String?);
          if (level == null) {
            throw const ValidationException('Invalid grant level');
          }
          final linked = await workspaceRepository.isRepoLinkedToWorkspace(
            workspaceId,
            repoId,
          );
          if (!linked) {
            throw const WorkspaceMismatchException(
              'Repo is not linked to this workspace',
            );
          }
          final target = await identityMembers.getMember(
            workspaceId,
            targetUserId,
          );
          if (target == null) {
            throw const NotFoundException('Member not found');
          }
          await identityMembers.setRepoGrant(
            workspaceId,
            targetUserId,
            repoId,
            level,
          );
          return {'ok': true};
        },
      ),
      // Mint a single-use, expiring invite. Admin-gated. The one-time code is
      // returned exactly ONCE here (only its hash is stored); the invite row
      // enumerates exactly which repos are shared and at what level, so
      // membership never silently out-privileges the forge.
      RepoOp(
        name: 'invites.create',
        kind: RepoOpKind.mutate,
        requiredArgs: ['role'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final role = WorkspaceRole.fromWire(ctx.args['role'] as String?);
          if (role == null || role == WorkspaceRole.owner) {
            throw const ValidationException('Invalid role');
          }
          final rawGrants = ctx.args['repo_grants'];
          final repoGrants = <String, RepoGrantLevel>{};
          if (rawGrants is Map) {
            for (final entry in rawGrants.entries) {
              final level = RepoGrantLevel.fromWire(entry.value as String?);
              final repoId = entry.key;
              if (level == null || repoId is! String) {
                throw const ValidationException('Invalid repo grant');
              }
              final linked = await workspaceRepository.isRepoLinkedToWorkspace(
                workspaceId,
                repoId,
              );
              if (!linked) {
                throw const WorkspaceMismatchException(
                  'Repo is not linked to this workspace',
                );
              }
              repoGrants[repoId] = level;
            }
          }
          final ttlHours = (ctx.args['ttl_hours'] as num?)?.toInt();
          final created = await identityInviteService.create(
            workspaceId: workspaceId,
            createdBy: ctx.userId,
            role: role,
            repoGrants: repoGrants,
            ttl: ttlHours != null && ttlHours > 0
                ? Duration(hours: ttlHours)
                : WorkspaceInviteService.defaultTtl,
          );
          // Derive the redeem URL from the LIVE descriptor (tunnel/LAN/wss)
          // so an off-host collaborator can actually reach it — falling back
          // to the static publicUrl only when no non-loopback path exists.
          final descriptor = await descriptorService?.describe();
          final liveRedeemUrl =
              _bestRedeemUrlFromDescriptor(descriptor) ?? inviteRedeemUrl;
          return {
            'invite': workspaceInviteToWire(created.invite),
            // Shown once; never persisted or re-derivable.
            'code': created.code,
            'redeem_url': liveRedeemUrl,
            // The full descriptor lets the client embed every path (incl.
            // relay) in the invite QR/link, so the resolver can find a way
            // in even when the redeem URL alone is unreachable.
            if (descriptor != null) 'descriptor': descriptor.toJson(),
          };
        },
      ),
      // Open/used/revoked invites of the workspace (metadata only).
      RepoOp(
        name: 'invites.list',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final invites = await identityInvites.getForWorkspace(
            ctx.workspaceId!,
          );
          return {'invites': invites.map(workspaceInviteToWire).toList()};
        },
      ),
      RepoOp(
        name: 'invites.revoke',
        kind: RepoOpKind.mutate,
        requiredArgs: ['invite_id'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          await identityInviteService.revoke(
            ctx.workspaceId!,
            ctx.args['invite_id'] as String,
          );
          return {'ok': true};
        },
      ),
      // The caller's OWN preferences (theme, fonts, keybindings…) — the same
      // set on every device the user signs in from. Never another user's.
      RepoOp(
        name: 'prefs.getAll',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final prefs = await identityPrefs.getAll(ctx.userId);
          return {'prefs': prefs};
        },
      ),
      RepoOp(
        name: 'prefs.set',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['key'],
        handler: (ctx) async {
          await identityPrefs.set(
            ctx.userId,
            ctx.args['key'] as String,
            ctx.args['value'] as String?,
          );
          return {'ok': true};
        },
      ),
      // The workspace audit trail: who did what (any member may read it —
      // accountability is a feature, not a secret).
      RepoOp(
        name: 'activity.listForWorkspace',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final limit = (ctx.args['limit'] as num?)?.toInt() ?? 200;
          final entries = await identityActivity.getForWorkspace(
            ctx.workspaceId!,
            limit: limit.clamp(1, 1000),
          );
          return {'entries': entries.map(userActivityToWire).toList()};
        },
      ),
    ],

    // ---- Approval routing (per-workspace; N humans must not collide on
    // approval gates) ----
    if (approvalRouting != null) ...[
      RepoOp(
        name: 'approvals.getRoutingPolicy',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final policy = await approvalRouting.policyFor(ctx.workspaceId!);
          return {'policy': policy.toJson()};
        },
      ),
      RepoOp(
        name: 'approvals.setRoutingPolicy',
        kind: RepoOpKind.mutate,
        requiredArgs: ['mode'],
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final mode = ApprovalRoutingMode.fromWire(
            ctx.args['mode'] as String?,
          );
          if (mode == null) {
            throw const ValidationException('Invalid routing mode');
          }
          final minutes =
              (ctx.args['escalation_timeout_minutes'] as num?)?.toInt() ?? 60;
          if (minutes < 1) {
            throw const ValidationException('Invalid escalation timeout');
          }
          final policy = ApprovalRoutingPolicy(
            mode: mode,
            escalationTimeout: Duration(minutes: minutes),
          );
          await approvalRouting.setPolicy(ctx.workspaceId!, policy);
          return {'policy': policy.toJson()};
        },
      ),
    ],

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
          ctx.workspaceId!,
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
      // Reversible: re-assigning to the prior assignee restores the state.
      undoClass: UndoClass.reversible,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async {
        final id = ctx.args['ticket_id'] as String;
        await ticketWorkflow.assign(
          id,
          workspaceId: ctx.workspaceId!,
          assigneeId:
              ctx.args['assignee_id'] as String? ??
              ctx.args['agent_id'] as String?,
          assigneeType:
              PrincipalType.fromWire(ctx.args['assignee_type'] as String?) ??
              PrincipalType.agent,
          teamId: ctx.args['team_id'] as String?,
        );
        final ticket = await ticketRepository.getById(ctx.workspaceId!, id);
        return {'ticket': ticket == null ? null : ticketToWire(ticket)};
      },
    ),
    RepoOp(
      name: 'tickets.insert',
      kind: RepoOpKind.mutate,
      // Compensable: no true inverse, but the created ticket can be deleted
      // (tickets.delete) to reverse the intent.
      undoClass: UndoClass.compensable,
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
      // Reversible: the prior field values are captured client-side and
      // re-applied by the inverse op (an update back to the old ticket).
      undoClass: UndoClass.reversible,
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
        final existing = await ticketRepository.getById(
          ctx.workspaceId!,
          ticket.id,
        );
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
    // §188: user-triggered "sync now" for the sync health card. Pulls + applies
    // the latest vendor changes for the bound workspace's enabled pull-capable
    // configs (optionally one `vendor`). Workspace-scoped via ctx.workspaceId.
    if (ticketSyncNow != null)
      RepoOp(
        name: 'ticket_sync.syncNow',
        kind: RepoOpKind.mutate,
        // Irreversible: pushes/pulls changes to an external vendor (Linear /
        // Jira / GitHub). No inverse — never in the undo stack.
        undoClass: UndoClass.irreversible,
        handler: (ctx) async {
          final vendor = ctx.args['vendor'];
          final summary = await ticketSyncNow(
            workspaceId: ctx.workspaceId!,
            vendor: vendor is String && vendor.isNotEmpty ? vendor : null,
          );
          return {
            'created': summary.created,
            'updated': summary.updated,
            'skipped': summary.skipped,
            'deduplicated': summary.deduplicated,
            'failed': summary.failed,
          };
        },
      ),
    RepoOp(
      name: 'tickets.addCollaborator',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'ticket_id', 'principal_id', 'joined_at'],
      handler: (ctx) async {
        final ticketId = ctx.args['ticket_id'] as String;
        await _assertTicketInWorkspace(
          ticketRepository,
          ticketId,
          ctx.workspaceId!,
        );
        await ticketRepository.addCollaborator(
          ctx.workspaceId!,
          collaboratorFromWire(ctx.args.cast<String, dynamic>()),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'tickets.removeCollaborator',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket_id', 'principal_id'],
      handler: (ctx) async {
        final ticketId = ctx.args['ticket_id'] as String;
        await _assertTicketInWorkspace(
          ticketRepository,
          ticketId,
          ctx.workspaceId!,
        );
        await ticketRepository.removeCollaborator(
          ctx.workspaceId!,
          ticketId,
          ctx.args['principal_id'] as String,
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
          ctx.workspaceId!,
        );
        final list = await ticketRepository.getCollaborators(
          ctx.workspaceId!,
          ticketId,
        );
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
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
        final agent = await agentRepository.getById(ctx.workspaceId!, id);
        if (agent != null && agent.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent belongs to a different workspace',
          );
        }
        await agentRepository.delete(ctx.workspaceId!, id);
        return {'ok': true};
      },
    ),

    // ---- Repos (global — declared workspace exemption) ----
    RepoOp(
      name: 'repos.get',
      kind: RepoOpKind.read,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final repo = await repoRepository.getById(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        if (repo == null) {
          throw const NotFoundException('Repo not found');
        }
        return {'repo': repoToWire(repo)};
      },
    ),
    // Repo identity ACROSS workspaces is by path, not id (each workspace mints
    // its own id for a checkout), so this is how a caller asks "is this
    // checkout already here?".
    RepoOp(
      name: 'repos.findByPath',
      kind: RepoOpKind.read,
      requiredArgs: ['path'],
      handler: (ctx) async {
        final repo = await repoRepository.findByPath(
          ctx.workspaceId!,
          ctx.args['path'] as String,
        );
        return {'repo': repo == null ? null : repoToWire(repo)};
      },
    ),
    RepoOp(
      name: 'repos.exists',
      kind: RepoOpKind.read,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final exists = await repoRepository.exists(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        return {'exists': exists};
      },
    ),
    RepoOp(
      name: 'repos.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo'],
      handler: (ctx) async {
        final id = await repoRepository.upsert(
          ctx.workspaceId!,
          repoFromWire((ctx.args['repo'] as Map).cast<String, dynamic>()),
        );
        return {'repo_id': id};
      },
    ),
    RepoOp(
      name: 'repos.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        await repoRepository.delete(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // Drag-to-reorder: persists the manual order every repo list reads back.
    RepoOp(
      name: 'repos.reorder',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_ids'],
      handler: (ctx) async {
        await repoRepository.reorder(
          ctx.workspaceId!,
          (ctx.args['repo_ids'] as List).map((e) => e.toString()).toList(),
        );
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
    if (adapters != null)
      ...[
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
    // Resolves the PR's channel worktree (creating + provisioning it if needed)
    // and opens it in the chosen editor on the host's display. Returns the
    // server-side worktree path (opaque to the client).
    if (launcher != null && ensurePrWorktree != null)
      RepoOp(
        name: 'ide.openPrInEditor',
        kind: RepoOpKind.mutate,
        requiredArgs: [
          'repo_full_name',
          'pr_number',
          'pr_node_id',
          'editor_id',
        ],
        handler: (ctx) async {
          final path = await ensurePrWorktree(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prNodeId: ctx.args['pr_node_id'] as String,
            title: ctx.args['title'] as String? ?? '',
            repoId: ctx.args['repo_id'] as String?,
          );
          await launcher.openDirectory(
            editorId: ctx.args['editor_id'] as String,
            directoryPath: path,
          );
          return {'path': path};
        },
      ),
    // Resolves the PR's channel worktree (creating + provisioning it if needed)
    // and returns its absolute path WITHOUT launching an editor — a GUI-attached
    // client (the native desktop app) launches the path in a LOCAL editor itself.
    // This is the SAME worktree the in-app workbench edits; there is no separate
    // `pr_worktrees/` checkout. Served even by a headless host.
    if (ensurePrWorktree != null)
      RepoOp(
        name: 'ide.ensureWorktree',
        kind: RepoOpKind.mutate,
        requiredArgs: ['repo_full_name', 'pr_number', 'pr_node_id'],
        handler: (ctx) async {
          final path = await ensurePrWorktree(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prNodeId: ctx.args['pr_node_id'] as String,
            title: ctx.args['title'] as String? ?? '',
            repoId: ctx.args['repo_id'] as String?,
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
    // ---- Generic workspace-scoped cache (IDE editor-layout persistence) ----
    //
    // The messaging IDE layout is persisted per conversation in the SERVER-owned
    // `cache` table, so a layout saved on one client (desktop) is restored on
    // another (web). Both ops are workspace-scoped (the `workspaceId` filter is
    // the isolation boundary). Absent on a host that owns no database.
    if (cacheRepo != null) ...[
      RepoOp(
        name: 'cache.read',
        kind: RepoOpKind.read,
        requiredArgs: ['kind', 'key'],
        handler: (ctx) async {
          final payload = await cacheRepo.read(
            ctx.workspaceId!,
            ctx.args['kind'] as String,
            ctx.args['key'] as String,
          );
          return {'payload': payload};
        },
      ),
      RepoOp(
        name: 'cache.write',
        kind: RepoOpKind.mutate,
        // Internal scratch store — auditing it is noise, not accountability.
        audited: false,
        requiredArgs: ['kind', 'key'],
        handler: (ctx) async {
          await cacheRepo.put(
            ctx.workspaceId!,
            ctx.args['kind'] as String,
            ctx.args['key'] as String,
            (ctx.args['payload'] ?? '') as String,
          );
          return const {};
        },
      ),
    ],
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
        // Diffs expose code: the caller needs a read grant on this repo.
        repoAccess: RepoGrantLevel.read,
        handler: (ctx) async {
          // `channel_id` is optional: the IDE Source Control panel (always
          // per-conversation) supplies it so the diff runs against the
          // conversation's isolated CoW worktree — the tree agents/code-server
          // edit. Absent → the original linked-repo checkout (back-compat).
          final channelId = ctx.args['channel_id'];
          final files = await repoCh(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            channelId: channelId is String && channelId.isNotEmpty
                ? channelId
                : null,
          );
          // Secret exclusion: diffs of excluded paths are dropped entirely
          // for read-only (viewer/guest) roles — never partially redacted.
          final policy = await secretPolicyForReadOnlyCaller(
            ctx.workspaceId!,
            ctx.userId,
          );
          final visible = policy == null
              ? files
              : [
                  for (final f in files)
                    if (!policy.isExcluded(f.filename)) f,
                ];
          return {'files': visible.map(prFileToWire).toList()};
        },
      ),
    // Staged/unstaged split of a repo's changes (real git index) for the VS
    // Code-style Source Control view. Same scoping + secret-exclusion as
    // `repos.changes`.
    if (repoChGrouped != null)
      RepoOp(
        name: 'repos.changesGrouped',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'repo_id'],
        repoAccess: RepoGrantLevel.read,
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'];
          final grouped = await repoChGrouped(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            channelId: channelId is String && channelId.isNotEmpty
                ? channelId
                : null,
          );
          final policy = await secretPolicyForReadOnlyCaller(
            ctx.workspaceId!,
            ctx.userId,
          );
          List<PrFile> filter(List<PrFile> fs) => policy == null
              ? fs
              : [
                  for (final f in fs)
                    if (!policy.isExcluded(f.filename)) f,
                ];
          return {
            'staged': filter(grouped.staged).map(prFileToWire).toList(),
            'unstaged': filter(grouped.unstaged).map(prFileToWire).toList(),
          };
        },
      ),
    // Stage files into the conversation worktree's git index (`git add`). Empty
    // `paths` ⇒ stage all. Foreign channel → the fetcher no-ops (isolation
    // boundary), returning ok:false.
    if (repoStageFn != null)
      RepoOp(
        name: 'repos.stage',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id'],
        repoAccess: RepoGrantLevel.write,
        handler: (ctx) async {
          final rawPaths = ctx.args['paths'];
          final paths = <String>[
            if (rawPaths is List)
              for (final p in rawPaths)
                if (p is String && p.isNotEmpty) p,
          ];
          final ok = await repoStageFn(
            ctx.workspaceId!,
            ctx.args['channel_id'] as String,
            ctx.args['repo_id'] as String,
            paths,
          );
          return {'ok': ok};
        },
      ),
    // Unstage files from the conversation worktree's git index (`git reset
    // HEAD`) — leaves working-tree content intact. Empty `paths` ⇒ unstage all.
    if (repoUnstageFn != null)
      RepoOp(
        name: 'repos.unstage',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id'],
        repoAccess: RepoGrantLevel.write,
        handler: (ctx) async {
          final rawPaths = ctx.args['paths'];
          final paths = <String>[
            if (rawPaths is List)
              for (final p in rawPaths)
                if (p is String && p.isNotEmpty) p,
          ];
          final ok = await repoUnstageFn(
            ctx.workspaceId!,
            ctx.args['channel_id'] as String,
            ctx.args['repo_id'] as String,
            paths,
          );
          return {'ok': ok};
        },
      ),
    if (repoFileC != null)
      RepoOp(
        name: 'repos.readFile',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'repo_id', 'path'],
        // File contents expose code: read grant required, and secret-excluded
        // paths are hard-blocked for read-only (viewer/guest) roles.
        repoAccess: RepoGrantLevel.read,
        handler: (ctx) async {
          final path = ctx.args['path'] as String;
          await assertPathNotSecretExcluded(ctx, path);
          final r = await repoFileC(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            path,
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
          await requireAllRepoReadGrants(
            workspaceId: ctx.workspaceId!,
            userId: ctx.userId,
          );
          final hits = await repoFileS(
            ctx.workspaceId!,
            (ctx.args['query'] ?? '') as String,
          );
          return {'hits': hits};
        },
      ),
    if (repoContentS != null)
      RepoOp(
        name: 'repos.searchContent',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'query'],
        handler: (ctx) async {
          await requireAllRepoReadGrants(
            workspaceId: ctx.workspaceId!,
            userId: ctx.userId,
          );
          // The option map is optional and defaults to legacy (case-insensitive
          // literal) behaviour. We pass it through verbatim; the fetcher reads
          // only the keys it knows.
          final optionsArg = ctx.args['options'];
          final options = optionsArg is Map
              ? Map<String, Object?>.from(optionsArg)
              : const <String, Object?>{};
          final hits = await repoContentS(
            ctx.workspaceId!,
            (ctx.args['query'] ?? '') as String,
            options: options,
          );
          return {'hits': hits};
        },
      ),
    if (worktreeContentS != null)
      RepoOp(
        name: 'worktree.searchContent',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id', 'query'],
        handler: (ctx) async {
          // Scoped to the conversation's isolated worktree — the isolation
          // registry (workspace→channel→repo) is the access boundary, so a
          // foreign channel resolves to no worktree → empty. The option map is
          // optional (legacy case-insensitive literal defaults).
          final optionsArg = ctx.args['options'];
          final options = optionsArg is Map
              ? Map<String, Object?>.from(optionsArg)
              : const <String, Object?>{};
          final hits = await worktreeContentS(
            ctx.workspaceId!,
            ctx.args['channel_id'] as String,
            ctx.args['repo_id'] as String,
            (ctx.args['query'] ?? '') as String,
            options: options,
          );
          return {'hits': hits};
        },
      ),
    if (worktreeFileS != null)
      RepoOp(
        name: 'worktree.searchFiles',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id', 'query'],
        handler: (ctx) async {
          // Scoped to the conversation's isolated worktree — the isolation
          // registry (workspace→channel→repo) is the access boundary, so a
          // foreign channel resolves to no worktree → empty. Empty query yields
          // the full worktree file tree (fff runs SERVER-SIDE).
          final hits = await worktreeFileS(
            ctx.workspaceId!,
            ctx.args['channel_id'] as String,
            ctx.args['repo_id'] as String,
            (ctx.args['query'] ?? '') as String,
          );
          return {'hits': hits};
        },
      ),
    // ---- Conversation worktree mutate ops (workspace + channel scoped) ----
    //
    // Backing the IDE's "untitled" draft save (⌘S) and the Source Control
    // "Revert" action. Both resolve the worktree via the isolation registry
    // (the workspace→channel→repo boundary), so a foreign channel is simply not
    // found. Absent on a host that owns no conversation worktrees.
    if (worktreeWrite != null)
      RepoOp(
        name: 'worktree.writeFile',
        kind: RepoOpKind.mutate,
        requiredArgs: [
          'workspace_id',
          'channel_id',
          'repo_id',
          'path',
          'content',
        ],
        handler: (ctx) async {
          final res = await worktreeWrite(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            path: ctx.args['path'] as String,
            content: ctx.args['content'] as String,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    if (worktreeRevert != null)
      RepoOp(
        name: 'worktree.revertFiles',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id', 'paths'],
        handler: (ctx) async {
          final rawPaths = ctx.args['paths'];
          final paths = <String>[];
          if (rawPaths is List) {
            for (final p in rawPaths) {
              if (p is String && p.isNotEmpty) {
                paths.add(p);
              }
            }
          }
          final res = await worktreeRevert(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            paths: paths,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    // Re-syncs a PR channel's worktree to the latest PR head. Mutating (fetch +
    // hard checkout), but skips when the tree is dirty (never clobbers edits).
    if (syncPrWorktree != null)
      RepoOp(
        name: 'worktree.syncToPrHead',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id'],
        handler: (ctx) async {
          return syncPrWorktree(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
          );
        },
      ),
    if (worktreeRead != null)
      RepoOp(
        name: 'worktree.readFile',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id', 'path'],
        handler: (ctx) async {
          final res = await worktreeRead(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            path: ctx.args['path'] as String,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    if (worktreeCommit != null)
      RepoOp(
        name: 'worktree.commitAndPush',
        kind: RepoOpKind.mutate,
        // Human-initiated commit&push resolves the same guardrail chokepoint as
        // an agent tool: gitCommit (default allow) + gitPush (default prompt) →
        // combined prompt, fail-closed to deny with no approver connected. The
        // dispatcher reads channel_id (a required arg) for channel-scoped policy.
        actionClasses: const {ActionClass.gitCommit, ActionClass.gitPush},
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id', 'message'],
        handler: (ctx) async {
          final rawPaths = ctx.args['paths'];
          final paths = <String>[
            if (rawPaths is List)
              for (final p in rawPaths)
                if (p is String && p.isNotEmpty) p,
          ];
          final res = await worktreeCommit(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            message: ctx.args['message'] as String,
            paths: paths,
            push: ctx.args['push'] as bool? ?? true,
            amend: ctx.args['amend'] as bool? ?? false,
            sync: ctx.args['sync'] as bool? ?? false,
            pushBranch: ctx.args['push_branch'] as String?,
            authorName: ctx.args['author_name'] as String?,
            authorEmail: ctx.args['author_email'] as String?,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    if (worktreePublish != null)
      RepoOp(
        name: 'worktree.publishBranch',
        kind: RepoOpKind.mutate,
        // A push and nothing else, so it declares gitPush alone (default:
        // prompt, fail-closed to deny with no approver connected). It never
        // commits, so gitCommit would be a false declaration — and the ratchet
        // test treats the declared set as the truth about what an op can do.
        actionClasses: const {ActionClass.gitPush},
        requiredArgs: ['workspace_id', 'channel_id', 'repo_id'],
        handler: (ctx) async {
          final res = await worktreePublish(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            branchOverride: ctx.args['branch'] as String?,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
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
          return {
            'servers': [for (final s in servers) s.toJson()],
          };
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
    if (terminals != null)
      ...[
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
          // Layout noise — fires on every pane resize, not an accountability event.
          audited: false,
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

    // ---- Code-server (VS Code in the browser) over RPC (WORKSPACE-SCOPED) ---
    //
    // code-server runs on the SERVER host — loopback-bound, opening the
    // conversation's isolated CoW worktree — and the client reaches it through
    // the authenticated `/proxy/vscode/<sid>/` reverse proxy. `open` mints a
    // high-entropy capability bound to the caller's `(workspaceId, deviceId)`
    // and returns the app-relative proxy URL (or a loopback URL for a
    // loopback-local desktop/Linux external open). The worktree is resolved
    // strictly from the caller's workspace; a foreign id → no worktree → no
    // session (never a raw-checkout fallback). Sessions are workspace-scoped:
    // the host validates ownership on `close`. These ops exist only when the
    // host wired a [CodeServerPort] (the headless cc_server).
    if (vscode != null)
      ...[
        RepoOp(
          name: 'codeServer.open',
          kind: RepoOpKind.mutate,
          requiredArgs: ['channel_id'],
          handler: (ctx) async {
            final session = await vscode.ensureSession(
              workspaceId: ctx.workspaceId!,
              channelId: ctx.args['channel_id'] as String,
              repoId: ctx.args['repo_id'] as String? ?? '',
              deviceId: ctx.deviceId,
              path: ctx.args['path'] as String?,
              // The client pushes its editor auto-save preference on every open;
              // the service sanitises it into `files.autoSave`. Default when the
              // client omits it (older clients) is the port's own default.
              autoSave: ctx.args['auto_save'] as String? ?? 'afterDelay',
            );
            final base = ctx.args['base_url'] as String?;
            // code-server web opens the folder (and any deep-linked file) from the
            // URL query — NOT from the CLI positional, which it ignores when the
            // workbench is reached at the proxy root. Build `?folder=<worktree>`
            // (+ a best-effort `payload=[["openFile", …]]` for the clicked file)
            // so the worktree tree + the file editor open on load. Without this the
            // editor comes up on an empty window. The file path is confined to the
            // worktree (a `..` escape is dropped, folder still opens).
            final lineArg = ctx.args['line'];
            final query = _codeServerOpenQuery(
              session.folderPath,
              ctx.args['path'] as String?,
              line: lineArg is num ? lineArg.toInt() : null,
            );
            // App-relative proxy URL by default (works on every tier). A
            // loopback-local desktop/Linux may pass base_url to get a direct
            // `http://127.0.0.1:<port>/` URL for an external-browser open.
            final url = base == null || base.isEmpty
                ? '/proxy/vscode/${session.sessionId}/$query'
                : '$base/proxy/vscode/${session.sessionId}/$query';
            return {
              'session_id': session.sessionId,
              'url': url,
              'port': session.port,
              'status': session.status.name,
              'direct_url': 'http://127.0.0.1:${session.port}/$query',
            };
          },
        ),
        RepoOp(
          name: 'codeServer.close',
          kind: RepoOpKind.mutate,
          requiredArgs: ['session_id'],
          handler: (ctx) async {
            await vscode.closeSession(
              workspaceId: ctx.workspaceId!,
              sessionId: ctx.args['session_id'] as String,
            );
            return const {};
          },
        ),
        // Save a dirty worktree-relative file to disk by asking the embedded
        // editor (the only holder of the unsaved buffer) via the reverse command
        // channel. Backs the app's "Save" tab-close choice. Returns
        // `{saved: bool}` — false when no running session / the save timed out.
        RepoOp(
          name: 'codeServer.saveFile',
          kind: RepoOpKind.mutate,
          requiredArgs: ['channel_id', 'path'],
          handler: (ctx) async {
            final saved = await vscode.saveFile(
              workspaceId: ctx.workspaceId!,
              channelId: ctx.args['channel_id'] as String,
              repoId: ctx.args['repo_id'] as String? ?? '',
              path: ctx.args['path'] as String,
            );
            return {'saved': saved};
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
    if (fs != null)
      ...[
        RepoOp(
          name: 'fs.workspaceDir',
          kind: RepoOpKind.read,
          handler: (ctx) async => {
            'path': await fs.workspaceDir(ctx.workspaceId!),
          },
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
          handler: (ctx) async => {
            'path': await fs.skillsDir(ctx.workspaceId!),
          },
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
          handler: (ctx) async => {
            'path': await fs.agentsDir(ctx.workspaceId!),
          },
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
            // No-op (kept for wire-compat): the agent-dir `.mcp.json` symlink was
            // removed when MCP config consolidation moved the derived config into
            // the per-agent overlay cwd (written by cc_server's
            // `ServerMcpControl` at dispatch). The op stays registered so older
            // clients don't hit an "unknown method" error; it now does nothing.
            return {'ok': true};
          },
        ),
        RepoOp(
          name: 'fs.writeAgentFile',
          kind: RepoOpKind.mutate,
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileDelete},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileDelete},
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
        RepoOp(
          name: 'fs.persistLogoBytes',
          kind: RepoOpKind.mutate,
          requiredArgs: ['bytes', 'extension'],
          handler: (ctx) async => {
            'path': await fs.persistLogoBytes(
              ctx.workspaceId!,
              base64Decode(ctx.args['bytes'] as String),
              ctx.args['extension'] as String,
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
        final messages = await messagingRepository.getMessages(
          ctx.workspaceId!,
          channelId,
        );
        return {'messages': messages.map(messageToWire).toList()};
      },
    ),
    RepoOp(
      name: 'messaging.searchInChannel',
      kind: RepoOpKind.read,
      requiredArgs: ['channel_id', 'query'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        final limit = ctx.args['limit'];
        final messages = await messagingRepository.searchInChannel(
          ctx.workspaceId!,
          channelId,
          ctx.args['query'] as String,
          limit: limit is int ? limit : 50,
        );
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
        // principal — a client-supplied `sender_id` is ignored so a device
        // can't attribute a message to an arbitrary user/agent. Human messages
        // are authored as the session's USER (not its device: three devices,
        // one author). The desktop's own in-process client (same trust
        // boundary) may post non-user system messages (e.g. "hired X"
        // notices), so the richer fields are honored ONLY when explicitly
        // supplied; absent ⇒ the secure user default.
        final senderType = ctx.args['sender_type'] as String? ?? 'user';
        final senderId = senderType == 'user'
            ? ctx.userId
            : (ctx.args['sender_id'] as String? ?? ctx.userId);
        final metadata = ctx.args['metadata'];
        final messageId = await messagingRepository.sendMessage(
          workspaceId: ctx.workspaceId!,
          channelId: channelId,
          content: ctx.args['content'] as String,
          senderId: senderId,
          senderType: senderType,
          messageType: ctx.args['message_type'] as String? ?? 'text',
          metadata: metadata is Map ? metadata.cast<String, dynamic>() : null,
          id: ctx.args['id'] as String?,
          conversationId: ctx.args['conversation_id'] as String?,
        );
        return {'message_id': messageId};
      },
    ),
    // ---- PR workbench: ensure the PR's backing channel ----
    if (ensurePrChannel != null)
      RepoOp(
        name: 'pr.ensureChannel',
        kind: RepoOpKind.mutate,
        // Idempotent ensure-on-open — auditing every PR view is noise.
        audited: false,
        requiredArgs: ['repo_full_name', 'pr_number', 'pr_node_id'],
        handler: (ctx) async {
          final result = await ensurePrChannel(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prNodeId: ctx.args['pr_node_id'] as String,
            createdByUserId: ctx.userId,
            title: ctx.args['title'] as String? ?? '',
          );
          return result;
        },
      ),
    // ---- Conversations (parallel streams / "parentheses" in a channel) ----
    if (conversationRepository != null) ...[
      RepoOp(
        name: 'conversation.ensureMain',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final conv = await conversationRepository.ensureMain(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
          );
          return {'conversation': conversationToWire(conv)};
        },
      ),
      RepoOp(
        name: 'conversation.create',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id', 'title'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final now = DateTime.now();
          final conv = await conversationRepository.create(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
            title: ctx.args['title'] as String,
            conversation: Conversation(
              id: '',
              workspaceId: ctx.workspaceId!,
              channelId: channelId,
              title: ctx.args['title'] as String,
              kind: ConversationKind.parenthesis,
              createdByPrincipalId: ctx.userId,
              createdAt: now,
              updatedAt: now,
            ),
          );
          return {'conversation': conversationToWire(conv)};
        },
      ),
      RepoOp(
        name: 'conversation.rename',
        kind: RepoOpKind.mutate,
        requiredArgs: ['conversation_id', 'title'],
        handler: (ctx) async {
          final conversationId = ctx.args['conversation_id'] as String;
          // Scope-load the conversation to assert it is in the bound workspace.
          final existing = await conversationRepository.getById(
            workspaceId: ctx.workspaceId!,
            conversationId: conversationId,
          );
          if (existing == null) {
            throw const NotFoundException('conversation not found');
          }
          await conversationRepository.rename(
            workspaceId: ctx.workspaceId!,
            conversationId: conversationId,
            title: ctx.args['title'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'conversation.archive',
        kind: RepoOpKind.mutate,
        requiredArgs: ['conversation_id'],
        handler: (ctx) async {
          final conversationId = ctx.args['conversation_id'] as String;
          final existing = await conversationRepository.getById(
            workspaceId: ctx.workspaceId!,
            conversationId: conversationId,
          );
          if (existing == null) {
            throw const NotFoundException('conversation not found');
          }
          final reopen = ctx.args['reopen'] == true;
          await conversationRepository.setStatus(
            workspaceId: ctx.workspaceId!,
            conversationId: conversationId,
            status: reopen
                ? ConversationStatus.active
                : ConversationStatus.archived,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'conversation.list',
        kind: RepoOpKind.read,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final list = await conversationRepository.listForChannel(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
          );
          return {'conversations': list.map(conversationToWire).toList()};
        },
      ),
    ],
    RepoOp(
      name: 'messaging.getMessageById',
      kind: RepoOpKind.read,
      requiredArgs: ['message_id'],
      handler: (ctx) async {
        final message = await messagingRepository.getMessageById(
          ctx.workspaceId!,
          ctx.args['message_id'] as String,
        );
        if (message == null) {
          return {'message': null};
        }
        // Messages are keyed by id alone — validate the owning channel is in the
        // bound workspace so a foreign message can't leak (isolation invariant).
        await assertChannelOwned(ctx.workspaceId!, message.channelId);
        final wire = messageToWire(message);
        // Per-viewer trace redaction (PRD 16): transcript bodies never cross
        // a repo grant the viewer lacks.
        if (await viewerTraceRestricted(
          ctx.workspaceId!,
          message.channelId,
          ctx.userId,
        )) {
          final metadata = wire['metadata'];
          if (metadata is Map && metadata['segments'] is List) {
            metadata['segments'] = [
              for (final seg in metadata['segments'] as List)
                if (seg is Map) redactSegmentJson(seg.cast<String, dynamic>()),
            ];
          }
        }
        return {'message': wire};
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
          channelId,
          Mode.fromDbValue(ctx.args['mode'] as String),
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
          ctx.workspaceId!,
          channelId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.updateMessage',
      kind: RepoOpKind.mutate,
      // Reversible: the prior message text is captured client-side and the
      // inverse re-applies it.
      undoClass: UndoClass.reversible,
      requiredArgs: ['message_id'],
      handler: (ctx) async {
        final messageId = ctx.args['message_id'] as String;
        // Messages are keyed by id alone — load + validate the owning channel
        // is in the bound workspace before mutating (isolation invariant).
        final existing = await messagingRepository.getMessageById(
          ctx.workspaceId!,
          messageId,
        );
        if (existing == null) {
          throw const NotFoundException('Message not found');
        }
        await assertChannelOwned(ctx.workspaceId!, existing.channelId);
        // Authorship gate: another member's words are not yours to rewrite.
        // Content edits to a human-authored message are limited to its author
        // (admins included, for moderation); metadata-only updates (feedback,
        // plan status) stay open to any member.
        if (ctx.args['content'] != null &&
            existing.isUser &&
            existing.senderId != ctx.userId &&
            !(ctx.role?.isAdmin ?? true)) {
          throw const AuthException('Only the author can edit this message');
        }
        final metadata = ctx.args['metadata'];
        await messagingRepository.updateMessage(
          ctx.workspaceId!,
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
    // wraps. This keeps the thin/web client's "new channel / clear /
    // remove participant" actions working with or without a wired dispatch
    // engine (previously these lived under `dispatch.*` and 404'd on a headless
    // server). Behaviour matches the old ops (which only delegated to the repo);
    // `deleteChannel` additionally re-publishes [ChannelDeleted] so worktree
    // GC still fires. Every op sources `ctx.workspaceId!` (never a client arg)
    // and asserts channel ownership (isolation invariant).
    RepoOp(
      name: 'messaging.createChannel',
      kind: RepoOpKind.mutate,
      requiredArgs: ['name', 'agent_ids'],
      handler: (ctx) async {
        final channel = await messagingRepository.createChannel(
          ctx.workspaceId!,
          ctx.args['name'] as String,
          (ctx.args['agent_ids'] as List).cast<String>(),
          mode: Mode.fromDbValue(ctx.args['mode'] as String? ?? 'chat'),
          pipelineRunId: ctx.args['pipeline_run_id'] as String?,
          // The creating human joins as a first-class participant (their own
          // read cursor); identity comes from the session, never from args.
          createdByUserId: ctx.userId,
          // Optional per-channel repo selection; empty → all workspace repos.
          repoIds: (ctx.args['repo_ids'] as List?)?.cast<String>() ?? const [],
        );
        // Mirror MessagingService.createChannel: the repo insert does NOT
        // publish, and channels are born `provisioning` — without this event
        // the background provisioner never runs and the channel sits behind
        // the "preparing workspace" gate forever (composer sends stay parked).
        eventBus?.publish(
          ChannelCreated(
            channelId: channel.id,
            workspaceId: channel.workspaceId,
            occurredAt: DateTime.now(),
          ),
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
        await messagingRepository.deleteChannel(ctx.workspaceId!, channelId);
        // Mirror MessagingService.deleteChannel: let listeners (e.g. worktree
        // GC) tear down per-conversation resources.
        eventBus?.publish(
          ChannelDeleted(channelId: channelId, occurredAt: DateTime.now()),
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
        await messagingRepository.clearChannelMessages(
          ctx.workspaceId!,
          channelId,
        );
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
          ctx.workspaceId!,
          channelId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // Revert a conversation to a checkpoint (undo) — hides every message after
    // [message_id] (kept for unrevert) and, when the host wired
    // [conversationRevert] (it owns the conversation's CoW worktree + per-turn
    // git snapshots), rolls the worktree filesystem back to that turn's state.
    // DB-backed + ALWAYS available; the filesystem rollback is additive. The
    // reverted rows simply drop out of the `messaging.watch*` streams, so a
    // subscribed client's transcript updates reactively.
    RepoOp(
      name: 'messaging.revertConversationTo',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id', 'message_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        final messageId = ctx.args['message_id'] as String;
        final inclusive = ctx.args['inclusive'] as bool? ?? false;
        // Prefer the host closure (transcript + worktree filesystem rollback);
        // fall back to a transcript-only revert where no closure is wired.
        if (conversationRevert != null) {
          final outcome = await conversationRevert(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
            messageId: messageId,
            inclusive: inclusive,
          );
          return {
            'affected_message_ids': outcome.affectedMessageIds,
            'filesystem_restored': outcome.filesystemRestored,
          };
        }
        final affected = await messagingRepository.revertConversationTo(
          ctx.workspaceId!,
          channelId,
          messageId,
          inclusive: inclusive,
        );
        return {'affected_message_ids': affected, 'filesystem_restored': false};
      },
    ),
    // Undo the most-recent revert (redo) — restores the latest reverted batch
    // (those messages reappear in the `messaging.watch*` streams). Conversation
    // only: the filesystem is not re-applied (the user re-runs the agent to
    // regenerate changes). DB-backed + ALWAYS available.
    RepoOp(
      name: 'messaging.unrevertConversation',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id'],
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        final affected = conversationUnrevert != null
            ? await conversationUnrevert(
                workspaceId: ctx.workspaceId!,
                channelId: channelId,
              )
            : await messagingRepository.unrevertConversation(
                ctx.workspaceId!,
                channelId,
              );
        return {'affected_message_ids': affected};
      },
    ),
    if (retryChannelProvisioning != null)
      RepoOp(
        name: 'messaging.retryChannelProvisioning',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          await retryChannelProvisioning(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
          );
          return {'ok': true};
        },
      ),

    // ---- Messaging dispatch (agent-run execution; SERVER-SIDE, conditional) ----
    //
    // Sending-and-dispatching, retrying, refining a plan, etc. actually EXECUTE
    // an agent run on the host (sandbox), so they exist
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
            ctx.workspaceId!,
            channelId,
            ctx.args['content'] as String,
            // Authored by the session's user (identity, never client args).
            senderUserId: ctx.userId,
            conversationId: ctx.args['conversation_id'] as String?,
            metadata: metadata is Map ? metadata.cast<String, dynamic>() : null,
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
            ctx.workspaceId!,
            channelId,
            ctx.args['agent_id'] as String,
            renameForGroup: ctx.args['rename_for_group'] != false,
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
            ctx.workspaceId!,
            channelId,
            ctx.args['content'] as String,
            // Authored by the session's user (identity, never client args).
            senderUserId: ctx.userId,
            conversationId: ctx.args['conversation_id'] as String?,
            structuredMentions: _structuredMentionsFromWire(
              ctx.args['structured_mentions'],
            ),
            entityRefs: _entityRefsFromWire(ctx.args['entity_refs']),
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
            workspaceId: ctx.workspaceId!,
            ticketId: ctx.args['ticket_id'] as String?,
            pipelineRunId: ctx.args['pipeline_run_id'] as String?,
            pipelineStepId: ctx.args['pipeline_step_id'] as String?,
            inReplyToAgentId: ctx.args['in_reply_to_agent_id'] as String?,
            // The run executes on behalf of the session's user (identity,
            // never a client arg): drives the commit co-author trailer and
            // per-user credential selection.
            requestedByUserId: ctx.userId,
            wakeContext: _wakeContextFromWire(ctx.args['wake_context']),
            conversationId: ctx.args['conversation_id'] as String?,
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
            workspaceId: ctx.workspaceId!,
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
            // The session's workspace, never a client arg. Without it the
            // retried run log carries no workspace, which hides it from the
            // composer's stop affordance and makes the ownership check on
            // `dispatch.stopRun` reject it — an unstoppable run.
            workspaceId: ctx.workspaceId!,
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
          final log = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (log == null || log.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Run belongs to a different workspace.',
            );
          }
          await dispatch.stopRun(ctx.workspaceId!, runId);
          return {'ok': true};
        },
      ),
      // Pause/resume a running built-in-harness agent at its next clean turn
      // boundary (PRD 16 §8 primitive, surfaced as a per-run control). Ownership
      // is asserted via the run log's workspace (an id alone never proves
      // ownership — isolation invariant). `paused`/`resumed` is false when the
      // run has no live pausable dispatch (finished, or an external-CLI
      // transport with no safe boundary — the client falls back to stop).
      RepoOp(
        name: 'dispatch.pauseRun',
        kind: RepoOpKind.mutate,
        requiredArgs: ['run_id'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          final log = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (log == null || log.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Run belongs to a different workspace.',
            );
          }
          final paused = await dispatch.pauseRun(runId);
          return {'paused': paused};
        },
      ),
      RepoOp(
        name: 'dispatch.resumeRun',
        kind: RepoOpKind.mutate,
        requiredArgs: ['run_id'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          final log = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (log == null || log.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Run belongs to a different workspace.',
            );
          }
          final resumed = await dispatch.resumeRun(runId);
          return {'resumed': resumed};
        },
      ),
      // Mid-run steering: nudge a running built-in-harness agent without a new
      // dispatch. Ownership is asserted via the run log's workspace (an id alone
      // never proves ownership — isolation invariant). `delivered` is false when
      // the run has no live dispatch (already finished, or an external-CLI
      // transport with no steering channel).
      RepoOp(
        name: 'dispatch.steer',
        kind: RepoOpKind.mutate,
        requiredArgs: ['run_id', 'message'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          final message = ctx.args['message'] as String;
          final followUp = ctx.args['follow_up'] == true;
          final log = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (log == null || log.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Run belongs to a different workspace.',
            );
          }
          final delivered = await dispatch.steerRun(
            runId,
            message,
            followUp: followUp,
          );
          return {'delivered': delivered};
        },
      ),
      // `/compact`: force an anchored-compaction pass over the conversation so
      // it can continue within the model's context window. The user's command
      // never lands in the transcript (the client intercepts it like `/todo`),
      // and the service refuses while a turn is streaming (the prune pass
      // would race the live transcript writes) or when nothing is old enough
      // to fold — both surface as a `status` the client narrates.
      RepoOp(
        name: 'dispatch.compact',
        kind: RepoOpKind.mutate,
        requiredArgs: ['channel_id'],
        handler: (ctx) async {
          final channelId = ctx.args['channel_id'] as String;
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final result = await dispatch.compactConversation(
            workspaceId: ctx.workspaceId!,
            channelId: channelId,
            conversationId: ctx.args['conversation_id'] as String?,
          );
          return {
            'status': result.status.name,
            'compacted_count': result.compactedMessageCount,
          };
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
          final conversationId = ctx.args['conversation_id'];
          await reviewDispatcher(
            workspaceId: ctx.workspaceId!,
            agentId: ctx.args['agent_id'] as String,
            prompt: ctx.args['prompt'] as String,
            channelId: channelId,
            conversationId: conversationId is String ? conversationId : null,
            // Stamped from the session identity, never a client arg.
            requestedByUserId: ctx.userId,
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
    // channel_id + the session's user, so one member opening a channel never
    // clears another member's unread indicator) ----
    RepoOp(
      name: 'channel_read.markChannelRead',
      kind: RepoOpKind.mutate,
      requiredArgs: ['channel_id'],
      // Reading a channel is not a workspace mutation; viewers/guests keep
      // their own cursors too.
      minRole: WorkspaceRole.guest,
      handler: (ctx) async {
        final channelId = ctx.args['channel_id'] as String;
        await assertChannelOwned(ctx.workspaceId!, channelId);
        await channelReadRepository.markChannelRead(
          ctx.workspaceId!,
          channelId,
          ctx.userId,
        );
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
        return {'domain': domain == null ? null : memoryDomainToWire(domain)};
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

    // ---- Provider governance policy (PRD 05; workspace-scoped) ----
    // Allow/deny statements the model catalog's finalize consults to drop
    // denied providers. Declared only when the host wired a policy repository.
    if (providerPolicy != null)
      RepoOp(
        name: 'provider_policy.listForWorkspace',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final policies = await providerPolicy.listForWorkspace(
            ctx.workspaceId!,
          );
          return {'policies': policies.map(providerPolicyToWire).toList()};
        },
      ),
    if (providerPolicy != null)
      RepoOp(
        name: 'provider_policy.upsert',
        kind: RepoOpKind.mutate,
        requiredArgs: ['policy'],
        handler: (ctx) async {
          final w = (ctx.args['policy'] as Map).cast<String, dynamic>();
          final id = w['id'] as String;
          final statement = PolicyStatement(
            action: w['action'] as String? ?? 'provider.use',
            resource: w['resource'] as String? ?? '*',
            effect: PolicyEffect.fromRaw(w['effect'] as String?),
            layer:
                PolicyLayer.values.asNameMap()[w['layer']] ??
                PolicyLayer.workspace,
          );
          // The row is written into the bound session workspace — a client
          // can't seed a policy into a foreign workspace (isolation invariant).
          await providerPolicy.upsert(ctx.workspaceId!, id, statement);
          return {'ok': true};
        },
      ),
    if (providerPolicy != null)
      RepoOp(
        name: 'provider_policy.delete',
        kind: RepoOpKind.mutate,
        requiredArgs: ['id'],
        handler: (ctx) async {
          // Scoped delete: the repository filters by workspaceId, so one
          // workspace can never delete another's statement.
          await providerPolicy.delete(
            ctx.workspaceId!,
            ctx.args['id'] as String,
          );
          return {'ok': true};
        },
      ),

    // ---- Workspace settings store ----
    // The workspace-scoped mirror of `prefs.*`: an opaque key/value space for
    // configuration two members of a workspace must agree on (branch naming,
    // agent/model defaults, default sandbox capabilities, data-sharing policy).
    // Previously these lived in device-local preferences, so two members — or
    // one member on two machines — disagreed about workspace policy.
    //
    // Reads sit at `member` rather than the derived `guest` floor because the
    // set describes the workspace's security posture. Writes carry an EXPLICIT
    // admin floor: `kind: mutate` alone would derive `member`, and any member
    // could then rewrite policy for everyone.
    if (workspaceSettingsRepository != null)
      RepoOp(
        name: 'workspace_settings.getAll',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.member,
        handler: (ctx) async => {
          'settings': await workspaceSettingsRepository.getAll(
            ctx.workspaceId!,
          ),
        },
      ),
    if (workspaceSettingsRepository != null)
      RepoOp(
        name: 'workspace_settings.set',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['key'],
        handler: (ctx) async {
          // Always the SESSION workspace — a client can never seed a setting
          // into a foreign workspace (isolation invariant).
          await workspaceSettingsRepository.set(
            ctx.workspaceId!,
            ctx.args['key'] as String,
            ctx.args['value'] as String?,
          );
          return {'ok': true};
        },
      ),

    // ---- Install-wide settings store ----
    // The scope above a workspace: what any process on this HOST may do
    // (sandbox posture, per-adapter launch argv/env). Not workspace-scoped
    // because one host serves every workspace — a per-workspace waiver of a
    // host bound is a host-wide waiver in practice.
    //
    // NOTE the guard. These ops are `workspaceScoped: false`, and the
    // dispatcher only evaluates `minRole` for workspace-scoped ops — so a
    // declared role floor here would be silently ignored. The check has to be
    // in the handler.
    if (serverSettingsRepository != null)
      RepoOp(
        name: 'server_settings.getAll',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async => {
          'settings': await serverSettingsRepository.getAll(),
        },
      ),
    if (serverSettingsRepository != null)
      RepoOp(
        name: 'server_settings.set',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        requiredArgs: ['key'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await serverSettingsRepository.set(
            ctx.args['key'] as String,
            ctx.args['value'] as String?,
          );
          return {'ok': true};
        },
      ),

    // ---- Action guardrails policy store (PRD 24 §4) ----
    // The agent-permissions matrix reads/writes rules here; the resolver runs
    // client-side against the watched set. upsert/delete are security config →
    // admin floor. All rows are forced into the session workspace.
    if (actionPolicyRepository != null)
      RepoOp(
        name: 'action_policy.list',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final rules = await actionPolicyRepository.rules(ctx.workspaceId!);
          return {
            'rules': [
              for (final r in rules) ActionPolicyRuleDto.fromEntity(r).toJson(),
            ],
          };
        },
      ),
    if (actionPolicyRepository != null)
      RepoOp(
        name: 'action_policy.upsert',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['rule'],
        handler: (ctx) async {
          final w = (ctx.args['rule'] as Map).cast<String, dynamic>();
          // Force the row into the bound session workspace — a client can never
          // seed a rule into a foreign workspace (isolation invariant).
          final rule = ActionPolicyRuleDto.fromJson(
            w,
          ).toEntity(workspaceId: ctx.workspaceId, now: DateTime.now());
          await actionPolicyRepository.upsertRule(rule);
          return {'ok': true};
        },
      ),
    if (actionPolicyRepository != null)
      RepoOp(
        name: 'action_policy.delete',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['id'],
        handler: (ctx) async {
          await actionPolicyRepository.deleteRule(
            ctx.workspaceId!,
            ctx.args['id'] as String,
          );
          return {'ok': true};
        },
      ),

    // ---- Skills registry browse/preview/install (PRD 23 §1/§3) ----
    // search/detail are genuinely global (a registry catalog is not workspace
    // data) — CROSS-WORKSPACE BY DESIGN. preview/install are workspace-scoped
    // (the scan cache + lock live per workspace) and always route through the
    // mandatory scan gate inside SkillBundleService.
    if (skillRegistry != null)
      RepoOp(
        name: 'skills.registrySearch',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['query'],
        handler: (ctx) async {
          final listings = await skillRegistry.search(
            ctx.args['query'] as String,
            limit: (ctx.args['limit'] as num?)?.toInt() ?? 25,
          );
          return {
            'results': [
              for (final l in listings)
                {
                  'slug': l.slug,
                  'name': l.name,
                  'description': l.description,
                  'author': l.author,
                  'version': l.version,
                  'install_count': l.installCount,
                  'verified_publisher': l.verifiedPublisher,
                },
            ],
          };
        },
      ),
    if (skillRegistry != null && skillBundles != null)
      RepoOp(
        name: 'skills.registryPreview',
        kind: RepoOpKind.read,
        requiredArgs: ['slug'],
        handler: (ctx) async {
          final result = await skillBundles.previewInstall(
            workspaceId: ctx.workspaceId!,
            slug: ctx.args['slug'] as String,
            version: ctx.args['version'] as String?,
          );
          return {
            'verdict': result.verdict.wire,
            'llm_reviewed': result.llmReviewed,
            'capabilities': result.manifest.labels,
            'required_action_classes': result.manifest.requiredActionClassWires,
            'findings': [for (final f in result.findings) f.toJson()],
          };
        },
      ),
    if (skillRegistry != null && skillBundles != null)
      RepoOp(
        name: 'skills.registryInstall',
        kind: RepoOpKind.mutate,
        requiredArgs: ['slug'],
        handler: (ctx) async {
          final entry = await skillBundles.installFromRegistry(
            workspaceId: ctx.workspaceId!,
            slug: ctx.args['slug'] as String,
            version: ctx.args['version'] as String?,
            allowQuarantineOverride:
                ctx.args['allow_quarantine_override'] == true,
          );
          return {
            'slug': entry.slug,
            'source': entry.source,
            'computed_hash': entry.computedHash,
            'trust_tier': entry.trustTier.wire,
            'scan_verdict': entry.scanVerdict?.wire,
            'status': 'installed',
          };
        },
      ),

    // ---- Harness providers & credentials (PRD 13) ----
    // Host-global (not workspace-scoped): LLM provider credentials live on the
    // server host, shared across workspaces. Every client manages API keys,
    // browser OAuth logins, custom providers, and the live model list over
    // these ops.
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.list',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final providers = <Map<String, dynamic>>[];
          for (final id in harnessSupportedProviderIds) {
            final meta = harnessProviderMetas[id]!;
            final cred = await harnessCreds.activeCredential(id);
            var enabled = HarnessProviderEnabled.disabled;
            String? accountLabel;
            var hasCredential = false;
            if (cred != null) {
              switch (cred.method) {
                case HarnessAuthMethod.none:
                  enabled = HarnessProviderEnabled.local;
                case HarnessAuthMethod.oauth:
                  enabled = HarnessProviderEnabled.oauth;
                  accountLabel = cred.email ?? cred.accountLabel;
                  hasCredential = true;
                case HarnessAuthMethod.apiKey:
                  final label = cred.accountLabel ?? '';
                  final fromEnv = label.startsWith('env:');
                  enabled = fromEnv
                      ? HarnessProviderEnabled.env
                      : HarnessProviderEnabled.account;
                  accountLabel = label.isEmpty ? null : label;
                  hasCredential = !fromEnv;
              }
            }
            providers.add(
              HarnessProviderInfo(
                id: id,
                displayName: meta.displayName,
                authMethods: meta.authMethods,
                enabled: enabled,
                hasCredential: hasCredential,
                accountLabel: accountLabel,
                baseUrl: cred?.baseUrl,
                generation:
                    cred?.generation ?? const ProviderGenerationDefaults(),
              ).toJson(),
            );
          }
          // User-defined custom providers (OpenAI-/Anthropic-compatible
          // endpoints). Keyed ones count as connected; keyless (public/local)
          // ones are probed so a stopped endpoint or wrong base URL shows as
          // "not connected" instead of silently listing nothing.
          for (final def in await _customProviderDefs(harnessCreds)) {
            final hasKey =
                def.method == HarnessAuthMethod.apiKey &&
                (def.apiKey?.isNotEmpty ?? false);
            var enabled = hasKey
                ? HarnessProviderEnabled.account
                : HarnessProviderEnabled.custom;
            if (!hasKey) {
              try {
                final probe = harnessProviderFactory.create(
                  providerId: def.providerId,
                  credential: def,
                );
                final served = await probe.listModels().timeout(
                  const Duration(seconds: 3),
                );
                if (served.isEmpty) {
                  enabled = HarnessProviderEnabled.disabled;
                }
              } on Object {
                enabled = HarnessProviderEnabled.disabled;
              }
            }
            providers.add(
              HarnessProviderInfo(
                id: def.providerId,
                displayName: def.displayName ?? def.providerId,
                authMethods: const [HarnessAuthMethod.apiKey],
                enabled: enabled,
                hasCredential: hasKey,
                accountLabel: def.accountLabel,
                baseUrl: def.baseUrl,
                isCustom: true,
                dialect: def.dialect,
                generation: def.generation,
              ).toJson(),
            );
          }
          return {'providers': providers};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.listModels',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final requested = ctx.args['provider_id'] as String?;
          final ids = requested != null
              ? [requested]
              : [
                  ...harnessSupportedProviderIds,
                  for (final def in await _customProviderDefs(harnessCreds))
                    def.providerId,
                ];
          final models = <Map<String, dynamic>>[];
          for (final id in ids) {
            var cred = await harnessCreds.activeCredential(id);
            // Only connected providers contribute models (a custom provider
            // always carries its definition credential — method `none` when
            // keyless). The model list is always the provider's own live
            // catalog; models.dev is used only to enrich prices/context.
            if (cred == null) {
              continue;
            }
            if (cred.method == HarnessAuthMethod.oauth && oauthBroker != null) {
              cred = await oauthBroker.refreshIfNeeded(cred);
            }
            try {
              final provider = harnessProviderFactory.create(
                providerId: id,
                credential: cred,
              );
              for (final m in await provider.listModels()) {
                models.add(
                  HarnessModelInfo(
                    id: '$id/${m.id}',
                    providerId: id,
                    displayName: m.displayName,
                    inputCostPerMTokens: m.inputCostPerMTokens,
                    outputCostPerMTokens: m.outputCostPerMTokens,
                    contextWindow: m.contextWindow,
                  ).toJson(),
                );
              }
            } on Object {
              // Endpoint unreachable — this provider contributes no models
              // until it answers again ("Sync now" retries).
            }
          }
          return {'models': models};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.saveApiKey',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id', 'api_key'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          final key = ctx.args['api_key'] as String;
          final baseUrl = ctx.args['base_url'] as String?;
          final label = ctx.args['account_label'] as String?;
          // A custom provider stores its definition (dialect, name, base URL)
          // on the same credential entry — merge instead of clobbering it. An
          // empty key here only updates the base URL, keeping any stored key.
          final def = await _customProviderDef(harnessCreds, id);
          if (def != null) {
            final mergedKey = key.isNotEmpty
                ? key
                : ((def.apiKey?.isEmpty ?? true) ? null : def.apiKey);
            await harnessCreds.remove(id);
            await harnessCreds.save(
              ProviderCredential(
                providerId: id,
                method: mergedKey == null
                    ? HarnessAuthMethod.none
                    : HarnessAuthMethod.apiKey,
                apiKey: mergedKey,
                baseUrl: baseUrl ?? def.baseUrl,
                accountLabel: label ?? def.accountLabel,
                dialect: def.dialect,
                displayName: def.displayName,
              ),
            );
            return {'ok': true};
          }
          await harnessCreds.save(
            ProviderCredential(
              providerId: id,
              method: HarnessAuthMethod.apiKey,
              apiKey: key.isEmpty ? null : key,
              baseUrl: baseUrl,
              accountLabel: label,
            ),
          );
          return {'ok': true};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.removeCredential',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          // For a custom provider "remove credential" drops only the key —
          // the provider definition survives (delete it via
          // `providers.removeCustom`).
          final def = await _customProviderDef(harnessCreds, id);
          if (def != null) {
            await harnessCreds.remove(id);
            await harnessCreds.save(
              ProviderCredential(
                providerId: id,
                method: HarnessAuthMethod.none,
                baseUrl: def.baseUrl,
                dialect: def.dialect,
                displayName: def.displayName,
              ),
            );
            return {'ok': true};
          }
          await harnessCreds.remove(
            id,
            accountLabel: ctx.args['account_label'] as String?,
          );
          return {'ok': true};
        },
      ),
    // Custom providers: any OpenAI- or Anthropic-compatible endpoint the user
    // adds (Ollama, LM Studio, vLLM, a private deployment, …), with an
    // optional API key. The definition lives in the same credential store the
    // dispatch path resolves, so a custom model id (`custom-<slug>/<model>`)
    // is immediately runnable.
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.addCustom',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['display_name', 'dialect', 'base_url'],
        handler: (ctx) async {
          final name = (ctx.args['display_name'] as String).trim();
          final dialect = CustomProviderDialect.fromWire(
            ctx.args['dialect'] as String?,
          );
          final baseUrl = (ctx.args['base_url'] as String).trim();
          final key = (ctx.args['api_key'] as String?)?.trim() ?? '';
          if (name.isEmpty) {
            throw ArgumentError('display_name must not be empty.');
          }
          if (dialect == null) {
            throw ArgumentError('dialect must be "openai" or "anthropic".');
          }
          final uri = Uri.tryParse(baseUrl);
          if (uri == null ||
              (uri.scheme != 'http' && uri.scheme != 'https') ||
              uri.host.isEmpty) {
            throw ArgumentError('base_url must be an http(s) URL.');
          }
          // Stable unique id: custom-<slug>, suffixed on collision.
          var slug = name
              .toLowerCase()
              .replaceAll(RegExp('[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'(^-+|-+$)'), '');
          if (slug.isEmpty) {
            slug = 'provider';
          }
          final taken = <String>{
            ...harnessSupportedProviderIds,
            for (final def in await _customProviderDefs(harnessCreds))
              def.providerId,
          };
          var id = 'custom-$slug';
          var n = 2;
          while (taken.contains(id)) {
            id = 'custom-$slug-${n++}';
          }
          await harnessCreds.save(
            ProviderCredential(
              providerId: id,
              method: key.isEmpty
                  ? HarnessAuthMethod.none
                  : HarnessAuthMethod.apiKey,
              apiKey: key.isEmpty ? null : key,
              baseUrl: baseUrl,
              dialect: dialect,
              displayName: name,
            ),
          );
          return {'id': id};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        name: 'providers.removeCustom',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          if (harnessProviderMetas.containsKey(id)) {
            throw ArgumentError('"$id" is a built-in provider.');
          }
          await harnessCreds.remove(id);
          return {'ok': true};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        // Per-provider sampling recipe + output ceiling. A frontier API and a
        // local quant cannot share one number: models publish their own output
        // ceilings and required sampling recipes, and serving one at other
        // values degrades it. Every field is optional, and omitting one clears
        // it back to "let the endpoint decide".
        name: 'providers.saveGenerationDefaults',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          if (!harnessProviderMetas.containsKey(id)) {
            final known = {
              for (final def in await _customProviderDefs(harnessCreds))
                def.providerId,
            };
            if (!known.contains(id)) {
              throw ArgumentError('Unknown provider "$id".');
            }
          }
          int? intArg(String key) {
            final raw = ctx.args[key];
            return raw == null ? null : (raw as num).toInt();
          }

          double? doubleArg(String key) {
            final raw = ctx.args[key];
            return raw == null ? null : (raw as num).toDouble();
          }

          final maxTokens = intArg('max_tokens');
          final temperature = doubleArg('temperature');
          final topP = doubleArg('top_p');
          final topK = intArg('top_k');
          if (maxTokens != null && maxTokens <= 0) {
            throw ArgumentError('max_tokens must be positive.');
          }
          if (temperature != null && (temperature < 0 || temperature > 2)) {
            throw ArgumentError('temperature must be in [0, 2].');
          }
          if (topP != null && (topP <= 0 || topP > 1)) {
            throw ArgumentError('top_p must be in (0, 1].');
          }
          if (topK != null && topK <= 0) {
            throw ArgumentError('top_k must be positive.');
          }
          final generation = ProviderGenerationDefaults(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            topK: topK,
          );
          // Built-ins may have no stored credential yet (env-var auth); create a
          // definition row so the setting has somewhere to live.
          final existing = await harnessCreds.activeCredential(id);
          await harnessCreds.save(
            (existing ??
                    ProviderCredential(
                      providerId: id,
                      method: HarnessAuthMethod.none,
                    ))
                .copyWith(generation: generation),
          );
          return {'ok': true, 'generation': generation.toJson()};
        },
      ),
    if (oauthBroker != null)
      RepoOp(
        name: 'providers.startOAuth',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id'],
        handler: (ctx) async {
          final start = await oauthBroker.start(
            ctx.args['provider_id'] as String,
          );
          return {
            'flow_id': start.flowId,
            'auth_url': start.authUrl,
            'manual_paste': start.supportsManualPaste,
            // Device-code logins only: the code the user confirms in the
            // browser. Absent for redirect flows.
            if (start.userCode != null) 'user_code': start.userCode,
          };
        },
      ),
    if (oauthBroker != null)
      RepoOp(
        name: 'providers.oauthStatus',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['flow_id'],
        handler: (ctx) async {
          final status = oauthBroker.status(ctx.args['flow_id'] as String);
          return {
            'status': status.state.name,
            'account': ?status.account,
            'error': ?status.error,
          };
        },
      ),
    if (oauthBroker != null)
      RepoOp(
        name: 'providers.completeOAuth',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['flow_id', 'code'],
        handler: (ctx) async {
          await oauthBroker.complete(
            ctx.args['flow_id'] as String,
            ctx.args['code'] as String,
          );
          return {'ok': true};
        },
      ),
    if (oauthBroker != null)
      RepoOp(
        name: 'providers.cancelOAuth',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['flow_id'],
        handler: (ctx) async {
          await oauthBroker.cancel(ctx.args['flow_id'] as String);
          return {'ok': true};
        },
      ),

    // ---- Usage / cost summary (PRD 05; workspace-scoped aggregation) ----
    // Aggregates the workspace's recent run-cost history into a spend summary
    // for the usage dashboard ("$X spent this week, resets in Ym").
    RepoOp(
      name: 'usage.costSummary',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final windowDays = (ctx.args['window_days'] as num?)?.toInt() ?? 7;
        final now = DateTime.now();
        final logs = await agentRunLogRepository.watchAll().first;
        final entries = <UsageCostHistoryEntry>[
          for (final log in logs)
            if (log.workspaceId == ctx.workspaceId &&
                log.cost.estimatedCostCents > 0)
              UsageCostHistoryEntry(
                recordedAt: log.startedAt,
                provider: log.adapter ?? 'agent',
                accountKey: log.adapter ?? 'agent',
                costUsd: log.cost.estimatedCostCents / 100.0,
              ),
        ];
        final summary = UsageTracker.summarizeLast(
          entries,
          window: Duration(days: windowDays),
          now: now,
        );
        return costSummaryToWire(summary);
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
        final status = ReviewChannelStatus.values
            .asNameMap()[ctx.args['status']];
        if (status == null) {
          throw const NotFoundException('Unknown review channel status');
        }
        await reviewChannelRepository.updateStatus(
          ctx.workspaceId!,
          id,
          status,
        );
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
          ctx.workspaceId!,
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
    // One run's recorded activity timeline — the replay half of the activity
    // tab (the live half is `agent_run_log.watchRunTranscript`). Resolves a
    // subagent's `run_transcripts` row OR a top-level run's own `agent_turn`
    // message via [loadRunReplay]. Absent when no transcript store is wired, so
    // a host without one is default-deny rather than silently empty.
    if (runTranscriptRepository != null)
      RepoOp(
        name: 'agent_run_log.getTranscript',
        kind: RepoOpKind.read,
        requiredArgs: ['run_id'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          // Run logs carry a nullable workspaceId; an ID-only lookup is not a
          // scoping boundary, so load the row and reject a foreign one.
          final run = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (run == null) {
            throw const NotFoundException('Agent run log not found');
          }
          if (run.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Agent run log belongs to a different workspace',
            );
          }
          final replay = await loadRunReplay(ctx.workspaceId!, runId);
          final transcript = replay.row;
          var segments = replay.segments;
          // Crash mid-run: the run row is terminal but the recording was never
          // finalized. Present in-flight tools as interrupted, not as live.
          // A message-backed timeline needs the same treatment — a killed
          // top-level run leaves its last tool segment `running` forever.
          if ((transcript == null || !transcript.complete) &&
              run.completedAt != null) {
            segments = normalizeInterrupted(segments);
          }
          var json = encodeTranscript(segments);
          if (await viewerTraceRestricted(
            ctx.workspaceId!,
            run.channelId ?? run.conversationId ?? '',
            ctx.userId,
          )) {
            json = [for (final seg in json) redactSegmentJson(seg)];
          }
          return {
            'run_id': runId,
            'segments': json,
            // No `run_transcripts` row means a message-backed top-level run:
            // the run log's own terminal state is then the completeness signal.
            'complete': transcript?.complete ?? (run.completedAt != null),
            'outcome': ?switch (transcript?.outcome) {
              final TurnOutcome o => turnOutcomeToString(o),
              null => null,
            },
            'transcript_chars': transcript?.transcriptChars ?? 0,
            'updated_at': ?(transcript?.updatedAt ?? run.completedAt)
                ?.toIso8601String(),
          };
        },
      ),
    RepoOp(
      name: 'agent_run_log.activeRunForAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final log = await agentRunLogRepository.activeRunForAgent(
          ctx.workspaceId!,
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
        final existing = await teamRepository.getTeam(
          ctx.workspaceId!,
          team.id,
        );
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
        final existing = await teamRepository.getTeam(ctx.workspaceId!, id);
        if (existing != null && existing.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.deleteTeam(ctx.workspaceId!, id);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.getTeam',
      kind: RepoOpKind.read,
      requiredArgs: ['id'],
      handler: (ctx) async {
        final team = await teamRepository.getTeam(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
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
        final team = await teamRepository.getTeam(
          ctx.workspaceId!,
          member.teamId,
        );
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.addMember(ctx.workspaceId!, member);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.removeMember',
      kind: RepoOpKind.mutate,
      requiredArgs: ['team_id', 'agent_id'],
      handler: (ctx) async {
        final teamId = ctx.args['team_id'] as String;
        final team = await teamRepository.getTeam(ctx.workspaceId!, teamId);
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        await teamRepository.removeMember(
          ctx.workspaceId!,
          teamId,
          ctx.args['agent_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'team.membersOf',
      kind: RepoOpKind.read,
      requiredArgs: ['team_id'],
      handler: (ctx) async {
        final teamId = ctx.args['team_id'] as String;
        final team = await teamRepository.getTeam(ctx.workspaceId!, teamId);
        if (team == null || team.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Team belongs to a different workspace',
          );
        }
        final members = await teamRepository.membersOf(
          ctx.workspaceId!,
          teamId,
        );
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
        await isolatedRepoRepository.deleteById(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
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
        final clip = await loadMeetingAudioClip(
          MeetingAudioRequest(audioDirPath: dir),
        );
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
            summaryInstructions: ctx.args['summary_instructions'] as String?,
          );
          return {'ok': true};
        },
      ),
    ],
    // ---- Voice dictation over RPC (PRD 25 §2) ----
    // The composer's mic streams PCM16 here; the host runs the SAME windowed
    // transcriber the meeting recorder uses and pushes finalized windows back
    // via `dictation.watchPartials`. Gated on an installed voice model.
    if (dictationService != null) ...[
      RepoOp(
        name: 'dictation.start',
        kind: RepoOpKind.mutate,
        handler: (ctx) async {
          // The SERVER mints the id (scoped to the bound workspace).
          final id = dictationService.start(ctx.workspaceId!);
          return {'ok': true, 'dictation_id': id};
        },
      ),
      RepoOp(
        name: 'dictation.ingestAudio',
        kind: RepoOpKind.mutate,
        requiredArgs: ['dictation_id', 'pcm'],
        handler: (ctx) async {
          // PCM16 frames travel base64 in the JSON-RPC envelope (no raw frame).
          dictationService.ingest(
            ctx.args['dictation_id'] as String,
            base64Decode(ctx.args['pcm'] as String),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dictation.stop',
        kind: RepoOpKind.mutate,
        requiredArgs: ['dictation_id'],
        handler: (ctx) async {
          await dictationService.stop(ctx.args['dictation_id'] as String);
          return {'ok': true};
        },
      ),
    ],
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
      // Cache-fill when the calendar scrolls outside the rolling window — noise.
      audited: false,
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
    // client id + secret, OR asks for the server's own app with `use_builtin`
    // (`connectInfo` says whether that is on offer); the HOST runs the
    // device-code flow, stores the refresh token server-side, and syncs.
    // `beginConnect` returns a code + URL + an opaque handle; the client polls
    // `pollConnect` until approved. A built-in connect stores a marker rather
    // than the server's pair, so no response and no on-disk credential ever
    // carries the built-in secret. Every op
    // sources `ctx.workspaceId!` (the bound session) — the handle is bound to
    // the workspace that began it, and `disconnect`'s account id embeds its
    // workspace, so a foreign-workspace handle/account is rejected. Declared
    // only when [calendarConnect] is wired (a host with the Google stack).
    if (calendarConnect != null) ...[
      RepoOp(
        // Says only WHETHER this server has a Google app of its own, so the
        // connect dialog knows whether to offer "use Control Center's Google
        // app". Deliberately not the client id: the client has no use for it,
        // and the pair never leaves the server.
        name: 'calendar.connectInfo',
        kind: RepoOpKind.read,
        handler: (ctx) async => {
          'builtin_available': calendarConnect.builtinAvailable,
        },
      ),
      RepoOp(
        name: 'calendar.beginConnect',
        kind: RepoOpKind.mutate,
        // Neither credential is required: `use_builtin` authorizes with the
        // server's own client instead. The service refuses the combination that
        // is actually empty, naming which box to fill.
        handler: (ctx) async {
          final begin = await calendarConnect.begin(
            workspaceId: ctx.workspaceId!,
            useBuiltin: ctx.args['use_builtin'] == true,
            clientId: ctx.args['client_id'] as String? ?? '',
            clientSecret: ctx.args['client_secret'] as String? ?? '',
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
        final pr = await prLifecycleRepository.getById(
          ctx.workspaceId!,
          ctx.args['id'] as String,
        );
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
        await assertPrLifecycleOwned(ctx.workspaceId!, prId);
        await prLifecycleRepository.updateDraft(
          ctx.workspaceId!,
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
      // Irreversible: opens a pull request on GitHub (external side effect).
      undoClass: UndoClass.irreversible,
      // Publishes a PR to GitHub — the PRD 24 prCreate effect (prompt by
      // default; an operator can set an allow rule in agent-permission settings).
      actionClasses: const {ActionClass.prCreate},
      requiredArgs: ['pr_id', 'owner', 'repo', 'title', 'body', 'head', 'base'],
      handler: (ctx) async {
        final prId = ctx.args['pr_id'] as String;
        await assertPrLifecycleOwned(ctx.workspaceId!, prId);
        final result = await prLifecycleRepository.createOnGitHub(
          workspaceId: ctx.workspaceId!,
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
        await assertPrLifecycleOwned(ctx.workspaceId!, id);
        await prLifecycleRepository.delete(ctx.workspaceId!, id);
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
    // Forces an immediate open-PR poller sweep (ETag short-circuits bypassed,
    // checks pass included) — the "refresh now" behind the live PR list. The
    // result arrives over the `pr.watchOpenForWorkspace` subscription, not in
    // this reply.
    if (openPrPoller != null)
      RepoOp(
        name: 'pr.refreshOpenForWorkspace',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          await openPrPoller.refreshNow(ctx.workspaceId!);
          return {'ok': true};
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
        final teams = await fetchViewerGitHubTeams?.call();
        return {
          'user': user,
          'teams': [
            for (final e in (teams ?? const <String, Set<String>>{}).entries)
              for (final slug in e.value) {'org': e.key, 'slug': slug},
          ],
        };
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        return {
          'profile': await read?.userProfile(ctx.args['login'] as String),
        };
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
    // The status.claude.com summary, relayed raw for the client to parse.
    // Global (not workspace data) and token-less.
    RepoOp(
      name: 'claude.serviceStatus',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchClaudeServiceStatus;
        if (fetch == null) {
          return {'summary': null};
        }
        return {'summary': await fetch()};
      },
    ),
    // The status.openai.com summary, relayed raw for the client to parse.
    // Global (not workspace data) and token-less.
    RepoOp(
      name: 'openai.serviceStatus',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchOpenAIServiceStatus;
        if (fetch == null) {
          return {'summary': null};
        }
        return {'summary': await fetch()};
      },
    ),
    // The status.moonshot.cn (Kimi) summary, relayed raw for the client to
    // parse. Global (not workspace data) and token-less.
    RepoOp(
      name: 'kimi.serviceStatus',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchKimiServiceStatus;
        if (fetch == null) {
          return {'summary': null};
        }
        return {'summary': await fetch()};
      },
    ),
    // Live subscription-usage quotas for the local AI coding CLIs (Claude,
    // Codex, z.ai) behind the title-bar usage pill. Global (account-level, not
    // workspace data). Everything resolves server-side: Claude/Codex from
    // their CLIs' own credentials, z.ai from the harness provider credential
    // store (the key saved in Settings → Adapters → Providers & models). Null
    // fetcher (or no providers configured) → an empty list.
    RepoOp(
      name: 'subscriptions.usage',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchSubscriptionUsage;
        if (fetch == null) {
          return {'providers': <Map<String, dynamic>>[]};
        }
        String? zaiApiKey;
        String? zaiBaseUrl;
        String? kimiAccessToken;
        String? kimiBaseUrl;
        String? kimiDeviceId;
        if (harnessCreds != null) {
          final cred = await harnessCreds.activeCredential('zai');
          zaiApiKey = cred?.apiKey;
          // A stored base URL points at the chat API (e.g. …/api/paas/v4);
          // the usage endpoint lives at the host root, so only the origin is
          // reused (it lets a bigmodel.cn account keep working).
          final base = cred?.baseUrl?.trim();
          if (base != null && base.isNotEmpty) {
            final uri = Uri.tryParse(base);
            if (uri != null &&
                (uri.scheme == 'https' || uri.scheme == 'http')) {
              zaiBaseUrl = uri.origin;
            }
          }
          // Kimi Code is OAuth-only, and its usage endpoint sits under the same
          // base URL as the chat API. Refresh first: the usage probe must not be
          // the thing that discovers an expired token.
          var kimi = await harnessCreds.activeCredential('kimi-code');
          if (kimi != null && oauthBroker != null) {
            kimi = await oauthBroker.refreshIfNeeded(kimi);
          }
          kimiAccessToken = kimi?.accessToken;
          kimiBaseUrl = kimi?.baseUrl;
          kimiDeviceId = kimi?.accountId;
        }
        return {
          'providers': await fetch(
            zaiApiKey: zaiApiKey,
            zaiBaseUrl: zaiBaseUrl,
            kimiAccessToken: kimiAccessToken,
            kimiBaseUrl: kimiBaseUrl,
            kimiDeviceId: kimiDeviceId,
          ),
        };
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        await requireWorkspaceGitHubRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
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
        final run = await pipelineRunRepository.getRun(
          ctx.args['id'] as String,
        );
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
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
          await pipeline.cancel(ctx.workspaceId!, runId);
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
          await pipeline.retry(ctx.workspaceId!, runId);
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
          await pipeline.killStep(ctx.workspaceId!, stepRunId);
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
          // Optional subtree scope (PRD 17 §4): when `approved_node_keys` is
          // present (and the scoped path is wired), unlisted nodes
          // materialize behind suspended approval gates.
          final rawKeys = ctx.args['approved_node_keys'];
          final nodeKeys = rawKeys is List
              ? rawKeys.whereType<String>().toSet()
              : null;
          if (nodeKeys != null && approveScoped != null) {
            await approveScoped(
              ctx.workspaceId!,
              ctx.args['orchestration_id'] as String,
              nodeKeys,
            );
          } else {
            await approveOrch(
              ctx.workspaceId!,
              ctx.args['orchestration_id'] as String,
            );
          }
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
    // ---- Plan Studio (PRD 17) ----
    // Widens an executing partial approval: newly approved nodes' suspended
    // gates resume. The use case enforces dependency-closure.
    if (approveNodes != null)
      RepoOp(
        name: 'orchestration.approveNodes',
        kind: RepoOpKind.mutate,
        requiredArgs: ['orchestration_id', 'node_keys'],
        handler: (ctx) async {
          await approveNodes(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
            (ctx.args['node_keys'] as List).whereType<String>().toSet(),
          );
          return {'ok': true};
        },
      ),
    // Saves an operator-edited proposal as a new revision (validated;
    // optimistic-concurrency via `base_revision` — a stale edit is refused
    // with "the plan moved on", never silently clobbered).
    if (saveRevision != null)
      RepoOp(
        name: 'orchestration.saveRevision',
        kind: RepoOpKind.mutate,
        requiredArgs: ['orchestration_id', 'proposal_json', 'base_revision'],
        handler: (ctx) async {
          final updated = await saveRevision.save(
            workspaceId: ctx.workspaceId!,
            orchestrationId: ctx.args['orchestration_id'] as String,
            proposal: OrchestrationProposal.fromJsonString(
              ctx.args['proposal_json'] as String,
            ),
            baseRevision: (ctx.args['base_revision'] as num).toInt(),
            authoredBy: ctx.userId,
          );
          return {'orchestration': orchestrationToWire(updated)};
        },
      ),
    // The append-only revision timeline (plan diff + rewind read surface).
    if (revisionsRepo != null)
      RepoOp(
        name: 'orchestration.revisions',
        kind: RepoOpKind.read,
        requiredArgs: ['orchestration_id'],
        handler: (ctx) async {
          final revisions = await revisionsRepo.forOrchestration(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
          );
          return {
            'revisions': revisions.map(orchestrationRevisionToWire).toList(),
          };
        },
      ),
    // Plan-drift divergence markers for the Studio canvas (PRD 17 §6).
    if (divergenceMarkers != null)
      RepoOp(
        name: 'orchestration.divergence',
        kind: RepoOpKind.read,
        requiredArgs: ['orchestration_id'],
        handler: (ctx) async => {
          'markers': await divergenceMarkers(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
          ),
        },
      ),
    // Resumes a node held by stop-and-ask drift policy.
    if (continueNode != null)
      RepoOp(
        name: 'orchestration.continueNode',
        kind: RepoOpKind.mutate,
        requiredArgs: ['orchestration_id', 'node_key'],
        handler: (ctx) async {
          await continueNode(
            ctx.workspaceId!,
            ctx.args['orchestration_id'] as String,
            ctx.args['node_key'] as String,
          );
          return {'ok': true};
        },
      ),
    // Per-node cost/time/blast-radius estimate (PRD 17 §3): gathers history +
    // impact server-side, runs the pure estimator, persists what the operator
    // saw into the stored proposal/plan, and returns the ranges. Honest or
    // absent — a node without history reports `sampleSize: 0`.
    if (estimateOrch != null)
      RepoOp(
        name: 'plan.estimate',
        kind: RepoOpKind.mutate,
        handler: (ctx) async {
          final orchestrationId = ctx.args['orchestration_id'];
          if (orchestrationId is String && orchestrationId.isNotEmpty) {
            return {
              'estimate': await estimateOrch(ctx.workspaceId!, orchestrationId),
            };
          }
          final planId = ctx.args['plan_id'];
          if (planId is String && planId.isNotEmpty && estimatePlan != null) {
            return {'estimate': await estimatePlan(ctx.workspaceId!, planId)};
          }
          throw const ValidationException(
            'plan.estimate needs orchestration_id or plan_id',
          );
        },
      ),
    // ---- Plan-mode documents (PRD 17 §8) ----
    if (plansRepo != null) ...[
      RepoOp(
        name: 'plan.getById',
        kind: RepoOpKind.read,
        requiredArgs: ['plan_id'],
        handler: (ctx) async {
          final doc = await plansRepo.getById(
            ctx.workspaceId!,
            ctx.args['plan_id'] as String,
          );
          if (doc == null) {
            throw const NotFoundException('Plan not found');
          }
          return {'plan': planDocumentToWire(doc)};
        },
      ),
      RepoOp(
        name: 'plan.latestForConversation',
        kind: RepoOpKind.read,
        requiredArgs: ['conversation_id'],
        handler: (ctx) async {
          final doc = await plansRepo.latestForConversation(
            ctx.workspaceId!,
            ctx.args['conversation_id'] as String,
          );
          return {'plan': doc == null ? null : planDocumentToWire(doc)};
        },
      ),
      // Reject / supersede a proposed plan (approve has its own op below —
      // it materializes, so it needs the engine-owning host).
      RepoOp(
        name: 'plan.updateStatus',
        kind: RepoOpKind.mutate,
        // Reversible: the prior plan status is captured client-side and
        // re-applied.
        undoClass: UndoClass.reversible,
        requiredArgs: ['plan_id', 'status'],
        handler: (ctx) async {
          final doc = await plansRepo.getById(
            ctx.workspaceId!,
            ctx.args['plan_id'] as String,
          );
          if (doc == null) {
            throw const NotFoundException('Plan not found');
          }
          await plansRepo.upsert(
            doc.copyWith(
              status: PlanDocumentStatus.fromName(ctx.args['status'] as String),
              updatedAt: DateTime.now(),
            ),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'plan.delete',
        kind: RepoOpKind.mutate,
        requiredArgs: ['plan_id'],
        handler: (ctx) async {
          await plansRepo.deleteById(
            ctx.workspaceId!,
            ctx.args['plan_id'] as String,
          );
          return {'ok': true};
        },
      ),
    ],
    // ---- Work products / artifacts ----
    //
    // Read-only: artifacts are written by the agent-facing MCP tools
    // (`publish_artifact` / `revise_artifact`), never by a client, so there is
    // deliberately no `workProduct.save` op here. Every read goes through the
    // repository's required `workspaceId`, so an id from another workspace
    // simply does not resolve — an id-only lookup is not a scoping boundary.
    if (workProductsRepo != null) ...[
      RepoOp(
        name: 'workProduct.getById',
        kind: RepoOpKind.read,
        requiredArgs: ['work_product_id'],
        handler: (ctx) async {
          final product = await workProductsRepo.getById(
            ctx.workspaceId!,
            ctx.args['work_product_id'] as String,
          );
          if (product == null) {
            throw const NotFoundException('Work product not found');
          }
          return {'work_product': workProductToWire(product)};
        },
      ),
      RepoOp(
        name: 'workProduct.revisions',
        kind: RepoOpKind.read,
        requiredArgs: ['work_product_id'],
        handler: (ctx) async {
          final productId = ctx.args['work_product_id'] as String;
          // Ownership first: without this a caller could enumerate any
          // workspace's revision bodies by id, since revisions are keyed by
          // their parent.
          final product = await workProductsRepo.getById(
            ctx.workspaceId!,
            productId,
          );
          if (product == null) {
            throw const NotFoundException('Work product not found');
          }
          final revisions = await workProductsRepo.getRevisions(
            ctx.workspaceId!,
            productId,
          );
          return {
            'revisions': [
              for (final r in revisions) workProductRevisionToWire(r),
            ],
          };
        },
      ),
      // The one write: restoring an earlier revision. Append-a-new-head, never a
      // rewrite, so the history stays an audit trail. This is an OPERATOR
      // action (an agent revises by publishing), which is why it lives here and
      // not in the MCP surface.
      RepoOp(
        name: 'workProduct.restoreRevision',
        kind: RepoOpKind.mutate,
        requiredArgs: ['work_product_id', 'revision_id'],
        handler: (ctx) async {
          final productId = ctx.args['work_product_id'] as String;
          // Ownership first: the revision is keyed by its parent, so without
          // this a foreign id could be restored into this workspace.
          final product = await workProductsRepo.getById(
            ctx.workspaceId!,
            productId,
          );
          if (product == null) {
            throw const NotFoundException('Work product not found');
          }
          final service = WorkProductService(repository: workProductsRepo);
          final revision = await service.restoreRevision(
            workspaceId: ctx.workspaceId!,
            workProductId: productId,
            revisionId: ctx.args['revision_id'] as String,
            authorId: ctx.userId,
          );
          return {'revision': workProductRevisionToWire(revision)};
        },
      ),
      RepoOp(
        name: 'workProduct.listForWorkspace',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final products = await workProductsRepo
              .watchByWorkspace(ctx.workspaceId!)
              .first;
          return {
            'work_products': [for (final p in products) workProductToWire(p)],
          };
        },
      ),
    ],
    // Approves a plan document: compiles it into a single-role orchestration
    // and runs the SAME deterministic approve/materialize path (incl. partial
    // approval via `approved_node_keys`).
    if (approvePlan != null)
      RepoOp(
        name: 'plan.approve',
        kind: RepoOpKind.mutate,
        requiredArgs: ['plan_id'],
        handler: (ctx) async {
          final rawKeys = ctx.args['approved_node_keys'];
          return approvePlan(
            workspaceId: ctx.workspaceId!,
            planId: ctx.args['plan_id'] as String,
            approvedNodeKeys: rawKeys is List
                ? rawKeys.whereType<String>().toSet()
                : null,
            maxCostCents: (ctx.args['max_cost_cents'] as num?)?.toInt(),
          );
        },
      ),
    // ---- Playbooks (PRD 17 §10) ----
    if (playbooksRepo != null) ...[
      RepoOp(
        name: 'playbook.list',
        kind: RepoOpKind.read,
        handler: (ctx) async => {
          'playbooks': [
            for (final p in await playbooksRepo.forWorkspace(ctx.workspaceId!))
              playbookToWire(p),
          ],
        },
      ),
      RepoOp(
        name: 'playbook.getById',
        kind: RepoOpKind.read,
        requiredArgs: ['playbook_id'],
        handler: (ctx) async {
          final playbook = await playbooksRepo.getById(
            ctx.workspaceId!,
            ctx.args['playbook_id'] as String,
          );
          if (playbook == null) {
            throw const NotFoundException('Playbook not found');
          }
          return {'playbook': playbookToWire(playbook)};
        },
      ),
      RepoOp(
        name: 'playbook.save',
        kind: RepoOpKind.mutate,
        requiredArgs: ['playbook'],
        handler: (ctx) async {
          final w = (ctx.args['playbook'] as Map).cast<String, dynamic>();
          final workspaceId = ctx.workspaceId!;
          if ((w['workspace_id'] as String?) != workspaceId) {
            throw const WorkspaceMismatchException(
              'Playbook belongs to a different workspace.',
            );
          }
          final now = DateTime.now();
          final existing = await playbooksRepo.getById(
            workspaceId,
            w['id'] as String? ?? '',
          );
          final playbook = Playbook(
            id: w['id'] as String,
            workspaceId: workspaceId,
            name: w['name'] as String? ?? '',
            description: w['description'] as String? ?? '',
            params: Playbook.paramsFromJsonString(
              w['params_json'] as String? ?? '[]',
            ),
            sourceProposal: OrchestrationProposal.fromJsonString(
              w['source_proposal_json'] as String? ?? '{}',
            ),
            version: existing == null ? 1 : existing.version + 1,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          );
          await playbooksRepo.upsert(playbook);
          return {'playbook': playbookToWire(playbook)};
        },
      ),
      RepoOp(
        name: 'playbook.delete',
        kind: RepoOpKind.mutate,
        requiredArgs: ['playbook_id'],
        handler: (ctx) async {
          await playbooksRepo.deleteById(
            ctx.workspaceId!,
            ctx.args['playbook_id'] as String,
          );
          return {'ok': true};
        },
      ),
    ],
    // Instantiates + proposes a playbook run. Phone-callable BY DESIGN
    // (PRD 17 §10 "phone-triggerable"): it only PROPOSES a plan — the
    // operator still approves before anything executes or spends, which is
    // what keeps this inside the companion tier's no-unbounded-spend rule.
    if (playbookRun != null)
      RepoOp(
        name: 'playbook.run',
        kind: RepoOpKind.mutate,
        requiredArgs: ['playbook_id', 'ticket_id'],
        handler: (ctx) async {
          final rawArgs = ctx.args['args'];
          return playbookRun(
            workspaceId: ctx.workspaceId!,
            ticketId: ctx.args['ticket_id'] as String,
            playbookId: ctx.args['playbook_id'] as String,
            args: rawArgs is Map
                ? {
                    for (final e in rawArgs.entries)
                      if (e.key is String && e.value != null)
                        e.key as String: e.value.toString(),
                  }
                : const {},
            userId: ctx.userId,
          );
        },
      ),
    // ---- Review Studio (PRD 18) ----
    // Reads are workspace-scoped via the synthetic PR key; compute + blast
    // radius run on a host that owns the code graph + git + PR fetch.
    if (reviewCohortRepository != null)
      RepoOp(
        name: 'review_studio.cohorts',
        kind: RepoOpKind.read,
        requiredArgs: ['owner', 'repo', 'pr_number'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          await resolvePrReviewRepository(
            ctx.workspaceId!,
            c.owner,
            c.repo,
            userId: ctx.userId,
          );
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: (ctx.args['pr_number'] as num).toInt(),
                )
              : reviewPrNodeKey(
                  c.owner,
                  c.repo,
                  (ctx.args['pr_number'] as num).toInt(),
                );
          final cohorts = await reviewCohortRepository.forPr(
            ctx.workspaceId!,
            key,
          );
          return {'cohorts': cohorts.map((x) => x.toJson()).toList()};
        },
      ),
    if (apiContractDiffRepository != null) ...[
      RepoOp(
        name: 'review_studio.setContractDecision',
        kind: RepoOpKind.mutate,
        requiredArgs: ['diff_id', 'change_id', 'decision'],
        handler: (ctx) async {
          await apiContractDiffRepository.setChangeDecision(
            ctx.workspaceId!,
            ctx.args['diff_id'] as String,
            ctx.args['change_id'] as String,
            ApiChangeDecision.fromName(ctx.args['decision'] as String?),
          );
          return {'ok': true};
        },
      ),
    ],
    if (visualDiffRepository != null)
      RepoOp(
        name: 'review_studio.approveVisual',
        kind: RepoOpKind.mutate,
        requiredArgs: ['snapshot_id', 'status'],
        handler: (ctx) async {
          await visualDiffRepository.setStatus(
            ctx.workspaceId!,
            ctx.args['snapshot_id'] as String,
            VisualDiffStatus.fromName(ctx.args['status'] as String?),
          );
          return {'ok': true};
        },
      ),
    // Computes cohorts + deterministic axes for a PR (host owns the graph/git).
    if (computeReviewStudio != null)
      RepoOp(
        name: 'review_studio.compute',
        kind: RepoOpKind.mutate,
        requiredArgs: ['owner', 'repo', 'pr_number'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          return computeReviewStudio(
            workspaceId: ctx.workspaceId!,
            owner: c.owner,
            repo: c.repo,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            userId: ctx.userId,
          );
        },
      ),
    // User-gated GitHub publish of a finalized review (the "Publish to GitHub"
    // button). prPublish → guardrail chokepoint gates it (fail-closed with no
    // approver). Channel-scoped: the publisher asserts channel ownership.
    if (publishReview != null)
      RepoOp(
        name: 'pr_review.publishReview',
        kind: RepoOpKind.mutate,
        actionClasses: const {ActionClass.prPublish},
        requiredArgs: ['workspace_id', 'channel_id'],
        handler: (ctx) async {
          final selection = ctx.args['selection'];
          return publishReview(
            workspaceId: ctx.workspaceId!,
            channelId: ctx.args['channel_id'] as String,
            selection: selection is String ? selection : 'consensus',
            approveOnShip: ctx.args['approve_on_ship'] == true,
          );
        },
      ),
    // Beyond-the-diff blast radius for a changed file (PRD 18 §6).
    if (reviewBlastRadius != null)
      RepoOp(
        name: 'review_studio.blastRadius',
        kind: RepoOpKind.read,
        requiredArgs: ['owner', 'repo', 'file_path'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          return reviewBlastRadius(
            workspaceId: ctx.workspaceId!,
            owner: c.owner,
            repo: c.repo,
            filePath: ctx.args['file_path'] as String,
            userId: ctx.userId,
            depth: (ctx.args['depth'] as num?)?.toInt() ?? 2,
          );
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
          ctx.workspaceId!,
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
        await pipelineTriggerRepository.deleteById(
          ctx.workspaceId!,
          existing.id,
        );
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
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
          ctx.workspaceId!,
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
        final list = await orchestrationRepository
            .approvedNeedingMaterialization();
        return {'orchestrations': list.map(orchestrationToWire).toList()};
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
        // workspace exactly once.
        final existing = await workspaceRepository.getById(incoming.id);
        final isNew = existing == null;
        // On CREATE the calling principal becomes the workspace owner: stamp
        // `ownerUserId` and record an owner-role membership row NOW, in the
        // same op. Without this the freshly created workspace has no members,
        // so every workspace-scoped call the creator makes next (the whole
        // post-onboarding app) is denied with "Not a member of this
        // workspace" until the next server restart, when
        // `IdentityBootstrap._backfillWorkspaceOwnership` happens to repair it.
        // On UPDATE, carry the stored owner over when the wire omits it so a
        // rename from an older client can never wipe the stamp.
        final toStore = incoming.ownerUserId != null
            ? incoming
            : incoming.copyWith(
                ownerUserId: isNew ? ctx.userId : existing.ownerUserId,
              );
        final id = await workspaceRepository.upsert(toStore);
        if (isNew) {
          final members = identityMembers;
          if (members != null &&
              await members.getMember(id, ctx.userId) == null) {
            await members.upsert(
              WorkspaceMember(
                id: const Uuid().v4(),
                workspaceId: id,
                userId: ctx.userId,
                role: WorkspaceRole.owner,
                joinedAt: DateTime.now(),
              ),
            );
          }
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
    // CROSS-WORKSPACE BY DESIGN: reordering IS a whole-list operation, so it
    // cannot scope to one workspace (same posture as upsert/delete above). The
    // order is a server-owned property of the registry rows, exactly like
    // `repos.position` within a workspace, so every client renders one sequence.
    RepoOp(
      name: 'workspace.reorder',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace_ids'],
      handler: (ctx) async {
        final ids = ((ctx.args['workspace_ids'] as List?) ?? const [])
            .map((w) => w.toString())
            .toList();
        await workspaceRepository.reorderWorkspaces(ids);
        return {'ok': true};
      },
    ),
    // The three repo-list writes below are WORKSPACE-SCOPED: repos live inside a
    // workspace, so the workspace id is the access gate (membership is checked
    // before the handler runs), not a selector over global rows.
    RepoOp(
      name: 'workspace.setReposForWorkspace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_ids'],
      handler: (ctx) async {
        final repoIds = ((ctx.args['repo_ids'] as List?) ?? const [])
            .map((r) => r.toString())
            .toList();
        await workspaceRepository.setReposForWorkspace(
          ctx.workspaceId!,
          repoIds,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.unlinkRepoFromWorkspace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        await workspaceRepository.unlinkRepoFromWorkspace(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'workspace.isRepoLinkedToWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final linked = await workspaceRepository.isRepoLinkedToWorkspace(
          ctx.workspaceId!,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
        );
        final candidates = await repo.listRequestableReviewers();
        return {
          'candidates': candidates.map(prReviewerCandidateToWire).toList(),
        };
      },
    ),
    RepoOp(
      name: 'pr_review.suggestedReviewers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final users = await repo.listSuggestedReviewers(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'users': users.map(prUserToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pr_review.getJobRunDetail',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'job_id'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final job = await repo.getJobRunDetail(
          (ctx.args['job_id'] as num).toInt(),
        );
        return {'job': ?(job == null ? null : jobRunDetailToWire(job))};
      },
    ),
    RepoOp(
      name: 'pr_review.getWorkflowGraph',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'run_id'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final graph = await repo.getWorkflowGraph(
          (ctx.args['run_id'] as num).toInt(),
        );
        return {'graph': ?(graph == null ? null : workflowGraphToWire(graph))};
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
      // Irreversible: publishes a review to GitHub (external side effect).
      undoClass: UndoClass.irreversible,
      requiredArgs: ['owner', 'repo', 'pr_number', 'event'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
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
      // Irreversible: merging lands commits on GitHub — an external side effect
      // that no inverse op can undo. It gets preview/confirm (below) instead
      // and never enters the undo stack (PRD 19 §4/§5).
      undoClass: UndoClass.irreversible,
      requiredArgs: ['owner', 'repo', 'pr_number', 'merge_method'],
      preview: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final n = (ctx.args['pr_number'] as num?)?.toInt();
        final method = ctx.args['merge_method'] as String? ?? 'merge';
        return ActionPreview(
          summary: 'Merge ${c.owner}/${c.repo} #$n via $method',
          warnings: const [
            'Merging pushes commits to GitHub and cannot be undone from here.',
          ],
        );
      },
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          final ok = pendingConfirmationRegistry.respond(
            id,
            approved: approved,
          );
          return {'ok': ok};
        },
      ),
    // ---- Governance (PRD 09; read-only over RPC) ----
    // The goal hierarchy + board approvals are workspace-scoped at the repo,
    // so an id-keyed read that resolves a row from a foreign workspace returns
    // null (treated as not-found) — no cross-workspace leak.
    RepoOp(
      name: 'goals.get',
      kind: RepoOpKind.read,
      requiredArgs: ['goal_id'],
      handler: (ctx) async {
        final goal = await goalRepository.getById(
          ctx.workspaceId!,
          ctx.args['goal_id'] as String,
        );
        if (goal == null) {
          throw const NotFoundException('Goal not found');
        }
        return {'goal': orgGoalToWire(goal)};
      },
    ),
    RepoOp(
      name: 'approvals.get',
      kind: RepoOpKind.read,
      requiredArgs: ['approval_id'],
      handler: (ctx) async {
        final approval = await approvalRepository.getById(
          ctx.workspaceId!,
          ctx.args['approval_id'] as String,
        );
        if (approval == null) {
          throw const NotFoundException('Approval not found');
        }
        return {'approval': approvalToWire(approval)};
      },
    ),
    RepoOp(
      name: 'approvals.getComments',
      kind: RepoOpKind.read,
      requiredArgs: ['approval_id'],
      handler: (ctx) async {
        final comments = await approvalRepository.getComments(
          ctx.workspaceId!,
          ctx.args['approval_id'] as String,
        );
        return {'comments': comments.map(approvalCommentToWire).toList()};
      },
    ),
    // Computed presence (availability × workload) for every agent in the
    // bound workspace, keyed by agent id — not a repo stream, so it is a read
    // op rather than a watch.
    RepoOp(
      name: 'agent_presence.forWorkspace',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final byAgent = await agentPresenceService.presenceForWorkspace(
          ctx.workspaceId!,
        );
        return {
          'presence': {
            for (final entry in byAgent.entries)
              entry.key: agentPresenceToWire(entry.value),
          },
        };
      },
    ),
    // ---- Per-conversation todo lists ----
    // Workspace-scoped (the bound workspace is `ctx.workspaceId!`); each op
    // additionally requires the `conversation_id` it operates on. The repo
    // filters by both, so a foreign conversation/workspace simply yields
    // nothing / deletes nothing.
    RepoOp(
      name: 'todos.list',
      kind: RepoOpKind.read,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        final items = await todoRepository.list(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
        );
        return {'todos': items.map(todoItemToWire).toList()};
      },
    ),
    RepoOp(
      name: 'todos.replaceAll',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'todos'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final conversationId = ctx.args['conversation_id'] as String;
        final raw = (ctx.args['todos'] as List).cast<Map>();
        final now = DateTime.now();
        final items = <TodoItem>[
          for (var i = 0; i < raw.length; i++)
            TodoItem(
              id:
                  (raw[i]['id'] as String?) ??
                  '${now.microsecondsSinceEpoch}-$i',
              workspaceId: workspaceId,
              conversationId: conversationId,
              content: (raw[i]['content'] as String? ?? '').trim(),
              status: TodoStatus.fromStorage(raw[i]['status'] as String?),
              position: i,
              createdAt: now,
              updatedAt: now,
            ),
        ]..removeWhere((t) => t.content.isEmpty);
        await todoRepository.replaceAll(workspaceId, conversationId, items);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'todos.append',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'content'],
      handler: (ctx) async {
        final item = await todoRepository.append(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          (ctx.args['content'] as String).trim(),
        );
        return {'todo': todoItemToWire(item)};
      },
    ),
    RepoOp(
      name: 'todos.setStatus',
      kind: RepoOpKind.mutate,
      // Reversible: the prior status is captured client-side and re-applied.
      undoClass: UndoClass.reversible,
      requiredArgs: ['conversation_id', 'id', 'status'],
      handler: (ctx) async {
        await todoRepository.updateStatus(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          ctx.args['id'] as String,
          TodoStatus.fromStorage(ctx.args['status'] as String?),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'todos.remove',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'id'],
      handler: (ctx) async {
        await todoRepository.remove(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          ctx.args['id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'todos.reorder',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'ordered_ids'],
      handler: (ctx) async {
        await todoRepository.reorder(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          (ctx.args['ordered_ids'] as List).cast<String>(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'todos.clear',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        await todoRepository.clear(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // Per-conversation working goal (`/goal`): set replaces the prior goal; a
    // blank title clears it (the repository normalizes). The todos render
    // nested under it client-side.
    RepoOp(
      name: 'todos.setGoal',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'title'],
      handler: (ctx) async {
        await todoRepository.setGoal(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          (ctx.args['title'] as String).trim(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'todos.clearGoal',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        await todoRepository.clearGoal(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // ---- Notification feed read marks ----
    // Both stamp the CALLER's own watermark row (`ctx.userId`, never a client
    // arg) with the server clock, so read state follows the user across
    // devices. `minRole: guest` matches the read floor — acknowledging your
    // own bell is not a workspace mutation.
    RepoOp(
      name: 'notifications.markAllRead',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.guest,
      handler: (ctx) async {
        await notificationFeedRepository.markAllRead(
          ctx.workspaceId!,
          ctx.userId,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'notifications.clear',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.guest,
      handler: (ctx) async {
        await notificationFeedRepository.clearAll(
          ctx.workspaceId!,
          ctx.userId,
        );
        return {'ok': true};
      },
    ),
    // Durable supervised goals (`/goal` + `/loop`) — NOT the per-conversation
    // working goal above: these pause / resume / cancel the supervisor's
    // persisted `AgentGoalRun`s.
    ...agentGoalRunOps(
      pauseGoal: goalSupervisor.pauseGoal,
      resumeGoal: goalSupervisor.resumeGoal,
      cancelGoal: goalSupervisor.cancelGoal,
    ),
    // ---- Fleet scaling & remote execution (PRD 20) ----
    // Built in the runtime (where the scheduler + repository live) and spliced
    // in here so this hub file stays agnostic of the fleet wiring.
    ...extraOps,
    // v17: action_policy.* (PRD 24 agent-permissions surface).
    // v18: skills.registry* (PRD 23 registry browse/preview/install).
    // v19: dictation.* (PRD 25 voice dictation over RPC).
    // v20: workspace_settings.* (workspace-scoped settings store).
    // v21: server_settings.* (install-wide settings store).
    // v22: notifications.* (durable per-workspace notification feed +
    //      per-user read marks; the bell moved out of device-local prefs).
  ], catalogVersion: 22);

  final watch = WatchQueryRegistry([
    // ---- Deterministic sync (PRD 16 §6) ----
    if (syncFeed != null)
      WatchQuery(
        name: 'sync.watch',
        handler: (ctx) {
          final store = ctx.args['store'];
          if (store is! String || store.isEmpty) {
            throw const ValidationException('store must be a non-empty string');
          }
          return syncFeed.watch(ctx.workspaceId!, store);
        },
      ),
    if (workspaceDbs != null) ...[
      WatchQuery(
        name: 'notes.watchForChannel',
        handler: (ctx) async* {
          final channelId = ctx.args['channel_id'] as String? ?? '';
          await assertChannelOwned(ctx.workspaceId!, channelId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .watchNoteForChannel(ctx.workspaceId!, channelId)
              .map(
                (row) => {'note': row == null ? null : channelNoteToWire(row)},
              );
        },
      ),
      WatchQuery(
        name: 'autonomy.watchForChannel',
        handler: (ctx) async* {
          final channelId = ctx.args['channel_id'] as String? ?? '';
          await assertChannelOwned(ctx.workspaceId!, channelId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .watchAutonomyForChannel(ctx.workspaceId!, channelId)
              .map(
                (rows) => {
                  'autonomy': [
                    for (final r in rows)
                      {'agent_id': r.agentId, 'level': r.autonomyLevel},
                  ],
                },
              );
        },
      ),
      WatchQuery(
        name: 'reactions.watchForChannel',
        handler: (ctx) async* {
          final channelId = ctx.args['channel_id'] as String? ?? '';
          await assertChannelOwned(ctx.workspaceId!, channelId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .channelExtrasDao
              .watchReactionsForChannel(ctx.workspaceId!, channelId)
              .map((rows) => {'reactions': rows.map(reactionToWire).toList()});
        },
      ),
    ],
    // ---- Presence lane (PRD 16 §1) ----
    // The workspace roster: humans + agents as co-equal principals. The
    // `tier` arg picks the consumer's coalescing budget (`summary` = phone).
    // Workspace-scoped: membership is enforced before the stream opens, so
    // presence never crosses a workspace boundary.
    if (presenceHub != null)
      WatchQuery(
        name: 'presence.watch',
        handler: (ctx) {
          final tier = ctx.args['tier'] == 'summary'
              ? PresenceCadence.summaryTierMinInterval
              : PresenceCadence.fullTierMinInterval;
          return presenceHub
              .watch(ctx.workspaceId!, minInterval: tier)
              .map((roster) => {'participants': roster});
        },
      ),
    // ---- Identity & membership (live counterparts of the identity ops) ----
    if (identityUsers != null &&
        identityMembers != null &&
        identityInvites != null &&
        identityActivity != null &&
        identityPrefs != null) ...[
      // CROSS-WORKSPACE BY DESIGN — identity is global; authorship display in
      // shared channels needs every co-member's name/avatar. Handles/display
      // names are directory data on a self-hosted server, not a secret.
      WatchQuery(
        name: 'users.watchAll',
        workspaceScoped: false,
        handler: (ctx) => identityUsers.watchAll().map(
          (users) => {'users': users.map(userToWire).toList()},
        ),
      ),
      WatchQuery(
        name: 'members.watchForWorkspace',
        handler: (ctx) => identityMembers
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (members) => {
                'members': members.map(workspaceMemberToWire).toList(),
              },
            ),
      ),
      WatchQuery(
        name: 'invites.watchForWorkspace',
        handler: (ctx) => identityInvites
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (invites) => {
                'invites': invites.map(workspaceInviteToWire).toList(),
              },
            ),
      ),
      WatchQuery(
        name: 'activity.watchForWorkspace',
        handler: (ctx) => identityActivity
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (entries) => {
                'entries': entries.map(userActivityToWire).toList(),
              },
            ),
      ),
      // The session user's OWN preferences (`ctx.userId`, never a client arg)
      // — the stream that makes a theme change on one device appear on the
      // user's others.
      WatchQuery(
        name: 'prefs.watchOwn',
        workspaceScoped: false,
        handler: (ctx) =>
            identityPrefs.watchAll(ctx.userId).map((prefs) => {'prefs': prefs}),
      ),
      // The session user's OWN devices (list/rename/revoke live-updates).
      // CROSS-WORKSPACE BY DESIGN — devices are global; scoped per user.
      WatchQuery(
        name: 'pairing.watchOwn',
        workspaceScoped: false,
        handler: (ctx) => pairedDeviceDao
            .watchForUser(ctx.userId)
            .map(
              (devices) => {
                'devices': [
                  for (final d in devices) pairedDeviceToWire(d, null),
                ],
              },
            ),
      ),
    ],
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
    // In-editor navigation → app tabs: the bundled bridge extension reports a
    // file the user navigated the embedded editor to; the client (subscribed
    // per conversation) opens it as a NEW app tab and the editor stays pinned on
    // its entry file. Workspace-scoped (the service stream filters on it); the
    // optional `channel_id` arg narrows to one conversation. Registered only when
    // the host runs code-server.
    if (vscode != null)
      WatchQuery(
        name: 'codeServer.watchOpenRequests',
        handler: (ctx) {
          final channel = ctx.args['channel_id'] as String?;
          return vscode
              .watchOpenRequests(ctx.workspaceId!)
              .where((r) => channel == null || r.channelId == channel)
              .map(
                (r) => {
                  'channel_id': r.channelId,
                  'repo_id': r.repoId,
                  'path': r.path,
                  if (r.line != null) 'line': r.line,
                },
              );
        },
      ),
    // Unsaved-changes reporting: the bridge extension reports each file's
    // dirty↔clean transitions; the client (subscribed per conversation) toggles
    // the per-tab unsaved-changes dot. Workspace-scoped (the service stream
    // filters on it); `channel_id` narrows to one conversation.
    if (vscode != null)
      WatchQuery(
        name: 'codeServer.watchDirtyState',
        handler: (ctx) {
          final channel = ctx.args['channel_id'] as String?;
          return vscode
              .watchDirtyState(ctx.workspaceId!)
              .where((e) => channel == null || e.channelId == channel)
              .map(
                (e) => {
                  'channel_id': e.channelId,
                  'repo_id': e.repoId,
                  'path': e.path,
                  'dirty': e.dirty,
                },
              );
        },
      ),
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
        ctx.workspaceId!,
      ),
    ),
    WatchQuery(
      name: 'project.watchForWorkspace',
      handler: (ctx) => projectRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map((list) => {'projects': list.map(projectToWire).toList()}),
    ),
    if (syncConfigRepository != null)
      WatchQuery(
        name: 'ticket_sync_config.watchForWorkspace',
        handler: (ctx) => syncConfigRepository
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (list) => {'configs': list.map(ticketSyncConfigToWire).toList()},
            ),
      ),
    if (syncLogRepository != null)
      WatchQuery(
        name: 'ticket_sync_log.watchForWorkspace',
        handler: (ctx) => syncLogRepository
            .watchForWorkspace(ctx.workspaceId!)
            .map((list) => {'logs': list.map(ticketSyncLogToWire).toList()}),
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
      handler: (ctx) => agentRepository.watchAll().map(
        (list) => {'agents': list.map(agentToWire).toList()},
      ),
    ),
    // A workspace's repos, in the operator's manual order. Workspace-scoped:
    // repos live inside a workspace, so there is no all-repos-on-this-server
    // subscription to offer.
    WatchQuery(
      name: 'repos.watchAll',
      handler: (ctx) => repoRepository
          .watchAll(ctx.workspaceId!)
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
        // Conversation (stream) inside the channel; defaults to `main` (== the
        // channel id) when the client doesn't scope it.
        final conversationId =
            ctx.args['conversation_id'] as String? ?? channelId;
        // Validate ownership once, before streaming any rows.
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* messagingRepository
            .watchMessages(ctx.workspaceId!, channelId, conversationId)
            .map((list) => {'messages': list.map(messageToWireLite).toList()});
      },
    ),
    // Windowed feed watch: newest-N messages of a conversation + has_more,
    // computed SERVER-side (the DAO's windowed query) so a long conversation
    // never ships its full history per emission. `loadMore` re-subscribes with
    // a larger limit. Emissions use the lite wire (segments elided).
    WatchQuery(
      name: 'messaging.watchMessagesWindow',
      handler: (ctx) async* {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        final conversationId =
            ctx.args['conversation_id'] as String? ?? channelId;
        final limit = ((ctx.args['limit'] as num?)?.toInt() ?? 60).clamp(
          1,
          2000,
        );
        await assertChannelOwned(ctx.workspaceId!, channelId);
        yield* messagingRepository
            .watchMessagesWindow(
              ctx.workspaceId!,
              channelId,
              conversationId,
              limit: limit,
            )
            .map(
              (w) => {
                'messages': w.messages.map(messageToWireLite).toList(),
                'has_more': w.hasMore,
              },
            );
      },
    ),
    // Live turn relay: seed snapshot of every active turn in the channel, then
    // coalesced per-segment updates straight from the dispatch stack's
    // ActiveStreamRegistry — the streaming path, decoupled from DB flushes.
    // Registered only on a host that runs the dispatch stack.
    if (streamRegistry != null)
      WatchQuery(
        name: 'messaging.watchChannelTurns',
        handler: (ctx) async* {
          final channelId = ctx.args['channel_id'] as String?;
          if (channelId == null) {
            throw const NotFoundException('Missing channel_id');
          }
          await assertChannelOwned(ctx.workspaceId!, channelId);
          final restricted = await viewerTraceRestricted(
            ctx.workspaceId!,
            channelId,
            ctx.userId,
          );
          final frames = watchChannelTurnFrames(streamRegistry, channelId);
          yield* restricted ? frames.map(redactTurnFrame) : frames;
        },
      ),
    // One run's activity timeline, live. Seeds from the in-memory registry while
    // the run streams, else from the persisted timeline with `live: false` — so
    // ONE op serves both a running run and a finished one being re-read.
    // Registered only on a host that runs the dispatch stack.
    if (streamRegistry != null)
      WatchQuery(
        name: 'agent_run_log.watchRunTranscript',
        handler: (ctx) async* {
          final runId = ctx.args['run_id'] as String?;
          if (runId == null) {
            throw const NotFoundException('Missing run_id');
          }
          // The registry is workspace-blind, so the run row is the only
          // isolation boundary. Check it BEFORE yielding anything.
          final run = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (run == null) {
            throw const NotFoundException('Agent run log not found');
          }
          if (run.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Agent run log belongs to a different workspace',
            );
          }
          // Replay covers BOTH stores: a subagent's `run_transcripts` row and a
          // top-level run's own `agent_turn` message (`messageId == runLog.id`).
          // The live lane needs no such split — the registry is keyed by that
          // same shared id — which is why only replay-after-restart was blank.
          final persisted = streamRegistry.isActive(runId)
              ? const <TranscriptSegment>[]
              : (await loadRunReplay(ctx.workspaceId!, runId)).segments;
          final restricted = await viewerTraceRestricted(
            ctx.workspaceId!,
            run.channelId ?? run.conversationId ?? '',
            ctx.userId,
          );
          final frames = watchRunTranscriptFrames(
            streamRegistry,
            runId,
            persisted: persisted,
          );
          yield* restricted ? frames.map(redactRunTranscriptFrame) : frames;
        },
      ),
    // Per-channel activity signals for the whole bound workspace in ONE
    // subscription: unread-dot + needs-input + attention-count sources.
    if (watchChannelActivity != null)
      WatchQuery(
        name: 'messaging.watchChannelActivity',
        handler: (ctx) => watchChannelActivity(
          ctx.workspaceId!,
        ).map((list) => {'channels': list.map((a) => a.toJson()).toList()}),
      ),
    // Conversations (streams) inside a channel: main + open parentheses.
    if (watchConversationsForChannel != null)
      WatchQuery(
        name: 'conversation.watchForChannel',
        handler: (ctx) async* {
          final channelId = ctx.args['channel_id'] as String?;
          if (channelId == null) {
            throw const NotFoundException('Missing channel_id');
          }
          await assertChannelOwned(ctx.workspaceId!, channelId);
          yield* watchConversationsForChannel(ctx.workspaceId!, channelId).map(
            (list) => {'conversations': list.map(conversationToWire).toList()},
          );
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
        yield* messagingRepository
            .watchParticipants(ctx.workspaceId!, channelId)
            .map(
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
      handler: (ctx) => workspaceRepository.watchAll().map(
        (list) => {'workspaces': list.map(workspaceToWire).toList()},
      ),
    ),
    // CROSS-WORKSPACE BY DESIGN: the repo-link join is queryable for any
    // A named workspace's repos. Workspace-scoped, so the id is the access gate
    // rather than a selector: reading another workspace's repo list requires
    // membership of that workspace. Mirrors
    // WorkspaceRepository.watchReposForWorkspace.
    WatchQuery(
      name: 'workspace.watchReposForWorkspace',
      handler: (ctx) => workspaceRepository
          .watchReposForWorkspace(ctx.workspaceId!)
          .map((list) => {'repos': list.map(repoToWire).toList()}),
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
            .watchUserLastReadAt(ctx.workspaceId!, channelId, ctx.userId)
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
          .map(
            (list) => {'grants': list.map(memoryAccessGrantToWire).toList()},
          ),
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
                'memory': memory == null
                    ? null
                    : agentWorkingMemoryToWire(memory),
              },
            );
      },
    ),
    WatchQuery(
      name: 'agent_working_memory.watchByWorkspace',
      handler: (ctx) => agentWorkingMemoryRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map(
            (list) => {'memories': list.map(agentWorkingMemoryToWire).toList()},
          ),
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
    if (providerPolicy != null)
      WatchQuery(
        name: 'provider_policy.watchForWorkspace',
        handler: (ctx) => providerPolicy
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (list) => {'policies': list.map(providerPolicyToWire).toList()},
            ),
      ),
    if (serverSettingsRepository != null)
      WatchQuery(
        name: 'server_settings.watch',
        handler: (ctx) => serverSettingsRepository.watchAll().map(
          (settings) => {'settings': settings},
        ),
      ),
    if (workspaceSettingsRepository != null)
      WatchQuery(
        name: 'workspace_settings.watchForWorkspace',
        handler: (ctx) => workspaceSettingsRepository
            .watchAll(ctx.workspaceId!)
            .map((settings) => {'settings': settings}),
      ),
    if (actionPolicyRepository != null)
      WatchQuery(
        name: 'action_policy.watchForWorkspace',
        handler: (ctx) => actionPolicyRepository
            .watchRules(ctx.workspaceId!)
            .map(
              (list) => {
                'rules': [
                  for (final r in list)
                    ActionPolicyRuleDto.fromEntity(r).toJson(),
                ],
              },
            ),
      ),
    WatchQuery(
      name: 'review_channel.watchByWorkspace',
      handler: (ctx) => reviewChannelRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map(
            (list) => {'associations': list.map(reviewChannelToWire).toList()},
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
        return reviewChannelRepository
            .watchByChannel(ctx.workspaceId!, channelId)
            .map(
              (a) => {
                'association': (a == null || a.workspaceId != ctx.workspaceId)
                    ? null
                    : reviewChannelToWire(a),
              },
            );
      },
    ),
    WatchQuery(
      name: 'review_channel.watchAllByChannel',
      handler: (ctx) {
        final channelId = ctx.args['channel_id'] as String?;
        if (channelId == null) {
          throw const NotFoundException('Missing channel_id');
        }
        // Workspace-scoped at the query level (the bound workspace), so a
        // foreign-workspace association is never emitted (isolation invariant).
        return reviewChannelRepository
            .watchAllByChannel(ctx.workspaceId!, channelId)
            .map(
              (list) => {
                'associations': list.map(reviewChannelToWire).toList(),
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
    // All runs (active + completed) for a conversation, for the run-tree UI
    // (parent dispatch + its ephemeral subagent runs).
    WatchQuery(
      name: 'agent_run_log.watchByConversation',
      handler: (ctx) => agentRunLogRepository
          .watchByConversation(
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
      handler: (ctx) => agentRunLogRepository.watchAll().map(
        (list) => {'logs': list.map(agentRunLogToWire).toList()},
      ),
    ),
    // CROSS-WORKSPACE BY DESIGN: the bounded companion to
    // `agent_run_log.watchAll` — only the newest `limit` rows are read and
    // shipped per change, so a client dashboard doesn't force the server to
    // re-materialize (and re-encode) the entire run history on every run-log
    // write. Prefer this from any live UI surface.
    WatchQuery(
      name: 'agent_run_log.watchRecent',
      workspaceScoped: false,
      handler: (ctx) {
        // Clamp to a sane ceiling so a buggy/malicious client can't turn the
        // bounded op back into a full-table watch.
        final requested = (ctx.args['limit'] as num?)?.toInt() ?? 1000;
        final limit = requested.clamp(1, 5000);
        return agentRunLogRepository
            .watchRecent(limit)
            .map((list) => {'logs': list.map(agentRunLogToWire).toList()});
      },
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
        return Stream.fromFuture(
          teamRepository.getTeam(ctx.workspaceId!, teamId),
        ).asyncExpand((team) {
          if (team == null || team.workspaceId != ctx.workspaceId) {
            return Stream<Map<String, dynamic>>.error(
              const WorkspaceMismatchException(
                'Team belongs to a different workspace',
              ),
            );
          }
          return teamRepository
              .watchMembersOf(ctx.workspaceId!, teamId)
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
            .map(
              (list) => {'segments': list.map(meetingSegmentToWire).toList()},
            );
      },
    ),
    if (dictationService != null)
      WatchQuery(
        name: 'dictation.watchPartials',
        handler: (ctx) {
          final id = ctx.args['dictation_id'] as String?;
          if (id == null) {
            throw const NotFoundException('Missing dictation_id');
          }
          // The session id is server-minted and workspace-prefixed; a client
          // watching a foreign id gets an empty stream (unknown session).
          return dictationService
              .watch(id)
              .map((p) => {'text': p.text, 'is_final': p.isFinal});
        },
      ),
    WatchQuery(
      name: 'meeting.watchSpeakers',
      handler: (ctx) {
        final meetingId = ctx.args['meeting_id'] as String?;
        if (meetingId == null) {
          throw const NotFoundException('Missing meeting_id');
        }
        return meetingRepository
            .watchSpeakers(ctx.workspaceId!, meetingId)
            .map(
              (list) => {
                'speakers': list.map(meetingSpeakerLabelToWire).toList(),
              },
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
            .map(
              (list) => {'items': list.map(meetingActionItemToWire).toList()},
            );
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
            .map(
              (list) => {'decisions': list.map(meetingDecisionToWire).toList()},
            );
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
          .map(
            (list) => {'accounts': list.map(calendarAccountToWire).toList()},
          ),
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
                (list) => {'entries': list.map(activityEntryToWire).toList()},
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
      handler: (ctx) => pipelineRunRepository.watchAll().map(
        (list) => {'runs': list.map(pipelineRunToWire).toList()},
      ),
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
              (list) => {'step_runs': list.map(pipelineStepRunToWire).toList()},
            );
      },
    ),
    WatchQuery(
      name: 'pipeline_template.watchForWorkspace',
      handler: (ctx) => pipelineTemplateRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map(
            (list) => {'templates': list.map(pipelineTemplateToWire).toList()},
          ),
    ),
    WatchQuery(
      name: 'pipeline_trigger.watchForWorkspace',
      handler: (ctx) => pipelineTriggerRepository
          .watchForWorkspace(ctx.workspaceId!)
          .map(
            (list) => {
              'triggers': list.map(pipelineTriggerEntityToWire).toList(),
            },
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
    // ---- Plan Studio (PRD 17): live plan documents / revisions / playbooks --
    if (revisionsRepo != null)
      WatchQuery(
        name: 'orchestration.watchRevisions',
        handler: (ctx) => revisionsRepo
            .watchForOrchestration(
              ctx.workspaceId!,
              ctx.args['orchestration_id'] as String,
            )
            .map(
              (list) => {
                'revisions': list.map(orchestrationRevisionToWire).toList(),
              },
            ),
      ),
    if (plansRepo != null) ...[
      WatchQuery(
        name: 'plan.watchForWorkspace',
        handler: (ctx) => plansRepo
            .watchForWorkspace(ctx.workspaceId!)
            .map((list) => {'plans': list.map(planDocumentToWire).toList()}),
      ),
      WatchQuery(
        name: 'plan.watchById',
        handler: (ctx) => plansRepo
            .watchById(ctx.workspaceId!, ctx.args['plan_id'] as String)
            .map((d) => {'plan': d == null ? null : planDocumentToWire(d)}),
      ),
    ],
    // ---- Work products / artifacts (live) ----
    if (workProductsRepo != null) ...[
      // One artifact, live: the artifact bubble carries ids only and watches
      // the row, so a `revise_artifact` re-renders the existing card instead of
      // posting a second message into the conversation.
      //
      // Derived from the workspace stream (the repository has no per-id watch)
      // and de-duplicated, so an unrelated artifact's revision does not wake
      // every open bubble.
      WatchQuery(
        name: 'workProduct.watchById',
        handler: (ctx) {
          final productId = ctx.args['work_product_id'] as String;
          return workProductsRepo
              .watchByWorkspace(ctx.workspaceId!)
              .map((list) => list.where((p) => p.id == productId).firstOrNull)
              .distinct()
              .map(
                (p) => {
                  'work_product': p == null ? null : workProductToWire(p),
                },
              );
        },
      ),
      // Every artifact published into one conversation, newest first.
      //
      // The association lives in the conversation's `artifact` messages
      // (`metadata['workProductId']`), NOT in a column: `work_products` is
      // reused as-is, with no schema migration. So this streams the
      // conversation's messages, projects the artifact ids, and only re-reads
      // the rows when that id list actually changes — a chatty channel must not
      // turn into a query per message.
      WatchQuery(
        name: 'workProduct.watchForChannel',
        handler: (ctx) async* {
          final workspaceId = ctx.workspaceId!;
          final channelId = ctx.args['channel_id'] as String;
          final conversationId =
              ctx.args['conversation_id'] as String? ?? channelId;
          // Messages are keyed by channel only, so ownership is checked here
          // before anything streams (workspace-isolation invariant).
          if (!await channelInWorkspace(workspaceId, channelId)) {
            throw const NotFoundException(
              'Channel not found in this workspace',
            );
          }
          yield* messagingRepository
              .watchMessages(ctx.workspaceId!, channelId, conversationId)
              .map((messages) {
                final ids = <String>[];
                for (final m in messages) {
                  if (m.messageType != ChannelMessageType.artifact) {
                    continue;
                  }
                  final id = m.metadata?['workProductId'];
                  if (id is String && id.isNotEmpty && !ids.contains(id)) {
                    ids.add(id);
                  }
                }
                return ids;
              })
              .distinct((a, b) => a.join(' ') == b.join(' '))
              .asyncMap((ids) async {
                final wire = <Map<String, dynamic>>[];
                // Newest first: messages arrive oldest-first.
                for (final id in ids.reversed) {
                  final product = await workProductsRepo.getById(
                    workspaceId,
                    id,
                  );
                  if (product != null) {
                    wire.add(workProductToWire(product));
                  }
                }
                return {'work_products': wire};
              });
        },
      ),
    ],
    if (playbooksRepo != null)
      WatchQuery(
        name: 'playbook.watchForWorkspace',
        handler: (ctx) => playbooksRepo
            .watchForWorkspace(ctx.workspaceId!)
            .map((list) => {'playbooks': list.map(playbookToWire).toList()}),
      ),

    // ---- Review Studio (PRD 18): live cohorts / contract / visual / axes ----
    // Each watch validates the workspace owns (owner, repo) before streaming
    // (isolation), then keys by the synthetic PR node key.
    if (reviewCohortRepository != null)
      WatchQuery(
        name: 'review_studio.watchCohorts',
        handler: (ctx) async* {
          final c = requireRepoCoords(ctx.args);
          await resolvePrReviewRepository(
            ctx.workspaceId!,
            c.owner,
            c.repo,
            userId: ctx.userId,
          );
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: (ctx.args['pr_number'] as num).toInt(),
                )
              : reviewPrNodeKey(
                  c.owner,
                  c.repo,
                  (ctx.args['pr_number'] as num).toInt(),
                );
          yield* reviewCohortRepository
              .watchForPr(ctx.workspaceId!, key)
              .map((list) => {'cohorts': list.map((x) => x.toJson()).toList()});
        },
      ),
    if (apiContractDiffRepository != null)
      WatchQuery(
        name: 'review_studio.watchContractDiffs',
        handler: (ctx) async* {
          final c = requireRepoCoords(ctx.args);
          await resolvePrReviewRepository(
            ctx.workspaceId!,
            c.owner,
            c.repo,
            userId: ctx.userId,
          );
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: (ctx.args['pr_number'] as num).toInt(),
                )
              : reviewPrNodeKey(
                  c.owner,
                  c.repo,
                  (ctx.args['pr_number'] as num).toInt(),
                );
          yield* apiContractDiffRepository
              .watchForPr(ctx.workspaceId!, key)
              .map((list) => {'diffs': list.map((x) => x.toJson()).toList()});
        },
      ),
    if (visualDiffRepository != null)
      WatchQuery(
        name: 'review_studio.watchVisualDiffs',
        handler: (ctx) async* {
          final c = requireRepoCoords(ctx.args);
          await resolvePrReviewRepository(
            ctx.workspaceId!,
            c.owner,
            c.repo,
            userId: ctx.userId,
          );
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: (ctx.args['pr_number'] as num).toInt(),
                )
              : reviewPrNodeKey(
                  c.owner,
                  c.repo,
                  (ctx.args['pr_number'] as num).toInt(),
                );
          yield* visualDiffRepository
              .watchForPr(ctx.workspaceId!, key)
              .map(
                (list) => {'snapshots': list.map((x) => x.toJson()).toList()},
              );
        },
      ),
    if (reviewAxisResultRepository != null)
      WatchQuery(
        name: 'review_studio.watchAxisResults',
        handler: (ctx) async* {
          final c = requireRepoCoords(ctx.args);
          await resolvePrReviewRepository(
            ctx.workspaceId!,
            c.owner,
            c.repo,
            userId: ctx.userId,
          );
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: (ctx.args['pr_number'] as num).toInt(),
                )
              : reviewPrNodeKey(
                  c.owner,
                  c.repo,
                  (ctx.args['pr_number'] as num).toInt(),
                );
          yield* reviewAxisResultRepository
              .watchForPr(ctx.workspaceId!, key)
              .map((list) => {'axes': list.map((x) => x.toJson()).toList()});
        },
      ),

    // ---- Live open-PR list (workspace-scoped) ----
    // The push counterpart of `pr.listOpenForWorkspace`: streams the poller's
    // snapshot (same wire shape) and re-emits whenever a sweep lands a change.
    // Subscribing registers watcher interest, which switches the workspace to
    // the fast polling cadence. Token-less hosts answer `authenticated: false`
    // once (mirroring the one-shot op) so the client can gate on it.
    WatchQuery(
      name: 'pr.watchOpenForWorkspace',
      handler: (ctx) async* {
        final poller = openPrPoller;
        if (poller == null) {
          yield {'authenticated': false, 'repos': <Map<String, dynamic>>[]};
          return;
        }
        yield* poller.watchOpenForWorkspace(ctx.workspaceId!);
      },
    ),

    // ---- Needs-my-review count (workspace-scoped, lite) ----
    // The count of open PRs requesting the SERVER user's review, derived from
    // the poller's snapshot stream. A deliberate lite feed for the sidebar's
    // always-on inbox badge: the client subscribes to a single int instead
    // of holding the full open-PR list (titles, bodies, checks) resident for
    // the whole session just to render a number.
    WatchQuery(
      name: 'pr.watchNeedsMyReviewCount',
      handler: (ctx) async* {
        final poller = openPrPoller;
        if (poller == null) {
          yield {'count': 0};
          return;
        }
        final user = await fetchCurrentGitHubUser?.call();
        final login = (user?['login'] as String?)?.toLowerCase() ?? '';
        if (login.isEmpty) {
          yield {'count': 0};
          return;
        }
        final teams = await fetchViewerGitHubTeams?.call() ?? const {};
        var last = -1;
        await for (final snapshot in poller.watchOpenForWorkspace(
          ctx.workspaceId!,
        )) {
          var count = 0;
          for (final repo in (snapshot['repos'] as List?) ?? const []) {
            if (repo is! Map) {
              continue;
            }
            for (final pr in (repo['prs'] as List?) ?? const []) {
              if (pr is! Map) {
                continue;
              }
              if (prCountsTowardNeedsMyReview(
                pr,
                login,
                viewerTeamsByOrg: teams,
              )) {
                count++;
              }
            }
          }
          if (count != last) {
            last = count;
            yield {'count': count};
          }
        }
      },
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
          userId: ctx.userId,
        );
        yield* repo
            .watchPullRequest((ctx.args['pr_number'] as num).toInt())
            .map(
              (pr) => {
                'pull_request': pr == null ? null : pullRequestToWire(pr),
              },
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
        );
        yield* repo
            .watchCommits((ctx.args['pr_number'] as num).toInt())
            .map(
              (commits) => {'commits': commits.map(prCommitToWire).toList()},
            );
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
          userId: ctx.userId,
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
      name: 'pr_review.watchTimelineEvents',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        yield* repo
            .watchTimelineEvents((ctx.args['pr_number'] as num).toInt())
            .map(
              (events) => {
                'events': events.map(prTimelineEventToWire).toList(),
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
          userId: ctx.userId,
        );
        yield* repo
            .watchCheckRuns((ctx.args['pr_number'] as num).toInt())
            .map((runs) => {'check_runs': runs.map(checkRunToWire).toList()});
      },
    ),
    WatchQuery(
      name: 'pr_review.watchCommitStatuses',
      handler: (ctx) async* {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        yield* repo
            .watchCommitStatuses((ctx.args['pr_number'] as num).toInt())
            .map(
              (statuses) => {
                'statuses': statuses.map(commitStatusToWire).toList(),
              },
            );
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
          userId: ctx.userId,
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
    if (terminals != null) ...[
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
      // The session's foreground-process title (`{title}`; '' = shell at its
      // prompt) — the server polls the PTY's foreground process group so the
      // client tab can say "pnpm dev serve" while it runs, ghostty-style, even
      // when the shell never emits an OSC 0/2 title. Current title replays on
      // subscribe; same workspace-ownership validation as `terminal.output`.
      WatchQuery(
        name: 'terminal.titles',
        handler: (ctx) {
          final sessionId = ctx.args['session_id'] as String?;
          if (sessionId == null) {
            throw const NotFoundException('Missing session_id');
          }
          return terminals
              .titles(workspaceId: ctx.workspaceId!, sessionId: sessionId)
              .map((title) => {'title': title});
        },
      ),
    ],
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
    // ---- Governance (PRD 09; read-only) ----
    WatchQuery(
      name: 'goals.watchForWorkspace',
      handler: (ctx) => goalRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'goals': list.map(orgGoalToWire).toList()}),
    ),
    WatchQuery(
      name: 'approvals.watchForWorkspace',
      handler: (ctx) => approvalRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'approvals': list.map(approvalToWire).toList()}),
    ),
    // Per-conversation todo list (workspace-scoped; the conversation comes
    // from the client's `conversation_id` filter arg).
    WatchQuery(
      name: 'todos.watch',
      handler: (ctx) => todoRepository
          .watch(ctx.workspaceId!, ctx.args['conversation_id'] as String)
          .map((list) => {'todos': list.map(todoItemToWire).toList()}),
    ),
    // The conversation's working goal (or null), driving the goal accordion
    // the todos nest under.
    WatchQuery(
      name: 'todos.watchGoal',
      handler: (ctx) => todoRepository
          .watchGoal(ctx.workspaceId!, ctx.args['conversation_id'] as String)
          .map((g) => {'goal': g == null ? null : goalToWire(g)}),
    ),
    // The workspace's durable notification feed (newest-first stored
    // `notifications/*` frames; the client renders + principal-routes rows
    // through the same frame mapper it uses for live pushes) and the
    // CALLER's read mark (keyed on the session user, never a client arg).
    WatchQuery(
      name: 'notifications.watch',
      handler: (ctx) => notificationFeedRepository
          .watchFeed(ctx.workspaceId!)
          .map(
            (list) => {
              'items': list.map(notificationFeedItemToWire).toList(),
            },
          ),
    ),
    WatchQuery(
      name: 'notifications.watchReadMark',
      handler: (ctx) => notificationFeedRepository
          .watchReadMark(ctx.workspaceId!, ctx.userId)
          .map(
            (mark) => {
              'mark': mark == null ? null : notificationReadMarkToWire(mark),
            },
          ),
    ),
    // The conversation's durable supervised goals (`/goal` + `/loop`),
    // backing the client's goal-run list with pause / resume / cancel via
    // the `agentGoalRuns.*` ops.
    agentGoalRunsWatchQuery(agentGoalRunRepository: agentGoalRunRepository),
    // ---- Fleet reactive queries (PRD 20 §7) ----
    ...extraWatchQueries,
  ]);

  return (ops: ops, watch: watch);
}

/// Derives the invite-redemption HTTP endpoint from the advertised RPC
/// WebSocket URL. Returns '' when `rpcUrl` is empty/unparseable.
/// Display names for `presence.update` entries, cached so cursor-cadence
/// updates never turn into per-call user lookups. Names change rarely; a
/// stale entry self-heals on server restart (presence is ephemeral anyway).
final Map<String, String> _presenceNameCache = {};

String _redeemUrlFrom(String rpcUrl) {
  if (rpcUrl.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(rpcUrl);
  if (uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return uri.replace(scheme: scheme, path: '/invites/redeem').toString();
}

/// Derives the best HTTP-reachable redemption URL from a live descriptor.
///
/// Prefers non-loopback direct paths (tunnel > LAN > tailnet > public wss)
/// over the static `config.publicUrl`, so an invite created after starting a
/// tunnel or binding to the LAN points at the reachable address — not
/// localhost. Returns null when only loopback is available (the caller falls
/// back to the static URL; the client warns the operator).
String? _bestRedeemUrlFromDescriptor(ConnectionDescriptor? descriptor) {
  if (descriptor == null) {
    return null;
  }
  final sorted = [...descriptor.paths]
    ..sort((a, b) => a.rank.compareTo(b.rank));
  for (final path in sorted) {
    if (path is LoopbackPath) {
      continue; // unreachable off-host
    }
    final uri = path.rpcUri;
    if (uri == null) {
      continue; // relay — no HTTP endpoint
    }
    return _redeemUrlFrom(uri.toString());
  }
  return null;
}

/// The custom-provider definitions stored in [creds], when the store can
/// enumerate them (empty for stores that can't, e.g. an env-only store).
Future<List<ProviderCredential>> _customProviderDefs(
  ProviderCredentialStore creds,
) async {
  if (creds is! CustomProviderLister) {
    return const [];
  }
  return (creds as CustomProviderLister).customProviders();
}

/// The stored definition of the custom provider [providerId], or null when
/// [providerId] is a built-in or unknown provider.
Future<ProviderCredential?> _customProviderDef(
  ProviderCredentialStore creds,
  String providerId,
) async {
  if (harnessProviderMetas.containsKey(providerId)) {
    return null;
  }
  for (final def in await _customProviderDefs(creds)) {
    if (def.providerId == providerId) {
      return def;
    }
  }
  return null;
}
