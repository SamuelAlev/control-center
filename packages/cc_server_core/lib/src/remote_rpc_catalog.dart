import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/activity_log_reader.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';
import 'package:cc_domain/core/domain/ports/entitlements_port.dart';
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/ports/repo_script_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_cost_history_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_role_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/services/secret_exclusion.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/user_activity_page.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_routing_service.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_routing_policy.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/guard_decision_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_templates.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/ide/domain/code_server_port.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_stack_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/space_factory.dart';
import 'package:cc_domain/features/messaging/domain/services/stack_branch_names.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/save_orchestration_revision_use_case.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show SkillAnalysisTemplate;
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_source.dart';
import 'package:cc_domain/features/skills/domain/exceptions/skill_scan_blocked_exception.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_source_port.dart';
import 'package:cc_domain/features/skills/domain/repositories/skill_source_repository.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
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
        PairedDevicesTableCompanion,
        TicketsTableCompanion,
        WorkspaceDatabaseManager;
import 'package:cc_persistence/database/daos/paired_device_dao.dart'
    show PairedDeviceDao, PairedDeviceStatus;
import 'package:cc_rpc/cc_rpc.dart' show RemoteControlCrypto;
import 'package:cc_server_core/src/catalog/agent_goal_run_ops.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';
import 'package:cc_server_core/src/catalog/meeting_ops.dart';
import 'package:cc_server_core/src/catalog/model_control_ops.dart';
import 'package:cc_server_core/src/catalog/pr_review_ops.dart';
import 'package:cc_server_core/src/catalog/space_stack_ops.dart';
import 'package:cc_server_core/src/catalog/terminal_port_ops.dart';
import 'package:cc_server_core/src/catalog/worktree_branch_ops.dart';
import 'package:cc_server_core/src/cc_server_runtime.dart'
    show accountPoolKeyForLane;
import 'package:cc_server_core/src/collab/checker_listener.dart';
import 'package:cc_server_core/src/collab/takeover_service.dart';
import 'package:cc_server_core/src/connection/network_runtime.dart';
import 'package:cc_server_core/src/connection/server_descriptor_service.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/harness_model_override_cache.dart';
import 'package:cc_server_core/src/identity/approval_escalation_sweeper.dart';
import 'package:cc_server_core/src/identity/managed_policy_service.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/identity/workspace_profile.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:cc_server_core/src/pr_review/review_ci_signal_service.dart';
import 'package:cc_server_core/src/rig_rpc_ops.dart';
import 'package:cc_server_core/src/rig_wire.dart';
import 'package:cc_server_core/src/run_log_reader.dart';
import 'package:cc_server_core/src/skill_analysis_service.dart';
import 'package:cc_server_core/src/sync/sync_feed_service.dart';
import 'package:cc_server_core/src/usage/harness_usage_accounts.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

export 'catalog/agent_goal_run_ops.dart';
export 'catalog/catalog_wire.dart';
export 'catalog/meeting_ops.dart';
export 'catalog/model_control_ops.dart';
export 'catalog/pr_review_ops.dart';
export 'catalog/terminal_port_ops.dart';

/// The repo-RPC + watch-query registries a server exposes to first-party
/// clients (desktop-remote / web). `ops` are request/response operations;
/// `watch` are reactive subscriptions.
typedef RemoteRpcCatalog = ({RepoOpRegistry ops, WatchQueryRegistry watch});

/// Builds the live repo-RPC catalog from the real repositories/services — the
/// composition point that turns the protocol machinery into a concrete,
/// workspace-scoped surface covering tickets, messaging and newsfeed.
///
/// Builds the workspace-scoped RPC catalog.
///
/// Every workspace-scoped op/query sources its workspace from the session
/// binding, never from client args. Spaces are workspace-scoped, but messages
/// are keyed only by `space_id`, so message ops **validate space ownership**
/// against the session's workspace before touching them — an ID-only lookup is
/// not a scoping boundary (workspace-isolation invariant). Newsfeed is global
/// (`workspaceScoped: false`), a declared exemption.
RemoteRpcCatalog buildRemoteRpcCatalog({
  // Users are global; membership + roles + invites + per-repo grants +
  // the audit trail are workspace-scoped. Optional as a group: when null the
  // identity ops are absent (bare test catalogs); production always wires
  // them.
  UserRepository? userRepository,
  // Moves a review finding between statuses (fixed / dismissed / reopened),
  // through the one service that also leaves a trace in the room and feeds
  // the suppression memory on a dismissal.
  required ReviewFindingStatusPort reviewFindingStatus,
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
  // Content-addressed storage for images. Backs `blob.put`, which is how an
  // image a human pastes into the composer reaches the server: the bytes go
  // into the workspace's blob directory and the message keeps a reference, so
  // a screenshot never travels inside a message row. Optional: when null the
  // op is absent and the composer silently keeps text-only behaviour.
  BlobStore? blobStore,
  // The server-side pending-question map behind the `ask_user` tool.
  //
  // `AgentQuestionService.ask()` blocks on a Completer in the process running
  // the AGENT — this one. The human answers in a CLIENT, which persists the
  // answer by writing the question message's metadata through
  // `messaging.updateMessage`. That write never touches this process's
  // completer map, so without a hook here the asking agent sits out its whole
  // timeout while the form already reads "answered". `messaging.updateMessage`
  // therefore hands every metadata write to this service, which ignores
  // anything that is not an answered question. Optional: when null the
  // `ask_user` tool is simply not offered.
  AgentQuestionService? agentQuestions,
  required WorkspaceRepository workspaceRepository,
  // Workspace logo bytes over RPC. Prefer `/workspace/logo` when reachable;
  // relay-only clients (`RelayPath.probeUri` null) have no HTTP origin, so the
  // logo also rides this channel. Null → op absent; clients use the initial mark.
  Future<List<int>?> Function({required String workspaceId})?
  workspaceLogoBytes,
  required NewsfeedRepository newsfeedRepository,
  required AgentRepository agentRepository,
  required RepoRepository repoRepository,
  // Per-repo lifecycle scripts (setup/archive) + their recorded runs. Backs
  // the `repos.getScripts` / `repos.setScripts` / `repos.watchScriptRuns`
  // surface. Optional — when null those ops are absent (the repos settings
  // page hides its scripts affordance) and provisioning runs no scripts.
  RepoScriptRepository? repoScriptRepository,
  // The script EXECUTOR (the service the provisioner also uses). Backs
  // `repos.testScript` — a draft executed in a throwaway clone. Separate from
  // the repository above because the RPC client never executes anything: only
  // the server-side service can. Optional — when null the op is absent.
  RepoScriptPort? repoScripts,
  required SpaceReadRepository spaceReadRepository,
  required MemoryDomainRepository memoryDomainRepository,
  required MemoryAccessGrantRepository memoryAccessGrantRepository,
  required AgentWorkingMemoryRepository agentWorkingMemoryRepository,
  required MemoryFactRepository memoryFactRepository,
  required MemoryPolicyRepository memoryPolicyRepository,
  // Per-workspace allow/deny statements the model catalog's finalize consults
  // to drop denied providers. Optional: when null the ops are absent
  // (default-deny) and the governance UI degrades to read-only catalog browsing.
  ProviderPolicyRepository? providerPolicyRepository,
  // Unified action-guardrail policy store (PRD 24 §4): backs the agent-
  // permissions matrix + what-if probe ops. Optional — when null the ops are
  // absent (the policy surface degrades) and enforcement runs on built-in
  // defaults only.
  ActionPolicyRepository? actionPolicyRepository,
  // Custom (subtractive) workspace roles: back the `roles.*` ops and the
  // role editor. Optional — when null only the built-in presets exist, which
  // is every solo install.
  WorkspaceRoleRepository? workspaceRoleRepository,
  // The tamper-evident authorization audit spine: backs `audit.*` (list,
  // verify, export). Optional — when null the audit surface is absent.
  GuardDecisionRepository? guardDecisionRepository,
  // The install-wide MANAGED policy tier (owner-only): an operator clamp
  // merged most-restrictive with every workspace's own guardrails.
  ManagedPolicyService? managedPolicy,
  // What this install is entitled to. Consulted at op REGISTRATION, so an
  // unentitled capability's ops are genuinely absent rather than refused by
  // a runtime check a client could probe. Self-hosted answers true to
  // everything; the hosted tier is where this ever says no.
  EntitlementsPort entitlements = const AllEntitlements(),
  SandboxExecGrantRepository? sandboxExecGrantRepository,
  WorkspaceSettingsRepository? workspaceSettingsRepository,
  ServerSettingsRepository? serverSettingsRepository,
  // Skill bundle service + sources (PRD 23 §1/§3): back the `skills.*`
  // browse/preview/install/uninstall ops for the Skills settings surface.
  // Sources are the GitHub repositories the operator registers; install
  // always routes through the mandatory scan gate inside the service.
  // Optional — absent when no source wiring is present.
  SkillBundlePort? skillBundles,
  SkillSourceRepository? skillSources,
  SkillSourcePort? skillSourceCatalog,
  // The skills antivirus as a pipeline (PRD 23 §2/§6): backs the scan /
  // analyze ops with run recording (projection rows the Pipelines UI shows).
  // Optional — absent when the host wires no analysis service.
  SkillAnalysisService? skillAnalysis,
  // The raw scan gate, for listing what a SPACE's checked-out repos ship
  // (`skills.repoSkills`). The same port the dispatch-time projector uses, so
  // the composer's palette can only ever offer a skill a slash command will
  // actually load. Optional — absent when no scanner is wired.
  SkillScanPort? skillScanner,
  // Built-in harness provider/credential brain (PRD 13): the server-owned
  // credential store + OAuth broker back the `providers.*` ops so every client
  // (desktop/web/remote) manages API keys, browser logins and the live model
  // list over RPC. Optional: when null the `providers.*` ops are absent.
  ProviderCredentialStore? harnessCredentialStore,
  HarnessOAuthBroker? harnessOAuthBroker,
  HarnessProviderFactory harnessProviderFactory =
      const HarnessProviderFactory(),
  // The sync in-memory view of per-model overrides: the save/remove ops keep
  // it current so dispatch's modelResolver (also wrapped around it) sees a
  // fresh context window the moment the operator edits one. Optional — when
  // null the override ops are absent and listModels reads the store directly.
  HarnessModelOverrideCache? harnessModelOverrides,
  required ReviewSpaceRepository reviewSpaceRepository,
  required AgentRunLogRepository agentRunLogRepository,
  required IsolatedRepoRepository isolatedRepoRepository,
  required VoiceProfileRepository voiceProfileRepository,
  required MeetingRepository meetingRepository,
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
  // The thin client READS this surface only: the goal hierarchy, board
  // approvals + their comment threads and computed agent presence (availability
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
  // The manual-pairing posture: when this returns false, `pairing.mint`
  // refuses (SSO-only onboarding — new devices must arrive via an SSO login,
  // which mints through the internal seam, not through this op). Null leaves
  // pairing ungated (tests, bare catalogs).
  Future<bool> Function()? manualPairingEnabled,
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
  // Builds the server's live ConnectionDescriptor (every reachable path +
  // the pinned identity fingerprint). When null, `connection.describe` is
  // absent and `pairing.mint`/invites omit the descriptor (bare test
  // catalogs); production always wires it.
  ServerDescriptorService? descriptorService,
  // The network runtime behind the `connectivity.*` ops: share-this-server
  // tunnel control, mDNS state and relay-usage accounting. A deferred
  // closure (like [ticketSyncNow]) because the runtime is constructed after
  // this catalog during bootstrap; resolved per request. Optional: when null
  // those ops are absent (bare test catalogs).
  NetworkRuntime? Function()? networkRuntime,
  // The in-memory hub behind `presence.update` / `presence.watch`. Presence
  // is NEVER persisted — no repository, no table, no DAO. Optional: when
  // null the presence ops are absent (bare test catalogs).
  PresenceHub? presenceHub,
  // The authoritative delta feed behind `sync.watch` / `sync.pull`, plus the
  // DAOs backing the per-column LWW ticket patch and the space extras
  // (Notes doc, autonomy dial, reactions). Optional as a group: when null
  // those ops are absent and every store stays in snapshot mode.
  SyncFeedService? syncFeed,
  // The per-workspace databases, for the handful of ops that reach a DAO
  // directly rather than through a repository (space notes / reactions /
  // autonomy). Each resolves `workspaceDbs.of(ctx.workspaceId!)`, so the bound
  // workspace picks the database file before any SQL runs.
  WorkspaceDatabaseManager? workspaceDbs,
  // Optional as a group: absent in bare test catalogs.
  TakeoverService? takeoverService,
  // The thin client READS this surface (synced events + connected accounts) and
  // drives the GUI connect over [calendarConnect] (below). The sync reconciler,
  // token refresh and alert sweep all run host-side against the host-resident
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
  // PR draft CRUD over RPC. Every op uses `ctx.workspaceId!`; id-keyed ops
  // validate workspace ownership. Resolved per acting user so publish carries
  // their forge identity (not the app's).
  required PrLifecycleRepository Function(String? actingUserId)
  prLifecycleRepositoryFor,
  // The audit trail for one entity (the `activity_log` table; workspace-scoped).
  // Optional: when null the `activity.watchForEntity` subscription is simply
  // absent (default-deny) and a client's entity-timeline view degrades to empty.
  // Wired on hosts that own the Drift `activity_log` DAO (the desktop in-process
  // host + the headless cc_server).
  ActivityLogReader? activityLogReader,
  // Builds a cached `PrReviewRepository` per (workspace, forge, owner, repo).
  // Null → empty `pr_review.*` surface. Resolved per acting user — shared
  // registry would attribute every mutation to the server identity.
  ForgeProviderRegistry Function(String? actingUserId, {String? workspaceId})?
  forgeProviderRegistryFor,
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
  // The CALLER's merged PR history across a workspace's repos, resolved per
  // forge under that caller's own per-forge viewer identity. Null → empty.
  Future<List<({Repo repo, List<PullRequest> prs, bool hasMore})>> Function(
    List<Repo> repos, {
    String? userId,
    String? workspaceId,
  })?
  fetchMergedHistory,
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
  // Fetches live subscription-usage quotas (Claude/Codex/Cursor/z.ai/Kimi)
  // for the `subscriptions.usage` op. Null → the op returns an empty list.
  SubscriptionUsageFetcher? fetchSubscriptionUsage,
  // The Claude Code login store behind the `claude_accounts.*` ops: one
  // config dir per account, so an operator can pick which login a run uses.
  // Server-side only; null ⇒ the ops are omitted.
  ClaudeAccountStore? claudeAccounts,
  // Per-account 5h/weekly quota, so the picker can show which login still has
  // headroom. Null ⇒ accounts list without usage.
  ClaudeAccountUsageFetcher? fetchClaudeAccountUsage,
  // Klipy GIF search / trending for the composer's GIF picker. Null (no Klipy
  // app key) → the `gif.*` ops return empty.
  GifSearchFetcher? gifSearch,
  GifTrendingFetcher? gifTrending,
  // The workspace-scoped cache backing the SWR PR/commit reference previews.
  // Optional: when null, previews skip caching and hit the fetcher directly.
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
  // Per-forge credential store, backing the `forge.*` and
  // `credentials.*ForgeToken` ops. SECURITY: connection status crosses the
  // wire, tokens never do. Absent when null → those ops are not declared and
  // the client shows every forge disconnected.
  ForgeCredentialPort? forgeCredentials,
  // Runs the browser sign-in that mints a user's own provider credential,
  // backing `oauth.*`. Absent when null → the client offers only the
  // paste-a-token path, which is exactly what a server with no app configured
  // should show.
  ProviderOAuthService? providerOAuth,
  // The SERVER's own app identity (GitHub App, Linear app), backing
  // `providerApps.*`. Operator-only; absent when null.
  ProviderAppSettings? providerApps,
  // Per-workspace GitHub App / background PAT. The `workspaceGitHub.*` ops
  // live in extraOps (`buildWorkspaceGitHubOps`); this port stays here so
  // `workspace.delete` can wipe that workspace's secrets. Absent when null.
  WorkspaceGitHubAppSettings? workspaceGitHubApps,
  // Builds the API client for one repo, on that repo's own forge, acting as
  // [actingUserId]. Backs the compose-PR reads (branches, default branch,
  // comparison, templates) so the composer works the same on every forge. Null
  // → those ops degrade to empty.
  ForgePrClient Function(
    Repo repo,
    String? actingUserId, {
    String? workspaceId,
  })?
  buildForgePrClient,
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
  // Reads an agent run's NDJSON log off the SERVER's disk for the run viewer.
  // The file lives in the server's data dir, so the thin client cannot open it
  // itself (it used to try, and rendered an empty dialog against any remote
  // server). Absent when null → `agent_run_log.readEvents` is not declared.
  RunLogReader? runLogReader,
  // Lets server-host capability ops publish domain events (e.g. `RepoAdded`,
  // which kicks off server-side code indexing). Optional — null on hosts with
  // no event-driven background pipeline.
  DomainEventBus? eventBus,
  // Opening a PR's branch in an editor launches a GUI editor on the SERVER's
  // machine, so the launch op exists only when the host wires the launcher (a
  // desktop / GUI host). A headless server leaves it null and the op is simply
  // absent (the client's open-in-IDE button then hides itself).
  EditorLauncherPort? editorLauncher,
  // Resolves a PR's on-disk worktree path — the SAME space worktree the
  // workbench edits (there is no separate `pr_worktrees/` checkout). Ensures the
  // PR space + provisioning, then returns the checkout path. Absent on a host
  // that owns no worktrees.
  Future<String> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
    String? repoId,
  })?
  ensurePrWorktree,
  // Re-syncs a PR space's worktree to the latest PR head (commits pushed after
  // it was provisioned). No-ops on a dirty tree. Absent on a host that owns no
  // worktrees.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  })?
  syncPrWorktree,
  // Computes a conversation's working-tree diff on the SERVER (reads the CoW
  // worktree registry + runs `git diff`). Only a host that owns those checkouts
  // wires it; absent elsewhere (the web panel then shows "no changes").
  /// Currently UNUSED: the conversation working-tree diff op this once gated
  /// has moved, and the leftover `if (convChanges != null)` was silently
  /// swallowing the `cache.*` block below it — a braceless `if` whose body was
  /// the next `if`. So a host with no worktree diff fetcher (a demo, a
  /// web-only deployment) also lost its editor-layout persistence, which is
  /// unrelated. Kept in the signature because callers still pass it.
  // ignore: unused_element_parameter
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
  // space ownership before delegating (isolation invariant).
  ConversationRevertFn? conversationRevert,
  ConversationUnrevertFn? conversationUnrevert,
  // Re-runs background space-workspace provisioning (repo worktrees +
  // per-agent overlay + `.mcp.json`) after a failure, so the UI's Retry button
  // can unblock a `failed` space. Server-side only; null ⇒ the op is omitted.
  // Workspace-scoped: asserts space ownership before retrying.
  //
  // Also the re-provision `messaging.setSpaceRepos` kicks when the edit ADDS a
  // repo — the same idempotent run, so a space that gains a repo materializes
  // its worktree instead of waiting for the next dispatch to do it inline.
  // Null there means the selection is written but nothing checks the new repo
  // out (a bare test host); the op itself stays present either way.
  Future<void> Function({required String workspaceId, required String spaceId})?
  retrySpaceProvisioning,
  // Stops a space's IN-FLIGHT provisioning (the running clone), so the
  // operator's stop actually stops the work rather than only the waiting.
  // Server-side only; null ⇒ the op is omitted.
  Future<void> Function({required String workspaceId, required String spaceId})?
  cancelSpaceProvisioning,
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
  // Explorer panel's flat results list + the composer @-mentions (fff runs
  // SERVER-SIDE over the CoW checkouts). Paged: offset + limit.
  RepoFileSearchFetcher? repoFileSearch,
  // Server-side one-level directory listing for the IDE Explorer's lazy tree,
  // cursor-paginated so no single response is unbounded. Ignores are honored
  // via `git check-ignore` so the tree matches what the fuzzy index ranks.
  RepoDirectoryListingFetcher? repoDirectoryListing,
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
  // worktrees. Workspace-scoped + space-owned: the worktree is resolved via
  // the isolation registry, so a foreign space is simply not found.
  WorktreeWriteFileFn? worktreeWriteFile,
  // Reverts working-tree files in a conversation's isolated worktree to HEAD,
  // SERVER-SIDE. Backs the IDE Source Control "Revert" action. Absent on a host
  // that owns no worktrees. Workspace-scoped + space-owned.
  WorktreeRevertFilesFn? worktreeRevertFiles,
  // Reads a file from a conversation's isolated worktree (PR-head tree) and
  // commits/pushes worktree changes. PR workbench file view/edit + commit&push.
  WorktreeReadFileFn? worktreeReadFile,
  WorktreeCommitAndPushFn? worktreeCommitAndPush,
  // Publishes a conversation worktree's branch to origin (push only). Lets the
  // compose-PR screen open a PR from a chat's local-only worktree branch.
  WorktreePublishBranchFn? worktreePublishBranch,
  // Fetch + rebase + push for the IDE Source Control "Sync changes" /
  // "Publish branch" button. Never commits. Null ⇒ the op is omitted.
  WorktreeSyncBranchFn? worktreeSyncBranch,
  // Branch list + checkout for the space Source Control picker. Both stay
  // inside the isolated worktree (no fetch). Null ⇒ the ops are omitted.
  WorktreeListBranchesFn? worktreeListBranches,
  WorktreeCheckoutFn? worktreeCheckout,
  // Stacked branches inside a space's one checkout. Always registered; a null
  // port answers an empty list and refuses mutations.
  SpaceStackPort? spaceStack,
  // Recorded layers, so pr.forSpaceBranches matches every part, not only the
  // branch currently checked out. Null keeps the single-branch match.
  SpaceStackRepository? spaceStackRepository,
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
  // Owns enclosures (rigs): disposable VMs/microVMs an agent or a human drives.
  // Present only on a host that can actually boot one — a server with no
  // hypervisor leaves this null, the `rig.*` ops are absent and the client
  // renders an honest "enclosed VMs are unavailable here" state instead of
  // failing per action. Rigs are workspace-scoped and ownership is validated on
  // every op.
  RigPort? rigs,
  // Port visibility + forwarding for enclosed rigs: what is listening inside a
  // Terminal (VM), and every address each port answers on (host loopback, an
  // optional LAN port, a dev domain in the Browser (VM)). Present alongside
  // [rigs] on a host with enclosure support; the `rig.*Port*` ops are absent
  // without it and the ports panel simply does not render.
  RigPortsPort? rigPorts,
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
  // Server-side [MessagingPort] (`MessagingService`) for space lifecycle +
  // agent dispatch. Needs the sandbox engine — null on a headless host without
  // it (`dispatch.*` absent). Replies stream via existing
  // `messaging.watchMessages` (segments on message rows). Every `dispatch.*` op
  // uses `ctx.workspaceId!` and asserts space ownership.
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
  // agents, creates teams and starts pipelines (cancel does the inverse) via
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
  // The plan surface: revision history + operator edits (`orchestration.
  // saveRevision` / `revisions`), partial approval (`approve` with
  // `approved_node_keys`, `approveNodes`), plan-mode documents (`plan.*`),
  // playbooks (`playbook.*`), estimates (`plan.estimate`) and plan-drift
  // markers (`orchestration.divergence` / `continueNode`). All optional —
  // absent on a host without the engine/services (default-deny). Every op is
  // workspace-scoped via `ctx.workspaceId!` + repository scoping.
  OrchestrationRevisionRepository? orchestrationRevisionRepository,
  PlanDocumentRepository? planDocumentRepository,
  PlaybookRepository? playbookRepository,
  SaveOrchestrationRevisionUseCase? saveOrchestrationRevision,
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
  // Merged reverse-dependency subgraph for a whole cohort (the Review Hub's
  // deep-dive impact view). Same host requirements as [reviewBlastRadius].
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String cohortKey,
    required String userId,
    int depth,
  })?
  reviewCohortImpact,
  // Starts the canonical AI review flow (Review Hub): ensure the PR space,
  // compute the deterministic review context, fan out reviewers into the
  // space, author the walkthrough, finalize. Returns immediately — progress
  // streams through the space + association status.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String userId,
    String? level,
  })?
  reviewHubStart,
  // Aggregated review-effectiveness counters for a workspace (findings made
  // vs. actually addressed).
  Future<Map<String, dynamic>> Function({required String workspaceId})?
  reviewHubStats,
  // A PR's dependency lockfile diffs (added / removed / upgraded packages).
  ReviewDependencyDiffRepository? reviewDependencyDiffRepository,
  // Publishes a finalized review to GitHub (user-gated: the client "Publish to
  // GitHub" button). Delegates to the [ReviewPublisherPort]; wired only by a
  // host that owns the GitHub PR client. Declares `prPublish`, so the guardrail
  // chokepoint gates it like any mutating action.
  //
  // Takes the caller: a person pressing the button publishes the review under
  // their own GitHub account. The agent-side auto-publish reaches the port
  // directly with no user and stays on the server's app identity.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    required String selection,
    required bool approveOnShip,
    required String userId,
  })?
  publishReview,
  // Resolves a PR's canonical review-studio key — its real GitHub node id
  // (migration 46) — for the studio read ops. Wired alongside the studio repos.
  ReviewPrExternalIdResolver? resolveStudioKey,
  // Dispatches a review-fix agent into a space on the SERVER (see
  // [ReviewDispatchFn]). Wired only by a host that owns the dispatch stack (the
  // desktop in-process host); a headless cc_server leaves it null → the
  // `dispatch.reviewFeedbackAgent` op is absent and the web "send findings to
  // agent" action degrades to "runs on the server host". Workspace-scoped: the
  // handler sources `ctx.workspaceId!` and asserts space ownership; the host
  // closure resolves the working directory from the bound workspace.
  ReviewDispatchFn? reviewDispatch,
  // The phone (cc_remote) approves/declines destructive agent commands. The
  // host-side [PendingConfirmationRegistry] bridges the agent's blocking
  // `ConfirmationPort.requestApproval` to remote clients: a destructive tool
  // call registers here, `confirmation.watchPending` streams the pending list to
  // the phone and `confirmation.respond` resolves it. Wired only by a host that
  // owns the dispatch stack + a remote approver (the desktop in-process host);
  // null on a headless cc_server (no dispatch) → both entries are absent.
  // CROSS-WORKSPACE BY DESIGN: approvals are host-global (a phone spans
  // workspaces); the `space_id` field routes them to the right space.
  PendingConfirmationRegistry? pendingConfirmationRegistry,
  // A dispatch that cannot authenticate registers here instead of failing, and
  // stays parked until the credential works, a client cancels it, or the host's
  // deadline passes. `credential_gate.watchBlocked` streams the parked set;
  // `credential_gate.resolve` re-probes or cancels one. Null on a host with no
  // dispatch stack, or when `--credential-gate=0` turns the feature off → both
  // entries are absent.
  // CROSS-WORKSPACE BY DESIGN: parked runs are host-global (one operator spans
  // workspaces); each entry carries the workspace it belongs to and the watch
  // is filtered to the subscriber's own.
  PendingCredentialBlockRegistry? credentialBlockRegistry,
  // The dispatch stack's in-flight turn registry. When wired, a thin client
  // subscribes per open space and receives a seed snapshot of every active
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
  // A SQL read-model projection (on DaoMessagingRepository, not the shared
  // repository interface): per-space activity signals so the sidebar doesn't
  // hold one full message-list subscription PER SPACE ROW. Null leaves the op
  // absent (default-deny).
  Stream<List<SpaceActivity>> Function(String workspaceId)? watchSpaceActivity,
  // The same bargain one conversation deeper: the size of a conversation's
  // live region, so the context meters stop holding a full message-list
  // subscription open to render a total. Null leaves the op absent
  // (default-deny) and the client falls back to nothing rather than to the
  // full history.
  Stream<ConversationTokenTotals> Function(
    String workspaceId,
    String spaceId,
    String conversationId,
  )?
  watchConversationTokens,
  // The composer's ↑/↓ recall. Null leaves the op absent; the client then
  // has no history rather than falling back to the full message list.
  Stream<List<String>> Function(
    String workspaceId,
    String spaceId,
    String conversationId,
    String userId,
  )?
  watchUserPromptHistory,
  // The provisioner tears down the worktree folder a repo loses when it
  // leaves a space's selection. Null (a bare test host) leaves the folder
  // behind — the selection write still lands, so a later sweep is the only
  // reconciliation, and the op's contract is documented on that basis.
  RepoWorkspaceProvisionerPort? provisioner,
  // The conversation repository backs the `conversation.*` mutate ops and the
  // `conversation.watchForSpace` subscription. Null leaves those ops absent.
  ConversationRepository? conversationRepository,
  Stream<List<Conversation>> Function(String workspaceId, String spaceId)?
  watchConversationsForSpace,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String? createdByUserId,
    String title,
  })?
  ensurePrSpace,
  // Backs `server.backupNow` (a whole-install snapshot directory: global.db
  // plus one file per workspace and a manifest) and the per-workspace
  // `workspace.export` / `workspace.import` pair, which exist because one
  // workspace is one file — exporting it is a single VACUUM INTO rather than a
  // table-by-table dump. All three are `fullClient`-only so a companion phone
  // can never trigger them. Null leaves the ops absent (default-deny).
  DatabaseBackupPort? databaseBackup,
  // Built in the runtime (which owns the scheduler + fleet repository) and
  // spliced into the closed registries here, so this hub stays agnostic of the
  // fleet wiring. Empty on a host with no fleet surface.
  List<RepoOp> extraOps = const [],
  List<WatchQuery> extraWatchQueries = const [],
  // The project's own GitHub star count, fetched and cached SERVER-side (the
  // client never dials GitHub — all external network I/O belongs to the
  // server). Wired only by the demo composition, so on a production server
  // the op is structurally absent, exactly like every other null-port family.
  // Null leaves the op absent.
  Future<int?> Function()? demoRepoStars,
}) {
  /// The PR-lifecycle store for the paths that only touch the local draft rows
  /// (list / read / create / update / delete). Those are identical whoever
  /// asks — only `publishToForge` reaches the forge, and it resolves its own
  /// instance from the caller so the pull request carries their name.
  final prLifecycleRepository = prLifecycleRepositoryFor(null);

  /// An indexed point lookup, NOT a materialize-then-scan.
  ///
  /// This gates every messaging op and every messaging/notes/reactions/autonomy
  /// watch attach, so it runs on the hot path of a message send. Reading the
  /// whole workspace's space list through a throwaway drift watch and
  /// scanning it in Dart made each of those O(all spaces) rows + entity
  /// mapping + a stream subscription, to answer a primary-key question.
  Future<bool> spaceInWorkspace(String workspaceId, String spaceId) async {
    final space = await messagingRepository.getSpaceById(workspaceId, spaceId);
    return space != null;
  }

  /// Whether [userId]'s view of this conversation's agent traces must be
  /// redacted: true when any repo linked to the conversation carries no
  /// grant for them (PRD 16 §follow-mode clarification). Admins and
  /// repo-less conversations are never redacted; absent identity wiring
  /// (single-user test catalogs) means no redaction.
  Future<bool> viewerTraceRestricted(
    String workspaceId,
    String spaceId,
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
    final repos = await isolatedRepoRepository.forSpace(workspaceId, spaceId);
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

  Future<void> assertSpaceOwned(String workspaceId, String spaceId) async {
    if (!await spaceInWorkspace(workspaceId, spaceId)) {
      throw const WorkspaceMismatchException(
        'Space belongs to a different workspace',
      );
    }
  }

  Future<void> assertConversationOwned(
    String workspaceId,
    String conversationId,
  ) async {
    final repo = conversationRepository;
    if (repo == null) {
      return;
    }
    final conv = await repo.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conv == null) {
      throw const WorkspaceMismatchException(
        'Conversation belongs to a different workspace',
      );
    }
  }

  /// The conversation (stream) a caller means: the one it named, or the
  /// space's standing conversation when it named none.
  ///
  /// There is no space-id aliasing left to fall back on. A conversation owns
  /// its own uuid, so the retired `?? spaceId` shortcut named a row that does
  /// not exist: a watch keyed on it streamed nothing and a write against it
  /// violated `conversation_messages.conversation_id`'s foreign key.
  Future<String> resolveConversationId(
    String workspaceId,
    String spaceId,
    Object? supplied,
  ) async {
    if (supplied is String && supplied.isNotEmpty) {
      return supplied;
    }
    final repo = conversationRepository;
    if (repo == null) {
      throw StateError(
        'No ConversationRepository is wired, so a caller that names no '
        'conversation cannot be served',
      );
    }
    final conversation = await repo.ensure(
      workspaceId: workspaceId,
      spaceId: spaceId,
    );
    return conversation.id;
  }

  /// One run's recorded activity for replay, from whichever store holds it.
  ///
  /// * Subagent runs: `RunTranscriptRecorder` → `run_transcripts` by child run id
  ///   (no message of their own).
  /// * Top-level runs: turn is a space message (`messageId == runLog.id`);
  ///   segments in `metadata['segments']` — nothing in `run_transcripts`.
  ///
  /// Live: `ActiveStreamRegistry` covers both (shared id). Returns the
  /// `run_transcripts` row when present (`complete` drives crash normalization),
  /// else message-backed segments.
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
    // Keyed by id alone, so the owning space is the isolation check — the
    // same rule `messaging.getMessageById` applies.
    if (message == null ||
        !await spaceInWorkspace(workspaceId, message.spaceId)) {
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
  // `publishToForge` / `delete`) take only a record id, which is NOT a boundary
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

  String? optionalArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    return value is String && value.isNotEmpty ? value : null;
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

  /// Workspace overlay for unscoped ops. RPC clients inject `workspace_id`
  /// even on `workspaceScoped: false` calls so Sign in / Profile in a
  /// workspace write the overlay rather than the global onboarding slot.
  String? overlayWorkspaceId(RepoOpContext ctx) {
    final raw = ctx.args['workspace_id'];
    if (raw is String && raw.isNotEmpty) {
      return raw;
    }
    return ctx.workspaceId;
  }

  /// Like [overlayWorkspaceId], but refuses a workspace the caller is not
  /// a member of. Unscoped ops have no dispatcher membership gate.
  Future<String?> overlayWorkspaceIdChecked(RepoOpContext ctx) async {
    final id = overlayWorkspaceId(ctx);
    if (id == null || id.isEmpty) {
      return null;
    }
    final members = identityMembers;
    if (members == null) {
      return id;
    }
    final member = await members.getMember(id, ctx.userId);
    if (member == null) {
      throw const AuthException('Not a member of this workspace');
    }
    return id;
  }

  final identityActivity = userActivityRepository;
  final identityPrefs = userPreferencesRepository;
  final identityInviteService = inviteService;
  final identityCredentials = userCredentials;

  /// The users [callerId] may see: themselves plus everyone they share a
  /// workspace with (the server owner sees all).
  ///
  /// Identity is global, so both lanes that hand user rows out have to apply
  /// this — and one of them did not. `users.list` filtered by co-membership
  /// while `users.watchAll` streamed `getAll()` verbatim, so subscribing was a
  /// way to read every account on the server that calling could not. On a
  /// public demo, with one global user row per visitor, that streamed every
  /// concurrent visitor to every other one. Sharing the rule is what keeps the
  /// two lanes from drifting apart again.
  Future<List<Map<String, dynamic>>> visibleUsersFor(
    String callerId,
    List<User> all,
  ) async {
    if (callerId == serverOwnerUserId) {
      return all.map(userToWire).toList();
    }
    final visible = <String>{callerId};
    if (identityMembers != null) {
      for (final membership in await identityMembers.getForUser(callerId)) {
        final coMembers = await identityMembers.getForWorkspace(
          membership.workspaceId,
        );
        visible.addAll(coMembers.map((m) => m.userId));
      }
    }
    return [
      for (final u in all)
        if (visible.contains(u.id)) userToWire(u),
    ];
  }

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
    // Everything else on the op has to be carried across too. This helper
    // used to rebuild the op from a subset of its fields, which silently
    // dropped `actionClasses` (the guardrail gate), `undoClass`, `preview`
    // and `audited` from every op it wrapped — the wrapper meant to RAISE the
    // privilege bar was quietly lowering it, and the loss was invisible at
    // the call site because the result is still a valid RepoOp.
    undoClass: op.undoClass,
    preview: op.preview,
    actionClasses: op.actionClasses,
    audited: op.audited,
  );

  /// Reads a guest port from a client arg, accepting the int and the numeric
  /// string a JSON client may send. Null on anything outside 1–65535.
  int? asPort(Object? raw) {
    final port = switch (raw) {
      final int i => i,
      final String s => int.tryParse(s),
      _ => null,
    };
    return (port == null || port <= 0 || port > 65535) ? null : port;
  }

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
  /// The workspace's repos that resolve to a real forge coordinate, on any
  /// forge. Repos with no recognized remote have nothing a forge API can be
  /// asked about, so they are filtered out once here rather than at each use.
  Future<List<Repo>> linkedForgeRepos(String workspaceId) async {
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    return [
      for (final r in linked)
        if (r.hasForgeRemote) r,
    ];
  }

  // Approval ROUTING for the ephemeral agent-action lane.
  //
  // The durable approval board has had routing + escalation since PRD 22
  // (`ApprovalRoutingService`, `ApprovalEscalationSweeper`); the inline
  // confirmations an agent blocks on had none — they broadcast to every
  // connected client and the first member to answer won. Same question, so
  // the same policy answers it: the tier is derived from the request's AGE,
  // which gives escalation without a second sweeper.
  //
  // Returns null when routing cannot be resolved (no identity wiring, no
  // workspace), which callers read as "anyone who is a member" — the
  // pre-routing behaviour.
  Future<List<String>?> confirmationAssignees(PendingConfirmation p) async {
    final members = identityMembers;
    final workspaceId = p.request.workspaceId;
    final routing = approvalRouting;
    if (members == null || workspaceId == null || routing == null) {
      return null;
    }
    final policy = await routing.policyFor(workspaceId);
    final tier = const ApprovalRoutingService().tierFor(
      createdAt: p.createdAt,
      now: DateTime.now(),
      policy: policy,
    );
    final roster = await members.getForWorkspace(workspaceId);
    return const ApprovalRoutingService().targetsForTier(
      policy: policy,
      members: roster,
      tier: tier,
      // An agent-initiated action has no requesting human in this lane, so
      // the `requestingUser` mode falls through to admins — never to nobody.
      requestingUserId: null,
    );
  }

  /// Whether [userId] is currently asked to answer [p].
  ///
  /// True when routing cannot be resolved (no identity wiring / no workspace)
  /// — the pre-routing "any member" behaviour — and when the tier's target
  /// set is empty, so a gate can never become unanswerable.
  Future<bool> isConfirmationTarget(
    PendingConfirmation p,
    String userId,
  ) async {
    final targets = await confirmationAssignees(p);
    return targets == null || targets.isEmpty || targets.contains(userId);
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
    final owner = serverOwnerUserId;
    if (owner == null) {
      // Fail CLOSED. This used to no-op, so a catalog built without identity
      // wiring served every server-wide setting ungated — the one shape where
      // "production always wires it" is an argument for the check being
      // cheap, not for skipping it.
      throw const AuthException(
        'This server has no operator identity configured, so server-wide '
        'settings cannot be changed.',
      );
    }
    if (ctx.userId != owner) {
      throw const AuthException(
        'This setting affects every workspace on this server and can only be '
        'changed by its operator.',
      );
    }
  }

  // Per-repo grant chokepoint: workspace membership must never silently
  // out-privilege the forge, so every code-bearing surface resolves the
  // caller's grant on the repo it exposes. Owners/admins hold every grant
  // implicitly. Denies loudly, never silently — and FAILS CLOSED when no
  // identity repository is wired (this used to return, i.e. grant access, on
  // a catalog with no membership wiring).
  Future<void> requireRepoReadGrant({
    required String workspaceId,
    required String userId,
    required String repoId,
  }) async {
    final members = identityMembers;
    if (members == null) {
      throw const AuthException(
        'This server has no membership wiring, so repo access cannot be '
        'authorized.',
      );
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
      // Fail closed, like `requireRepoReadGrant`.
      throw const AuthException(
        'This server has no membership wiring, so repo access cannot be '
        'authorized.',
      );
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

  // The repo set a SPACE-scoped surface exposes, for `RepoOp.repoAccessVia`.
  // A terminal, a code-server tab and an agent dispatch all reach code through
  // the space's worktree rather than a single `repo_id` argument, which is how
  // they shipped with no per-repo grant check at all — a zero-grant member
  // could open a shell in every repo. Selection semantics mirror the
  // provisioner's: explicit `space_repos` rows are the selection; no rows +
  // `no_repos` false = ALL workspace repos; `no_repos` true = nothing. A
  // missing `space_id` arg (the host-shell terminal) exposes every linked
  // repo — the shell can `cd` into each of them.
  Future<List<String>> reposExposedBySpaceArg(RepoOpContext ctx) async {
    final workspaceId = ctx.workspaceId!;
    Future<List<String>> allLinked() async => [
      for (final r
          in await workspaceRepository
              .watchReposForWorkspace(workspaceId)
              .first)
        r.id,
    ];
    final dbs = workspaceDbs;
    if (dbs == null) {
      // A catalog with no workspace persistence has no space selections to
      // read (bare tests); the surfaces this feeds don't exist there either.
      return const [];
    }
    final spaceArg = ctx.args['space_id'];
    if (spaceArg is! String || spaceArg.isEmpty) {
      return allLinked();
    }
    final db = dbs.of(workspaceId);
    final space = await db.messagingDao.getSpaceById(spaceArg);
    if (space != null && space.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Space belongs to a different workspace',
      );
    }
    if (space?.noRepos ?? false) {
      return const [];
    }
    final selected = await db.spaceRepoDao.repoIdsForSpace(
      workspaceId,
      spaceArg,
    );
    return selected.isEmpty ? allLinked() : selected;
  }

  // Validates that `(owner, repo)` is a repo linked to the bound workspace
  // before a client-supplied owner/repo is used in a server-side forge fetch —
  // so a thin client can only drive reads against repos its workspace owns
  // (workspace-isolation invariant) — AND that the calling [userId] holds a
  // read grant on it (membership ≠ code access). Denies loudly on a foreign or
  // ungranted repo. Returns the matched repo, whose `forge` picks the adapter.
  Future<Repo> requireWorkspaceForgeRepo(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
  }) async {
    final repos = await linkedForgeRepos(workspaceId);
    Repo? match;
    for (final r in repos) {
      if (r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          r.remoteName.toLowerCase() == repo.toLowerCase()) {
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
    return match;
  }

  /// The forge client for a repo already validated by
  /// [requireWorkspaceForgeRepo], acting as [actingUserId], or null when its
  /// forge has no client wired.
  ForgePrClient? forgeClientFor(
    Repo repo,
    String? actingUserId, {
    String? workspaceId,
  }) => repo.hasForgeRemote
      ? buildForgePrClient?.call(repo, actingUserId, workspaceId: workspaceId)
      : null;

  /// [userId] is the caller: it gates repo access and keys the cache.
  ///
  /// [asApp] posts under the SERVER's app identity instead of the caller's
  /// account, for content the caller did not write. The access check still runs
  /// against [userId] — this changes whose name is on the write, never whether
  /// they were allowed to make it.
  Future<PrReviewRepository> resolvePrReviewRepository(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
    bool asApp = false,
  }) async {
    if (forgeProviderRegistryFor == null) {
      return const EmptyPrReviewRepository();
    }
    // Resolve the linked repo row for (owner, repo) in the bound workspace.
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    Repo? match;
    for (final r in linked) {
      if (r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          r.remoteName.toLowerCase() == repo.toLowerCase()) {
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
    // Cache key: forge + coordinate + acting user + `asApp`. Same owner/repo
    // on two forges are different repos; the cached instance holds the
    // authenticated write client (sharing would mis-attribute).
    final identity = asApp ? '\u0000app' : userId;
    final key =
        '$workspaceId|${match.forge.wire}|'
        '${owner.toLowerCase()}|${repo.toLowerCase()}|$identity';
    final existing = prRepoCache[key];
    if (existing != null) {
      return existing;
    }
    // Resolution is by `match.forge`, so a workspace mixing GitHub, GitLab and
    // Bitbucket routes each repo to its own adapter with no branching here. A
    // repo whose forge has no credential resolves to the empty repository
    // rather than throwing, keeping one unconnected forge from breaking the
    // others.
    final created = forgeProviderRegistryFor(
      asApp ? null : userId,
      workspaceId: workspaceId,
    ).resolve(ForgeProviderContext(repo: match, workspaceId: workspaceId));
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
  final sandboxDetect = sandboxDetector;
  final processes = processDetection;
  final launcher = editorLauncher;
  final cacheRepo = cacheRepository;
  final repoCh = repoChanges;
  final repoChGrouped = repoChangesGrouped;
  final repoStageFn = repoStage;
  final repoUnstageFn = repoUnstage;
  final repoFileC = repoFileContent;
  final repoFileS = repoFileSearch;
  final repoDirL = repoDirectoryListing;
  final repoContentS = repoContentSearch;
  final worktreeContentS = worktreeContentSearch;
  final worktreeFileS = worktreeFileSearch;
  final worktreeWrite = worktreeWriteFile;
  final worktreeRevert = worktreeRevertFiles;
  final worktreeRead = worktreeReadFile;
  final worktreeCommit = worktreeCommitAndPush;
  final worktreePublish = worktreePublishBranch;
  final worktreeSync = worktreeSyncBranch;
  final worktreeBranches = worktreeListBranches;
  final worktreeCheckoutFn = worktreeCheckout;
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

  // `late` so the `roles.list` handler below can name the registry it lives
  // in: the permission vocabulary a role editor offers is DERIVED from the
  // ops actually enforced, and the closure only runs long after assignment.
  late final RepoOpRegistry ops;
  ops = RepoOpRegistry([
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
        // A snapshot captures EVERY workspace's database, so it is owner-only
        // like the `/backup/snapshot` HTTP route — being an admin of one
        // workspace must not be a way to copy all the others. This lane
        // shipped with no owner gate at all: any paired full client could
        // snapshot the whole install over RPC while the HTTP twin was gated.
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          final path = await databaseBackup.backupNow();
          return {'ok': true, 'path': path};
        },
      ),
    // Lists the snapshots already on disk, newest first. Same lane and same
    // gate as taking one: a caller allowed to write a whole-install snapshot is
    // not further protected by being unable to see the ones that exist — and
    // without this, restoring meant knowing the data directory by heart, which
    // is why the backup surface had no UI for years.
    if (databaseBackup != null)
      RepoOp(
        name: 'server.listBackups',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        // Same authority as taking one: the listing names whole-install
        // snapshot paths on the server's disk.
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          final snapshots = await databaseBackup.listBackups();
          return {
            'backups': [for (final s in snapshots) backupSnapshotToWire(s)],
          };
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
    // other and no client clock is consulted. Workflow/status transitions
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
    if (workspaceDbs != null) ...[
      // The shared handoff doc: authoritative LWW in server receipt order
      // (no expected version — the whole doc is one column; soft-claims on
      // the presence lane make concurrent editing VISIBLE instead of locked).
      RepoOp(
        name: 'notes.update',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'content'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final content = ctx.args['content'];
          if (content is! String) {
            throw const ValidationException('content must be a string');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final row = await workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .upsertNote(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                spaceId: spaceId,
                contentMarkdown: content,
                updatedByPrincipal: ctx.principal.wire,
              );
          return {'note': spaceNoteToWire(row)};
        },
      ),
      RepoOp(
        name: 'reactions.toggle',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'message_id', 'emoji'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final messageId = ctx.args['message_id'] as String;
          final emoji = ctx.args['emoji'];
          if (emoji is! String || emoji.isEmpty || emoji.length > 16) {
            throw const ValidationException('emoji must be a short string');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final message = await messagingRepository.getMessageById(
            ctx.workspaceId!,
            messageId,
          );
          if (message == null || message.spaceId != spaceId) {
            throw const NotFoundException('Message not found in this space');
          }
          final added = await workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .toggleReaction(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                spaceId: spaceId,
                messageId: messageId,
                principalId: ctx.userId,
                principalType: 'user',
                emoji: emoji,
              );
          return {'added': added};
        },
      ),
    ],
    // `presence.update` applies the calling USER's own ephemeral presence —
    // identity comes from the session (never client args), the payload is a
    // compact awareness delta and nothing is persisted or audited (a
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
    if (takeoverService != null) ...[
      RepoOp(
        name: 'takeover.begin',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          String displayName = ctx.userId;
          if (userRepository != null) {
            displayName =
                (await userRepository.getById(ctx.userId))?.displayName ??
                ctx.userId;
          }
          final marker = await takeoverService.begin(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            userId: ctx.userId,
            displayName: displayName,
          );
          return {'takeover': marker};
        },
      ),
      RepoOp(
        name: 'takeover.handBack',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          String displayName = ctx.userId;
          if (userRepository != null) {
            displayName =
                (await userRepository.getById(ctx.userId))?.displayName ??
                ctx.userId;
          }
          return takeoverService.handBack(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            userId: ctx.userId,
            displayName: displayName,
            note: ctx.args['note'] as String? ?? '',
          );
        },
      ),
      RepoOp(
        name: 'takeover.status',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          return {
            'takeover': await takeoverService.status(ctx.workspaceId!, spaceId),
          };
        },
      ),
    ],
    if (workspaceDbs != null)
      RepoOp(
        name: 'autonomy.setForSpace',
        kind: RepoOpKind.mutate,
        // Admin, like `action_policy.upsert`: `actFreely` pre-approves every
        // `prompt` verdict in the space, so the member floor this op shipped
        // with let any member neutralize the admin-gated guardrail matrix in
        // one call.
        minRole: WorkspaceRole.admin,
        requiredArgs: ['space_id', 'agent_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final agentId = ctx.args['agent_id'] as String;
          final level = ctx.args['level'];
          const allowed = {'proposeOnly', 'actWithApproval', 'actFreely'};
          if (level != null && (level is! String || !allowed.contains(level))) {
            throw ValidationException(
              'level must be one of ${allowed.join(', ')} or null',
            );
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .setAutonomy(
                id: const Uuid().v4(),
                workspaceId: ctx.workspaceId!,
                spaceId: spaceId,
                agentId: agentId,
                autonomyLevel: level as String?,
              );
          return {'ok': true};
        },
      ),
    if (workspaceDbs != null) ...[
      RepoOp(
        name: 'checker.setForSpace',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final agentId = ctx.args['agent_id'];
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          if (agentId is String && agentId.isNotEmpty) {
            await workspaceDbs
                .of(ctx.workspaceId!)
                .cacheDao
                .put(
                  ctx.workspaceId!,
                  CheckerDispatchListener.cacheKind,
                  spaceId,
                  jsonEncode({'agent_id': agentId}),
                );
          } else {
            await workspaceDbs
                .of(ctx.workspaceId!)
                .cacheDao
                .deleteEntry(
                  ctx.workspaceId!,
                  CheckerDispatchListener.cacheKind,
                  spaceId,
                );
          }
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'checker.get',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final raw = await workspaceDbs
              .of(ctx.workspaceId!)
              .cacheDao
              .read(
                ctx.workspaceId!,
                CheckerDispatchListener.cacheKind,
                spaceId,
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
        if (manualPairingEnabled != null && !await manualPairingEnabled()) {
          throw const AuthException(
            'Manual pairing is disabled on this server — join through '
            'single sign-on instead',
          );
        }
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
        if (existing.userId != null) {}
        return {'ok': true};
      },
    ),

    // Users are global identities; membership (role), invites, per-repo
    // grants and the audit trail are workspace-scoped. Reads are open to any
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
          var user = await identityUsers.getById(ctx.userId);
          if (user == null) {
            throw const NotFoundException('User not found');
          }
          final overlayId = overlayWorkspaceId(ctx);
          if (overlayId != null && overlayId.isNotEmpty) {
            final member = await identityMembers.getMember(
              overlayId,
              ctx.userId,
            );
            user = applyMemberOverlay(user, member);
          }
          final memberships = await identityMembers.getForUser(ctx.userId);
          return {
            'user': userToWire(user, includeOnboarding: true),
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
        handler: (ctx) async => {
          'users': await visibleUsersFor(
            ctx.userId,
            await identityUsers.getAll(),
          ),
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
          return {'user': userToWire(updated, includeOnboarding: true)};
        },
      ),
      // Records that the caller has finished first-run setup. Self-service
      // like `users.updateProfile`: the target is always `ctx.userId`, so
      // there is no admin gate and no way to mark another member.
      //
      // Monotonic and idempotent — an already-onboarded user keeps their
      // original timestamp. The client calls this both when the flow ends and
      // whenever the onboarding gate observes an already-complete setup, so a
      // re-stamp must not move the date, and there is deliberately no op to
      // clear it.
      RepoOp(
        name: 'users.markOnboardingFinished',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          final user = await identityUsers.getById(ctx.userId);
          if (user == null) {
            throw const NotFoundException('User not found');
          }
          // Stamped at whole-second resolution because that is what the column
          // stores: a microsecond-precise `DateTime.now()` would come back
          // truncated, so this op would answer with a timestamp the very next
          // `identity.me` disagrees with.
          final now = DateTime.now();
          final at =
              user.onboardingFinishedAt ??
              DateTime.fromMillisecondsSinceEpoch(
                now.millisecondsSinceEpoch - now.millisecondsSinceEpoch % 1000,
              );
          if (!user.hasOnboarded) {
            await identityUsers.upsert(user.copyWith(onboardingFinishedAt: at));
          }
          return {'onboarding_finished_at': at.toIso8601String()};
        },
      ),
      // Per-user GitHub credentials. Strictly self-service: the target is
      // always `ctx.userId` — no principal can set or probe another member's
      // token. Write-only: the stored value is NEVER returned (only a
      // configured flag) and it is never logged. User-scoped like `prefs.*`,
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
      ],
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
          // Peer-admin protection: demoting another admin, or minting a new
          // one, reshapes who governs the workspace — that is the owner's
          // call. Without this floor two admins could demote each other, and
          // any admin could quietly multiply admins.
          if ((target.role == WorkspaceRole.admin ||
                  role == WorkspaceRole.admin) &&
              ctx.role != WorkspaceRole.owner) {
            throw const AuthException(
              'Changing an admin\'s role requires the workspace owner',
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
          // Same peer-admin protection as `members.setRole`: removing a
          // fellow admin is governance, not housekeeping.
          if (target.role == WorkspaceRole.admin &&
              ctx.role != WorkspaceRole.owner) {
            throw const AuthException(
              'Removing an admin requires the workspace owner',
            );
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
      // Transfer workspace ownership to an existing ADMIN. Owner-only — SCIM
      // deprovisioning refuses to remove an owner with "transfer ownership
      // first", and until this op existed that sentence pointed at nothing:
      // an owner who left the company was unremovable through the product.
      // The target must already be an admin so the handover is a deliberate
      // two-step for anyone lower (promote, then transfer). Ordering is
      // chosen so every failure mode leaves AT LEAST one owner: promote the
      // target first (two owners momentarily), then restamp the global
      // registry row, then demote the caller to admin.
      RepoOp(
        name: 'workspace.transferOwnership',
        kind: RepoOpKind.mutate,
        requiredArgs: ['user_id'],
        minRole: WorkspaceRole.owner,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          if (targetUserId == ctx.userId) {
            throw const ValidationException(
              'Ownership is already held by this user',
            );
          }
          final target = await identityMembers.getMember(
            workspaceId,
            targetUserId,
          );
          if (target == null) {
            throw const NotFoundException('Member not found');
          }
          if (target.role != WorkspaceRole.admin) {
            throw const ValidationException(
              'Ownership can only be transferred to an admin — promote the '
              'member first',
            );
          }
          final now = DateTime.now();
          await identityMembers.setRole(
            workspaceId,
            targetUserId,
            WorkspaceRole.owner,
          );
          // Restamp the registry row: `listWorkspaces` and the identity
          // bootstrap read ownership from `workspaces.owner_user_id`, while
          // the role gates read the membership row — both must agree.
          final registryRow = (await workspaceRepository.watchAll().first)
              .where((w) => w.id == workspaceId)
              .firstOrNull;
          if (registryRow != null) {
            await workspaceRepository.upsert(
              registryRow.copyWith(ownerUserId: targetUserId),
            );
          }
          await identityMembers.setRole(
            workspaceId,
            ctx.userId,
            WorkspaceRole.admin,
          );
          eventBus?.publish(
            WorkspaceMemberRoleChanged(
              workspaceId: workspaceId,
              userId: targetUserId,
              role: WorkspaceRole.owner,
              occurredAt: now,
            ),
          );
          eventBus?.publish(
            WorkspaceMemberRoleChanged(
              workspaceId: workspaceId,
              userId: ctx.userId,
              role: WorkspaceRole.admin,
              occurredAt: now,
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
    ],

    if (approvalRouting != null) ...[
      RepoOp(
        name: 'approval_routing.getPolicy',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.member,
        handler: (ctx) async => {
          'policy': (await approvalRouting.policyFor(
            ctx.workspaceId!,
          )).toJson(),
        },
      ),
      RepoOp(
        name: 'approval_routing.setPolicy',
        kind: RepoOpKind.mutate,
        // Who a gate is asked of is the workspace's security posture, so the
        // derived `member` floor of `mutate` would be far too low.
        minRole: WorkspaceRole.admin,
        requiredArgs: ['policy'],
        handler: (ctx) async {
          await approvalRouting.setPolicy(
            ctx.workspaceId!,
            ApprovalRoutingPolicy.fromJson(
              (ctx.args['policy'] as Map).cast<String, dynamic>(),
            ),
          );
          return {'ok': true};
        },
      ),
    ],

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
    // Scoped ticket list reads (indexed DAO; not client-side filter of
    // `tickets.list`). Caller-supplied id is a FILTER, never auth — queries use
    // `ctx.workspaceId`'s DB + `workspace_id = ?`; foreign ids return empty
    // (no existence oracle).
    RepoOp(
      name: 'tickets.listForAgent',
      kind: RepoOpKind.read,
      requiredArgs: ['agent_id'],
      handler: (ctx) async {
        final tickets = await ticketRepository.forAgent(
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {'tickets': tickets.map(ticketToWire).toList()};
      },
    ),
    RepoOp(
      name: 'tickets.listChildren',
      kind: RepoOpKind.read,
      requiredArgs: ['parent_ticket_id'],
      handler: (ctx) async {
        final tickets = await ticketRepository.childrenOf(
          ctx.workspaceId!,
          ctx.args['parent_ticket_id'] as String,
        );
        return {'tickets': tickets.map(ticketToWire).toList()};
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
        await assertTicketInWorkspace(
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
        await assertTicketInWorkspace(
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
        await assertTicketInWorkspace(
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
        final existing = await agentRepository.getById(
          ctx.workspaceId!,
          agent.id,
        );
        if (existing == null) {
          throw const ValidationException(
            'Create agents via agents.create — agents.upsert updates an '
            'existing row only.',
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
    // Stops every OS process belonging to one agent and marks its live runs
    // killed. This is HOST work, not client work: the processes live in the
    // server's process table, so a thin client that killed pids locally either
    // no-op'd (remote server) or killed an unrelated recycled pid on its own
    // machine. Privileged, hence `fullClient`-only; absent when the host wires
    // no detector (a client then simply cannot offer the action).
    if (processDetection != null)
      RepoOp(
        name: 'agents.killProcesses',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_id'],
        requiredCapability: SessionCapability.fullClient,
        handler: (ctx) async {
          final agentId = ctx.args['agent_id'] as String;
          final agent = await agentRepository.getById(
            ctx.workspaceId!,
            agentId,
          );
          if (agent == null) {
            throw const NotFoundException('Agent not found');
          }
          if (agent.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Agent belongs to a different workspace',
            );
          }
          final logs = await agentRunLogRepository
              .watchByAgent(ctx.workspaceId!, agentId)
              .first;
          final killedPids = <int>{};
          final now = DateTime.now();
          for (final log in logs) {
            final pid = log.pid;
            if (!log.isRunning || pid == null) {
              continue;
            }
            await processDetection.killProcess(pid);
            killedPids.add(pid);
            await agentRunLogRepository.upsert(
              log.copyWith(
                status: RunStatus.error,
                completedAt: now,
                summary: 'Killed by user',
              ),
            );
          }
          // Runs whose pid was never recorded (crash before the stamp) still
          // show up in the host's process table under the agent's name.
          for (final proc in await processDetection.detect()) {
            if (!killedPids.contains(proc.pid) &&
                proc.command.contains(agent.name)) {
              await processDetection.killProcess(proc.pid);
              killedPids.add(proc.pid);
            }
          }
          return {'killed': killedPids.length};
        },
      ),

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
    // Declared only when the host wires a [RepoScriptRepository]. The bodies
    // are SERVER-EXECUTED shell, which is why they never ride `repos.upsert`:
    // reads are member-level, but WRITING them is admin-gated and declared
    // `processSpawn` so the action guard sees the honest worst case.
    if (repoScriptRepository != null)
      RepoOp(
        name: 'repos.getScripts',
        kind: RepoOpKind.read,
        requiredArgs: ['repo_id'],
        handler: (ctx) async {
          final scripts = await repoScriptRepository.getScripts(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
          );
          return {'scripts': scripts.toJson()};
        },
      ),
    if (repoScriptRepository != null)
      RepoOp(
        name: 'repos.setScripts',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: ['repo_id'],
        handler: (ctx) async {
          final repoId = ctx.args['repo_id'] as String;
          // An id from another workspace does not resolve here — the write is
          // simply a no-op on that workspace's file, never a cross-workspace
          // mutation.
          if (!await repoRepository.exists(ctx.workspaceId!, repoId)) {
            throw const NotFoundException('Repo not found');
          }
          final scripts = RepoScripts.fromJson(
            (ctx.args['scripts'] as Map?)?.cast<String, dynamic>(),
          );
          await repoScriptRepository.setScripts(
            ctx.workspaceId!,
            repoId,
            scripts,
          );
          return {'ok': true};
        },
      ),
    // Test-run a script DRAFT in a throwaway clone of the repo. Same privilege
    // shape as `repos.setScripts` — it EXECUTES the body — plus the honest
    // processSpawn action class. The op returns the run id immediately; the
    // clone, execution and teardown continue server-side, streaming into the
    // run row the client already watches via `repos.watchScriptRuns`.
    if (repoScripts != null)
      RepoOp(
        name: 'repos.testScript',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: ['repo_id', 'kind', 'script'],
        handler: (ctx) async {
          final repoId = ctx.args['repo_id'] as String;
          if (!await repoRepository.exists(ctx.workspaceId!, repoId)) {
            throw const NotFoundException('Repo not found');
          }
          // The lifecycle slot the draft belongs to — a LABEL for the run row,
          // not a selector of stored scripts (the body is caller-supplied).
          final kindArg = ctx.args['kind'] as String? ?? '';
          final kind = switch (kindArg) {
            'setup' => RepoScriptKind.setup,
            'archive' => RepoScriptKind.archive,
            _ => null,
          };
          if (kind == null) {
            throw ArgumentError.value(
              kindArg,
              'kind',
              'Expected "setup" or "archive"',
            );
          }
          final runId = await repoScripts.runTest(
            workspaceId: ctx.workspaceId!,
            repoId: repoId,
            kind: kind,
            body: ctx.args['script'] as String,
          );
          return {'run_id': runId};
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
    // What each forge can do. Static per forge and identical for every client,
    // so the client never hardcodes a forge's abilities — it asks, and hides
    // the affordances the answering forge does not have.
    RepoOp(
      name: 'forge.capabilities',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => {
        'forges': [
          for (final forge in ForgeHost.supported)
            capabilitiesOf(forge).toJson(),
        ],
      },
    ),
    // Which forges the CALLER is connected to, and as whom. Never carries a
    // token: this crosses to every client including remote ones, and the
    // credential stays on the server.
    //
    // Answered for `ctx.userId`, so two members of the same server see their
    // own accounts rather than the operator's. A user with no credential of
    // their own reads as disconnected even on a server whose app identity is
    // configured — "connected" here means "I signed in", which is the question
    // the onboarding gate and the account row are asking.
    if (forgeCredentials != null)
      RepoOp(
        name: 'forge.listConnections',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => {
          'connections': [
            for (final c in await forgeCredentials.connections(
              userId: ctx.userId,
              workspaceId: await overlayWorkspaceIdChecked(ctx),
            ))
              c.toJson(),
          ],
        },
      ),
    // Re-probes one forge and refreshes the caller's cached viewer identity.
    // Backs the "test connection" affordance, so it deliberately hits the
    // network rather than reporting the cached verdict.
    if (forgeCredentials != null)
      RepoOp(
        name: 'forge.testConnection',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final forge = ForgeHost.fromWire(ctx.args['forge'] as String?);
          if (!forge.isSupported) {
            throw const NotFoundException('Missing or invalid argument: forge');
          }
          return (await forgeCredentials.testConnection(
            forge,
            userId: ctx.userId,
            workspaceId: await overlayWorkspaceIdChecked(ctx),
          )).toJson();
        },
      ),
    // Stores or clears the CALLER's own forge credential — the paste-a-token
    // path, for a server with no app configured or a user who prefers a PAT.
    //
    // Strictly self-service: the target is always `ctx.userId`, so there is no
    // admin gate (a member managing their own credential is not privileged)
    // and no way to write another member's. Takes effect on the next request —
    // tokens are read per call, so there is no restart and no stale
    // interceptor holding the old value.
    if (forgeCredentials != null)
      RepoOp(
        name: 'credentials.setForgeToken',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          final forge = ForgeHost.fromWire(ctx.args['forge'] as String?);
          if (!forge.isSupported) {
            throw const NotFoundException('Missing or invalid argument: forge');
          }
          final token = ctx.args['token'];
          if (token is! String) {
            throw const NotFoundException('Missing or invalid argument: token');
          }
          final workspaceId = await overlayWorkspaceIdChecked(ctx);
          final oauth = providerOAuth;
          final app = ProviderApp.fromWire(forge.wire);
          if (oauth != null && app != null && token.isNotEmpty) {
            // Resolve WHO the token belongs to while storing it, so a pasted
            // credential shows the same "signed in as …" line a minted one
            // does instead of an anonymous "connected".
            await oauth.storePastedToken(
              userId: ctx.userId,
              provider: app,
              token: token,
              workspaceId: workspaceId,
            );
          } else {
            await forgeCredentials.setToken(
              forge,
              token,
              userId: ctx.userId,
              workspaceId: workspaceId,
            );
          }
          return (await forgeCredentials.testConnection(
            forge,
            userId: ctx.userId,
            workspaceId: workspaceId,
          )).toJson();
        },
      ),
    if (forgeCredentials != null)
      RepoOp(
        name: 'credentials.clearForgeToken',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          final forge = ForgeHost.fromWire(ctx.args['forge'] as String?);
          if (!forge.isSupported) {
            throw const NotFoundException('Missing or invalid argument: forge');
          }
          await forgeCredentials.clearToken(
            forge,
            userId: ctx.userId,
            workspaceId: await overlayWorkspaceIdChecked(ctx),
          );
          return {'ok': true};
        },
      ),
    // The ticketing vendor is authenticated per user for the same reason the
    // forge is: a ticket the app files on someone's behalf should carry their
    // name, not a shared robot's.
    if (userCredentials != null) ...[
      RepoOp(
        name: 'ticketing.listConnections',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => {
          'connections': [
            for (final provider in TicketProvider.values)
              if (provider != TicketProvider.local)
                {
                  'provider': provider.name,
                  'connected': await userCredentials.hasTicketToken(
                    ctx.userId,
                    provider,
                  ),
                  'username':
                      (await userCredentials.ticketToken(
                        ctx.userId,
                        provider,
                      ))?.accountLogin ??
                      '',
                },
          ],
        },
      ),
      RepoOp(
        name: 'credentials.setTicketingToken',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          final provider = TicketProvider.fromStorage(
            ctx.args['provider'] as String?,
          );
          if (provider == TicketProvider.local) {
            throw const NotFoundException('Local tickets need no credential.');
          }
          final token = ctx.args['token'];
          if (token is! String) {
            throw const NotFoundException('Missing or invalid argument: token');
          }
          final oauth = providerOAuth;
          final app = ProviderApp.fromWire(provider.name);
          if (oauth != null && app != null && token.isNotEmpty) {
            final account = await oauth.storePastedToken(
              userId: ctx.userId,
              provider: app,
              token: token,
            );
            return {'ok': true, 'username': account};
          }
          await userCredentials.setTicketToken(
            ctx.userId,
            provider,
            ProviderToken(accessToken: token),
          );
          return {'ok': true, 'username': ''};
        },
      ),
      RepoOp(
        name: 'credentials.clearTicketingToken',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          await userCredentials.clearTicketToken(
            ctx.userId,
            TicketProvider.fromStorage(ctx.args['provider'] as String?),
          );
          return {'ok': true};
        },
      ),
    ],
    // `oauth.providers` is what the account rows branch on: a provider whose
    // app is configured offers "sign in", one without it offers "paste a
    // token". The redirect URI rides along because the operator has to
    // register it with the provider verbatim, and hand-assembling it is the
    // most common way this is set up wrong.
    if (providerOAuth != null) ...[
      RepoOp(
        name: 'oauth.providers',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          final available = await providerOAuth.availableProviders(
            workspaceId: await overlayWorkspaceIdChecked(ctx),
          );
          final origin = _httpOriginFrom(pairingServerUrl);
          return {
            'providers': [
              for (final provider in available)
                {
                  'provider': provider.wire,
                  // Which flow this provider signs in with. A device flow
                  // needs no callback URL at all, so its row reports an empty
                  // one rather than a URL nobody has to register.
                  'flow': ProviderOAuthService.usesDeviceFlow(provider)
                      ? 'device'
                      : 'redirect',
                  'redirect_uri':
                      origin.isEmpty ||
                          ProviderOAuthService.usesDeviceFlow(provider)
                      ? ''
                      : providerOAuthRedirectUri(
                          origin,
                          provider.wire,
                        ).toString(),
                },
            ],
          };
        },
      ),
      // Starts a sign-in. The caller's identity comes from the SESSION — a
      // client cannot start a login on behalf of another user, because it
      // never gets to name one.
      //
      // Two shapes come back, and the client renders whichever it is handed:
      // `{mode: 'device', user_code, verification_uri, …}` for a device flow
      // (the server polls and stores the credential itself), or
      // `{mode: 'redirect', url}` for a browser round-trip.
      RepoOp(
        name: 'oauth.begin',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          final provider = ProviderApp.fromWire(
            ctx.args['provider'] as String?,
          );
          if (provider == null) {
            throw const NotFoundException(
              'Missing or invalid argument: provider',
            );
          }
          if (ProviderOAuthService.usesDeviceFlow(provider)) {
            final prompt = await providerOAuth.beginDeviceLogin(
              provider: provider,
              userId: ctx.userId,
              workspaceId: await overlayWorkspaceIdChecked(ctx),
            );
            return prompt.toJson();
          }
          final origin = _httpOriginFrom(pairingServerUrl);
          if (origin.isEmpty) {
            throw const AuthException(
              'This server does not advertise a reachable URL, so a sign-in '
              'has nowhere to come back to.',
            );
          }
          final url = await providerOAuth.beginLogin(
            provider: provider,
            userId: ctx.userId,
            redirectUri: providerOAuthRedirectUri(origin, provider.wire),
            workspaceId: await overlayWorkspaceIdChecked(ctx),
          );
          return {'mode': 'redirect', 'url': url.toString()};
        },
      ),
    ],
    // These configure how the SERVER authenticates as itself, which is a
    // server-wide decision — hence `requireServerAdmin`, matching `sso.*` and
    // `models.*`. Secrets are write-only: what comes back is presence flags.
    if (providerApps != null) ...[
      RepoOp(
        name: 'providerApps.list',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final origin = _httpOriginFrom(pairingServerUrl);
          return {
            'apps': [
              for (final status in await providerApps.statuses())
                {
                  ...status.toJson(),
                  'redirect_uri': origin.isEmpty
                      ? ''
                      : providerOAuthRedirectUri(
                          origin,
                          status.provider.wire,
                        ).toString(),
                },
            ],
          };
        },
      ),
      RepoOp(
        name: 'providerApps.save',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final provider = ProviderApp.fromWire(
            ctx.args['provider'] as String?,
          );
          if (provider == null) {
            throw const NotFoundException(
              'Missing or invalid argument: provider',
            );
          }
          // A field the form did not send is left alone; an empty string
          // clears it. That is what lets the form submit without re-typing a
          // secret it was never shown.
          String? field(String key) {
            final value = ctx.args[key];
            return value is String ? value : null;
          }

          final saved = await providerApps.save(
            provider,
            appId: field('app_id'),
            clientId: field('client_id'),
            clientSecret: field('client_secret'),
            privateKeyPem: field('private_key'),
            apiKey: field('api_key'),
          );
          return saved.toJson();
        },
      ),
      // Asks the provider whether the stored credentials actually work —
      // "saved" and "works" are different claims, and only the second one
      // means background work will run.
      RepoOp(
        name: 'providerApps.test',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['provider'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final provider = ProviderApp.fromWire(
            ctx.args['provider'] as String?,
          );
          if (provider == null) {
            throw const NotFoundException(
              'Missing or invalid argument: provider',
            );
          }
          return (await providerApps.status(provider, probe: true)).toJson();
        },
      ),
    ],
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
    // Resolves the PR's space worktree (creating + provisioning it if needed)
    // and opens it in the chosen editor on the host's display. Returns the
    // server-side worktree path (opaque to the client).
    if (launcher != null && ensurePrWorktree != null)
      RepoOp(
        name: 'ide.openPrInEditor',
        kind: RepoOpKind.mutate,
        requiredArgs: [
          'repo_full_name',
          'pr_number',
          'pr_external_id',
          'editor_id',
        ],
        handler: (ctx) async {
          final path = await ensurePrWorktree(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prExternalId: ctx.args['pr_external_id'] as String,
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
    // Opens the conversation's existing worktree in an editor on this host.
    // The path is resolved here; a client-supplied directory would be able to
    // launch an editor on any path the server can see.
    if (launcher != null)
      RepoOp(
        name: 'ide.openSpaceWorktree',
        kind: RepoOpKind.mutate,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: ['space_id', 'repo_id', 'editor_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final repoId = ctx.args['repo_id'] as String;
          final trees = await isolatedRepoRepository.forSpace(
            ctx.workspaceId!,
            spaceId,
          );
          String? path;
          for (final tree in trees) {
            if (tree.repoId == repoId) {
              path = tree.path;
              break;
            }
          }
          if (path == null || path.isEmpty) {
            throw const NotFoundException('no worktree for this repo');
          }
          await launcher.openDirectory(
            editorId: ctx.args['editor_id'] as String,
            directoryPath: path,
          );
          return {'ok': true};
        },
      ),
    // Resolves the PR's space worktree (creating + provisioning it if needed)
    // and returns its absolute path WITHOUT launching an editor. The thin
    // client now opens editors through `ide.openPrInEditor`; this op remains
    // for hosts that expose a worktree path to other server-side tools.
    // This is the SAME worktree the in-app workbench edits; there is no
    // separate `pr_worktrees/` checkout. Served even by a headless host.
    if (ensurePrWorktree != null)
      RepoOp(
        name: 'ide.ensureWorktree',
        kind: RepoOpKind.mutate,
        requiredArgs: ['repo_full_name', 'pr_number', 'pr_external_id'],
        handler: (ctx) async {
          final path = await ensurePrWorktree(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prExternalId: ctx.args['pr_external_id'] as String,
            title: ctx.args['title'] as String? ?? '',
            repoId: ctx.args['repo_id'] as String?,
          );
          return {'path': path};
        },
      ),
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
          // `space_id` is optional: the IDE Source Control panel (always
          // per-conversation) supplies it so the diff runs against the
          // conversation's isolated CoW worktree — the tree agents/code-server
          // edit. Absent → the original linked-repo checkout (back-compat).
          final spaceId = ctx.args['space_id'];
          final files = await repoCh(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
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
          final spaceId = ctx.args['space_id'];
          final grouped = await repoChGrouped(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
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
            'hasUpstream': grouped.hasUpstream,
            'ahead': grouped.ahead,
            'behind': grouped.behind,
            'aheadOfBase': grouped.aheadOfBase,
          };
        },
      ),
    // Stage files into the conversation worktree's git index (`git add`). Empty
    // `paths` ⇒ stage all. Foreign space → the fetcher no-ops (isolation
    // boundary), returning ok:false.
    if (repoStageFn != null)
      RepoOp(
        name: 'repos.stage',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'space_id', 'repo_id'],
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
            ctx.args['space_id'] as String,
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
        requiredArgs: ['workspace_id', 'space_id', 'repo_id'],
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
            ctx.args['space_id'] as String,
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
        // File contents expose code: read grant required and secret-excluded
        // paths are hard-blocked for read-only (viewer/guest) roles.
        repoAccess: RepoGrantLevel.read,
        handler: (ctx) async {
          final path = ctx.args['path'] as String;
          await assertPathNotSecretExcluded(ctx, path);
          // `space_id` is optional and scopes the read to the conversation's
          // isolated CoW worktree — the copy the Explorer lists and agents
          // write. Absent → the linked checkout (back-compat).
          final spaceId = ctx.args['space_id'];
          final r = await repoFileC(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            path,
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
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
          // Paged through the ranked list: `offset` + `limit` bound one
          // response (clamped server-side so a caller cannot reintroduce the
          // unbounded full-tree pull this op used to serve); `has_more` says
          // whether another page may follow. The Explorer pages on scroll and
          // the composer @-mention takes page 0 only.
          final limit = ((ctx.args['limit'] as num?)?.toInt() ?? 200).clamp(
            1,
            200,
          );
          // `space_id` scopes the search to the conversation's isolated CoW
          // worktrees, so it ranks the same trees the Explorer lists.
          final spaceId = ctx.args['space_id'];
          final hits = await repoFileS(
            ctx.workspaceId!,
            (ctx.args['query'] ?? '') as String,
            offset: (ctx.args['offset'] as num?)?.toInt() ?? 0,
            limit: limit,
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
          );
          return {'hits': hits, 'has_more': hits.length == limit};
        },
      ),
    if (repoDirL != null)
      RepoOp(
        name: 'repos.listDirectory',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'repo_id'],
        handler: (ctx) async {
          await requireAllRepoReadGrants(
            workspaceId: ctx.workspaceId!,
            userId: ctx.userId,
          );
          // One level of the repo tree, cursor-paginated in path order: the
          // client passes the last entry's `relativePath` back as `cursor` and
          // repeats until `has_more` is false — every entry stays reachable
          // while no single response is unbounded. `path` '' = repo root.
          // `space_id` lists the conversation's isolated CoW worktree instead
          // of the linked checkout — the tree its agents actually write to.
          final spaceId = ctx.args['space_id'];
          return repoDirL(
            ctx.workspaceId!,
            ctx.args['repo_id'] as String,
            path: ctx.args['path'] as String? ?? '',
            cursor: ctx.args['cursor'] as String? ?? '',
            limit: (ctx.args['limit'] as num?)?.toInt(),
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
          );
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
          // `space_id` greps the conversation's isolated CoW worktrees, so a
          // match names a line that exists in the tree the Explorer shows.
          final spaceId = ctx.args['space_id'];
          final hits = await repoContentS(
            ctx.workspaceId!,
            (ctx.args['query'] ?? '') as String,
            options: options,
            spaceId: spaceId is String && spaceId.isNotEmpty ? spaceId : null,
          );
          return {'hits': hits};
        },
      ),
    if (worktreeContentS != null)
      RepoOp(
        name: 'worktree.searchContent',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'space_id', 'repo_id', 'query'],
        handler: (ctx) async {
          // Scoped to the conversation's isolated worktree — the isolation
          // registry (workspace→space→repo) is the access boundary, so a
          // foreign space resolves to no worktree → empty. The option map is
          // optional (legacy case-insensitive literal defaults).
          final optionsArg = ctx.args['options'];
          final options = optionsArg is Map
              ? Map<String, Object?>.from(optionsArg)
              : const <String, Object?>{};
          final hits = await worktreeContentS(
            ctx.workspaceId!,
            ctx.args['space_id'] as String,
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
        requiredArgs: ['workspace_id', 'space_id', 'repo_id', 'query'],
        handler: (ctx) async {
          // Scoped to the conversation's isolated worktree — the isolation
          // registry (workspace→space→repo) is the access boundary, so a
          // foreign space resolves to no worktree → empty. Paged exactly like
          // `repos.searchFiles` (offset + limit + `has_more`).
          final limit = ((ctx.args['limit'] as num?)?.toInt() ?? 200).clamp(
            1,
            200,
          );
          final hits = await worktreeFileS(
            ctx.workspaceId!,
            ctx.args['space_id'] as String,
            ctx.args['repo_id'] as String,
            (ctx.args['query'] ?? '') as String,
            offset: (ctx.args['offset'] as num?)?.toInt() ?? 0,
            limit: limit,
          );
          return {'hits': hits, 'has_more': hits.length == limit};
        },
      ),
    // Backing the IDE's "untitled" draft save (⌘S) and the Source Control
    // "Revert" action. Both resolve the worktree via the isolation registry
    // (the workspace→space→repo boundary), so a foreign space is simply not
    // found. Absent on a host that owns no conversation worktrees.
    if (worktreeWrite != null)
      RepoOp(
        name: 'worktree.writeFile',
        kind: RepoOpKind.mutate,
        requiredArgs: [
          'workspace_id',
          'space_id',
          'repo_id',
          'path',
          'content',
        ],
        handler: (ctx) async {
          final res = await worktreeWrite(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
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
        requiredArgs: ['workspace_id', 'space_id', 'repo_id', 'paths'],
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
            spaceId: ctx.args['space_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            paths: paths,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    // Re-syncs a PR space's worktree to the latest PR head. Mutating (fetch +
    // hard checkout), but skips when the tree is dirty (never clobbers edits).
    if (syncPrWorktree != null)
      RepoOp(
        name: 'worktree.syncToPrHead',
        kind: RepoOpKind.mutate,
        requiredArgs: ['workspace_id', 'space_id', 'repo_id'],
        // It fetches from the forge before it checks out, so the honest worst
        // case reaches the network. Its sibling worktree mutations
        // (`writeFile`/`revertFiles`) stay inside the isolated worktree and
        // declare nothing — see the exemptions in
        // `test/core/action_class_coverage_test.dart`.
        actionClasses: const {ActionClass.networkEgress},
        handler: (ctx) async {
          return syncPrWorktree(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
            repoId: ctx.args['repo_id'] as String,
          );
        },
      ),
    if (worktreeRead != null)
      RepoOp(
        name: 'worktree.readFile',
        kind: RepoOpKind.read,
        requiredArgs: ['workspace_id', 'space_id', 'repo_id', 'path'],
        handler: (ctx) async {
          final res = await worktreeRead(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
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
        // dispatcher reads space_id (a required arg) for space-scoped policy.
        actionClasses: const {ActionClass.gitCommit, ActionClass.gitPush},
        requiredArgs: ['workspace_id', 'space_id', 'repo_id', 'message'],
        handler: (ctx) async {
          final rawPaths = ctx.args['paths'];
          final paths = <String>[
            if (rawPaths is List)
              for (final p in rawPaths)
                if (p is String && p.isNotEmpty) p,
          ];
          final users = identityUsers;
          final members = identityMembers;
          final identity = users != null && members != null
              ? await resolveWorkspaceGitIdentity(
                  users: users,
                  members: members,
                  ownerUserId: serverOwnerUserId ?? ctx.userId,
                  userId: ctx.userId,
                  workspaceId: ctx.workspaceId,
                )
              : null;
          final res = await worktreeCommit(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            message: ctx.args['message'] as String,
            paths: paths,
            push: ctx.args['push'] as bool? ?? true,
            amend: ctx.args['amend'] as bool? ?? false,
            sync: ctx.args['sync'] as bool? ?? false,
            pushBranch: ctx.args['push_branch'] as String?,
            // Git identity is overlay → global User. Client-supplied author
            // strings are not the source of truth.
            authorName: identity?.name,
            authorEmail: identity?.email,
            // The push is authored on the forge as the human who clicked.
            actingUserId: ctx.userId,
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
        requiredArgs: ['workspace_id', 'space_id', 'repo_id'],
        handler: (ctx) async {
          final res = await worktreePublish(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
            repoId: ctx.args['repo_id'] as String,
            branchOverride: ctx.args['branch'] as String?,
            // The push is authored on the forge as the human who clicked.
            actingUserId: ctx.userId,
          );
          if (res == null) {
            return {'ok': false};
          }
          return {'ok': true, ...res};
        },
      ),
    // Sync, branch list, and checkout live in [buildWorktreeBranchOps] so
    // this file's constructor count stays on the freeze.
    ...buildWorktreeBranchOps(
      sync: worktreeSync,
      listBranches: worktreeBranches,
      checkout: worktreeCheckoutFn,
    ),
    ...buildSpaceStackOps(stack: spaceStack),

    // The MCP HTTP server is a single process-wide listener the SERVER hosts;
    // it is not workspace data, so these ops are `workspaceScoped: false`. They
    // exist only when the host wired an [McpServerControl] (the guard promotes
    // `mcp` non-null into the closures). A headless server with no MCP server
    // leaves them absent and the web section shows "not available".
    if (mcp != null) ...[
      // Every op here is operator-only: the listener + bearer token decide who
      // can drive the full MCP tool surface from off-host, so mere pairing (or
      // a membership somewhere) must never suffice.
      RepoOp(
        name: 'mcp.status',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final status = await mcp.status();
          return status.toJson();
        },
      ),
      RepoOp(
        name: 'mcp.start',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcp.start();
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.stop',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcp.stop();
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.setEnabled',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['enabled'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcp.setEnabled(enabled: ctx.args['enabled'] as bool);
          return (await mcp.status()).toJson();
        },
      ),
      RepoOp(
        name: 'mcp.setToken',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcp.setToken(ctx.args['token'] as String?);
          return (await mcp.status()).toJson();
        },
      ),
    ],

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
      // Operator-only: the external-server roster + approval posture decide
      // which third-party tools every agent on this host may run.
      RepoOp(
        name: 'mcp.client.servers',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final servers = await mcpClient.servers();
          return {
            'servers': [for (final s in servers) s.toJson()],
          };
        },
      ),
      RepoOp(
        name: 'mcp.client.approvalMode',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          return {'mode': (await mcpClient.approvalMode()).wire};
        },
      ),
      RepoOp(
        name: 'mcp.client.setApprovalMode',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['mode'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcpClient.setApprovalMode(
            ApprovalMode.fromWire(ctx.args['mode'] as String?),
          );
          return {'mode': (await mcpClient.approvalMode()).wire};
        },
      ),
      RepoOp(
        name: 'mcp.client.authorize',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['name'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcpClient.authorize(ctx.args['name'] as String);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'mcp.client.reconnect',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['name'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await mcpClient.reconnect(ctx.args['name'] as String);
          return {'ok': true};
        },
      ),
    ],

    // Each model (embedding / diarization / voice) is a single device-local
    // asset the SERVER hosts, NOT workspace data, so these ops are
    // `workspaceScoped: false`. They exist only when the host wired the matching
    // [ModelControl] (the guard promotes it non-null into the closures). A
    // headless server that hosts no models leaves them null → the ops are absent
    // and the web sections show "managed on the server host". `*Status` returns
    // the snapshot wire map; the mutators return the fresh snapshot so the client
    // can refresh without a second round-trip.
    if (embeddingModel != null)
      ...modelControlOps(
        prefix: 'embedding',
        control: embeddingModel,
        guard: requireServerAdmin,
      ),
    if (diarizationModel != null)
      ...modelControlOps(
        prefix: 'diarization',
        control: diarizationModel,
        guard: requireServerAdmin,
      ),
    if (voiceModel != null)
      ...modelControlOps(
        prefix: 'voice',
        control: voiceModel,
        guard: requireServerAdmin,
      ),
    // Voice is the only SELECTABLE model (the user picks the active ASR build),
    // so when the host wired a selectable voice control we also expose the
    // catalog + select ops on top of its status/install/… surface. A fixed
    // (non-selectable) voice control omits these → the web picker hides itself.
    if (voiceModel is SelectableModelControl)
      ...voiceSelectionOps(control: voiceModel, guard: requireServerAdmin),

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
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: ['rows', 'cols'],
          // A shell reaches every repo in the space's worktree (all linked
          // repos for a host shell with no space), so membership alone must
          // not open one — the same "membership ≠ code access" rule the
          // single-repo surfaces enforce.
          repoAccess: RepoGrantLevel.read,
          repoAccessVia: reposExposedBySpaceArg,
          // A `microvm` spawn legitimately boots a VM and syncs a worktree
          // (~150s server-side; the client waits 180s), so it outlives the
          // session's default handler budget.
          timeout: const Duration(minutes: 4),
          handler: (ctx) async {
            final sessionId = await terminals.spawn(
              workspaceId: ctx.workspaceId!,
              rows: (ctx.args['rows'] as num).toInt(),
              cols: (ctx.args['cols'] as num).toInt(),
              spaceId: ctx.args['space_id'] as String?,
              cwd: ctx.args['cwd'] as String?,
              backend: ctx.args['backend'] as String?,
              // From the SESSION, never the arguments: a client cannot open a
              // shell as somebody else. For an enclosed terminal this decides
              // which rig is opened or reused and whose forge access the
              // guest's credentials are bounded by.
              actingUserId: ctx.userId,
            );
            // The backend the session ACTUALLY got, which is not always the
            // one asked for. The client badges it, so reporting the request
            // back would let a host-shell session claim to be an enclosed VM.
            return {
              'session_id': sessionId,
              'backend': ?terminals.backendOf(sessionId),
            };
          },
        ),
        RepoOp(
          name: 'terminal.write',
          kind: RepoOpKind.mutate,
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: ['session_id', 'data'],
          // Keystrokes that never hit Enter do nothing the trail should
          // record — they sit in the shell's line editor. Only a send
          // (and the reconstructed line) is an accountability event.
          auditWhen: (_, result) => result['sent'] == true,
          handler: (ctx) async {
            final outcome = await terminals.write(
              workspaceId: ctx.workspaceId!,
              sessionId: ctx.args['session_id'] as String,
              // Bytes travel as a base64 string (the same framing the
              // `terminal.output` snapshots use), decoded back to raw bytes here.
              data: base64Decode(ctx.args['data'] as String),
            );
            return {
              if (outcome.sent) 'sent': true,
              if (outcome.command != null) 'command': outcome.command,
            };
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
          actionClasses: const {ActionClass.processSpawn},
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

    // A rig is a disposable VM an agent or a human drives. These ops exist only
    // when the host wired a [RigPort]: a server with no hypervisor leaves it
    // null, the ops are absent and the client renders an honest "enclosed VMs
    // are unavailable on this server" state instead of failing per action.
    //
    // Every op is `fullClientOnly`: the paired phone is a lower-privilege
    // principal whose surface is tickets/messaging/newsfeed, and booting a
    // machine is not on that list. `RemoteToolPolicy` denies the MCP side by
    // default for the same reason.
    if (rigs != null)
      ...[
        RepoOp(
          name: 'rig.detect',
          kind: RepoOpKind.read,
          handler: (ctx) async => (await rigs.probe()).toJson(),
        ),
        buildRigInstallBackendSetupOp(
          rigs: rigs,
          requireServerAdmin: requireServerAdmin,
        ),
        RepoOp(
          name: 'rig.list',
          kind: RepoOpKind.read,
          handler: (ctx) async {
            final all = await rigs.list(ctx.workspaceId!);
            return {
              'rigs': [for (final r in all) rigToWire(r)],
            };
          },
        ),
        RepoOp(
          name: 'rig.open',
          kind: RepoOpKind.mutate,
          requiredArgs: ['surface'],
          actionClasses: const {
            ActionClass.enclosureControl,
            ActionClass.processSpawn,
          },
          handler: (ctx) async {
            // Build the spec from a CLOSED set of client-supplied fields.
            //
            // Splatting `ctx.args` into `RigSpec.fromJson` handed the caller
            // every field the spec has: `worktreePath` would tar an arbitrary
            // host directory (`~/.ssh` — the sync excludes `.env` and `*.pem`,
            // not `id_ed25519`) into a VM the caller drives, and `memoryMb` /
            // `cpuCount` / `ttlSeconds` would let one call evict every other
            // rig on the host or mint one with no effective lifetime. The
            // client only ever sends these two, and the resource envelope is
            // the server's to choose.
            final surface = ctx.args['surface'];
            if (surface is! String) {
              throw const ValidationException(
                'Missing or invalid argument: surface',
              );
            }
            final parsedSurface = RigSurface.fromWire(surface);
            if (parsedSurface == null) {
              throw ValidationException('Unknown rig surface "$surface"');
            }
            // Read, not cast: a client that sends a number here produced a
            // raw `TypeError` (mapped to the generic internal error) instead
            // of a named validation failure the caller can act on.
            final conversationId = ctx.args['conversation_id'];
            if (conversationId != null && conversationId is! String) {
              throw const ValidationException(
                'Invalid argument: conversation_id (expected a string)',
              );
            }
            // Which browser, when the surface is one. Refused rather than
            // defaulted on an unknown name: a client asking for an engine
            // this server cannot boot is asking a compatibility question, and
            // answering it with a different browser is worse than not
            // answering it.
            final engineArg = ctx.args['engine'];
            if (engineArg != null && engineArg is! String) {
              throw const ValidationException(
                'Invalid argument: engine (expected a string)',
              );
            }
            // WHICH machine of this kind in the conversation. Absent is the
            // conversation's default — what an agent's `*_use` calls reach —
            // so a client that names none behaves exactly as before slots.
            // `RigSpec` validates the shape; a wrong TYPE is caught here so
            // it reads as a named validation failure rather than a TypeError.
            final slotArg = ctx.args['slot_id'];
            if (slotArg != null && slotArg is! String) {
              throw const ValidationException(
                'Invalid argument: slot_id (expected a string)',
              );
            }
            final slotError = RigSpec.slotIdError(
              slotArg as String?,
              parsedSurface,
            );
            if (slotError != null) {
              throw ValidationException(
                'Invalid argument: slot_id. $slotError',
              );
            }
            final engine = engineArg == null
                ? RigBrowserEngine.fallback
                : RigBrowserEngine.fromWire(engineArg as String);
            if (engine == null) {
              throw ValidationException(
                'Unknown browser engine "$engineArg". Use '
                '${RigBrowserEngine.values.map((e) => e.wire).join(', ')}.',
              );
            }
            // The home page's color scheme is baked into the guest at boot,
            // so it has to arrive WITH the open. An explicit `home_theme`
            // wins and is remembered: an agent-opened rig (the browser_use
            // tool sends none) then follows the last theme any app named
            // rather than the server's static default.
            final themeArg = ctx.args['home_theme'];
            if (themeArg != null && themeArg is! String) {
              throw const ValidationException(
                'Invalid argument: home_theme (expected a string)',
              );
            }
            var homeTheme = RigBrowserHomeTheme.fromWire(themeArg as String?);
            if (themeArg != null && homeTheme == null) {
              throw ValidationException(
                'Unknown home theme "$themeArg". Use '
                '${RigBrowserHomeTheme.values.map((t) => t.wire).join(', ')}.',
              );
            }
            if (homeTheme != null) {
              await serverSettingsRepository?.set(
                kRigHomeThemeSettingKey,
                homeTheme.wire,
              );
            } else {
              homeTheme = RigBrowserHomeTheme.fromWire(
                await serverSettingsRepository?.get(kRigHomeThemeSettingKey),
              );
            }
            final rig = await rigs.open(
              workspaceId: ctx.workspaceId!,
              spec: RigSpec(
                surface: parsedSurface,
                browserEngine: engine,
                conversationId: conversationId as String?,
                slotId: slotArg,
                homeTheme: homeTheme,
                // A browser rig boots to its home page, so its default
                // allowlist admits that page's host — an empty list left the
                // tab a white rectangle whose first navigation anywhere was
                // refused. Still the caller's to widen, never the client's:
                // the egress envelope is the server's to choose.
                egressAllowlist: parsedSurface == RigSurface.browser
                    ? browserRigEgressAllowlist()
                    : const [],
                // Whose forge access anything inside this machine is bounded
                // by. A rig cannot tell which process is asking, so the
                // credential grant is bound to the person who opened it.
                openedByUserId: ctx.userId,
              ),
              openedBy: ctx.principal,
            );
            return rigToWire(rig);
          },
        ),
        RepoOp(
          name: 'rig.restartUnrestricted',
          // This removes a host-level network boundary and can expose the
          // server's LAN from inside the guest. Workspace membership alone is
          // not authority to make that machine-wide security decision.
          serverAuthority: ServerAuthority.serverOwner,
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id'],
          actionClasses: const {
            ActionClass.enclosureControl,
            ActionClass.networkEgress,
            ActionClass.processSpawn,
          },
          handler: (ctx) async {
            requireServerAdmin(ctx);
            final workspaceId = ctx.workspaceId!;
            final rig = await rigs.get(
              workspaceId,
              ctx.args['rig_id'] as String,
            );
            if (rig == null || rig.status.phase.isTerminal) {
              throw const NotFoundException('Rig not found in this workspace');
            }
            if (!rig.backend.hasEnforcedEgress) {
              throw const ValidationException(
                'This backend already allows every network host; it has no '
                'egress gate to bypass.',
              );
            }
            if (rig.spec.unrestrictedNetwork) {
              return rigToWire(rig);
            }

            // The existing row is closed BEFORE the replacement is opened:
            // reuse matching would otherwise hand the caller the restricted
            // machine it is trying to replace. Only this one policy bit is
            // widened; every server-owned resource and filesystem field comes
            // from the persisted spec, never from client arguments.
            await rigs.close(
              workspaceId: workspaceId,
              rigId: rig.id,
              reason: RigCloseReason.requested,
            );
            final restarted = await rigs.open(
              workspaceId: workspaceId,
              spec: rig.spec.copyWith(
                unrestrictedNetwork: true,
                openedByUserId: ctx.userId,
              ),
              openedBy: ctx.principal,
            );
            return rigToWire(restarted);
          },
        ),
        RepoOp(
          name: 'rig.act',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'action'],
          // Human take-over: attributed to the caller's own principal, never
          // to the agent that owns the rig.
          //
          // Out of the GENERIC audit trail (like `terminal.resize`) because a
          // person driving a rig emits a mouse event per frame — mirroring
          // those into the per-user audit would bury every real accountability
          // event under pointer noise. They are not unrecorded: every one lands
          // in `rig_action_log` with its principal and a monotonic sequence,
          // which is the purpose-built record and the finer one.
          audited: false,
          actionClasses: const {ActionClass.enclosureControl},
          handler: (ctx) async {
            final rig = await rigs.get(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
            );
            if (rig == null) {
              throw const NotFoundException('Rig not found in this workspace');
            }
            final parse = parseRigAction(rig.surface, ctx.args);
            if (parse is RigActionInvalid) {
              throw ValidationException(parse.message);
            }
            final result = await rigs.act(
              workspaceId: ctx.workspaceId!,
              rigId: rig.id,
              action: (parse as RigActionParsed).action,
              actor: ctx.principal,
            );
            return {
              'text': result.text,
              'is_error': result.isError,
              if (result.displaySize != null) 'display': result.displaySize,
              if (result.imageBase64 != null)
                'image_base64': result.imageBase64,
              if (result.imageMediaType != null)
                'image_media_type': result.imageMediaType,
            };
          },
        ),
        RepoOp(
          name: 'rig.browserState',
          kind: RepoOpKind.read,
          requiredArgs: ['rig_id'],
          handler: (ctx) async {
            // The address bar's live half: back/forward reachability comes
            // from the page's own session history, so it has to be asked for
            // — the pushed `current_url` on the rig row is the other half.
            final rig = await rigs.get(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
            );
            if (rig == null) {
              throw const NotFoundException('Rig not found in this workspace');
            }
            if (rig.surface != RigSurface.browser) {
              throw ValidationException(
                'Rig ${rig.id} is a ${rig.surface.wire} rig; only a browser '
                'rig has navigation state.',
              );
            }
            final state = await rigs.browserState(
              workspaceId: ctx.workspaceId!,
              rigId: rig.id,
            );
            // Not live (booting, closed): report the last known URL with no
            // history rather than erroring a toolbar that races the boot.
            return state?.toJson() ??
                {
                  'url': rig.currentUrl ?? '',
                  'can_go_back': false,
                  'can_go_forward': false,
                  'loading': false,
                };
          },
        ),
        RepoOp(
          name: 'rig.takeControl',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id'],
          actionClasses: const {ActionClass.enclosureControl},
          handler: (ctx) async {
            final rig = await rigs.takeControl(
              workspaceId: ctx.workspaceId!,
              rigId: ctx.args['rig_id'] as String,
              actor: ctx.principal,
            );
            return rigToWire(rig);
          },
        ),
        RepoOp(
          name: 'rig.releaseControl',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id'],
          actionClasses: const {ActionClass.enclosureControl},
          handler: (ctx) async {
            final rig = await rigs.releaseControl(
              workspaceId: ctx.workspaceId!,
              rigId: ctx.args['rig_id'] as String,
              actor: ctx.principal,
            );
            return rigToWire(rig);
          },
        ),
        RepoOp(
          name: 'rig.images',
          serverAuthority: ServerAuthority.serverOwner,
          kind: RepoOpKind.read,
          workspaceScoped: false,
          handler: (ctx) async {
            // Admin-gated like its two mutations. This is host inventory —
            // which operating systems this machine has on disk and how far a
            // download got — not workspace data, and it is only ever read by
            // the Settings → Enclosures page, which is already operator-only.
            // A viewer in any workspace could read it before.
            requireServerAdmin(ctx);
            return {'images': rigs.imageStatuses()};
          },
        ),
        RepoOp(
          name: 'rig.downloadImage',
          serverAuthority: ServerAuthority.serverOwner,
          kind: RepoOpKind.mutate,
          workspaceScoped: false,
          requiredArgs: ['image_id'],
          // Fetching an operating system onto the host. Not `enclosureControl`
          // — nothing is driven — but it is a real network fetch and a
          // multi-gigabyte write, so it declares both.
          actionClasses: const {
            ActionClass.networkEgress,
            ActionClass.packageInstall,
          },
          handler: (ctx) async {
            requireServerAdmin(ctx);
            // Returns as soon as the download is ACCEPTED, not when it
            // finishes: a base image is ~590 MB and holding an RPC call open
            // for minutes ties up the connection and times the client out on a
            // download that is working fine. The service owns the transfer;
            // progress rides on `rig.images` (the partial size on disk).
            await rigs.downloadImage(ctx.args['image_id'] as String);
            return const {'started': true};
          },
        ),
        RepoOp(
          name: 'rig.importImage',
          serverAuthority: ServerAuthority.serverOwner,
          kind: RepoOpKind.mutate,
          workspaceScoped: false,
          requiredArgs: ['image_id', 'path'],
          actionClasses: const {ActionClass.packageInstall},
          handler: (ctx) async {
            // Reading a caller-named path off the server's disk, so it is
            // operator-only: this is the same trust level as choosing which
            // operating system every rig on this host boots.
            requireServerAdmin(ctx);
            await rigs.importImage(
              imageId: ctx.args['image_id'] as String,
              sourcePath: ctx.args['path'] as String,
            );
            return const {};
          },
        ),
        RepoOp(
          name: 'rig.removeImage',
          serverAuthority: ServerAuthority.serverOwner,
          kind: RepoOpKind.mutate,
          workspaceScoped: false,
          requiredArgs: ['image_id'],
          actionClasses: const {ActionClass.fileDelete},
          handler: (ctx) async {
            requireServerAdmin(ctx);
            await rigs.removeImage(ctx.args['image_id'] as String);
            return const {};
          },
        ),
        RepoOp(
          name: 'rig.destroy',
          // Mutate, like `terminal.kill` — NOT destructive. A rig is
          // disposable by construction (overlay discarded, TTL-bounded), so
          // stopping one is routine lifecycle, and `destructive` is denied
          // outright wherever no confirmation flow is wired ("Operation
          // requires approval") — which made the panel's stop button fail
          // with a permission error on every press.
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id'],
          actionClasses: const {ActionClass.enclosureControl},
          handler: (ctx) async {
            // Parsed HERE, at the wire edge, so an unknown reason is a named
            // validation error rather than a silent fall back to `requested`
            // in the service — the row's close reason is the only surviving
            // answer to "where did my machine go".
            final rawReason = ctx.args['reason'];
            if (rawReason != null && rawReason is! String) {
              throw const ValidationException(
                'Invalid argument: reason (expected a string)',
              );
            }
            final reason = rawReason == null
                ? null
                : RigCloseReason.fromWire(rawReason as String);
            if (rawReason != null && reason == null) {
              throw ValidationException(
                'Unknown close reason "$rawReason". Expected one of: '
                '${RigCloseReason.values.map((r) => r.wire).join(', ')}.',
              );
            }
            // Look the row up BEFORE close so the audit trail can say
            // which machine and which space, not just `rig.destroy`.
            final existing = await rigs.get(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
            );
            await rigs.close(
              workspaceId: ctx.workspaceId!,
              rigId: ctx.args['rig_id'] as String,
              reason: reason,
            );
            return {
              if (existing?.conversationId != null)
                'conversation_id': existing!.conversationId,
              if (existing != null) 'surface': existing.surface.wire,
            };
          },
        ),
      ].map(fullClientOnly),

    // What is listening inside a Terminal (VM), and every address each port
    // answers on: host loopback (`localhost:<port>`), an optional LAN port
    // (`<server-ip>:<random>`), and a dev domain in the Browser (VM). Present
    // only when the host wired a [RigPortsPort] alongside [rigs]. Reads are
    // plain reads; each mutation reconfigures a host listener, so it declares
    // `networkEgress`.
    if (rigPorts != null)
      ...[
        RepoOp(
          name: 'rig.setPortsAutoForward',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'enabled'],
          // The WIDEST of the port ops: with this on, every port a guest opens
          // is forwarded automatically, so one call stands in for an unbounded
          // number of `rig.addPort`s. It shipped with no class and
          // `audited: false` — an egress decision that neither the guardrails
          // nor the activity log could see.
          actionClasses: const {ActionClass.networkEgress},
          handler: (ctx) async {
            final ok = await rigPorts.setPortsAutoForward(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
              enabled: ctx.args['enabled'] == true,
            );
            return {'ok': ok};
          },
        ),
        RepoOp(
          name: 'rig.addPort',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'guest_port'],
          actionClasses: const {ActionClass.networkEgress},
          handler: (ctx) async {
            final port = asPort(ctx.args['guest_port']);
            if (port == null) {
              throw const ValidationException(
                'Invalid argument: guest_port (expected 1-65535)',
              );
            }
            final ok = await rigPorts.addPortForward(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
              port,
            );
            return {'ok': ok};
          },
        ),
        RepoOp(
          name: 'rig.removePort',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'guest_port'],
          // Reconfigures the same host listener its sibling opens. Declared
          // even though this direction only ever NARROWS exposure: the class
          // is what a read-only mode denies, and a mode that refuses `addPort`
          // has nothing left for this to close.
          actionClasses: const {ActionClass.networkEgress},
          handler: (ctx) async {
            final port = asPort(ctx.args['guest_port']);
            if (port == null) {
              throw const ValidationException(
                'Invalid argument: guest_port (expected 1-65535)',
              );
            }
            final ok = await rigPorts.removePortForward(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
              port,
            );
            return {'ok': ok};
          },
        ),
        RepoOp(
          name: 'rig.setPortLan',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'guest_port', 'exposed'],
          // Publishing a guest port on the LAN is a real egress decision, so
          // it declares the class — read-only modes deny it, and the autonomy
          // dial can demote it to a prompt.
          actionClasses: const {ActionClass.networkEgress},
          handler: (ctx) async {
            final port = asPort(ctx.args['guest_port']);
            if (port == null) {
              throw const ValidationException(
                'Invalid argument: guest_port (expected 1-65535)',
              );
            }
            final ok = await rigPorts.setPortLanExposed(
              ctx.workspaceId!,
              ctx.args['rig_id'] as String,
              port,
              exposed: ctx.args['exposed'] == true,
            );
            return {'ok': ok};
          },
        ),
        RepoOp(
          name: 'rig.setPortDomain',
          kind: RepoOpKind.mutate,
          requiredArgs: ['rig_id', 'guest_port'],
          // Mapping a dev domain onto a guest port is the same kind of
          // exposure decision `setPortLan` declares — it changes which name
          // reaches what is listening inside the machine.
          actionClasses: const {ActionClass.networkEgress},
          handler: (ctx) async {
            final port = asPort(ctx.args['guest_port']);
            if (port == null) {
              throw const ValidationException(
                'Invalid argument: guest_port (expected 1-65535)',
              );
            }
            try {
              final ok = await rigPorts.setPortDomain(
                ctx.workspaceId!,
                ctx.args['rig_id'] as String,
                port,
                ctx.args['domain'] as String?,
              );
              return {'ok': ok};
            } on ArgumentError catch (e) {
              // The domain validation message reaches the client verbatim.
              throw ValidationException('${e.message}');
            }
          },
        ),
      ].map(fullClientOnly),

    // Same snapshots and mutations as `rig.*Port*`. The literals live in
    // `catalog/terminal_port_ops.dart` so this file's RepoOp freeze does not
    // grow. Present only when [rigPorts] is wired (demo omits them).
    if (rigPorts != null)
      ...buildTerminalPortOps(rigPorts: rigPorts).map(fullClientOnly),

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
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: ['space_id'],
          // Full VS Code over the space worktree = code access to every repo
          // the space checks out; gate on the per-repo grant like any other
          // code-bearing surface.
          repoAccess: RepoGrantLevel.read,
          repoAccessVia: reposExposedBySpaceArg,
          handler: (ctx) async {
            final session = await vscode.ensureSession(
              workspaceId: ctx.workspaceId!,
              spaceId: ctx.args['space_id'] as String,
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
            final query = codeServerOpenQuery(
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
        // Save a dirty worktree-relative file to disk by asking the embedded
        // editor (the only holder of the unsaved buffer) via the reverse command
        // space. Backs the app's "Save" tab-close choice. Returns
        // `{saved: bool}` — false when no running session / the save timed out.
        RepoOp(
          name: 'codeServer.saveFile',
          kind: RepoOpKind.mutate,
          requiredArgs: ['space_id', 'path'],
          handler: (ctx) async {
            final saved = await vscode.saveFile(
              workspaceId: ctx.workspaceId!,
              spaceId: ctx.args['space_id'] as String,
              repoId: ctx.args['repo_id'] as String? ?? '',
              path: ctx.args['path'] as String,
            );
            return {'saved': saved};
          },
        ),
      ].map(fullClientOnly),

    // Server filesystem tree (agents/skills/conversations) via
    // [WorkspaceFilesystemPort]; absent when unwired. Workspace-scoped
    // (`ctx.workspaceId!`); opaque-path ops (`fs.ensureDir` / `fs.writeString`)
    // stay workspace-scoped so unbound sessions cannot reach them.
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
          name: 'fs.spacesDir',
          kind: RepoOpKind.read,
          handler: (ctx) async => {
            'path': await fs.spacesDir(ctx.workspaceId!),
          },
        ),
        RepoOp(
          name: 'fs.spaceDir',
          kind: RepoOpKind.read,
          requiredArgs: ['conversation_id'],
          handler: (ctx) async => {
            'path': await fs.spaceDir(
              ctx.workspaceId!,
              ctx.args['conversation_id'] as String,
            ),
          },
        ),
        RepoOp(
          name: 'fs.ensureSpaceDir',
          kind: RepoOpKind.mutate,
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
          requiredArgs: ['conversation_id'],
          handler: (ctx) async => {
            'path': await fs.ensureSpaceDir(
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
          handler: (ctx) async {
            await fs.ensureWorkspaceDirs(ctx.workspaceId!);
            return {'ok': true};
          },
        ),
        RepoOp(
          name: 'fs.ensureAgentDir',
          kind: RepoOpKind.mutate,
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
            final slug = validatedSlug(ctx.args['skill_slug'] as String);
            final content = ctx.args['content'] as String;
            // HARDENED (PRD 23 §2): skill writes route through the antivirus
            // gate (scan → policy → write → pin) whenever the bundle service
            // is wired; the raw write remains only as the fallback for a host
            // with no scanner configured.
            final bundles = skillBundles;
            if (bundles == null) {
              await fs.writeSkillFile(ctx.workspaceId!, slug, content);
              return {'ok': true};
            }
            try {
              await bundles.saveLocal(
                workspaceId: ctx.workspaceId!,
                slug: slug,
                content: content,
                allowQuarantineOverride:
                    ctx.args['allow_quarantine_override'] == true,
              );
              return {'ok': true};
            } on SkillScanBlockedException catch (e) {
              return {
                'ok': false,
                'blocked': true,
                'verdict': e.result?.verdict.wire,
                'findings': [for (final f in e.findings) f.toJson()],
                if (e.reason != null) 'reason': e.reason,
              };
            }
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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
          actionClasses: const {ActionClass.fileWriteOutsideWorktree},
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

    RepoOp(
      name: 'messaging.listSpaces',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final spaces = await messagingRepository
            .watchSpacesByWorkspace(ctx.workspaceId!)
            .first;
        return {'spaces': spaces.map(spaceToWire).toList()};
      },
    ),
    RepoOp(
      name: 'messaging.getMessages',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final messages = await messagingRepository.getMessages(
          ctx.workspaceId!,
          spaceId,
          conversationId: ctx.args['conversation_id'] as String?,
        );
        return {'messages': messages.map(messageToWire).toList()};
      },
    ),
    // Server-side cursor page (replaces shipping the whole conversation
    // client-side). `messageToWireLite` drops segments (history bubbles;
    // transcript opened per message). `hasMore` from keyset (+1 row), not COUNT.
    //
    // `assertSpaceOwned` gates the space; `conversation_id` is SQL-bound to it
    // (`getMessagePageRows`) so owning one space cannot read another's threads.
    RepoOp(
      name: 'messaging.getMessagePage',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id', 'conversation_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final rawLimit = (ctx.args['limit'] as num?)?.toInt();
        final page = await messagingRepository.getMessagePage(
          ctx.workspaceId!,
          spaceId,
          ctx.args['conversation_id'] as String,
          // Clamped server-side: the limit is caller-supplied and an unbounded
          // one would reintroduce exactly the whole-conversation pull this op
          // exists to remove.
          limit: (rawLimit ?? defaultMessagePageSize).clamp(1, 500),
          cursor: ctx.args['cursor'] as String?,
        );
        return {
          'messages': page.messages.map(messageToWireLite).toList(),
          'has_more': page.hasMore,
          'next_cursor': page.nextCursor,
        };
      },
    ),
    RepoOp(
      name: 'messaging.searchInSpace',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id', 'query'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final limit = ctx.args['limit'];
        final messages = await messagingRepository.searchInSpace(
          ctx.workspaceId!,
          spaceId,
          ctx.args['query'] as String,
          limit: limit is int ? limit : 50,
        );
        return {'messages': messages.map(messageToWire).toList()};
      },
    ),
    RepoOp(
      name: 'messaging.sendMessage',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'content'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        // Attribution is stamped server-side. Human messages are authored as
        // the session's USER (not its device: three devices, one author).
        //
        // A non-`user` sender_type used to honor a client-supplied
        // `sender_id` verbatim, justified by "the desktop's own in-process
        // client is the same trust boundary" — but the desktop reaches this op
        // over the SAME WSS surface as any other paired member, so in the
        // multi-user model any member could post as any agent (and agents act
        // on each other through these very messages). So the id must now name
        // a real agent IN THIS WORKSPACE; anything else falls back to the
        // authenticated user rather than being taken on trust.
        final senderType = ctx.args['sender_type'] as String? ?? 'user';
        var senderId = ctx.userId;
        if (senderType != 'user') {
          final claimed = ctx.args['sender_id'] as String?;
          if (claimed != null && claimed.isNotEmpty) {
            final agent = await agentRepository.getById(
              ctx.workspaceId!,
              claimed,
            );
            if (agent == null || agent.workspaceId != ctx.workspaceId) {
              throw const AuthException(
                'sender_id must name an agent in this workspace',
              );
            }
            senderId = claimed;
          }
        }
        final metadata = ctx.args['metadata'];
        final messageId = await messagingRepository.sendMessage(
          workspaceId: ctx.workspaceId!,
          spaceId: spaceId,
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
    if (ensurePrSpace != null)
      RepoOp(
        name: 'pr.ensureSpace',
        kind: RepoOpKind.mutate,
        // Idempotent ensure-on-open — auditing every PR view is noise.
        audited: false,
        requiredArgs: ['repo_full_name', 'pr_number', 'pr_external_id'],
        handler: (ctx) async {
          final result = await ensurePrSpace(
            workspaceId: ctx.workspaceId!,
            repoFullName: ctx.args['repo_full_name'] as String,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            prExternalId: ctx.args['pr_external_id'] as String,
            createdByUserId: ctx.userId,
            title: ctx.args['title'] as String? ?? '',
          );
          return result;
        },
      ),
    if (conversationRepository != null) ...[
      RepoOp(
        name: 'conversation.ensure',
        kind: RepoOpKind.mutate,
        // Idempotent ensure-on-open (like `pr.ensureSpace`) — auditing every
        // space open is noise.
        audited: false,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final conv = await conversationRepository.ensure(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
          );
          return {'conversation': conversationToWire(conv)};
        },
      ),
      RepoOp(
        name: 'conversation.create',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'title'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          // Thread anchoring (validated here, one chokepoint): the anchor
          // message must live in a conversation OF THIS space, and that
          // conversation must itself be unanchored — threads never nest.
          final anchorMessageId = ctx.args['anchor_message_id'];
          if (anchorMessageId is String) {
            final anchor = await messagingRepository.getMessageById(
              ctx.workspaceId!,
              anchorMessageId,
            );
            if (anchor == null || anchor.spaceId != spaceId) {
              throw const NotFoundException(
                'Anchor message not found in this space.',
              );
            }
            final parent = await conversationRepository.getById(
              workspaceId: ctx.workspaceId!,
              conversationId: anchor.conversationId,
            );
            if (parent == null) {
              throw const NotFoundException(
                'Anchor message not found in this space.',
              );
            }
            if (parent.anchorMessageId != null) {
              throw const ValidationException('Threads cannot nest.');
            }
          }
          final conv = await conversationRepository.create(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            title: ctx.args['title'] as String,
            anchorMessageId: anchorMessageId is String ? anchorMessageId : null,
            createdByPrincipalId: ctx.userId,
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
        // Scope-loaded by id: the repository filters on the bound workspace,
        // so a foreign conversation is simply not found. There is no space
        // argument because a caller holding only a conversation id has no
        // space to name — which is what made resolving this through
        // `conversation.list` (with the conversation id passed as `space_id`)
        // fail its ownership check every time.
        name: 'conversation.getById',
        kind: RepoOpKind.read,
        requiredArgs: ['conversation_id'],
        handler: (ctx) async {
          final conversation = await conversationRepository.getById(
            workspaceId: ctx.workspaceId!,
            conversationId: ctx.args['conversation_id'] as String,
          );
          return {
            'conversation': conversation == null
                ? null
                : conversationToWire(conversation),
          };
        },
      ),
      RepoOp(
        name: 'conversation.list',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final list = await conversationRepository.listForSpace(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
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
        // Messages are keyed by id alone — validate the owning space is in the
        // bound workspace so a foreign message can't leak (isolation invariant).
        await assertSpaceOwned(ctx.workspaceId!, message.spaceId);
        final wire = messageToWire(message);
        // Per-viewer trace redaction (PRD 16): transcript bodies never cross
        // a repo grant the viewer lacks.
        if (await viewerTraceRestricted(
          ctx.workspaceId!,
          message.spaceId,
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
      name: 'messaging.spaceExists',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        // Report existence only for a space in the bound workspace — a
        // foreign space reads as "does not exist" (no cross-workspace probe).
        final exists = await spaceInWorkspace(
          ctx.workspaceId!,
          ctx.args['space_id'] as String,
        );
        return {'exists': exists};
      },
    ),
    RepoOp(
      name: 'messaging.getParticipants',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final participants = await messagingRepository.getParticipants(
          ctx.workspaceId!,
          spaceId,
        );
        return {
          'participants': participants.map(spaceParticipantToWire).toList(),
        };
      },
    ),
    RepoOp(
      name: 'messaging.setSpaceMode',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'mode'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.setSpaceMode(
          ctx.workspaceId!,
          spaceId,
          Mode.fromDbValue(ctx.args['mode'] as String),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.addParticipant',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'agent_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.addParticipant(
          ctx.workspaceId!,
          spaceId,
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
        // Messages are keyed by id alone — load + validate the owning space
        // is in the bound workspace before mutating (isolation invariant).
        final existing = await messagingRepository.getMessageById(
          ctx.workspaceId!,
          messageId,
        );
        if (existing == null) {
          throw const NotFoundException('Message not found');
        }
        await assertSpaceOwned(ctx.workspaceId!, existing.spaceId);
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
        final typedMetadata = metadata is Map
            ? metadata.cast<String, dynamic>()
            : null;
        await messagingRepository.updateMessage(
          ctx.workspaceId!,
          messageId,
          content: ctx.args['content'] as String?,
          metadata: typedMetadata,
        );
        // This is where an `ask_user` answer crosses back from the client to
        // the blocked agent. Runs after the write so the persisted state and
        // the resumed run cannot disagree; a no-op for every other update.
        agentQuestions?.resolveFromMetadata(messageId, typedMetadata);
        return {'ok': true};
      },
    ),

    // The human's half of the image lane. An agent's screenshots are stored by
    // the dispatch path; a person's pasted image arrives here, gets written to
    // the SAME per-workspace blob directory, and the composer keeps only the
    // returned reference — so a pasted screenshot never becomes base64 inside
    // a message row.
    //
    // Membership is the gate: `ctx.workspaceId` is the caller's bound
    // workspace and the dispatcher has already checked their role, so this
    // cannot write into a workspace the caller is not a member of. The store
    // itself caps size and refuses a payload that is not decodable.
    if (blobStore != null)
      RepoOp(
        name: 'blob.put',
        kind: RepoOpKind.mutate,
        // Content-addressed and idempotent — re-running writes the same bytes
        // to the same path — but there is no inverse and nothing a person
        // would want to "undo": the blob is meaningless until a message
        // references it, and THAT message is what enters the undo stack.
        undoClass: UndoClass.irreversible,
        requiredArgs: ['data'],
        handler: (ctx) async {
          final data = ctx.args['data'];
          if (data is! String || data.isEmpty) {
            throw const ValidationException('data must be a base64 string');
          }
          // Any type, not just images: the device and the server are often not
          // the same machine, so a dropped PDF or source file has to have its
          // BYTES here too — a host path means nothing on this side.
          final mediaType = ctx.args['media_type'];
          final stored = await blobStore.putBase64(
            ctx.workspaceId!,
            data,
            mediaType: mediaType is String && mediaType.contains('/')
                ? mediaType
                : 'application/octet-stream',
          );
          if (stored == null) {
            throw const ValidationException(
              'attachment could not be stored (empty, malformed, or too large)',
            );
          }
          return {
            'ref': stored.ref,
            'bytes': stored.bytes,
            'media_type': stored.mediaType,
          };
        },
      ),

    // Opening a DM, creating a group, deleting/clearing a space and removing
    // a participant are pure persistence — they need no dispatch engine — so
    // they are served on EVERY host (including a pure-Dart headless server),
    // backed by the same [MessagingRepository] the in-process [MessagingService]
    // wraps. This keeps the thin/web client's "new space / clear /
    // remove participant" actions working with or without a wired dispatch
    // engine (previously these lived under `dispatch.*` and 404'd on a headless
    // server). Behaviour matches the old ops (which only delegated to the repo);
    // `deleteSpace` additionally re-publishes [SpaceDeleted] so worktree
    // GC still fires. Every op sources `ctx.workspaceId!` (never a client arg)
    // and asserts space ownership (isolation invariant).
    RepoOp(
      name: 'messaging.createSpace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['name', 'agent_ids'],
      handler: (ctx) async {
        // Through [SpaceFactory] — the same chokepoint the in-process
        // [MessagingService] uses — so the row and its `SpaceCreated` stay one
        // operation. A space created without the event never provisions its
        // checkout: the room sits behind the "preparing workspace" gate forever
        // and the composer's sends stay parked.
        final space =
            await SpaceFactory(
              repository: messagingRepository,
              eventBus: eventBus,
            ).create(
              ctx.workspaceId!,
              ctx.args['name'] as String,
              (ctx.args['agent_ids'] as List).cast<String>(),
              mode: Mode.fromDbValue(ctx.args['mode'] as String? ?? 'chat'),
              pipelineRunId: ctx.args['pipeline_run_id'] as String?,
              // The creating human joins as a first-class participant (their
              // own read cursor); identity comes from the session, never args.
              createdByUserId: ctx.userId,
              // Optional per-space repo selection; absent → all workspace
              // repos, an EMPTY list → the space checks out no repos at all.
              repoIds: (ctx.args['repo_ids'] as List?)?.cast<String>(),
              // The base branch each selected repo's worktree is cut from,
              // keyed by repo id. Absent → the repo's own default branch.
              repoBranches: (ctx.args['repo_branches'] as Map?)
                  ?.cast<String, String>(),
            );
        return {'space': spaceToWire(space)};
      },
    ),
    RepoOp(
      name: 'messaging.deleteSpace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.deleteSpace(ctx.workspaceId!, spaceId);
        // Mirror MessagingService.deleteSpace: let listeners (e.g. worktree
        // GC) tear down per-conversation resources.
        eventBus?.publish(
          SpaceDeleted(
            spaceId: spaceId,
            workspaceId: ctx.workspaceId!,
            occurredAt: DateTime.now(),
          ),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.archiveSpace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.archiveSpace(ctx.workspaceId!, spaceId);
        // Deliberately no SpaceDeleted: archiving is a reversible hide, so
        // nothing (worktree GC, retention sweeps) may tear the space's
        // resources down — restore expects them intact.
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.unarchiveSpace',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.unarchiveSpace(ctx.workspaceId!, spaceId);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.updateSpaceName',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'name'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.updateSpaceName(
          ctx.workspaceId!,
          spaceId,
          ctx.args['name'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.getSpaceRepos',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        // The effective selection in createSpace's contract: null → all
        // workspace repos, [] → explicitly none, a subset → those ids.
        final repoIds = await messagingRepository.spaceRepoSelection(
          ctx.workspaceId!,
          spaceId,
        );
        return {'repo_ids': repoIds};
      },
    ),
    RepoOp(
      name: 'messaging.setSpaceRepos',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(workspaceId, spaceId);
        // Same contract as createSpace: absent/null → all workspace repos,
        // an EMPTY list → explicitly none. Repos the selection DROPS lose
        // their worktree folder through the provisioner's ordinary destroy
        // path (uncommitted work is rescued, never silently deleted).
        final repoIds = (ctx.args['repo_ids'] as List?)?.cast<String>();
        // What the space checked out BEFORE the edit, so an unchanged save
        // (the dialog's Save with nothing touched) costs nothing.
        final before = await messagingRepository.spaceRepoSelection(
          workspaceId,
          spaceId,
        );
        await messagingRepository.setSpaceRepos(workspaceId, spaceId, repoIds);
        await provisioner?.releaseSpaceReposOutside(
          workspaceId: workspaceId,
          spaceId: spaceId,
          keepRepoIds: repoIds?.toSet(),
        );
        // Materialize worktrees for repos added to a space (idempotent reuse).
        // Without this the folder never appears until a later dispatch.
        // Unawaited like `SpaceCreated`: clone is slow; `provision` writes its
        // own terminal status. Kicked before answering so `provisioning` is
        // in flight when the dialog closes.
        if (retrySpaceProvisioning != null &&
            spaceReposChanged(before, repoIds)) {
          unawaited(
            retrySpaceProvisioning(
              workspaceId: workspaceId,
              spaceId: spaceId,
            ).catchError((Object e, StackTrace st) {
              CcHostLog.error(
                'space provisioning: re-provision after repo edit failed '
                'for $spaceId: $e',
                e,
                st,
              );
            }),
          );
        }
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.clearSpaceMessages',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.clearSpaceMessages(ctx.workspaceId!, spaceId);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'messaging.removeParticipant',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'agent_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await messagingRepository.removeParticipant(
          ctx.workspaceId!,
          spaceId,
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
    // The conversation's branch tree. Read-only: the tree is derived from the
    // parent links every message already carries, so nothing has to be
    // maintained alongside it.
    RepoOp(
      name: 'messaging.conversationTree',
      kind: RepoOpKind.read,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        final tree = await messagingRepository.conversationTree(
          workspaceId: ctx.workspaceId!,
          conversationId: ctx.args['conversation_id'] as String,
        );
        return {
          'leaf_message_id': ?tree.leafMessageId,
          'branch_count': tree.branchCount,
          'nodes': [
            for (final node in tree.nodes)
              {
                'message_id': node.messageId,
                'parent_message_id': ?node.parentMessageId,
                'sender_type': node.senderType,
                'sender_id': node.senderId,
                'preview': node.preview,
                'created_at': node.createdAt.toIso8601String(),
                'on_current_branch': node.onCurrentBranch,
                'child_count': node.childCount,
              },
          ],
        };
      },
    ),
    // Moves the branch pointer. Writes nothing else — that is the whole
    // session-tree design: the path you left is still there, so switching back
    // is another pointer move rather than a restore.
    RepoOp(
      name: 'messaging.branchConversationAt',
      kind: RepoOpKind.mutate,
      requiredArgs: ['conversation_id', 'message_id'],
      handler: (ctx) async {
        await messagingRepository.branchConversationAt(
          workspaceId: ctx.workspaceId!,
          conversationId: ctx.args['conversation_id'] as String,
          messageId: ctx.args['message_id'] as String,
        );
        return {'ok': true};
      },
    ),
    // Copies a branch into a NEW conversation. A copy rather than a pointer,
    // because two conversations sharing rows would show each other's later
    // messages.
    RepoOp(
      name: 'messaging.forkConversation',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'conversation_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final forkId = await messagingRepository.forkConversation(
          workspaceId: ctx.workspaceId!,
          spaceId: spaceId,
          conversationId: ctx.args['conversation_id'] as String,
          messageId: ctx.args['message_id'] as String?,
          title: ctx.args['title'] as String?,
        );
        return {'conversation_id': forkId};
      },
    ),
    RepoOp(
      name: 'messaging.revertConversationTo',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'message_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final messageId = ctx.args['message_id'] as String;
        final inclusive = ctx.args['inclusive'] as bool? ?? false;
        // Prefer the host closure (transcript + worktree filesystem rollback);
        // fall back to a transcript-only revert where no closure is wired.
        if (conversationRevert != null) {
          final outcome = await conversationRevert(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
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
          spaceId,
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
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final affected = conversationUnrevert != null
            ? await conversationUnrevert(
                workspaceId: ctx.workspaceId!,
                spaceId: spaceId,
              )
            : await messagingRepository.unrevertConversation(
                ctx.workspaceId!,
                spaceId,
              );
        return {'affected_message_ids': affected};
      },
    ),
    if (retrySpaceProvisioning != null)
      RepoOp(
        name: 'messaging.retrySpaceProvisioning',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await retrySpaceProvisioning(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
          );
          return {'ok': true};
        },
      ),
    if (cancelSpaceProvisioning != null)
      RepoOp(
        name: 'messaging.cancelSpaceProvisioning',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await cancelSpaceProvisioning(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
          );
          return {'ok': true};
        },
      ),

    // Dispatch ops need a wired [MessagingPort] (null → ops absent). Replies
    // stream via `messaging.watch*`. Every op uses `ctx.workspaceId!` and
    // asserts space ownership.
    if (dispatch != null) ...[
      RepoOp(
        name: 'dispatch.sendUserMessage',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'content'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final metadata = ctx.args['metadata'];
          await dispatch.sendUserMessage(
            ctx.workspaceId!,
            spaceId,
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
        name: 'dispatch.addAgentToSpace',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'agent_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await dispatch.addAgentToSpace(
            ctx.workspaceId!,
            spaceId,
            ctx.args['agent_id'] as String,
            renameForGroup: ctx.args['rename_for_group'] != false,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.sendAndDispatch',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'content'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await dispatch.sendAndDispatch(
            ctx.workspaceId!,
            spaceId,
            ctx.args['content'] as String,
            // Authored by the session's user (identity, never client args).
            senderUserId: ctx.userId,
            conversationId: ctx.args['conversation_id'] as String?,
            structuredMentions: structuredMentionsFromWire(
              ctx.args['structured_mentions'],
            ),
            entityRefs: entityRefsFromWire(ctx.args['entity_refs']),
            // What the caller attached, narrowed to `attachments` — the rest of
            // a message's metadata is this server's to write.
            metadata: userMessageMetadataFromWire(ctx.args['metadata']),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.dispatchAgent',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'agent_id', 'prompt'],
        // An agent run reads and edits the space's repos on the caller's
        // behalf and streams the results back to them — code access by proxy,
        // so the caller needs the same read grant the direct surfaces require.
        repoAccess: RepoGrantLevel.read,
        repoAccessVia: reposExposedBySpaceArg,
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final schema = ctx.args['expected_output_schema'];
          final runId = await dispatch.dispatchAgent(
            spaceId: spaceId,
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
            wakeContext: wakeContextFromWire(ctx.args['wake_context']),
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
        requiredArgs: ['space_id', 'feedback'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await dispatch.refinePlan(
            spaceId: spaceId,
            feedback: ctx.args['feedback'] as String,
            workspaceId: ctx.workspaceId!,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'dispatch.retryAgentTurn',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'failed_message_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          await dispatch.retryAgentTurn(
            spaceId: spaceId,
            failedMessageId: ctx.args['failed_message_id'] as String,
            // The session's workspace, never a client arg. Without it the
            // retried run log carries no workspace, which hides it from the
            // composer's stop affordance and makes the ownership check on
            // `dispatch.stopRun` reject it — an unstoppable run.
            workspaceId: ctx.workspaceId!,
            // Retrying on a DIFFERENT model is the move that actually changes
            // the outcome when the first model produced something the loop
            // could not use. Applies to this run only — the agent record keeps
            // its configured model.
            modelOverride: ctx.args['model_override'] as String?,
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
      // transport with no steering space).
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
      // Unlike `dispatch.steer` (fire-and-forget, in-process delivery only),
      // these ops persist steering messages as conversation rows: every client
      // sees the same queue over `messaging.watchMessages`, injected rows move
      // into the trail, and anything still queued when the last run ends
      // converts to a normal user message. All workspace-scoped: the workspace
      // comes from the session, and space/conversation ownership is asserted
      // before anything is written.
      RepoOp(
        name: 'steering.enqueue',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'conversation_id', 'message'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final conversationId = ctx.args['conversation_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final result = await dispatch.enqueueSteering(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: conversationId,
            content: ctx.args['message'] as String,
          );
          if (result == null) {
            // No run is live: nothing to steer. The client treats this as
            // "fall through to a normal send".
            return {'message_id': null, 'steerable': false};
          }
          return {
            'message_id': result.messageId,
            'steerable': result.steerable,
          };
        },
      ),
      RepoOp(
        name: 'steering.update',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'conversation_id', 'message_id', 'message'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final conversationId = ctx.args['conversation_id'] as String;
          final messageId = ctx.args['message_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final ok = await dispatch.editSteering(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: conversationId,
            messageId: messageId,
            content: ctx.args['message'] as String,
          );
          return {'ok': ok};
        },
      ),
      RepoOp(
        name: 'steering.delete',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'conversation_id', 'message_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final conversationId = ctx.args['conversation_id'] as String;
          final messageId = ctx.args['message_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final ok = await dispatch.deleteSteering(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: conversationId,
            messageId: messageId,
          );
          return {'ok': ok};
        },
      ),
      RepoOp(
        name: 'steering.reorder',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'conversation_id', 'message_ids'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final conversationId = ctx.args['conversation_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final ids = (ctx.args['message_ids'] as List)
              .whereType<String>()
              .toList();
          await dispatch.reorderSteering(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: conversationId,
            orderedIds: ids,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'steering.deliver',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id', 'conversation_id', 'message_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          final conversationId = ctx.args['conversation_id'] as String;
          final messageId = ctx.args['message_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final delivered = await dispatch.deliverSteering(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: conversationId,
            messageId: messageId,
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
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final result = await dispatch.compactConversation(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: ctx.args['conversation_id'] as String?,
          );
          return {
            'status': result.status.name,
            'compacted_count': result.compactedMessageCount,
          };
        },
      ),
      // `/shake`: drop heavy content WITHOUT summarizing. The move between
      // doing nothing and compacting — no model call, every word kept, only
      // the bulk nobody was going to re-read is blanked. Like `/compact` the
      // command never lands in the transcript.
      RepoOp(
        name: 'dispatch.shake',
        kind: RepoOpKind.mutate,
        // The blanked output is not recoverable from the message row, so
        // there is no inverse to register.
        undoClass: UndoClass.irreversible,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final result = await dispatch.shakeConversation(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: ctx.args['conversation_id'] as String?,
            target: ctx.args['target'] as String? ?? 'tool_output',
          );
          return {
            'tokens_reclaimed': result.tokensReclaimed,
            'messages_touched': result.messagesTouched,
            'images_dropped': result.imagesDropped,
            'unavailable': result.unavailable,
          };
        },
      ),
      // `/handoff`, `/btw`, `/omfg`: one question ABOUT the conversation that
      // never becomes part of it. The command and its answer are deliberately
      // not persisted — the agent's next real turn sees exactly what it would
      // have seen anyway, which is the whole value of asking.
      // One step of the `/goal` objective interview. A read: it spends a model
      // call and persists nothing — the objective only becomes real when the
      // human dispatches it.
      RepoOp(
        name: 'dispatch.guidedGoalStep',
        kind: RepoOpKind.read,
        requiredArgs: ['rough'],
        handler: (ctx) async {
          final step = await dispatch.guidedGoalStep(
            workspaceId: ctx.workspaceId!,
            rough: ctx.args['rough'] as String,
            transcript: [
              for (final line in (ctx.args['transcript'] as List?) ?? const [])
                if (line is String) line,
            ],
          );
          return {
            'question': ?step.question,
            'objective': ?step.objective,
            'missing': step.missing,
            'weaknesses': step.weaknesses,
            'unavailable': step.unavailable,
          };
        },
      ),
      RepoOp(
        name: 'dispatch.aside',
        // A read: it spends a model call but persists nothing, which is the
        // defining property of a side channel.
        kind: RepoOpKind.read,
        requiredArgs: ['space_id', 'kind'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final result = await dispatch.askAside(
            workspaceId: ctx.workspaceId!,
            spaceId: spaceId,
            conversationId: ctx.args['conversation_id'] as String?,
            kind: ctx.args['kind'] as String,
            input: ctx.args['input'] as String? ?? '',
          );
          return {
            'text': ?result.text,
            'unavailable': result.unavailable,
            'empty': result.empty,
          };
        },
      ),
    ],

    // Sends selected PR-review findings to an agent that fixes them, posting
    // into the space. The agent process spawns on the SERVER; the working
    // directory is resolved host-side from the bound workspace (NOT a client
    // path), so a thin client can't aim the agent at an arbitrary directory.
    // Present only when the host wired a [ReviewDispatchFn] (desktop in-process
    // host); a headless server leaves it absent. Space ownership is asserted
    // before dispatch (isolation invariant).
    if (reviewDispatcher != null)
      RepoOp(
        name: 'dispatch.reviewFeedbackAgent',
        kind: RepoOpKind.mutate,
        requiredArgs: ['agent_id', 'prompt', 'space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final conversationId = ctx.args['conversation_id'];
          await reviewDispatcher(
            workspaceId: ctx.workspaceId!,
            agentId: ctx.args['agent_id'] as String,
            prompt: ctx.args['prompt'] as String,
            spaceId: spaceId,
            conversationId: conversationId is String ? conversationId : null,
            // Stamped from the session identity, never a client arg.
            requestedByUserId: ctx.userId,
          );
          return {'ok': true};
        },
      ),

    RepoOp(
      name: 'newsfeed.listArticles',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final articles = await newsfeedRepository
            .watchArticles(ctx.userId)
            .first;
        return {'articles': articles.map(articleToWire).toList()};
      },
    ),
    // The other real-external-data lane besides the newsfeed: the SERVER
    // fetches public repo metadata and caches it, the visitor reads the one
    // number their tour's "Star on GitHub" button shows next to its label.
    // Unscoped (no workspace owns it), session-gated like every op, and
    // declared only when the host wired [demoRepoStars] — which only the demo
    // composition does, so a production server answers `opUnknown` here.
    if (demoRepoStars != null)
      RepoOp(
        name: 'demo.repoStars',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => {'stars': await demoRepoStars()},
      ),
    // Scoped point lookup. The client used to `listArticles()` and scan for the
    // id, which pulls every article across every subscribed feed to answer a
    // primary-key question. The DAO query joins through `rss_feeds` so the
    // article is found only if it belongs to THIS user's feeds — an id alone
    // never proves ownership.
    RepoOp(
      name: 'newsfeed.getArticle',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['article_id'],
      handler: (ctx) async {
        final article = await newsfeedRepository.getArticleById(
          ctx.userId,
          ctx.args['article_id'] as String,
        );
        if (article == null) {
          throw const NotFoundException('Article not found');
        }
        return {'article': articleToWire(article)};
      },
    ),
    RepoOp(
      name: 'newsfeed.setArticleRead',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['article_id', 'read'],
      handler: (ctx) async {
        await newsfeedRepository.setArticleRead(
          ctx.userId,
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
          ctx.userId,
          ctx.args['article_id'] as String,
          saved: ctx.args['saved'] as bool,
        );
        return {'ok': true};
      },
    ),
    // Feed management + refresh (per-user). RSS fetching runs server-side;
    // these let a thin client SEE the user's feeds, manage them and trigger
    // a host-side fetch. The refreshed rows stream back over
    // `newsfeed.watchArticles` / `newsfeed.watchFeeds`.
    RepoOp(
      name: 'newsfeed.refreshAll',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      // Fetches every enabled feed + og:image fallbacks host-side; the
      // first-party client gives the call 3 minutes, so the server budget
      // must outlive it (the deadline exists to free the session slot, not
      // to cut a healthy sweep short).
      timeout: const Duration(minutes: 4),
      handler: (ctx) async {
        await newsfeedRepository.refreshAll(ctx.userId);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.refreshFeed',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['feed_id'],
      // See `newsfeed.refreshAll` for the budget.
      timeout: const Duration(minutes: 4),
      handler: (ctx) async {
        await newsfeedRepository.refreshFeed(
          ctx.userId,
          ctx.args['feed_id'] as String,
        );
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
          ctx.userId,
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
          ctx.userId,
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
        await newsfeedRepository.deleteFeed(
          ctx.userId,
          ctx.args['feed_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'newsfeed.markAllRead',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await newsfeedRepository.markAllRead(ctx.userId);
        return {'ok': true};
      },
    ),
    // Seeds the session user's default feed set on first use, so a user
    // created after boot still gets the bundled defaults the moment they
    // open the newsfeed (the boot-time sweep only covers users that
    // existed at startup).
    RepoOp(
      name: 'newsfeed.seedDefaultFeedsIfEmpty',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await newsfeedRepository.seedDefaultFeedsIfEmpty(ctx.userId);
        return {'ok': true};
      },
    ),

    RepoOp(
      name: 'space_read.markSpaceRead',
      kind: RepoOpKind.mutate,
      // Per-user read cursor — recording every "opened a space" is noise.
      audited: false,
      requiredArgs: ['space_id'],
      // Reading a space is not a workspace mutation; viewers/guests keep
      // their own cursors too.
      minRole: WorkspaceRole.guest,
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        await spaceReadRepository.markSpaceRead(
          ctx.workspaceId!,
          spaceId,
          ctx.userId,
        );
        return {'ok': true};
      },
    ),

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

    // The workspace-scoped mirror of `prefs.*`: an opaque key/value space for
    // configuration two members of a workspace must agree on (branch naming,
    // agent/model defaults, default sandbox capabilities, data-sharing policy).
    // Previously these lived in device-local preferences, so two members — or
    // one member on two machines — disagreed about workspace policy.
    //
    // Reads sit at `member` rather than the derived `guest` floor because the
    // set describes the workspace's security posture. Writes carry an EXPLICIT
    // admin floor: `kind: mutate` alone would derive `member` and any member
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

    // The scope above a workspace: what any process on this HOST may do
    // (sandbox posture, per-adapter launch argv/env). Not workspace-scoped
    // because one host serves every workspace — a per-workspace waiver of a
    // host bound is a host-wide waiver in practice.
    //
    // NOTE the gate. These ops are `workspaceScoped: false` and the
    // dispatcher only evaluates `minRole` for workspace-scoped ops — so a
    // declared role floor here would be silently ignored. `serverAuthority`
    // is the declarative gate (enforced by the dispatcher, visible in
    // `op/list`); the in-handler `requireServerAdmin` stays as depth for
    // catalogs driven without the dispatcher.
    if (serverSettingsRepository != null)
      RepoOp(
        name: 'server_settings.getAll',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          return {'settings': await serverSettingsRepository.getAll()};
        },
      ),
    if (serverSettingsRepository != null)
      RepoOp(
        name: 'server_settings.set',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
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

    // The agent-permissions matrix reads/writes rules here; the resolver runs
    // client-side against the watched set. upsert/delete are security config →
    // admin floor. All rows are forced into the session workspace.
    if (actionPolicyRepository != null)
      RepoOp(
        name: 'action_policy.list',
        kind: RepoOpKind.read,
        // Security posture is not guest reading material: the rule set names
        // exactly which effects would pass unprompted, per scope.
        minRole: WorkspaceRole.member,
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

    // A starting posture and a way to move one between workspaces. Without
    // these a workspace starts at the built-in defaults and an operator
    // re-derives the same thirteen decisions by hand, per workspace — which
    // is how a policy surface ends up configured once and never again.
    if (actionPolicyRepository != null) ...[
      RepoOp(
        name: 'action_policy.applyTemplate',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['template'],
        handler: (ctx) async {
          final template = PolicyTemplate.fromWire(
            ctx.args['template'] as String?,
          );
          if (template == null) {
            throw const ValidationException(
              'template must be strict, balanced or permissive',
            );
          }
          final rules = const PolicyTemplates().rulesFor(
            template,
            workspaceId: ctx.workspaceId!,
            idFactory: () => const Uuid().v4(),
            now: DateTime.now(),
            createdBy: ctx.userId,
          );
          for (final rule in rules) {
            await actionPolicyRepository.upsertRule(rule);
          }
          return {'ok': true, 'applied': rules.length};
        },
      ),
      RepoOp(
        name: 'action_policy.export',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final rules = await actionPolicyRepository.rules(ctx.workspaceId!);
          return {
            // A posture, not rows: no ids, no workspace, no timestamps, so
            // importing elsewhere mints fresh rules instead of colliding.
            'policy': const PolicyTemplates().export(rules),
          };
        },
      ),
      RepoOp(
        name: 'action_policy.import',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['policy'],
        handler: (ctx) async {
          final raw = ctx.args['policy'];
          if (raw is! List) {
            throw const ValidationException('policy must be a JSON array');
          }
          final rules = const PolicyTemplates().import(
            raw,
            workspaceId: ctx.workspaceId!,
            idFactory: () => const Uuid().v4(),
            now: DateTime.now(),
            createdBy: ctx.userId,
          );
          for (final rule in rules) {
            await actionPolicyRepository.upsertRule(rule);
          }
          return {'ok': true, 'imported': rules.length};
        },
      ),
    ],

    // A custom role names a base preset and a set of DENIED permissions
    // removed from it, so it can never grant more than its base — which is
    // what keeps every hand-rolled `role.isAdmin` check in this catalog a
    // sound upper bound while the surface migrates to the permission
    // catalog. Members hold them as `custom:<id>`; an old client parses that
    // as an unknown role and fails safe to guest.
    if (workspaceRoleRepository != null &&
        entitlements.has(Entitlement.customRoles)) ...[
      RepoOp(
        name: 'roles.list',
        kind: RepoOpKind.read,
        // The role list names who can do what — governance, not content.
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final roles = await workspaceRoleRepository.forWorkspace(
            ctx.workspaceId!,
          );
          return {
            'roles': [for (final r in roles) roleDefinitionToWire(r)],
            // The vocabulary a role editor offers, derived from the live op
            // catalog so the palette can never drift from what is enforced.
            'catalog': [for (final p in ops.permissions) p.wire],
          };
        },
      ),
      RepoOp(
        name: 'roles.upsert',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['role'],
        handler: (ctx) async {
          final wire = (ctx.args['role'] as Map).cast<String, dynamic>();
          final base = WorkspaceRole.fromWire(wire['base_preset'] as String?);
          if (base == null || base == WorkspaceRole.owner) {
            throw const ValidationException(
              'A custom role must be based on admin, member, viewer or guest',
            );
          }
          final name = (wire['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) {
            throw const ValidationException('A custom role needs a name');
          }
          final rawDenied = wire['denied_permissions'];
          final denied = <String>{
            for (final d in rawDenied is List ? rawDenied : const [])
              if (d is String && Permission.fromWire(d) != null) d,
          };
          await workspaceRoleRepository.upsert(
            ctx.workspaceId!,
            RoleDefinition(
              id: (wire['id'] as String?) ?? const Uuid().v4(),
              name: name,
              basePreset: base,
              deniedPermissions: denied,
              isCustom: true,
            ),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'roles.delete',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['id'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final id = ctx.args['id'] as String;
          final role = await workspaceRoleRepository.byId(workspaceId, id);
          if (role == null) {
            throw const NotFoundException('Role not found');
          }
          // Reassign holders to the base preset FIRST. A member left holding
          // a `custom:<id>` that no longer resolves would fail safe to guest
          // — safe, but a silent demotion nobody asked for.
          final members = identityMembers;
          if (members != null) {
            final wire = 'custom:$id';
            for (final m in await members.getForWorkspace(workspaceId)) {
              if (m.roleWire == wire) {
                await members.setRole(workspaceId, m.userId, role.basePreset);
                eventBus?.publish(
                  WorkspaceMemberRoleChanged(
                    workspaceId: workspaceId,
                    userId: m.userId,
                    role: role.basePreset,
                    occurredAt: DateTime.now(),
                  ),
                );
              }
            }
          }
          await workspaceRoleRepository.delete(workspaceId, id);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'roles.assign',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['user_id', 'role'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final targetUserId = ctx.args['user_id'] as String;
          final wire = ctx.args['role'] as String;
          final members = identityMembers;
          if (members == null) {
            throw const AuthException('This server has no membership wiring');
          }
          final target = await members.getMember(workspaceId, targetUserId);
          if (target == null) {
            throw const NotFoundException('Member not found');
          }
          if (target.role == WorkspaceRole.owner) {
            throw const AuthException(
              "The workspace owner's role cannot be changed",
            );
          }
          final customId = RoleDefinition.customIdOf(wire);
          if (customId == null) {
            throw const ValidationException(
              'roles.assign takes a custom:<id> role; use members.setRole for '
              'a preset',
            );
          }
          final role = await workspaceRoleRepository.byId(
            workspaceId,
            customId,
          );
          if (role == null) {
            throw const NotFoundException('Role not found');
          }
          // Same peer-admin protection as `members.setRole`: handing someone
          // an admin-based role is minting an admin.
          if ((target.role == WorkspaceRole.admin ||
                  role.basePreset == WorkspaceRole.admin) &&
              ctx.role != WorkspaceRole.owner) {
            throw const AuthException(
              "Changing an admin's role requires the workspace owner",
            );
          }
          await members.setRoleWire(workspaceId, targetUserId, wire);
          eventBus?.publish(
            WorkspaceMemberRoleChanged(
              workspaceId: workspaceId,
              userId: targetUserId,
              role: role.basePreset,
              occurredAt: DateTime.now(),
            ),
          );
          return {'ok': true};
        },
      ),
    ],

    // Hash-chained, append-only, allow AND deny. `audit.verifyChain` is the
    // claim an operator hands an auditor: an intact result means no row was
    // edited, deleted or reordered since it was written.
    if (guardDecisionRepository != null) ...[
      RepoOp(
        name: 'audit.list',
        kind: RepoOpKind.read,
        // Reading who was refused what is an administrative view.
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final limit = (ctx.args['limit'] as num?)?.toInt() ?? 100;
          final before = (ctx.args['before_seq'] as num?)?.toInt();
          final rows = await guardDecisionRepository.recent(
            ctx.workspaceId!,
            limit: limit.clamp(1, 500),
            beforeSeq: before,
          );
          return {
            'decisions': [for (final d in rows) guardDecisionToWire(d)],
          };
        },
      ),
      RepoOp(
        name: 'audit.verifyChain',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.admin,
        handler: (ctx) async {
          final result = await guardDecisionRepository.verifyChain(
            ctx.workspaceId!,
          );
          return {
            'rows_checked': result.rowsChecked,
            'intact': result.intact,
            'broken_at_seq': ?result.brokenAtSeq,
            'reason': ?result.reason,
          };
        },
      ),
      RepoOp(
        name: 'audit.export',
        kind: RepoOpKind.read,
        // The whole trail in one response: owner-only, and paged so a large
        // chain does not have to be buffered whole.
        minRole: WorkspaceRole.owner,
        handler: (ctx) async {
          final from = (ctx.args['from_seq'] as num?)?.toInt() ?? 1;
          final limit = (ctx.args['limit'] as num?)?.toInt() ?? 500;
          final rows = await guardDecisionRepository.pageFrom(
            ctx.workspaceId!,
            from,
            limit: limit.clamp(1, 1000),
          );
          return {
            'decisions': [for (final d in rows) guardDecisionToWire(d)],
            'next_seq': rows.isEmpty ? null : rows.last.seq + 1,
          };
        },
      ),
    ],

    // Server-owner only, and unscoped: these rules apply to EVERY workspace.
    // They can only tighten — `PolicyResolver` merges them most-restrictive
    // with the workspace chain — so an admin cannot use their own workspace
    // policy to escape one. A `CC_SERVER_MANAGED_POLICY` file outranks these
    // rows entirely, which is what lets an operator pin a posture no admin UI
    // can flip.
    if (managedPolicy != null &&
        entitlements.has(Entitlement.managedPolicy)) ...[
      RepoOp(
        name: 'managed_policy.list',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final rules = await managedPolicy.rules();
          return {
            'pinned_to_file': managedPolicy.isPinnedToFile,
            'rules': [
              for (final r in rules)
                {
                  'id': r.id,
                  'action_class': ?r.actionClass?.wire,
                  'command_prefix': ?r.commandPrefix,
                  'decision': r.decision.wire,
                  'enforcement': r.enforcement.wire,
                  'constraint': ?r.constraint?.toJson(),
                },
            ],
          };
        },
      ),
      RepoOp(
        name: 'managed_policy.upsert',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        requiredArgs: ['decision'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          if (managedPolicy.isPinnedToFile) {
            throw const AuthException(
              'This install pins its managed policy to a file '
              '(CC_SERVER_MANAGED_POLICY); stored rules are not consulted.',
            );
          }
          final rawClass = ctx.args['action_class'];
          final rawPrefix = ctx.args['command_prefix'];
          if ((rawClass is String) == (rawPrefix is String)) {
            throw const ValidationException(
              'Exactly one of action_class / command_prefix must be set',
            );
          }
          if (rawClass is String && ActionClass.fromWire(rawClass) == null) {
            throw const ValidationException('Unknown action class');
          }
          final rawConstraint = ctx.args['constraint'];
          await managedPolicy.upsert(
            id: ctx.args['id'] as String?,
            actionClass: rawClass is String ? rawClass : null,
            commandPrefix: rawPrefix is String ? rawPrefix : null,
            decision: ActionDecision.fromWire(ctx.args['decision'] as String),
            enforcement: EnforcementLevel.fromWire(
              ctx.args['enforcement'] as String?,
            ),
            constraint: rawConstraint is Map
                ? ActionConstraint.fromJson(
                    rawConstraint.cast<String, dynamic>(),
                  )
                : null,
            updatedBy: ctx.userId,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'managed_policy.delete',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        requiredArgs: ['id'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await managedPolicy.delete(ctx.args['id'] as String);
          return {'ok': true};
        },
      ),
    ],

    // Which worktrees the operator has allowed agents to run programs from.
    // Read is member-level (seeing what you granted is not privileged);
    // revoking is security config, so it takes the same admin floor as the
    // guardrail store. Both are forced into the session workspace.
    //
    // There is deliberately NO grant op: a grant is only ever created by
    // answering a confirmation the sandbox raised, so the decision is always
    // attached to a concrete tree the operator was shown. A client that could
    // mint one directly would be a way to widen the sandbox with no prompt.
    if (sandboxExecGrantRepository != null)
      RepoOp(
        name: 'sandbox.listExecGrants',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final grants = await sandboxExecGrantRepository.grants(
            ctx.workspaceId!,
          );
          return {
            'grants': [
              for (final g in grants)
                {
                  'id': g.id,
                  'path': g.path,
                  'decision': g.decision.wire,
                  'created_by': g.createdBy,
                  'created_at': g.createdAt.toUtc().toIso8601String(),
                },
            ],
          };
        },
      ),
    if (sandboxExecGrantRepository != null)
      RepoOp(
        name: 'sandbox.revokeExecGrant',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['id'],
        handler: (ctx) async {
          await sandboxExecGrantRepository.revoke(
            ctx.workspaceId!,
            ctx.args['id'] as String,
          );
          return {'ok': true};
        },
      ),

    // (the skills.sh registry replacement). Everything here is
    // workspace-scoped — the sources, the lock, the scan cache and the skills
    // dir are per-workspace — and every install routes through the mandatory
    // scan gate inside SkillBundleService. Repository metadata is untrusted
    // display data; the content hash CC computes over the fetched bytes is the
    // only trusted fact.
    if (skillSources != null)
      RepoOp(
        name: 'skills.sourcesList',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final sources = await skillSources.list(ctx.workspaceId!);
          return {
            'sources': [for (final s in sources) skillSourceToWire(s)],
          };
        },
      ),
    if (skillSources != null && skillSourceCatalog != null)
      RepoOp(
        name: 'skills.sourcesAdd',
        kind: RepoOpKind.mutate,
        requiredArgs: ['url'],
        handler: (ctx) async {
          final url = (ctx.args['url'] as String).trim();
          final remote = parseForgeRemote(url);
          if (remote == null || remote.forge != ForgeHost.github) {
            throw ArgumentError(
              'Not a GitHub repository URL: expected '
              'https://github.com/<owner>/<repo>.',
            );
          }
          final owner = remote.owner;
          final repo = remote.name;
          final workspaceId = ctx.workspaceId!;
          final existing = await skillSources.byOwnerRepo(
            workspaceId,
            owner,
            repo,
          );
          if (existing != null) {
            return {
              'source': skillSourceToWire(existing),
              'already_exists': true,
            };
          }
          // Existence + metadata probe: a 404 (or a private repo the host's
          // credentials cannot see) fails the add with a typed error.
          final snapshot = await skillSourceCatalog.repoSnapshot(owner, repo);
          final source = SkillSource(
            id: const Uuid().v4(),
            workspaceId: workspaceId,
            owner: owner,
            repo: repo,
            url: 'https://github.com/$owner/$repo',
            description: snapshot.description,
            defaultBranch: snapshot.defaultBranch,
            starCount: snapshot.starCount,
            createdAt: DateTime.now(),
          );
          final stored = await skillSources.add(workspaceId, source);
          return {'source': skillSourceToWire(stored)};
        },
      ),
    if (skillSources != null)
      RepoOp(
        name: 'skills.sourcesRemove',
        kind: RepoOpKind.mutate,
        requiredArgs: ['source_id'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final id = ctx.args['source_id'] as String;
          final source = await skillSources.byId(workspaceId, id);
          if (source == null) {
            throw StateError('Unknown skill source.');
          }
          // Removing a source never uninstalls: lock pins are self-contained
          // (source + path + commit), so installed skills keep updating too.
          await skillSources.remove(workspaceId, id);
          return {'ok': true};
        },
      ),
    if (skillSources != null &&
        skillSourceCatalog != null &&
        skillBundles != null)
      RepoOp(
        name: 'skills.sourceListings',
        kind: RepoOpKind.read,
        timeout: const Duration(seconds: 45),
        requiredArgs: ['source_id'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final source = await skillSources.byId(
            workspaceId,
            ctx.args['source_id'] as String,
          );
          if (source == null) {
            throw StateError('Unknown skill source.');
          }
          final List<SourceSkillListing> listings;
          try {
            listings = await skillSourceCatalog.listSkills(
              source.owner,
              source.repo,
            );
            await skillSources.update(
              workspaceId,
              source.copyWith(
                skillCount: listings.length,
                lastSyncedAt: DateTime.now(),
                clearLastError: true,
              ),
            );
          } on Object catch (e) {
            await skillSources.update(
              workspaceId,
              source.copyWith(lastError: '$e'),
            );
            rethrow;
          }
          // Cross-reference the lock so the grid can badge installed skills
          // and flag updates (one update-check sweep over the workspace's
          // GitHub pins, matched by slug).
          final lock = await skillBundles.readLock(workspaceId);
          final updates = {
            for (final u in await skillBundles.checkUpdates(workspaceId))
              u.slug: u,
          };
          return {
            'source': skillSourceToWire(source),
            'skills': [
              for (final l in listings)
                () {
                  final entry = lock.skills[l.slug];
                  final fromThisSource =
                      entry != null &&
                      entry.sourceType == SkillOrigin.github &&
                      entry.source == source.fullName &&
                      entry.skillPath == l.skillFilePath;
                  return {
                    'slug': l.slug,
                    'name': l.name,
                    'description': l.description,
                    'path': l.skillFilePath,
                    'installed': fromThisSource,
                    // The slug is taken by a skill installed from elsewhere:
                    // installing would refuse, so the grid says so up front.
                    'slug_taken': !fromThisSource && entry != null,
                    'update_available':
                        fromThisSource && updates.containsKey(l.slug),
                  };
                }(),
            ],
          };
        },
      ),
    if (skillSources != null &&
        skillSourceCatalog != null &&
        skillBundles != null)
      RepoOp(
        name: 'skills.sourceSkillDetail',
        kind: RepoOpKind.read,
        timeout: const Duration(seconds: 45),
        requiredArgs: ['source_id', 'path'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final source = await skillSources.byId(
            workspaceId,
            ctx.args['source_id'] as String,
          );
          if (source == null) {
            throw StateError('Unknown skill source.');
          }
          final path = ctx.args['path'] as String;
          // One resolve serves both the README and the scan preview — the
          // bytes are the exact bytes an install would write, so the later
          // install's scan is a free cache hit.
          final resolved = await skillSourceCatalog.resolve(
            source.owner,
            source.repo,
            path,
          );
          final scan = await skillBundles.previewFiles(
            workspaceId: workspaceId,
            slug: slugForSkillPath(path),
            files: resolved.files,
          );
          return {
            'path': path,
            'ref': resolved.ref,
            'file_count': resolved.files.length,
            'readme': resolved.readme,
            'scan': {
              'verdict': scan.verdict.wire,
              'llm_reviewed': scan.llmReviewed,
              'capabilities': scan.manifest.labels,
              'required_action_classes': scan.manifest.requiredActionClassWires,
              'findings': [for (final f in scan.findings) f.toJson()],
            },
          };
        },
      ),
    if (skillSources != null && skillBundles != null)
      RepoOp(
        name: 'skills.sourceInstall',
        kind: RepoOpKind.mutate,
        actionClasses: const {
          ActionClass.packageInstall,
          ActionClass.networkEgress,
        },
        requiredArgs: ['source_id', 'path'],
        timeout: const Duration(seconds: 60),
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final source = await skillSources.byId(
            workspaceId,
            ctx.args['source_id'] as String,
          );
          if (source == null) {
            throw StateError('Unknown skill source.');
          }
          final path = ctx.args['path'] as String;
          if (!path.endsWith('/SKILL.md') ||
              path.startsWith('/') ||
              path.contains('..')) {
            throw ArgumentError(
              'path must be a repo-relative path to a SKILL.md.',
            );
          }
          final slug = validatedSlug(slugForSkillPath(path));
          // Never silently overwrite: a slug already installed from a
          // different source/path must be uninstalled first.
          final lock = await skillBundles.readLock(workspaceId);
          final existing = lock.skills[slug];
          if (existing != null &&
              (existing.source != source.fullName ||
                  existing.skillPath != path)) {
            throw StateError(
              'Skill "$slug" is already installed from '
              '"${existing.source.isEmpty ? "another source" : existing.source}" '
              '(${existing.skillPath}). Uninstall it first.',
            );
          }
          final allowOverride = ctx.args['allow_quarantine_override'] == true;
          try {
            final entry = await skillBundles.installFromGitHub(
              workspaceId: workspaceId,
              slug: slug,
              owner: source.owner,
              repo: source.repo,
              path: path,
              ref: ctx.args['ref'] as String?,
              allowQuarantineOverride: allowOverride,
              spaceId: ctx.args['space_id'] as String?,
              agentId: ctx.args['agent_id'] as String?,
            );
            return {
              'status': 'installed',
              'slug': entry.slug,
              'source': entry.source,
              'ref': entry.ref,
              'computed_hash': entry.computedHash,
              'trust_tier': entry.trustTier.wire,
              'scan_verdict': entry.scanVerdict?.wire,
            };
          } on SkillScanBlockedException catch (e) {
            // Structured block (nothing was written): the UI renders findings
            // + the explicit-override flow instead of string-parsing errors.
            return {
              'status': 'blocked',
              'slug': slug,
              'verdict': e.result?.verdict.wire,
              'llm_reviewed': e.result?.llmReviewed ?? false,
              'findings': [for (final f in e.findings) f.toJson()],
              if (e.reason != null) 'reason': e.reason,
            };
          }
        },
      ),
    if (skillBundles != null)
      RepoOp(
        name: 'skills.uninstall',
        kind: RepoOpKind.destructive,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async {
          final slug = validatedSlug(ctx.args['skill_slug'] as String);
          final entry = await skillBundles.uninstall(
            workspaceId: ctx.workspaceId!,
            slug: slug,
          );
          return {
            'status': 'uninstalled',
            'slug': slug,
            'was_managed': entry != null,
          };
        },
      ),
    if (skillBundles != null)
      RepoOp(
        name: 'skills.checkUpdates',
        kind: RepoOpKind.read,
        timeout: const Duration(seconds: 45),
        handler: (ctx) async {
          final candidates = await skillBundles.checkUpdates(ctx.workspaceId!);
          return {
            'updates': [
              for (final c in candidates)
                {
                  'slug': c.slug,
                  'current_ref': c.currentRef,
                  'latest_ref': c.latestRef,
                },
            ],
          };
        },
      ),
    if (skillBundles != null)
      RepoOp(
        name: 'skills.updateSkill',
        kind: RepoOpKind.mutate,
        actionClasses: const {
          ActionClass.packageInstall,
          ActionClass.networkEgress,
        },
        requiredArgs: ['skill_slug'],
        timeout: const Duration(seconds: 60),
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final slug = validatedSlug(ctx.args['skill_slug'] as String);
          SkillUpdateCandidate? candidate;
          for (final c in await skillBundles.checkUpdates(workspaceId)) {
            if (c.slug == slug) {
              candidate = c;
              break;
            }
          }
          if (candidate == null) {
            return {'status': 'up_to_date', 'slug': slug};
          }
          try {
            final entry = await skillBundles.applyUpdate(
              workspaceId: workspaceId,
              slug: slug,
              ref: candidate.latestRef,
              allowQuarantineOverride:
                  ctx.args['allow_quarantine_override'] == true,
              spaceId: ctx.args['space_id'] as String?,
              agentId: ctx.args['agent_id'] as String?,
            );
            return {
              'status': 'updated',
              'slug': entry.slug,
              'ref': entry.ref,
              'computed_hash': entry.computedHash,
              'previous_hash': entry.previousHash,
              'scan_verdict': entry.scanVerdict?.wire,
            };
          } on SkillScanBlockedException catch (e) {
            return {
              'status': 'blocked',
              'slug': slug,
              'verdict': e.result?.verdict.wire,
              'llm_reviewed': e.result?.llmReviewed ?? false,
              'findings': [for (final f in e.findings) f.toJson()],
              if (e.reason != null) 'reason': e.reason,
            };
          }
        },
      ),

    // Status + on-demand re-scan of what is ALREADY on disk and the gated
    // local-save path for the settings editor (same fail-closed gate as
    // create_skill). All workspace-scoped: the lock, the scan cache and the
    // skills dir are per-workspace.
    if (skillBundles != null)
      RepoOp(
        name: 'skills.installedList',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final statuses = await skillBundles.listInstalledStatus(
            ctx.workspaceId!,
          );
          final fsPort = fs;
          return {
            'skills': [
              for (final s in statuses)
                {
                  'slug': s.slug,
                  'lock_state': s.lockState.wire,
                  'origin': s.origin?.wire,
                  'source': s.source,
                  'trust_tier': s.trustTier?.wire,
                  'computed_hash': s.computedHash,
                  // Raw SKILL.md so the client parses name/description locally
                  // (null when no filesystem port is wired).
                  'content': fsPort == null
                      ? null
                      : await fsPort.readSkillFile(ctx.workspaceId!, s.slug),
                  'scan': s.scan == null
                      ? null
                      : {
                          'verdict': s.scan!.verdict.wire,
                          'llm_reviewed': s.scan!.llmReviewed,
                          'rules_version': s.scan!.rulesVersion,
                          'rules_stale': s.rulesStale,
                          'findings': [
                            for (final f in s.scan!.findings) f.toJson(),
                          ],
                        },
                },
            ],
          };
        },
      ),
    if (skillScanner != null && fs != null)
      RepoOp(
        // What the space's checked-out repos ship, so the composer's slash
        // palette can offer them with their provenance.
        //
        // Deliberately ALL repos, not just the one an agent happens to be
        // working in: scoping to the active repo is a context-budget decision
        // that only applies to an always-loaded index, and a human naming a
        // skill pays no such cost. It is also unanswerable here — a space can
        // hold several agents, each with its own overlay and its own active
        // repo, so "the" active repo does not exist at the space level.
        name: 'skills.repoSkills',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final spaceDir = await fs.spaceDir(ctx.workspaceId!, spaceId);
          final catalog = RepoSkillCatalog(
            workspaceId: ctx.workspaceId!,
            reposDir: p.join(spaceDir, 'repos'),
            scanner: skillScanner,
          );
          return {
            'skills': [
              for (final s in await catalog.listAll())
                {
                  'repo': s.repo,
                  'slug': s.slug,
                  'name': s.name,
                  'qualified_name': s.qualifiedName,
                  'description': s.description,
                },
            ],
          };
        },
      ),
    if (skillAnalysis != null)
      RepoOp(
        name: 'skills.scanInstalled',
        kind: RepoOpKind.read,
        requiredArgs: ['skill_slug'],
        handler: (ctx) async {
          final slug = validatedSlug(ctx.args['skill_slug'] as String);
          // Routed through the analysis service so the scan (and its
          // quarantine detach) is ALSO recorded as a skill_analysis pipeline
          // run — skipped silently when the template is disabled.
          final recorded = await skillAnalysis.runRecorded(
            workspaceId: ctx.workspaceId!,
            slugs: [slug],
            triggerEventType:
                SkillAnalysisTemplate.manualProjectionTriggerEventType,
            triggerPayload: {'slug': slug},
            runLlmReview: ctx.args['llm_review'] != false,
          );
          final result = recorded.outcome.results.single;
          if (result.error != null) {
            throw StateError(result.error!);
          }
          return {
            'verdict': result.verdict!.wire,
            'llm_reviewed': result.llmReviewed,
            'capabilities': result.capabilities,
            'findings': [for (final f in result.findings) f.toJson()],
            if (result.detachedAgents.isNotEmpty)
              'detached_agents': result.detachedAgents,
            if (recorded.runId != null) 'run_id': recorded.runId,
          };
        },
      ),
    if (skillAnalysis != null)
      RepoOp(
        name: 'skills.analyze',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final slugs = [
            for (final s in (ctx.args['slugs'] as List?) ?? const [])
              validatedSlug(s.toString()),
          ];
          // Scan-all (and any batch scan): one run, one step per skill's
          // result streaming into its output. LLM review is opt-in here —
          // a batch pass is the fast deterministic profile.
          final recorded = await skillAnalysis.runRecorded(
            workspaceId: ctx.workspaceId!,
            slugs: slugs,
            triggerEventType:
                SkillAnalysisTemplate.manualProjectionTriggerEventType,
            runLlmReview: ctx.args['llm_review'] == true,
          );
          return {
            if (recorded.runId != null) 'run_id': recorded.runId,
            ...recorded.outcome.toJson(),
          };
        },
      ),
    if (skillBundles != null)
      RepoOp(
        name: 'skills.saveLocal',
        kind: RepoOpKind.mutate,
        actionClasses: const {ActionClass.fileWriteOutsideWorktree},
        requiredArgs: ['skill_slug', 'content'],
        handler: (ctx) async {
          final slug = validatedSlug(ctx.args['skill_slug'] as String);
          final content = ctx.args['content'] as String;
          try {
            final entry = await skillBundles.saveLocal(
              workspaceId: ctx.workspaceId!,
              slug: slug,
              content: content,
              allowQuarantineOverride:
                  ctx.args['allow_quarantine_override'] == true,
            );
            return {
              'status': 'saved',
              'slug': entry.slug,
              'scan_verdict': entry.scanVerdict?.wire,
            };
          } on SkillScanBlockedException catch (e) {
            // Structured block (nothing was written): the UI renders findings
            // + the explicit-override flow instead of string-parsing errors.
            return {
              'status': 'blocked',
              'slug': slug,
              'verdict': e.result?.verdict.wire,
              'llm_reviewed': e.result?.llmReviewed ?? false,
              'findings': [for (final f in e.findings) f.toJson()],
              if (e.reason != null) 'reason': e.reason,
            };
          }
        },
      ),

    // Host-global (not workspace-scoped): LLM provider credentials live on the
    // server host, shared across workspaces. Every client manages API keys,
    // browser OAuth logins, custom providers and the live model list over
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
                  // A stored OAuth credential for a provider that no longer
                  // accepts one (anthropic, since its browser login was
                  // withdrawn) is dead weight: the factory ignores it and the
                  // request 401s. Reporting it as connected would leave the
                  // provider looking configured while every run failed, so it
                  // reads as disconnected and the UI asks for an API key.
                  if (!meta.supportsOAuth) {
                    break;
                  }
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
            // Every stored credential, in rotation order — runs start on the
            // active one and advance when a key/subscription is exhausted.
            // Secret-less placeholders (a generation-defaults row) and env
            // entries are listed so the UI can show provenance; only stored
            // secrets are removable over RPC.
            final credentials = [
              for (final c in await harnessCreds.credentialsFor(id))
                if (c.secret != null)
                  HarnessCredentialSummary(
                    credentialId: c.credentialId,
                    method: c.method,
                    isActive: c.credentialId == cred?.credentialId,
                    removable: !(c.accountLabel ?? '').startsWith('env:'),
                    label: c.method == HarnessAuthMethod.oauth
                        ? (c.email ?? c.accountLabel)
                        : c.accountLabel,
                    hint: c.secretHint,
                  ),
            ];
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
                credentials: credentials,
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
            // catalog, with stored per-model overrides winning field by field;
            // models.dev is used only to enrich prices/context client-side.
            if (cred == null) {
              continue;
            }
            if (cred.method == HarnessAuthMethod.oauth && oauthBroker != null) {
              cred = await oauthBroker.refreshIfNeeded(cred);
            }
            final overrides = await HarnessModelOverrideCache.load(
              harnessCreds,
              id,
            );
            final reported = <String>{};
            try {
              final provider = harnessProviderFactory.create(
                providerId: id,
                credential: cred,
              );
              for (final m in await provider.listModels()) {
                reported.add(m.id);
                final ov = overrides[m.id];
                models.add(
                  HarnessModelInfo(
                    id: '$id/${m.id}',
                    providerId: id,
                    displayName: m.displayName,
                    inputCostPerMTokens: m.inputCostPerMTokens,
                    outputCostPerMTokens: m.outputCostPerMTokens,
                    contextWindow: ov?.contextWindow ?? m.contextWindow,
                    maxOutputTokens: ov?.maxOutputTokens,
                    inputModalities: ov?.inputModalities ?? const [],
                    outputModalities: ov?.outputModalities ?? const [],
                    hasOverride: ov != null,
                  ).toJson(),
                );
              }
            } on Object {
              // Endpoint unreachable — this provider contributes no live models
              // until it answers again ("Sync now" retries). Manual models
              // below are still listed: they are the whole point of registering
              // a model by hand on an endpoint that cannot enumerate its own.
            }
            for (final entry in overrides.entries) {
              if (!entry.value.manual || reported.contains(entry.key)) {
                continue;
              }
              final ov = entry.value;
              models.add(
                HarnessModelInfo(
                  id: '$id/${entry.key}',
                  providerId: id,
                  contextWindow: ov.contextWindow,
                  maxOutputTokens: ov.maxOutputTokens,
                  inputModalities: ov.inputModalities,
                  outputModalities: ov.outputModalities,
                  hasOverride: true,
                  manual: true,
                ).toJson(),
              );
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
            // A run parked for want of a credential can go now. The gate would
            // find this on its next poll anyway; nudging turns "up to eight
            // seconds after I pasted the key" into "as I paste it", which is
            // the difference between a dialog that closes itself and one the
            // operator sits watching.
            await credentialBlockRegistry?.nudge();
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
          await credentialBlockRegistry?.nudge();
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
            credentialId: ctx.args['credential_id'] as String?,
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
          // Optional initial model registrations (`models`: [{id, ...override
          // fields}]) — for endpoints that cannot enumerate their own models,
          // so the provider is usable from the moment it is added.
          final modelOverrides = <String, ProviderModelOverride>{};
          for (final raw in (ctx.args['models'] as List?) ?? const []) {
            if (raw is! Map) {
              continue;
            }
            final map = raw.cast<String, dynamic>();
            final modelId = (map['id'] as String? ?? '').trim();
            if (modelId.isEmpty) {
              continue;
            }
            modelOverrides[modelId] = _modelOverrideFromArgs(map, manual: true);
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
              modelOverrides: modelOverrides,
            ),
          );
          await harnessModelOverrides?.refreshProvider(id);
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
          harnessModelOverrides?.removeProvider(id);
          return {'ok': true};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        // Per-provider sampling recipe + output ceiling. A frontier API and a
        // local quant cannot share one number: models publish their own output
        // ceilings and required sampling recipes and serving one at other
        // values degrades it. Every field is optional and omitting one clears
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
    if (harnessCreds != null)
      RepoOp(
        // Per-model metadata override (the settings UI's "edit model" save):
        // context window, output ceiling and modalities, stored on the
        // provider's credential row and winning over the endpoint's live
        // report and the models.dev catalog everywhere the model resolves.
        // `manual: true` additionally registers a model the endpoint did not
        // report (its only listing, when the endpoint cannot enumerate its
        // own). An override with every field cleared is a remove.
        name: 'providers.saveModelOverride',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id', 'model_id'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          await _requireKnownProvider(harnessCreds, id);
          final modelId = _bareModelId(id, ctx.args['model_id'] as String);
          final override = _modelOverrideFromArgs(ctx.args);
          // Write target mirrors saveGenerationDefaults: the custom provider's
          // definition row, else the active credential, else a fresh
          // definition row so a built-in with env-only auth has somewhere for
          // the setting to live.
          final existing =
              await _customProviderDef(harnessCreds, id) ??
              await harnessCreds.activeCredential(id) ??
              ProviderCredential(
                providerId: id,
                method: HarnessAuthMethod.none,
              );
          final overrides = Map<String, ProviderModelOverride>.from(
            existing.modelOverrides,
          );
          if (override.isEmpty) {
            overrides.remove(modelId);
          } else {
            overrides[modelId] = override;
          }
          await harnessCreds.save(existing.copyWith(modelOverrides: overrides));
          harnessModelOverrides?.setEntry(
            id,
            modelId,
            override.isEmpty ? null : override,
          );
          return {'ok': true, 'override': override.toJson()};
        },
      ),
    if (harnessCreds != null)
      RepoOp(
        // Clears one model's override. For a manual model this is also how it
        // leaves the list; for a live-reported model the endpoint's own
        // metadata takes over again.
        name: 'providers.removeModelOverride',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['provider_id', 'model_id'],
        handler: (ctx) async {
          final id = ctx.args['provider_id'] as String;
          await _requireKnownProvider(harnessCreds, id);
          final modelId = _bareModelId(id, ctx.args['model_id'] as String);
          final existing =
              await _customProviderDef(harnessCreds, id) ??
              await harnessCreds.activeCredential(id);
          if (existing != null &&
              existing.modelOverrides.containsKey(modelId)) {
            final overrides = Map<String, ProviderModelOverride>.from(
              existing.modelOverrides,
            )..remove(modelId);
            await harnessCreds.save(
              existing.copyWith(modelOverrides: overrides),
            );
          }
          harnessModelOverrides?.setEntry(id, modelId, null);
          return {'ok': true};
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
          // Same instant-unblock as `providers.saveApiKey`. It covers the
          // paste-code flow only — a loopback or device login completes inside
          // the broker with no op to hook — so the client also nudges through
          // `credential_gate.resolve` when its login panel reports connected,
          // and the gate's own poll is the backstop under both.
          await credentialBlockRegistry?.nudge();
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

    // Aggregates the workspace's recent run-cost history into a spend summary
    // for the usage dashboard ("$X spent this week, resets in Ym").
    RepoOp(
      name: 'usage.costSummary',
      kind: RepoOpKind.read,
      handler: (ctx) async {
        final windowDays = (ctx.args['window_days'] as num?)?.toInt() ?? 7;
        final now = DateTime.now();
        final window = Duration(days: windowDays);
        final since = now.subtract(window);
        // Workspace-scoped, time-bounded and projected where the host offers
        // it. This used to pull EVERY run log of EVERY workspace — each
        // carrying its serialized prompt context — and filter in Dart, to
        // summarize ONE workspace's spend over one week.
        final costs = agentRunLogRepository;
        final List<UsageCostHistoryEntry> entries;
        if (costs case final AgentRunCostHistoryPort projected) {
          entries = await projected.costHistory(ctx.workspaceId!, since);
        } else {
          // A host wired to a repository without the projected read (the thin
          // client's RPC-backed one) still answers correctly, just the old way.
          final logs = await agentRunLogRepository.watchAll().first;
          entries = [
            for (final log in logs)
              if (log.workspaceId == ctx.workspaceId &&
                  log.cost.estimatedCostCents > 0 &&
                  !log.startedAt.isBefore(since))
                UsageCostHistoryEntry(
                  recordedAt: log.startedAt,
                  provider: log.adapter ?? 'agent',
                  accountKey: log.adapter ?? 'agent',
                  costUsd: log.cost.estimatedCostCents / 100.0,
                ),
          ];
        }
        final summary = UsageTracker.summarizeLast(
          entries,
          window: window,
          now: now,
        );
        return costSummaryToWire(summary);
      },
    ),

    RepoOp(
      name: 'review_space.create',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'space_id',
        'pr_external_id',
        'pr_number',
        'repo_full_name',
      ],
      handler: (ctx) async {
        // The association is stamped with the bound session workspace — a
        // client can't create one in a foreign workspace (isolation invariant).
        final association = await reviewSpaceRepository.create(
          spaceId: ctx.args['space_id'] as String,
          workspaceId: ctx.workspaceId!,
          prExternalId: ctx.args['pr_external_id'] as String,
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          repoFullName: ctx.args['repo_full_name'] as String,
        );
        return {'association': reviewSpaceToWire(association)};
      },
    ),
    RepoOp(
      name: 'review_space.updateStatus',
      kind: RepoOpKind.mutate,
      requiredArgs: ['id', 'status'],
      handler: (ctx) async {
        final id = ctx.args['id'] as String;
        // Verify ownership before mutating (ID-only lookup is not a boundary):
        // the association must already be visible in the bound workspace.
        final owned = await reviewSpaceRepository
            .watchByWorkspace(ctx.workspaceId!)
            .first;
        if (!owned.any((a) => a.id == id)) {
          throw const WorkspaceMismatchException(
            'Review space association belongs to a different workspace',
          );
        }
        final status = ReviewSpaceStatus.values.asNameMap()[ctx.args['status']];
        if (status == null) {
          throw const NotFoundException('Unknown review space status');
        }
        await reviewSpaceRepository.updateStatus(ctx.workspaceId!, id, status);
        return {'ok': true};
      },
    ),
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
            run.spaceId ?? run.conversationId ?? '',
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
    // The raw NDJSON run log for one run (the "run viewer" dialog). Host-side
    // read: the file is in the SERVER's data dir and the path comes from the
    // run row, never from the client, so no client-supplied path is ever
    // opened. Bounded (tail-capped) — a runaway agent's log is not a reason to
    // block the serving isolate.
    if (runLogReader != null)
      RepoOp(
        name: 'agent_run_log.readEvents',
        kind: RepoOpKind.read,
        requiredArgs: ['run_id'],
        handler: (ctx) async {
          final runId = ctx.args['run_id'] as String;
          final run = await agentRunLogRepository.getById(
            ctx.workspaceId!,
            runId,
          );
          if (run == null) {
            throw const NotFoundException('Agent run log not found');
          }
          // Run logs carry a nullable workspaceId; an ID-only lookup is not a
          // scoping boundary, so reject a row owned by another workspace.
          if (run.workspaceId != ctx.workspaceId) {
            throw const WorkspaceMismatchException(
              'Agent run log belongs to a different workspace',
            );
          }
          final path = run.logPath;
          if (path == null || path.isEmpty) {
            return {'events': const [], 'truncated': false};
          }
          final read = await runLogReader.readRunLogEvents(path);
          return {'events': read.events, 'truncated': read.truncated};
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
        // The incoming team must belong to the bound workspace and the
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

    RepoOp(
      name: 'isolated_repo.forUnitRepo',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id', 'repo_id'],
      handler: (ctx) async {
        final repo = await isolatedRepoRepository.forUnitRepo(
          ctx.workspaceId!,
          ctx.args['space_id'] as String,
          ctx.args['repo_id'] as String,
        );
        return {'repo': repo == null ? null : isolatedRepoToWire(repo)};
      },
    ),
    RepoOp(
      name: 'isolated_repo.forSpace',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forSpace(
          ctx.workspaceId!,
          ctx.args['space_id'] as String,
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
    // CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique space id;
    // each returned row carries its own workspaceId (mirrors the documented
    // IsolatedRepoRepository.forSpaceAcrossWorkspaces exemption).
    RepoOp(
      name: 'isolated_repo.forSpaceAcrossWorkspaces',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['space_id'],
      handler: (ctx) async {
        final repos = await isolatedRepoRepository.forSpaceAcrossWorkspaces(
          ctx.args['space_id'] as String,
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
    ...buildMeetingOps(
      meetingRepository: meetingRepository,
      meetingRecording: meetingRecording,
      dictationService: dictationService,
    ),
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
    // Google calendar connect: client supplies id+secret or `use_builtin`;
    // host runs device-code flow and stores the refresh token. Built-in
    // connect stores a marker (never the server secret). Ops use
    // `ctx.workspaceId!`; handles/accounts are workspace-bound. Only when
    // [calendarConnect] is wired.
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
            userId: ctx.userId,
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
            userId: ctx.userId,
          );
          return {'ok': true};
        },
      ),
    ],
    // The thin client BOTH reads and writes this surface. Every op sources
    // `ctx.workspaceId!` (the bound session, never a client arg). `createDraft`
    // stamps that workspace on the new row. The id-keyed ops (`getById` /
    // `updateDraft` / `publishToForge` / `delete`) are NOT a boundary on their
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
          prNumber: (ctx.args['pr_number'] as num?)?.toInt(),
          prUrl: ctx.args['pr_url'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_lifecycle.publish',
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
        // Acting as the caller: a pull request opened from the composer is
        // theirs, and must be authored by them on the forge.
        final result = await prLifecycleRepositoryFor(ctx.userId)
            .publishToForge(
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
            if (r.hasForgeRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'authenticated': true, 'repos': <Map<String, dynamic>>[]};
        }
        final groups = await fetch(ghRepos, workspaceId: ctx.workspaceId);
        return {
          'authenticated': true,
          'repos': [
            for (final g in groups)
              {
                'repo_id': g.repo.id,
                'repo_full_name': g.repo.fullName,
                'github_owner': g.repo.remoteOwner,
                'github_repo_name': g.repo.remoteName,
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
    // Open PR(s) from this conversation — matched by head branch. One space
    // worktree can carry a stack of branches; every recorded layer matches,
    // not only the one checked out. Branch is the join (`review_spaces` runs
    // the other way via `pr.ensureSpace`).
    if (openPrPoller != null)
      RepoOp(
        name: 'pr.forSpaceBranches',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id'],
        handler: (ctx) async {
          final spaceId = ctx.args['space_id'] as String;
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final worktrees = await isolatedRepoRepository.forSpace(
            ctx.workspaceId!,
            spaceId,
          );
          if (worktrees.isEmpty) {
            return {'matches': <Map<String, dynamic>>[]};
          }
          final linked = await workspaceRepository
              .watchReposForWorkspace(ctx.workspaceId!)
              .first;
          final reposById = {for (final r in linked) r.id: r};
          final matches = <Map<String, dynamic>>[];
          for (final worktree in worktrees) {
            final repo = reposById[worktree.repoId];
            if (repo == null || !repo.hasForgeRemote) {
              continue;
            }
            final heads = pullRequestHeadBranches(
              checkedOut: worktree.branch,
              stackBranches: spaceStackRepository == null
                  ? const []
                  : (await spaceStackRepository.forRepo(
                      ctx.workspaceId!,
                      spaceId,
                      worktree.repoId,
                    )).map((entry) => entry.branch),
            );
            for (final branch in heads) {
              final pr = await openPrPoller.openPrForHeadBranch(
                workspaceId: ctx.workspaceId!,
                repoFullName: repo.fullName,
                branch: branch,
              );
              if (pr == null) {
                continue;
              }
              matches.add({
                'repo_id': repo.id,
                'repo_full_name': repo.fullName,
                'branch': branch,
                'pull_request': pr,
              });
            }
          }
          return {'matches': matches};
        },
      ),
    // The SERVER's authenticated GitHub user (global — not workspace data). The
    // thin client holds no token, so its `login`/avatar resolve from the host.
    RepoOp(
      name: 'github.currentUser',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final user = await fetchCurrentGitHubUser?.call(ctx.userId);
        final teams = await fetchViewerGitHubTeams?.call(ctx.userId);
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
            if (r.hasForgeRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'reviews': <Map<String, dynamic>>[]};
        }
        final results = await fetch(ghRepos, ctx.userId);
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
            if (r.hasForgeRemote) r,
        ];
        if (ghRepos.isEmpty) {
          return {'keys': <String>[]};
        }
        final keys = await fetch(ghRepos, ctx.userId);
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
        final ghRepos = await linkedForgeRepos(ctx.workspaceId!);
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
    // The operator's merged PR history across the bound workspace's repos.
    //
    // Fans out per forge under each forge's OWN viewer identity rather than
    // searching one login everywhere: the same human is a different account on
    // GitHub than on GitLab, so a single-login search would silently return
    // nothing for every repo outside the forge that login belongs to. The
    // `login` argument is therefore advisory — the server resolves the real
    // per-forge identity itself.
    RepoOp(
      name: 'pr.closedByAuthorForWorkspace',
      kind: RepoOpKind.read,
      requiredArgs: ['login'],
      handler: (ctx) async {
        final history = fetchMergedHistory;
        if (history == null) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        final repos = await linkedForgeRepos(ctx.workspaceId!);
        if (repos.isEmpty) {
          return {'repos': <Map<String, dynamic>>[]};
        }
        // The CALLER's history: resolved under their own per-forge identity
        // and fetched on their own credential, so one member's merged PRs are
        // never presented to another as theirs.
        final groups = await history(
          repos,
          userId: ctx.userId,
          workspaceId: ctx.workspaceId,
        );
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
        final ghRepos = await linkedForgeRepos(ctx.workspaceId!);
        final owners = {
          for (final r in ghRepos)
            if (r.remoteOwner.isNotEmpty) r.remoteOwner,
        }.toList();
        if (owners.isEmpty) {
          return {'members': <Map<String, dynamic>>[]};
        }
        return {'members': await fetch(owners)};
      },
    ),
    // Profile analytics are workspace-scoped: the linked repo set is derived
    // server-side and a team organization must own at least one of those repos.
    // Team members are resolved from GitHub on the caller's credential, never
    // accepted as a client-supplied list.
    RepoOp(
      name: 'github.profileActivity',
      kind: RepoOpKind.read,
      requiredArgs: ['kind'],
      handler: (ctx) async {
        final read = githubRead;
        if (read == null) {
          return {
            'metrics': GitHubProfileActivity.empty.metrics.toWire(),
            'repos': <Map<String, dynamic>>[],
          };
        }
        final repos = await linkedForgeRepos(ctx.workspaceId!);
        final kind = ctx.args['kind'] as String;
        late final List<String> logins;
        switch (kind) {
          case 'user':
            final login = ctx.args['login'];
            if (login is! String || login.trim().isEmpty) {
              throw const ValidationException(
                'Missing or invalid argument: login',
              );
            }
            logins = [login];
          case 'team':
            final organization = ctx.args['organization'];
            final slug = ctx.args['slug'];
            if (organization is! String || organization.trim().isEmpty) {
              throw const ValidationException(
                'Missing or invalid argument: organization',
              );
            }
            if (slug is! String || slug.trim().isEmpty) {
              throw const ValidationException(
                'Missing or invalid argument: slug',
              );
            }
            final ownsLinkedRepo = repos.any(
              (repo) =>
                  repo.remoteOwner.toLowerCase() == organization.toLowerCase(),
            );
            if (!ownsLinkedRepo) {
              throw const WorkspaceMismatchException(
                'Team belongs to an organization not linked to this workspace',
              );
            }
            final team = await read.teamProfile(organization, slug, ctx.userId);
            if (team == null) {
              throw const NotFoundException('GitHub team not found');
            }
            logins = [
              for (final member in team.members)
                if (member.login.isNotEmpty) member.login,
            ];
          default:
            throw const ValidationException(
              'Invalid argument: kind must be user or team',
            );
        }
        final activity = await read.profileActivity(repos, logins, ctx.userId);
        return {
          'metrics': activity.metrics.toWire(),
          'repos': [
            for (final group in activity.repos)
              {
                'repo_id': group.repoId,
                'prs': [for (final pr in group.prs) pullRequestToWire(pr)],
              },
          ],
        };
      },
    ),
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
        final matched = await requireWorkspaceForgeRepo(
          ctx.workspaceId!,
          ctx.args['owner'] as String,
          ctx.args['repo'] as String,
          userId: ctx.userId,
        );
        final client = forgeClientFor(
          matched,
          ctx.userId,
          workspaceId: ctx.workspaceId,
        );
        if (client == null) {
          return {'branches': <String>[]};
        }
        final branches = await client.listBranches();
        // The CALLER's own branches lead the picker — that is almost always
        // what they are about to open a PR from. Resolved per forge AND per
        // caller: the same human is a different account on each forge, and
        // the server's viewer login is not this member's.
        final me =
            (await forgeCredentials?.viewerLogin(
                      matched.forge,
                      userId: ctx.userId,
                      workspaceId: ctx.workspaceId,
                    ) ??
                    '')
                .toLowerCase();
        final mine = <String>[];
        final others = <String>[];
        for (final b in branches) {
          (me.isNotEmpty && b.lastCommitAuthor.toLowerCase() == me
                  ? mine
                  : others)
              .add(b.name);
        }
        return {
          'branches': [...mine, ...others],
        };
      },
    ),
    RepoOp(
      name: 'github.defaultBranch',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final matched = await requireWorkspaceForgeRepo(
          ctx.workspaceId!,
          ctx.args['owner'] as String,
          ctx.args['repo'] as String,
          userId: ctx.userId,
        );
        final client = forgeClientFor(
          matched,
          ctx.userId,
          workspaceId: ctx.workspaceId,
        );
        if (client == null) {
          return {'branch': ''};
        }
        return {'branch': await client.getDefaultBranch()};
      },
    ),
    RepoOp(
      name: 'github.prTemplates',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final matched = await requireWorkspaceForgeRepo(
          ctx.workspaceId!,
          ctx.args['owner'] as String,
          ctx.args['repo'] as String,
          userId: ctx.userId,
        );
        final client = forgeClientFor(
          matched,
          ctx.userId,
          workspaceId: ctx.workspaceId,
        );
        if (client == null || !client.capabilities.prTemplates) {
          return {'templates': <Map<String, dynamic>>[]};
        }
        final templates = await client.listPrTemplates();
        return {
          'templates': [
            for (final entry in templates.entries)
              {
                'name': entry.key,
                'body': entry.value,
                // The conventional single template is the default; with several
                // the composer lets the operator pick.
                'is_default': templates.length == 1,
              },
          ],
        };
      },
    ),
    RepoOp(
      name: 'github.compareBranches',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'base', 'head'],
      handler: (ctx) async {
        final matched = await requireWorkspaceForgeRepo(
          ctx.workspaceId!,
          ctx.args['owner'] as String,
          ctx.args['repo'] as String,
          userId: ctx.userId,
        );
        final client = forgeClientFor(
          matched,
          ctx.userId,
          workspaceId: ctx.workspaceId,
        );
        if (client == null) {
          return {'comparison': null};
        }
        final c = await client.compareBranches(
          base: ctx.args['base'] as String,
          head: ctx.args['head'] as String,
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
        await requireWorkspaceForgeRepo(
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
        await requireWorkspaceForgeRepo(
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
        await requireWorkspaceForgeRepo(
          ctx.workspaceId!,
          owner,
          repo,
          userId: ctx.userId,
        );
        return {
          'permission': await read.repoPermission(
            owner,
            repo,
            ctx.userId,
            workspaceId: ctx.workspaceId,
          ),
        };
      },
    ),
    // A GitHub identity profile (user, organization, or GitHub App) — global
    // data keyed only by login, so NOT workspace-scoped (mirrors
    // `github.currentUser`). Read on the CALLER's own credential: the org/team
    // block is unreadable by an app installation token, so the no-caller lane
    // failed the whole hover card. App slugs (`parced`, not `parced[bot]`)
    // resolve via `GET /apps/{slug}` after GraphQL `repositoryOwner` misses.
    RepoOp(
      name: 'github.userProfile',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['login'],
      handler: (ctx) async {
        final read = githubRead;
        return {
          'profile': await read?.userProfile(
            ctx.args['login'] as String,
            ctx.userId,
          ),
        };
      },
    ),
    // A GitHub team profile is global data keyed by organization + slug. It is
    // read on the caller's credential because private team membership is
    // principal-specific and GitHub Apps cannot enumerate it reliably.
    RepoOp(
      name: 'github.teamProfile',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['organization', 'slug'],
      handler: (ctx) async {
        final read = githubRead;
        final organization = ctx.args['organization'] as String;
        final slug = ctx.args['slug'] as String;
        final profile = await read?.teamProfile(organization, slug, ctx.userId);
        return {'profile': profile?.toWire()};
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
    // Every polled external status page in ONE response. The client sidebar
    // entry polls this on a timer; four separate ops meant four RPCs per tick,
    // each occupying its own session concurrency slot. The pages are fetched
    // in parallel and one that fails (or has no fetcher wired) yields null for
    // its key only — an unreachable status page must not take the other three
    // down with it.
    RepoOp(
      name: 'serviceStatus.getAll',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        Future<Map<String, dynamic>?> guarded(
          Future<Map<String, dynamic>> Function()? fetch,
        ) async {
          if (fetch == null) {
            return null;
          }
          try {
            return await fetch();
          } catch (_) {
            return null;
          }
        }

        final results = await Future.wait([
          guarded(fetchGitHubServiceStatus),
          guarded(fetchClaudeServiceStatus),
          guarded(fetchOpenAIServiceStatus),
          guarded(fetchKimiServiceStatus),
        ]);
        return {
          'github': results[0],
          'claude': results[1],
          'openai': results[2],
          'kimi': results[3],
        };
      },
    ),
    // Live subscription-usage quotas for Claude Code and harness plans
    // (Codex, Cursor, z.ai, Kimi Code) behind the title-bar usage pill.
    // Global (account-level, not workspace data). Claude still reads the
    // CLI's own credentials; Codex/Cursor/z.ai/Kimi resolve from the harness
    // provider credential store. Null fetcher → an empty list.
    RepoOp(
      name: 'subscriptions.usage',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final fetch = fetchSubscriptionUsage;
        if (fetch == null) {
          return {'providers': <Map<String, dynamic>>[]};
        }
        final accounts = harnessCreds == null
            ? const <SubscriptionUsageAccount>[]
            : await collectHarnessUsageAccounts(
                store: harnessCreds,
                oauthBroker: oauthBroker,
              );
        return {'providers': await fetch(accounts)};
      },
    ),
    // One `CLAUDE_CONFIG_DIR` per login, under `<dataDir>/claude-accounts/`.
    // Not workspace-scoped: the directories are host state, like the adapter
    // launch overrides, and one host serves every workspace.
    //
    // Control Center never performs the login. `claude_accounts.loginCommand`
    // hands back the argv + env for a terminal to run `claude auth login` in,
    // and the CLI writes its own credential — minting Claude Code tokens from
    // another app is exactly what the harness's Anthropic provider stopped
    // doing.
    if (claudeAccounts != null) ...[
      RepoOp(
        name: 'claude_accounts.list',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async {
          // Reads at the default floor: every member picks which login their
          // own runs use, and the payload carries identity, never a token.
          final accounts = await claudeAccounts.listWithStatus();
          final fetchUsage = fetchClaudeAccountUsage;
          final usage = <String, Map<String, dynamic>?>{};
          if (fetchUsage != null) {
            // Concurrently, and only for accounts that could answer — probing
            // a signed-out one spends a round trip to be told what its status
            // already said.
            //
            // An expired access token is excluded for the same reason and it
            // is NOT the same test as `loggedIn`: a lapsed token with a live
            // refresh token beside it stays in the rotation (the CLI renews it
            // on the next run) but still cannot authenticate THIS request —
            // the usage endpoint takes the bearer as-is and refreshes nothing.
            // Asking anyway is what put a 401 in the log every ten minutes for
            // hours, re-learning a fact the credential states on disk.
            final live = [
              for (final a in accounts)
                if (a.loggedIn && !a.isCredentialExpired()) a,
            ];
            final results = await Future.wait([
              for (final a in live)
                fetchUsage(
                  claudeAccounts.configDirFor(a.id),
                ).catchError((Object _) => null),
            ]);
            for (var i = 0; i < live.length; i++) {
              usage[live[i].id] = results[i];
            }
          }
          return {
            'accounts': [
              for (final a in accounts)
                {...a.toJson(), if (usage[a.id] != null) 'usage': usage[a.id]},
            ],
          };
        },
      ),
      RepoOp(
        name: 'claude_accounts.create',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final account = await claudeAccounts.create(
            label: ctx.args['label'] as String?,
          );
          return {'account': account.toJson()};
        },
      ),
      RepoOp(
        name: 'claude_accounts.rename',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id', 'label'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await claudeAccounts.rename(
            ctx.args['id'] as String,
            ctx.args['label'] as String,
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'claude_accounts.remove',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await claudeAccounts.remove(ctx.args['id'] as String);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'claude_accounts.setDefault',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          await claudeAccounts.setDefault(ctx.args['id'] as String);
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'claude_accounts.loginCommand',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          requireServerAdmin(ctx);
          final cmd = claudeAccounts.loginCommand(
            ctx.args['id'] as String,
            email: ctx.args['email'] as String?,
            console: ctx.args['console'] as bool? ?? false,
          );
          return {'argv': cmd.argv, 'environment': cmd.environment};
        },
      ),
    ],
    // Which credentials a workspace (or one of its agents) may spend, in what
    // order, and whether to drain them one at a time or spread runs across
    // them. ONE pair of ops for both lanes — the Claude Code adapter's account
    // directories and a harness provider's stored credentials — because the
    // thing being edited is identical: an ordered list plus a strategy.
    //
    // Reads sit at `member` (every member can see how their runs are routed);
    // writes carry an EXPLICIT admin floor, matching `workspace_settings.set`,
    // because attaching or reordering changes which plan every member's runs
    // spend.
    if (workspaceSettingsRepository != null) ...[
      RepoOp(
        name: 'account_pools.get',
        kind: RepoOpKind.read,
        minRole: WorkspaceRole.member,
        requiredArgs: ['lane'],
        handler: (ctx) async {
          final lane = ctx.args['lane'] as String;
          final agentId = ctx.args['agent_id'] as String?;
          final key = accountPoolKeyForLane(lane, agentId);
          if (key == null) {
            throw const NotFoundException('Unknown account pool lane');
          }
          final raw = await workspaceSettingsRepository.get(
            ctx.workspaceId!,
            key,
          );
          // The workspace pool is returned alongside an agent's own, so the
          // editor can show what an unset agent would inherit rather than a
          // misleading empty list.
          final inheritedKey = agentId == null
              ? null
              : accountPoolKeyForLane(lane, null);
          final inherited = inheritedKey == null
              ? null
              : await workspaceSettingsRepository.get(
                  ctx.workspaceId!,
                  inheritedKey,
                );
          return {
            'pool': _decodePool(raw),
            if (inherited != null) 'inherited': _decodePool(inherited),
          };
        },
      ),
      RepoOp(
        name: 'account_pools.set',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        requiredArgs: ['lane'],
        handler: (ctx) async {
          final lane = ctx.args['lane'] as String;
          final agentId = ctx.args['agent_id'] as String?;
          final key = accountPoolKeyForLane(lane, agentId);
          if (key == null) {
            throw const NotFoundException('Unknown account pool lane');
          }
          final pool = ctx.args['pool'];
          // Always the SESSION workspace — a client can never write a pool
          // into a foreign workspace (isolation invariant).
          await workspaceSettingsRepository.set(
            ctx.workspaceId!,
            key,
            pool is Map<String, dynamic>
                ? jsonEncode(AccountPool.fromJson(pool).toJson())
                // Null clears the pool, which is how an agent goes back to
                // inheriting the workspace's.
                : null,
          );
          return {'ok': true};
        },
      ),
    ],

    // The composer's GIF picker. Run on the host's Klipy app key (the thin
    // client holds none and the browser can't reach Klipy cross-origin). Null
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
        await requireWorkspaceForgeRepo(
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
      name: 'pipeline_run.activeRunCountForTemplate',
      kind: RepoOpKind.read,
      requiredArgs: ['template_id'],
      handler: (ctx) async {
        final count = await pipelineRunRepository.activeRunCountForTemplate(
          workspaceId: ctx.workspaceId!,
          templateId: ctx.args['template_id'] as String,
          excludeTriggerEventTypes:
              ((ctx.args['exclude_trigger_event_types'] as List?) ?? const [])
                  .whereType<String>()
                  .toSet(),
        );
        return {'count': count};
      },
    ),
    RepoOp(
      name: 'pipeline_run.nextQueuedRunForTemplate',
      kind: RepoOpKind.read,
      requiredArgs: ['template_id'],
      handler: (ctx) async {
        final run = await pipelineRunRepository.nextQueuedRunForTemplate(
          workspaceId: ctx.workspaceId!,
          templateId: ctx.args['template_id'] as String,
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
          spaceId: ctx.args['space_id'] as String?,
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
      name: 'pipeline_run.restartStepRun',
      kind: RepoOpKind.mutate,
      requiredArgs: ['step_run_id', 'started_at'],
      handler: (ctx) async {
        await assertPipelineStepRunOwned(
          ctx.workspaceId!,
          ctx.args['step_run_id'] as String,
        );
        await pipelineRunRepository.restartStepRun(
          ctx.workspaceId!,
          ctx.args['step_run_id'] as String,
          startedAt: DateTime.parse(ctx.args['started_at'] as String),
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
        // Starts a run whose graph may contain `bash.script` (Process.start).
        actionClasses: const {ActionClass.processSpawn},
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
        // Interrupts a live step process. Same family as `terminal.kill`.
        actionClasses: const {ActionClass.processSpawn},
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
        // Re-opens failed steps, which may spawn bash again.
        actionClasses: const {ActionClass.processSpawn},
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
        actionClasses: const {ActionClass.processSpawn},
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
    // Approving/cancelling an orchestration hires agents + starts/cancels
    // pipelines via the concrete engine, so it runs on the host that owns the
    // engine (the desktop in-process host); absent on a headless server. Both
    // ops are workspace-scoped (`ctx.workspaceId!`, never a client arg); the
    // use-cases re-validate the orchestration belongs to that workspace.
    if (approveOrch != null)
      RepoOp(
        name: 'orchestration.approve',
        kind: RepoOpKind.mutate,
        // Hires agents and starts the generated pipeline (bash included).
        actionClasses: const {ActionClass.processSpawn},
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
    // Widens an executing partial approval: newly approved nodes' suspended
    // gates resume. The use case enforces dependency-closure.
    if (approveNodes != null)
      RepoOp(
        name: 'orchestration.approveNodes',
        kind: RepoOpKind.mutate,
        actionClasses: const {ActionClass.processSpawn},
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
        actionClasses: const {ActionClass.processSpawn},
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
    // saw into the stored proposal/plan and returns the ranges. Honest or
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
        // Compiles the plan into an orchestration and runs the same approve
        // path that starts pipelines.
        actionClasses: const {ActionClass.processSpawn},
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
    if (playbooksRepo != null) ...[
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
    // approver). Space-scoped: the publisher asserts space ownership.
    if (publishReview != null)
      RepoOp(
        name: 'pr_review.publishReview',
        kind: RepoOpKind.mutate,
        actionClasses: const {ActionClass.prPublish},
        requiredArgs: ['workspace_id', 'space_id'],
        handler: (ctx) async {
          final selection = ctx.args['selection'];
          return publishReview(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
            selection: selection is String ? selection : 'consensus',
            approveOnShip: ctx.args['approve_on_ship'] == true,
            userId: ctx.userId,
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
    // Merged impact subgraph for a whole cohort (the Review Hub deep dive).
    if (reviewCohortImpact != null)
      RepoOp(
        name: 'review_studio.cohortImpact',
        kind: RepoOpKind.read,
        requiredArgs: ['owner', 'repo', 'pr_number', 'cohort_key'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          return reviewCohortImpact(
            workspaceId: ctx.workspaceId!,
            owner: c.owner,
            repo: c.repo,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            cohortKey: ctx.args['cohort_key'] as String,
            userId: ctx.userId,
            depth: (ctx.args['depth'] as num?)?.toInt() ?? 2,
          );
        },
      ),
    // Structured failure signals from the PR's failing CI jobs, correlated to
    // its changed files. Reads only what the checks tab already fetches.
    if (reviewCohortRepository != null)
      RepoOp(
        name: 'review_studio.ciSignals',
        kind: RepoOpKind.read,
        requiredArgs: ['owner', 'repo', 'pr_number'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          final prNumber = (ctx.args['pr_number'] as num).toInt();
          final repository = await resolvePrReviewRepository(
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
                  prNumber: prNumber,
                )
              : reviewPrNodeKey(c.owner, c.repo, prNumber);
          final cohorts = await reviewCohortRepository.forPr(
            ctx.workspaceId!,
            key,
          );
          // Job detail is a property of OUR integration with that forge, known
          // at compile time — never probed, and never taken from the client.
          final linked = await workspaceRepository
              .watchReposForWorkspace(ctx.workspaceId!)
              .first;
          ForgeHost? forge;
          for (final r in linked) {
            if (r.remoteOwner.toLowerCase() == c.owner.toLowerCase() &&
                r.remoteName.toLowerCase() == c.repo.toLowerCase()) {
              forge = r.forge;
              break;
            }
          }
          final files = await repository.watchFiles(prNumber).first;
          final signals = await const ReviewCiSignalService().compute(
            repository: repository,
            prNumber: prNumber,
            changedFiles: [for (final f in files) f.filename],
            cohorts: cohorts,
            supportsJobDetail:
                forge != null &&
                (kForgeCapabilities[forge]?.ciJobDetail ?? false),
          );
          return signals.toJson();
        },
      ),
    // A PR's dependency lockfile diffs.
    if (reviewDependencyDiffRepository != null)
      RepoOp(
        name: 'review_studio.dependencyDiffs',
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
          final prNumber = (ctx.args['pr_number'] as num).toInt();
          final key = resolveStudioKey != null
              ? await resolveStudioKey(
                  workspaceId: ctx.workspaceId!,
                  owner: c.owner,
                  repo: c.repo,
                  prNumber: prNumber,
                )
              : reviewPrNodeKey(c.owner, c.repo, prNumber);
          final diffs = await reviewDependencyDiffRepository.forPr(
            ctx.workspaceId!,
            key,
          );
          return {
            'diffs': [for (final d in diffs) dependencyDiffToWire(d)],
          };
        },
      ),
    // Review-effectiveness counters for the workspace.
    if (reviewHubStats != null)
      RepoOp(
        name: 'review_hub.stats',
        kind: RepoOpKind.read,
        handler: (ctx) => reviewHubStats(workspaceId: ctx.workspaceId!),
      ),
    // Starts the AI review (the "Ask AI" action): runs the `pr_review`
    // pipeline. Manual by design — no event trigger. The run proceeds in the
    // background; the response only reports the space + status.
    if (reviewHubStart != null)
      RepoOp(
        name: 'review_hub.start',
        kind: RepoOpKind.mutate,
        // Starting a review fans out N reviewer agent runs (plus the editorial
        // pass), each of which is a real process on the host.
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: ['workspace_id', 'owner', 'repo', 'pr_number'],
        handler: (ctx) async {
          final c = requireRepoCoords(ctx.args);
          // Optional per-run override of the workspace's default review level.
          // Validated here rather than coerced downstream: a caller that names
          // a level we do not have has a bug worth reporting, and silently
          // reviewing at some other depth is what would hide it.
          final rawLevel = ctx.args['level'];
          if (rawLevel != null &&
              (rawLevel is! String || ReviewLevel.fromWire(rawLevel) == null)) {
            throw ValidationException(
              'Unknown review level: $rawLevel. Expected one of '
              '${ReviewLevel.values.map((l) => l.wireName).join(', ')}.',
            );
          }
          return reviewHubStart(
            workspaceId: ctx.workspaceId!,
            owner: c.owner,
            repo: c.repo,
            prNumber: (ctx.args['pr_number'] as num).toInt(),
            userId: ctx.userId,
            level: rawLevel as String?,
          );
        },
      ),
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
      // Authoring a `bash.script` node schedules a process spawn by proxy —
      // the same claim `repos.setScripts` makes about a lifecycle script.
      actionClasses: const {ActionClass.processSpawn},
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
    RepoOp(
      name: 'pipeline_trigger.insert',
      kind: RepoOpKind.mutate,
      // An enabled event/cron/webhook trigger is `engine.start` without an
      // RPC, which is how a visitor would fire a bash-bearing pipeline.
      actionClasses: const {ActionClass.processSpawn},
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
      // Enabling or scheduling a trigger is the same spawn-by-proxy as insert.
      actionClasses: const {ActionClass.processSpawn},
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

    // A workspace's logo as bytes, for a client with no HTTP route to this
    // server (see [workspaceLogoBytes] for why that is the phone's normal
    // case). Workspace-scoped — unlike the registry CRUD below — so the
    // dispatcher's membership gate runs BEFORE the handler and a non-member
    // never reaches the file.
    if (workspaceLogoBytes != null)
      RepoOp(
        name: 'workspace.logo',
        kind: RepoOpKind.read,
        handler: (ctx) async {
          final bytes = await workspaceLogoBytes(workspaceId: ctx.workspaceId!);
          if (bytes == null || bytes.isEmpty) {
            return {'bytes': null, 'content_type': null};
          }
          // A logo is capped at 2 MB by the upload UI. Refusing anything
          // larger here keeps a hand-edited `logo_path` from pushing an
          // arbitrary file through a JSON frame, where it would be
          // base64-inflated by a third and buffered whole on both ends.
          if (bytes.length > kMaxLogoBytes) {
            return {'bytes': null, 'content_type': null};
          }
          return {
            'bytes': base64Encode(bytes),
            'content_type': logoContentTypeOf(bytes),
          };
        },
      ),
    // CROSS-WORKSPACE BY DESIGN: create_workspace / list_workspaces are the
    // declared isolation exemptions (a workspace can't be scoped to itself
    // before it exists). Mirrors WorkspaceRepository.{upsert,delete,watchAll}.
    RepoOp(
      name: 'workspace.upsert',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace'],
      handler: (ctx) async {
        final raw = (ctx.args['workspace'] as Map).cast<String, dynamic>();
        final incoming = workspaceFromWire(raw);
        // Detect a CREATE (vs an update) so the server can bootstrap the new
        // workspace exactly once.
        final existing = await workspaceRepository.getById(incoming.id);
        final isNew = existing == null;
        // UPDATEs mutate another tenant's registry row. The op is
        // `workspaceScoped: false` because a CREATE has no workspace to scope
        // to, so the dispatcher's role gate never fires here — enforce it in
        // the handler: only an admin of the existing workspace may change it.
        if (!isNew) {
          // Fail closed: an identity-less catalog previously served this
          // ungated, so "update any workspace" depended on wiring that the
          // check itself is supposed to enforce.
          final members = identityMembers;
          if (members == null) {
            throw const AuthException(
              'This server has no membership wiring, so a workspace cannot be '
              'updated.',
            );
          }
          final role = (await members.getMember(incoming.id, ctx.userId))?.role;
          if (role == null || !role.atLeast(WorkspaceRole.admin)) {
            throw const AuthException(
              'Updating a workspace requires its admin role',
            );
          }
        }
        // On CREATE the calling principal becomes the workspace owner: stamp
        // `ownerUserId` and record an owner-role membership row NOW, in the
        // same op. Without this the freshly created workspace has no members,
        // so every workspace-scoped call the creator makes next (the whole
        // post-onboarding app) is denied with "Not a member of this
        // workspace" until the next server restart, when
        // `IdentityBootstrap._backfillWorkspaceOwnership` happens to repair it.
        // On UPDATE, carry the stored owner over when the wire omits it so a
        // rename from an older client can never wipe the stamp.
        var toStore = incoming.ownerUserId != null
            ? incoming
            : incoming.copyWith(
                ownerUserId: isNew ? ctx.userId : existing.ownerUserId,
              );
        // Older clients omit the GitHub identity fields. Carry the stored
        // values over so a rename cannot silently reset a workspace that
        // picked its own App or a PAT.
        final previous = existing;
        if (previous != null) {
          if (!raw.containsKey('github_auth_mode')) {
            toStore = toStore.copyWith(githubAuthMode: previous.githubAuthMode);
          }
          if (!raw.containsKey('github_app_id')) {
            toStore = toStore.copyWith(githubAppId: previous.githubAppId);
          }
        }
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
            // Announce the membership, not just the workspace. Every live
            // membership-scoped stream ([visibleRows]) resolves the
            // subscriber's workspace set ONCE and re-resolves only on this
            // event — so a session that subscribed to `workspace.watchAll`
            // while the user belonged to nothing (onboarding does exactly
            // that) would filter its own brand-new workspace out of every
            // later emission for the life of the connection. That is what
            // stranded first-run onboarding: the workspace existed on disk,
            // the client's list stayed empty, the gate stayed "incomplete",
            // and Finish was bounced straight back to the flow, which then
            // created another workspace on the next attempt.
            eventBus?.publish(
              WorkspaceMemberAdded(
                workspaceId: id,
                userId: ctx.userId,
                role: WorkspaceRole.owner,
                occurredAt: DateTime.now(),
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
        // Deleting a workspace unlinks its entire database file — the most
        // destructive registry operation there is. The op is unscoped (the
        // row lives in the GLOBAL registry), so the dispatcher's role gate
        // never fires; only the workspace's OWNER may delete it.
        final id = ctx.args['id'] as String;
        final members = identityMembers;
        if (members != null) {
          final role = (await members.getMember(id, ctx.userId))?.role;
          if (role != WorkspaceRole.owner) {
            throw const AuthException(
              'Deleting a workspace requires its owner role',
            );
          }
        }
        await workspaceRepository.delete(id);
        await workspaceGitHubApps?.deleteForWorkspace(id);
        return {'ok': true};
      },
    ),
    // Reordering IS a whole-list operation over the caller's own picker, so it
    // cannot scope to one workspace (`workspaceScoped: false`). The order is a
    // server-owned property of the registry rows — but every id in the list
    // must be a workspace the caller belongs to, or a non-member could move
    // (and thereby learn) foreign registry rows.
    RepoOp(
      name: 'workspace.reorder',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['workspace_ids'],
      handler: (ctx) async {
        final ids = ((ctx.args['workspace_ids'] as List?) ?? const [])
            .map((w) => w.toString())
            .toList();
        final members = identityMembers;
        if (members != null) {
          final memberships = await members.getForUser(ctx.userId);
          final visible = {for (final m in memberships) m.workspaceId};
          if (ids.any((id) => !visible.contains(id))) {
            throw const AuthException(
              'Cannot reorder a workspace you do not belong to',
            );
          }
        }
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

    ...buildPrReviewOps(
      resolvePrReviewRepository: resolvePrReviewRepository,
      requireRepoCoords: requireRepoCoords,
      previewSwr: previewSwr,
      assertSpaceOwned: assertSpaceOwned,
      messagingRepository: messagingRepository,
      fetchPrPreview: fetchPrPreview,
      fetchCommitPreview: fetchCommitPreview,
      userRepository: userRepository,
      reviewFindingStatus: reviewFindingStatus,
    ),
    // Approvals are host-global (a phone spans workspaces), so the op is
    // `workspaceScoped: false` — but the request carries the workspace it was
    // raised in and the responder MUST be a member (member role or above) of
    // that workspace: an approval decides whether a privileged agent action
    // runs, so a non-member resolving it is a privilege escalation. Absent
    // entirely when the host wired no [PendingConfirmationRegistry] (headless
    // cc_server has no dispatch).
    if (pendingConfirmationRegistry != null)
      RepoOp(
        name: 'confirmation.respond',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          final id = ctx.args['id'] as String;
          final pending = pendingConfirmationRegistry.pendingById(id);
          if (pending == null) {
            return {'ok': false};
          }
          final members = membershipRepository;
          final ws = pending.request.workspaceId;
          if (members != null && ws != null) {
            final role = (await members.getMember(ws, ctx.userId))?.role;
            if (role == null || !role.atLeast(WorkspaceRole.member)) {
              throw const AuthException(
                'Resolving this approval requires membership in its '
                'workspace',
              );
            }
            // Routing: at tier 0 only the policy's primary audience may
            // answer; the set widens on the policy's timeout (admins, then
            // the owner) so a gate is never stuck on someone who is away.
            if (!await isConfirmationTarget(pending, ctx.userId)) {
              throw const AuthException(
                'This approval is currently routed to someone else; it '
                'escalates if it goes unanswered.',
              );
            }
          }
          final approved = ctx.args['approved'] == true;
          final ok = pendingConfirmationRegistry.respond(
            id,
            approved: approved,
          );
          // "Remember this decision" — a STANDING APPROVAL, materialized as a
          // real, expiring, argument-scoped policy rule.
          //
          // `RememberScope` and a fingerprint had been set on every guard
          // confirmation since PRD 24 and read by nobody: the docs described
          // the feature, no code implemented it, and `provenance:'remembered'`
          // had no writer. This is it. The rule is narrow (the constraint
          // generalized from the approved call), scoped (space / agent /
          // workspace) and SELF-REVOKING (an explicit TTL), so an operator
          // saying "yes, for the next few hours" is not quietly rewriting
          // their permanent policy.
          final remember = ctx.args['remember'];
          if (ok &&
              approved &&
              remember is Map &&
              ws != null &&
              actionPolicyRepository != null) {
            final scopeWire = remember['scope'] as String?;
            final requestedTtl = (remember['ttl_seconds'] as num?)?.toInt();
            final classes = pending.request.actionClasses;
            // Answering a prompt is a MEMBER-level act; writing workspace
            // policy is an ADMIN one (`action_policy.upsert` is admin-gated).
            // A standing approval must not be a way around that, so a
            // non-admin's remember is confined to the space (or the agent)
            // the prompt came from, and workspace scope needs the same role
            // the policy editor does.
            final responderRole = members == null
                ? null
                : (await members.getMember(ws, ctx.userId))?.role;
            final mayWriteWorkspaceScope = responderRole?.isAdmin ?? false;
            final spaceId = pending.request.spaceId;
            final agentId = pending.request.agentId ?? '';
            final (scopeType, scopeId) = switch (scopeWire) {
              'space' when spaceId.isNotEmpty => (
                ActionScopeType.space,
                spaceId,
              ),
              'agent' when agentId.isNotEmpty => (
                ActionScopeType.agent,
                agentId,
              ),
              'workspace' when mayWriteWorkspaceScope => (
                ActionScopeType.workspace,
                '',
              ),
              // Narrow rather than refuse: the answer already stands, and the
              // narrowest scope that exists is what the responder is entitled
              // to. With neither a space nor an agent to pin it to, an
              // unprivileged remember writes nothing at all.
              _ when spaceId.isNotEmpty => (ActionScopeType.space, spaceId),
              _ when agentId.isNotEmpty => (ActionScopeType.agent, agentId),
              _ when mayWriteWorkspaceScope => (ActionScopeType.workspace, ''),
              _ => (ActionScopeType.workspace, unscopedRemember),
            };
            if (classes.isNotEmpty && scopeId != unscopedRemember) {
              // A standing approval is time-boxed BY DEFINITION. An unbounded
              // ttl would let one click become permanent policy, which is the
              // admin-gated act this path must not become.
              final ttl = Duration(
                seconds: (requestedTtl ?? defaultRememberTtlSeconds).clamp(
                  60,
                  maxRememberTtlSeconds,
                ),
              );
              final now = DateTime.now();
              for (final wire in classes) {
                final cls = ActionClass.fromWire(wire);
                if (cls == null) {
                  continue;
                }
                await actionPolicyRepository.upsertRule(
                  ActionPolicyRule(
                    id: const Uuid().v4(),
                    workspaceId: ws,
                    scopeType: scopeType,
                    scopeId: scopeId,
                    actionClass: cls,
                    decision: ActionDecision.allow,
                    provenance: 'remembered',
                    createdBy: ctx.userId,
                    constraint: ActionConstraint.decode(
                      pending.request.constraintJson,
                    ),
                    expiresAt: now.add(ttl),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              }
            }
          }
          return {'ok': ok};
        },
      ),
    // Answers a parked run: `retry` re-probes the credential immediately (the
    // operator says they have just fixed it), `cancel` gives up and lets the
    // turn fail with the message it would have failed with anyway.
    //
    // Membership-gated against the BLOCKED RUN's workspace, for the same reason
    // `confirmation.respond` is: cancelling somebody else's run is a mutation
    // in their workspace. `retry` is gated too — it is cheap, but it names a
    // block a non-member should not be able to confirm exists.
    if (credentialBlockRegistry != null)
      RepoOp(
        name: 'credential_gate.resolve',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        requiredArgs: ['id'],
        handler: (ctx) async {
          final id = ctx.args['id'] as String;
          final blocked = credentialBlockRegistry.blockById(id);
          if (blocked == null) {
            // Already resolved — the credential landed while the click was in
            // flight, which is the happy path, not an error.
            return {'ok': false};
          }
          final members = membershipRepository;
          final ws = blocked.request.workspaceId;
          if (members != null && ws != null) {
            final role = (await members.getMember(ws, ctx.userId))?.role;
            if (role == null || !role.atLeast(WorkspaceRole.member)) {
              throw const AuthException(
                'Resolving this blocked run requires membership in its '
                'workspace',
              );
            }
          }
          final ok = await credentialBlockRegistry.respond(
            id,
            cancel: ctx.args['action'] == 'cancel',
          );
          return {'ok': ok};
        },
      ),
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
    // Workspace-scoped (the bound workspace is `ctx.workspaceId!`); each op
    // additionally requires the `conversation_id` it operates on, and proves
    // the conversation belongs to that workspace before it touches a row. The
    // list is per CONVERSATION, not per space: a conversation owns one stream
    // and one task list, and the `todos.conversation_id` foreign key points
    // at `conversations`.
    RepoOp(
      name: 'todos.list',
      kind: RepoOpKind.read,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        final items = await todoRepository.list(
          ctx.workspaceId!,
          conversationId,
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
        await assertConversationOwned(workspaceId, conversationId);
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        final item = await todoRepository.append(
          ctx.workspaceId!,
          conversationId,
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.updateStatus(
          ctx.workspaceId!,
          conversationId,
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.remove(
          ctx.workspaceId!,
          conversationId,
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.reorder(
          ctx.workspaceId!,
          conversationId,
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.clear(ctx.workspaceId!, conversationId);
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.setGoal(
          ctx.workspaceId!,
          conversationId,
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
        final conversationId = ctx.args['conversation_id'] as String;
        await assertConversationOwned(ctx.workspaceId!, conversationId);
        await todoRepository.clearGoal(ctx.workspaceId!, conversationId);
        return {'ok': true};
      },
    ),
    // Every op below writes the CALLER's own row (`ctx.userId`, never a client
    // arg) with the server clock, so read state follows the user across
    // devices. `minRole: guest` matches the read floor — acknowledging your
    // own bell is not a workspace mutation.
    //
    // A per-item op takes an `item_id` it does NOT validate against the feed:
    // the row it writes is keyed on (workspace, caller, item) and is only ever
    // read back joined against that workspace's feed, so an id naming nothing
    // writes a state nobody can observe. It cannot reach another workspace —
    // `ctx.workspaceId` picks the database file.
    RepoOp(
      name: 'notifications.markAllRead',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.guest,
      // Per-user read mark (bulk form of setItemRead) — noise, not
      // accountability.
      audited: false,
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
        await notificationFeedRepository.clearAll(ctx.workspaceId!, ctx.userId);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'notifications.setItemRead',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.guest,
      // Per-user read mark — noise, not accountability.
      audited: false,
      requiredArgs: ['item_id'],
      handler: (ctx) async {
        await notificationFeedRepository.setItemRead(
          ctx.workspaceId!,
          ctx.userId,
          ctx.args['item_id'] as String,
          read: ctx.args['read'] as bool? ?? true,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'notifications.dismissItem',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.guest,
      requiredArgs: ['item_id'],
      handler: (ctx) async {
        await notificationFeedRepository.dismissItem(
          ctx.workspaceId!,
          ctx.userId,
          ctx.args['item_id'] as String,
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
    // Built in the runtime (where the scheduler + repository live) and spliced
    // in here so this hub file stays agnostic of the fleet wiring.
    ...extraOps,
    // Wire catalog bumps (non-obvious rules only):
    // v22 notifications.* — durable feed; bell left device-local prefs.
    // v23 installed skills scan + fs.writeSkillFile through the same scan gate.
    // v24 skills.analyze / scanInstalled as skill_analysis pipeline runs.
    // v26 notifications.clear (was client-called but never registered) +
    //     per-item read/dismiss + watchItemStates.
    // v27 skills.sources* — operator GitHub repos replace skills.sh; full
    //     lifecycle (uninstall/checkUpdates/updateSkill) on the server.
  ], catalogVersion: 27);

  // Membership-scoped cross-workspace streams. The solo-era `*.watchAll`
  // queries fan out over EVERY workspace on the server; with multi-user
  // identity, "all workspaces" means all workspaces THE SUBSCRIBER belongs
  // to. Rows from foreign workspaces are filtered out of every emission and
  // this user's membership add/remove events force a re-emission of the last
  // snapshot (re-filtered), so a revoke stops the flow immediately rather
  // than on the next source change. On a host without identity wiring
  // (single-user), streams pass through unfiltered.
  Stream<List<T>> visibleRows<T>(
    WatchQueryContext ctx,
    Stream<List<T>> source,
    String? Function(T row) workspaceOf,
  ) {
    final members = membershipRepository;
    if (members == null) {
      return source;
    }
    final userId = ctx.userId;
    final bus = eventBus;
    // The membership set is resolved ONCE per subscription instead of once per
    // emission. `watchAll`-shaped sources re-emit on every row change in every
    // workspace, so a membership SELECT per emission put a database round trip
    // on the server's single shared connection in front of every filtered
    // frame. Correctness is unchanged: the very events that can change this
    // set — the ones this stream already listens to in order to re-emit — also
    // clear the memo, so a revoke still takes effect on the same frame it
    // always did. With no event bus there is nothing to invalidate against, so
    // that path keeps querying per emission rather than going stale.
    Set<String>? visibleMemo;
    final triggered = Stream<List<T>>.multi((controller) {
      List<T>? latest;
      final subs = <StreamSubscription<Object?>>[
        source.listen(
          (rows) {
            latest = rows;
            controller.add(rows);
          },
          onError: controller.addError,
          onDone: controller.close,
        ),
      ];
      if (bus != null) {
        void reemit(String eventUserId) {
          if (eventUserId != userId) {
            return;
          }
          visibleMemo = null;
          final rows = latest;
          if (rows != null) {
            controller.add(rows);
          }
        }

        subs.add(
          bus.on<WorkspaceMemberAdded>().listen((e) => reemit(e.userId)),
        );
        subs.add(
          bus.on<WorkspaceMemberRemoved>().listen((e) => reemit(e.userId)),
        );
      }
      controller.onCancel = () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      };
    });
    return triggered.asyncMap((rows) async {
      var visible = bus == null ? null : visibleMemo;
      if (visible == null) {
        final memberships = await members.getForUser(userId);
        visible = {for (final m in memberships) m.workspaceId};
        if (bus != null) {
          visibleMemo = visible;
        }
      }
      final resolved = visible;
      return [
        for (final row in rows)
          if (workspaceOf(row) case final ws? when resolved.contains(ws)) row,
      ];
    });
  }

  final watch = WatchQueryRegistry([
    // Custom roles + the authorization audit trail (Stage 2 governance).
    if (workspaceRoleRepository != null &&
        entitlements.has(Entitlement.customRoles))
      WatchQuery(
        name: 'roles.watchForWorkspace',
        minRole: WorkspaceRole.member,
        handler: (ctx) => workspaceRoleRepository
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (roles) => {
                'roles': [for (final r in roles) roleDefinitionToWire(r)],
              },
            ),
      ),
    if (guardDecisionRepository != null)
      WatchQuery(
        name: 'audit.watchRecent',
        minRole: WorkspaceRole.admin,
        handler: (ctx) => guardDecisionRepository
            .watchRecent(ctx.workspaceId!)
            .map(
              (rows) => {
                'decisions': [for (final d in rows) guardDecisionToWire(d)],
              },
            ),
      ),
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
        name: 'notes.watchForSpace',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String? ?? '';
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .watchNoteForSpace(ctx.workspaceId!, spaceId)
              .map(
                (row) => {'note': row == null ? null : spaceNoteToWire(row)},
              );
        },
      ),
      WatchQuery(
        name: 'autonomy.watchForSpace',
        minRole: WorkspaceRole.member,
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String? ?? '';
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .watchAutonomyForSpace(ctx.workspaceId!, spaceId)
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
        name: 'reactions.watchForSpace',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String? ?? '';
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          yield* workspaceDbs
              .of(ctx.workspaceId!)
              .spaceExtrasDao
              .watchReactionsForSpace(ctx.workspaceId!, spaceId)
              .map((rows) => {'reactions': rows.map(reactionToWire).toList()});
        },
      ),
    ],
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
    if (identityUsers != null &&
        identityMembers != null &&
        identityInvites != null &&
        identityActivity != null &&
        identityPrefs != null) ...[
      // CROSS-WORKSPACE BY DESIGN — identity is global; authorship display in
      // shared spaces needs every co-member's name/avatar. Handles/display
      // names are directory data on a self-hosted server, not a secret.
      WatchQuery(
        name: 'users.watchAll',
        workspaceScoped: false,
        // Same co-membership rule as `users.list` — see `visibleUsersFor`.
        // Recomputed per emission rather than once at subscribe: a membership
        // granted mid-session must widen the stream, and the user list changes
        // rarely enough that the extra lookup is not on any hot path.
        handler: (ctx) => identityUsers.watchAll().asyncMap(
          (users) async => {'users': await visibleUsersFor(ctx.userId, users)},
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
        minRole: WorkspaceRole.admin,
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
        minRole: WorkspaceRole.admin,
        handler: (ctx) {
          // Cursor page of the audit trail. `limit` defaults to 200 so a
          // subscriber that does not pass paging args still gets the
          // historic snapshot; the settings table always sends a page size.
          final rawLimit = (ctx.args['limit'] as num?)?.toInt();
          final rawIds = ctx.args['user_ids'];
          return identityActivity
              .watchPage(
                ctx.workspaceId!,
                limit: (rawLimit ?? 200).clamp(1, 200),
                cursor: ctx.args['cursor'] as String?,
                filter: UserActivityFilter(
                  query: optionalArg(ctx.args, 'query'),
                  ip: optionalArg(ctx.args, 'ip'),
                  countryCode: optionalArg(ctx.args, 'country_code'),
                  localNetwork: ctx.args['local_network'] == true,
                  userIds: rawIds is List
                      ? rawIds.whereType<String>().toList()
                      : const [],
                ),
              )
              .map(
                (page) => {
                  'entries': page.entries.map(userActivityToWire).toList(),
                  'total': page.total,
                  'start': page.start,
                  'next_cursor': page.nextCursor,
                  'prev_cursor': page.prevCursor,
                  'has_more': page.hasMore,
                },
              );
        },
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
    // optional `space_id` arg narrows to one conversation. Registered only when
    // the host runs code-server.
    if (vscode != null)
      WatchQuery(
        name: 'codeServer.watchOpenRequests',
        handler: (ctx) {
          final space = ctx.args['space_id'] as String?;
          return vscode
              .watchOpenRequests(ctx.workspaceId!)
              .where((r) => space == null || r.spaceId == space)
              .map(
                (r) => {
                  'space_id': r.spaceId,
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
    // filters on it); `space_id` narrows to one conversation.
    if (vscode != null)
      WatchQuery(
        name: 'codeServer.watchDirtyState',
        handler: (ctx) {
          final space = ctx.args['space_id'] as String?;
          return vscode
              .watchDirtyState(ctx.workspaceId!)
              .where((e) => space == null || e.spaceId == space)
              .map(
                (e) => {
                  'space_id': e.spaceId,
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
        minRole: WorkspaceRole.member,
        handler: (ctx) => syncConfigRepository
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (list) => {'configs': list.map(ticketSyncConfigToWire).toList()},
            ),
      ),
    if (syncLogRepository != null)
      WatchQuery(
        name: 'ticket_sync_log.watchForWorkspace',
        minRole: WorkspaceRole.member,
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
    // The dashboard's global all-agents view — membership-scoped via
    // [visibleRows]: "all" is all workspaces the SUBSCRIBER belongs to; a
    // non-member's agents never stream.
    WatchQuery(
      name: 'agents.watchAll',
      workspaceScoped: false,
      handler: (ctx) => visibleRows(
        ctx,
        agentRepository.watchAll(),
        (a) => a.workspaceId,
      ).map((list) => {'agents': list.map(agentToWire).toList()}),
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
    // Recorded lifecycle script runs (setup/archive), newest first. Workspace-
    // scoped like the row itself; an optional repo_id narrows to one repo.
    // Declared only when the host wires a [RepoScriptRepository].
    if (repoScriptRepository != null)
      WatchQuery(
        name: 'repos.watchScriptRuns',
        handler: (ctx) => repoScriptRepository
            .watchRuns(ctx.workspaceId!, repoId: ctx.args['repo_id'] as String?)
            .map((runs) => {'runs': runs.map((r) => r.toJson()).toList()}),
      ),
    WatchQuery(
      name: 'messaging.watchSpaces',
      handler: (ctx) => messagingRepository
          .watchSpacesByWorkspace(ctx.workspaceId!)
          .map((list) => {'spaces': list.map(spaceToWire).toList()}),
    ),
    WatchQuery(
      name: 'messaging.watchMessages',
      handler: (ctx) async* {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        // Validate ownership once, before streaming any rows.
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        // Conversation (stream) inside the space; the space's standing
        // conversation when the client doesn't scope it.
        final conversationId = await resolveConversationId(
          ctx.workspaceId!,
          spaceId,
          ctx.args['conversation_id'],
        );
        yield* messagingRepository
            .watchMessages(ctx.workspaceId!, spaceId, conversationId)
            .map((list) => {'messages': list.map(messageToWireLite).toList()});
      },
    ),
    // Space-wide watch: every message in the room, across all its
    // conversations. The review surfaces need it — findings are filed by
    // several reviewers, each in its own stream, so a conversation-scoped watch
    // renders one reviewer's findings and calls it the review.
    WatchQuery(
      name: 'messaging.watchSpaceMessages',
      handler: (ctx) async* {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        // Same ownership gate as the conversation-scoped watch, before any row
        // streams — widening the read must not widen who may read.
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        yield* messagingRepository
            .watchSpaceMessages(ctx.workspaceId!, spaceId)
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
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        final limit = ((ctx.args['limit'] as num?)?.toInt() ?? 60).clamp(
          1,
          2000,
        );
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        final conversationId = await resolveConversationId(
          ctx.workspaceId!,
          spaceId,
          ctx.args['conversation_id'],
        );
        yield* messagingRepository
            .watchMessagesWindow(
              ctx.workspaceId!,
              spaceId,
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
    // Context-meter aggregate: the live region's size as two integers.
    //
    // The meters used to subscribe to `messaging.watchMessages` — the whole
    // conversation, re-sent on every write — to render a number and a bar.
    // This computes the same figures next to the rows and ships 30 bytes, so
    // opening a chat (and hovering a space) stops costing its history.
    if (watchConversationTokens != null)
      WatchQuery(
        name: 'messaging.watchConversationTokens',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String?;
          if (spaceId == null) {
            throw const NotFoundException('Missing space_id');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final conversationId = await resolveConversationId(
            ctx.workspaceId!,
            spaceId,
            ctx.args['conversation_id'],
          );
          yield* watchConversationTokens(
            ctx.workspaceId!,
            spaceId,
            conversationId,
          ).map((t) => {'tokens': t.tokens, 'chars': t.chars});
        },
      ),
    // Composer recall: this caller's recent plain-text prompts, not the
    // conversation. The user id comes from the session, never from args, so
    // a client cannot ask for someone else's history.
    if (watchUserPromptHistory != null)
      WatchQuery(
        name: 'messaging.watchUserPromptHistory',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String?;
          if (spaceId == null) {
            throw const NotFoundException('Missing space_id');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final conversationId = await resolveConversationId(
            ctx.workspaceId!,
            spaceId,
            ctx.args['conversation_id'],
          );
          yield* watchUserPromptHistory(
            ctx.workspaceId!,
            spaceId,
            conversationId,
            ctx.userId,
          ).map((prompts) => {'prompts': prompts});
        },
      ),
    // Live turn relay: seed snapshot of every active turn in the space, then
    // coalesced per-segment updates straight from the dispatch stack's
    // ActiveStreamRegistry — the streaming path, decoupled from DB flushes.
    // Registered only on a host that runs the dispatch stack.
    if (streamRegistry != null)
      WatchQuery(
        name: 'messaging.watchSpaceTurns',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String?;
          if (spaceId == null) {
            throw const NotFoundException('Missing space_id');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          final restricted = await viewerTraceRestricted(
            ctx.workspaceId!,
            spaceId,
            ctx.userId,
          );
          final frames = watchSpaceTurnFrames(streamRegistry, spaceId);
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
            run.spaceId ?? run.conversationId ?? '',
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
    // Per-space activity signals for the whole bound workspace in ONE
    // subscription: unread-dot + needs-input + attention-count sources.
    if (watchSpaceActivity != null)
      WatchQuery(
        name: 'messaging.watchSpaceActivity',
        handler: (ctx) => watchSpaceActivity(
          ctx.workspaceId!,
        ).map((list) => {'spaces': list.map((a) => a.toJson()).toList()}),
      ),
    // Conversations (streams) inside a space — flat equals, threads included.
    if (watchConversationsForSpace != null)
      WatchQuery(
        name: 'conversation.watchForSpace',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String?;
          if (spaceId == null) {
            throw const NotFoundException('Missing space_id');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          yield* watchConversationsForSpace(ctx.workspaceId!, spaceId).map(
            (list) => {'conversations': list.map(conversationToWire).toList()},
          );
        },
      ),
    // Per-thread rollups for the whole space, so the feed can draw a
    // "N replies · last reply …" row under every message that started a
    // thread from ONE subscription instead of one watch per thread.
    if (conversationRepository != null)
      WatchQuery(
        name: 'conversation.watchThreadSummaries',
        handler: (ctx) async* {
          final spaceId = ctx.args['space_id'] as String?;
          if (spaceId == null) {
            throw const NotFoundException('Missing space_id');
          }
          await assertSpaceOwned(ctx.workspaceId!, spaceId);
          yield* conversationRepository
              .watchThreadSummaries(
                workspaceId: ctx.workspaceId!,
                spaceId: spaceId,
              )
              .map(
                (list) => {'threads': list.map(threadSummaryToWire).toList()},
              );
        },
      ),
    WatchQuery(
      name: 'messaging.watchParticipants',
      handler: (ctx) async* {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        yield* messagingRepository
            .watchParticipants(ctx.workspaceId!, spaceId)
            .map(
              (list) => {
                'participants': list.map(spaceParticipantToWire).toList(),
              },
            );
      },
    ),
    // The workspace chooser's source. Membership-scoped via [visibleRows]: a
    // user sees only workspaces they belong to — a non-member must not even
    // learn another workspace's name/id from the picker. The query itself
    // stays `workspaceScoped: false` because the picker is pre-membership UI
    // (there is no target workspace to gate on); the filter is the boundary.
    WatchQuery(
      name: 'workspace.watchAll',
      workspaceScoped: false,
      handler: (ctx) => visibleRows(
        ctx,
        workspaceRepository.watchAll(),
        (w) => w.id,
      ).map((list) => {'workspaces': list.map(workspaceToWire).toList()}),
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
      handler: (ctx) => newsfeedRepository
          .watchArticles(ctx.userId)
          .map((list) => {'articles': list.map(articleToWire).toList()}),
    ),
    WatchQuery(
      name: 'newsfeed.watchFeeds',
      workspaceScoped: false,
      handler: (ctx) => newsfeedRepository
          .watchFeeds(ctx.userId)
          .map((list) => {'feeds': list.map(feedToWire).toList()}),
    ),
    WatchQuery(
      name: 'space_read.watchUserLastReadAt',
      handler: (ctx) async* {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        // Validate ownership once, before streaming any cursor updates.
        await assertSpaceOwned(ctx.workspaceId!, spaceId);
        yield* spaceReadRepository
            .watchUserLastReadAt(ctx.workspaceId!, spaceId, ctx.userId)
            .map((lastReadAt) => spaceReadToWire(spaceId, lastReadAt));
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
      minRole: WorkspaceRole.member,
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
      minRole: WorkspaceRole.member,
      handler: (ctx) => memoryPolicyRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'policies': list.map(memoryPolicyToWire).toList()}),
    ),
    if (providerPolicy != null)
      WatchQuery(
        name: 'provider_policy.watchForWorkspace',
        minRole: WorkspaceRole.member,
        handler: (ctx) => providerPolicy
            .watchForWorkspace(ctx.workspaceId!)
            .map(
              (list) => {'policies': list.map(providerPolicyToWire).toList()},
            ),
      ),
    if (serverSettingsRepository != null)
      WatchQuery(
        name: 'server_settings.watch',
        serverAuthority: ServerAuthority.serverOwner,
        // Install-wide values (launch argv/env can carry host credentials), so
        // workspace membership is not the bar — the OPERATOR's is. Declared
        // unscoped: no workspace_id selects anything here.
        workspaceScoped: false,
        handler: (ctx) async* {
          if (serverOwnerUserId != null && ctx.userId != serverOwnerUserId) {
            throw const AuthException(
              'This setting affects every workspace on this server and can '
              'only be read by its operator.',
            );
          }
          yield* serverSettingsRepository.watchAll().map(
            (settings) => {'settings': settings},
          );
        },
      ),
    if (workspaceSettingsRepository != null)
      WatchQuery(
        name: 'workspace_settings.watchForWorkspace',
        minRole: WorkspaceRole.member,
        handler: (ctx) => workspaceSettingsRepository
            .watchAll(ctx.workspaceId!)
            .map((settings) => {'settings': settings}),
      ),
    if (actionPolicyRepository != null)
      WatchQuery(
        name: 'action_policy.watchForWorkspace',
        minRole: WorkspaceRole.member,
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
      name: 'review_space.watchByWorkspace',
      handler: (ctx) => reviewSpaceRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map(
            (list) => {'associations': list.map(reviewSpaceToWire).toList()},
          ),
    ),
    WatchQuery(
      name: 'review_space.watchByPr',
      handler: (ctx) {
        final prExternalId = ctx.args['pr_external_id'] as String?;
        if (prExternalId == null) {
          throw const NotFoundException('Missing pr_external_id');
        }
        // PR node ids are global; scope to the bound workspace server-side.
        return reviewSpaceRepository
            .watchByPr(ctx.workspaceId!, prExternalId)
            .map(
              (a) => {'association': a == null ? null : reviewSpaceToWire(a)},
            );
      },
    ),
    WatchQuery(
      name: 'review_space.watchBySpace',
      handler: (ctx) {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        // The interface keys by space_id alone; enforce ownership on the
        // emitted row — a foreign-workspace association is filtered to null so
        // an ID-only lookup can't leak across workspaces (isolation invariant).
        return reviewSpaceRepository
            .watchBySpace(ctx.workspaceId!, spaceId)
            .map(
              (a) => {
                'association': (a == null || a.workspaceId != ctx.workspaceId)
                    ? null
                    : reviewSpaceToWire(a),
              },
            );
      },
    ),
    WatchQuery(
      name: 'review_space.watchAllBySpace',
      handler: (ctx) {
        final spaceId = ctx.args['space_id'] as String?;
        if (spaceId == null) {
          throw const NotFoundException('Missing space_id');
        }
        // Workspace-scoped at the query level (the bound workspace), so a
        // foreign-workspace association is never emitted (isolation invariant).
        return reviewSpaceRepository
            .watchAllBySpace(ctx.workspaceId!, spaceId)
            .map(
              (list) => {'associations': list.map(reviewSpaceToWire).toList()},
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
    WatchQuery(
      name: 'agent_run_log.watchActiveBySpace',
      handler: (ctx) => agentRunLogRepository
          .watchActiveBySpace(ctx.workspaceId!, ctx.args['space_id'] as String)
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
    WatchQuery(
      name: 'agent_run_log.watchBySpace',
      handler: (ctx) => agentRunLogRepository
          .watchBySpace(ctx.workspaceId!, ctx.args['space_id'] as String)
          .map((list) => {'logs': list.map(agentRunLogToWire).toList()}),
    ),
    // The global all-runs view — membership-scoped via [visibleRows].
    WatchQuery(
      name: 'agent_run_log.watchAll',
      workspaceScoped: false,
      handler: (ctx) => visibleRows(
        ctx,
        agentRunLogRepository.watchAll(),
        (l) => l.workspaceId,
      ).map((list) => {'logs': list.map(agentRunLogToWire).toList()}),
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
        return visibleRows(
          ctx,
          agentRunLogRepository.watchRecent(limit),
          (l) => l.workspaceId,
        ).map((list) => {'logs': list.map(agentRunLogToWire).toList()});
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
      minRole: WorkspaceRole.member,
      handler: (ctx) => voiceProfileRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'profiles': list.map(voiceProfileToWire).toList()}),
    ),
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
    // Every watch sources `ctx.workspaceId!` (the bound session, never a client
    // arg) as the leading `workspaceId`; the impl scopes every query by it, so a
    // foreign-workspace row never streams through. The range watch reads ISO-8601
    // `from`/`to`; the single-event watch reads the `event_id` from the args.
    WatchQuery(
      name: 'calendar.watchAccounts',
      handler: (ctx) => calendarRepository
          .watchAccounts(ctx.workspaceId!)
          .map(
            (list) => {
              'accounts': [
                for (final a in list)
                  if (a.userId == ctx.userId || a.userId.isEmpty)
                    calendarAccountToWire(a),
              ],
            },
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
    // The compose-PR draft list for the bound workspace. Sources
    // `ctx.workspaceId!` (the bound session, never a client arg); the impl scopes
    // the query by it, so a foreign-workspace row never streams through.
    WatchQuery(
      name: 'pr_lifecycle.watchByWorkspace',
      handler: (ctx) => prLifecycleRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'prs': list.map(prGenerationToWire).toList()}),
    ),
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
        minRole: WorkspaceRole.member,
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
    // The global all-runs view — membership-scoped via [visibleRows].
    WatchQuery(
      name: 'pipeline_run.watchAll',
      workspaceScoped: false,
      handler: (ctx) => visibleRows(
        ctx,
        pipelineRunRepository.watchAll(),
        (r) => r.workspaceId,
      ).map((list) => {'runs': list.map(pipelineRunToWire).toList()}),
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
      // Artifacts in one conversation (newest first), or the whole space when
      // no conversation is named. Association via `artifact` messages'
      // `metadata['workProductId']` (no schema column). Re-reads rows only when
      // the id list changes.
      //
      // Unscoped = space-wide on purpose: review spaces have no standing
      // conversation; minting one hid the review report from its tab.
      WatchQuery(
        name: 'workProduct.watchForSpace',
        handler: (ctx) async* {
          final workspaceId = ctx.workspaceId!;
          final spaceId = ctx.args['space_id'] as String;
          // Messages are keyed by space only, so ownership is checked here
          // before anything streams (workspace-isolation invariant).
          if (!await spaceInWorkspace(workspaceId, spaceId)) {
            throw const NotFoundException('Space not found in this workspace');
          }
          final supplied = ctx.args['conversation_id'];
          final Stream<List<Message>> messages;
          if (supplied is String && supplied.isNotEmpty) {
            messages = messagingRepository.watchMessages(
              workspaceId,
              spaceId,
              supplied,
            );
          } else {
            messages = messagingRepository.watchSpaceMessages(
              workspaceId,
              spaceId,
            );
          }
          yield* messages
              .map((messages) {
                final ids = <String>[];
                for (final m in messages) {
                  if (m.messageType != MessageType.artifact) {
                    continue;
                  }
                  final id = m.metadata?['workProductId'];
                  if (id is String && id.isNotEmpty && !ids.contains(id)) {
                    ids.add(id);
                  }
                }
                return ids;
              })
              .distinct((a, b) => a.join('') == b.join(''))
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
    if (reviewDependencyDiffRepository != null)
      WatchQuery(
        name: 'review_studio.watchDependencyDiffs',
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
          yield* reviewDependencyDiffRepository
              .watchForPr(ctx.workspaceId!, key)
              .map(
                (list) => {
                  'diffs': [for (final d in list) dependencyDiffToWire(d)],
                },
              );
        },
      ),

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

    // The repos the poller has parked as inaccessible (a 404/403 that held
    // through the failure threshold — typically a GitHub App not installed on
    // the repo's org), with a reason and since-when. A lite feed for the
    // repos-settings notice: it rides the persisted snapshot's watch without
    // holding the full open-PR payload or registering fast-cadence interest.
    WatchQuery(
      name: 'pr.watchRepoAccessForWorkspace',
      handler: (ctx) async* {
        final poller = openPrPoller;
        if (poller == null) {
          yield {'inaccessible_repos': <Map<String, dynamic>>[]};
          return;
        }
        yield* poller
            .watchRepoAccessForWorkspace(ctx.workspaceId!)
            .map((list) => {'inaccessible_repos': list});
      },
    ),

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
        final user = await fetchCurrentGitHubUser?.call(ctx.userId);
        final login = (user?['login'] as String?)?.toLowerCase() ?? '';
        if (login.isEmpty) {
          yield {'count': 0};
          return;
        }
        final teams =
            await fetchViewerGitHubTeams?.call(ctx.userId) ?? const {};
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
        final includePatches = ctx.args['include_patches'] != false;
        yield* repo
            .watchFiles(
              (ctx.args['pr_number'] as num).toInt(),
              includePatches: includePatches,
            )
            .map(
              (files) => {
                'files': [
                  for (final f in files)
                    prFileToWire(f, includePatch: includePatches),
                ],
              },
            );
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
        final includeHunks = ctx.args['include_hunks'] != false;
        yield* repo
            .watchReviewComments(
              (ctx.args['pr_number'] as num).toInt(),
              includeHunks: includeHunks,
            )
            .map(
              (comments) => {
                'comments': [
                  for (final c in comments)
                    prCodeReviewCommentToWire(c, includeHunk: includeHunks),
                ],
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
    // Status, display size and who holds control, pushed on every change. The
    // FRAMES do not come through here — video over a JSON-RPC subscription
    // would put base64 in the same lane as every other message. They ride the
    // separate `/rig/stream/<id>` chunked HTTP body.
    if (rigs != null)
      WatchQuery(
        name: 'rig.watchSessions',
        handler: (ctx) => rigs
            .watch(ctx.workspaceId!)
            .map(
              (list) => {
                'rigs': [for (final r in list) rigToWire(r)],
              },
            ),
      ),
    // The panel's data. One stream per rig, pushed on every port that opens,
    // closes or is forwarded — the discovery poll is server-side, so the
    // client never polls the guest.
    if (rigPorts != null)
      WatchQuery(
        name: 'rig.watchPorts',
        handler: (ctx) {
          final rigId = ctx.args['rig_id'];
          if (rigId is! String || rigId.isEmpty) {
            throw const ValidationException(
              'Missing or invalid argument: rig_id',
            );
          }
          return rigPorts.watchPorts(ctx.workspaceId!, rigId);
        },
      ),
    if (rigPorts != null)
      WatchQuery(
        name: 'terminal.watchPorts',
        handler: (ctx) {
          final sessionId = ctx.args['session_id'];
          final spaceId = ctx.args['space_id'];
          if (sessionId is! String || sessionId.isEmpty) {
            throw const ValidationException(
              'Missing or invalid argument: session_id',
            );
          }
          if (spaceId is! String) {
            throw const ValidationException(
              'Missing or invalid argument: space_id',
            );
          }
          return rigPorts.watchTerminalPorts(
            ctx.workspaceId!,
            sessionId,
            spaceId: spaceId,
          );
        },
      ),
    // CROSS-WORKSPACE BY DESIGN: approvals are host-global; the `space_id`
    // field in the snapshot routes each to the right thread. Absent when the
    // host wired no [PendingConfirmationRegistry] (headless cc_server).
    if (pendingConfirmationRegistry != null)
      WatchQuery(
        name: 'confirmation.watchPending',
        workspaceScoped: false,
        // Pending approvals leak the action's command + detail; a subscriber
        // sees only requests from workspaces they belong to.
        //
        // `space_id` is an OPTIONAL narrowing on top of that, not a
        // second authorization check. The phone renders approvals inside one
        // space and used to subscribe host-globally and filter in Dart — so
        // every workspace's destructive-action prompts, command text and all,
        // crossed the wire to a device that would never show them. Omitting
        // the argument keeps the previous host-global behaviour, which is what
        // the desktop's global approval overlay wants.
        handler: (ctx) {
          final spaceId = ctx.args['space_id'] as String?;
          return visibleRows(
            ctx,
            pendingConfirmationRegistry.pending,
            (p) => p.request.workspaceId,
          ).asyncMap(
            (list) async => {
              'pending': [
                for (final p in list)
                  if ((spaceId == null || p.request.spaceId == spaceId) &&
                      await isConfirmationTarget(p, ctx.userId))
                    pendingConfirmationToWire(p),
              ],
            },
          );
        },
      ),
    // Runs parked on a credential. Host-global like the approvals above and
    // filtered the same way: an entry names a provider, an account roster and
    // the sentence the run would have failed with, so a non-member must not
    // see it. `space_id` narrows further for a surface that renders one thread.
    if (credentialBlockRegistry != null)
      WatchQuery(
        name: 'credential_gate.watchBlocked',
        workspaceScoped: false,
        handler: (ctx) {
          final spaceId = ctx.args['space_id'] as String?;
          return visibleRows(
            ctx,
            // Seeded, unlike the approvals stream: a parked run can sit for the
            // whole deadline without the set changing, so a client that
            // connects mid-wait has to be told what is already blocked or it
            // shows an empty screen over a run it could unblock.
            credentialBlockRegistry.blockedWithSnapshot,
            (b) => b.request.workspaceId,
          ).map(
            (list) => {
              'blocked': [
                for (final b in list)
                  if (spaceId == null || b.request.spaceId == spaceId)
                    pendingCredentialBlockToWire(b),
              ],
            },
          );
        },
      ),
    WatchQuery(
      name: 'goals.watchForWorkspace',
      handler: (ctx) => goalRepository
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'goals': list.map(orgGoalToWire).toList()}),
    ),
    WatchQuery(
      name: 'approvals.watchForWorkspace',
      minRole: WorkspaceRole.member,
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
            (list) => {'items': list.map(notificationFeedItemToWire).toList()},
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
    // The CALLER's per-item overrides (mark one read / delete one). A separate
    // subscription rather than a field on the read mark: it is a LIST whose
    // rows change one at a time, and folding it into the single-row mark would
    // re-emit the whole watermark pair on every per-item action.
    WatchQuery(
      name: 'notifications.watchItemStates',
      handler: (ctx) => notificationFeedRepository
          .watchItemStates(ctx.workspaceId!, ctx.userId)
          .map(
            (states) => {
              'states': states.map(notificationItemStateToWire).toList(),
            },
          ),
    ),
    // The conversation's durable supervised goals (`/goal` + `/loop`),
    // backing the client's goal-run list with pause / resume / cancel via
    // the `agentGoalRuns.*` ops.
    agentGoalRunsWatchQuery(agentGoalRunRepository: agentGoalRunRepository),
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

/// The HTTP origin of this server, derived from its advertised RPC URL
/// (`wss://host:9030/rpc` → `https://host:9030`). Empty when the server
/// advertises nothing reachable.
/// Decodes a stored pool into its wire shape, tolerating a corrupt value.
///
/// A pool that will not parse reads as unconfigured rather than failing the
/// op: the editor then shows an empty list the operator can fix, instead of a
/// settings page that refuses to open.
Map<String, dynamic> _decodePool(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const AccountPool().toJson();
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return AccountPool.fromJson(decoded).toJson();
    }
  } on Object {
    // Fall through to the empty pool.
  }
  return const AccountPool().toJson();
}

String _httpOriginFrom(String rpcUrl) {
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
  return Uri(scheme: scheme, host: uri.host, port: uri.port).toString();
}

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

/// Throws unless [providerId] is a built-in or a stored custom provider — the
/// same existence gate `providers.saveGenerationDefaults` applies.
Future<void> _requireKnownProvider(
  ProviderCredentialStore creds,
  String providerId,
) async {
  if (harnessProviderMetas.containsKey(providerId)) {
    return;
  }
  final known = {
    for (final def in await _customProviderDefs(creds)) def.providerId,
  };
  if (!known.contains(providerId)) {
    throw ArgumentError('Unknown provider "$providerId".');
  }
}

/// Accepts a bare model id or the qualified `<providerId>/<modelId>` form and
/// returns the bare id. A qualified id naming a DIFFERENT provider is
/// rejected: silently filing the override under another provider's model is
/// worse than an error.
String _bareModelId(String providerId, String raw) {
  final id = raw.trim();
  if (id.isEmpty) {
    throw ArgumentError('model_id must not be empty.');
  }
  final slash = id.indexOf('/');
  if (slash < 0) {
    return id;
  }
  if (id.substring(0, slash) != providerId) {
    throw ArgumentError(
      'model_id "$id" does not belong to provider "$providerId".',
    );
  }
  final bare = id.substring(slash + 1);
  if (bare.isEmpty) {
    throw ArgumentError('model_id must not be empty.');
  }
  return bare;
}

/// Parses the `providers.saveModelOverride` / `providers.addCustom` model
/// fields into a [ProviderModelOverride], validating ranges and the modality
/// vocabulary. Absent fields stay null/empty ("inherit").
ProviderModelOverride _modelOverrideFromArgs(
  Map<String, dynamic> args, {
  bool manual = false,
}) {
  int? intArg(String key) {
    final raw = args[key];
    if (raw == null) {
      return null;
    }
    if (raw is! num) {
      throw ArgumentError('$key must be a number.');
    }
    final value = raw.toInt();
    if (value <= 0) {
      throw ArgumentError('$key must be positive.');
    }
    return value;
  }

  List<String> modalitiesArg(String key) {
    final raw = args[key];
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw ArgumentError('$key must be a list of modality names.');
    }
    return [
      for (final v in raw)
        if (v is! String || !ProviderModelOverride.knownModalities.contains(v))
          throw ArgumentError(
            '$key entries must be one of '
            '${ProviderModelOverride.knownModalities.join(', ')}.',
          )
        else
          v,
    ];
  }

  return ProviderModelOverride(
    contextWindow: intArg('context_window'),
    maxOutputTokens: intArg('max_output_tokens'),
    inputModalities: modalitiesArg('input_modalities'),
    outputModalities: modalitiesArg('output_modalities'),
    manual: manual || (args['manual'] as bool? ?? false),
  );
}
