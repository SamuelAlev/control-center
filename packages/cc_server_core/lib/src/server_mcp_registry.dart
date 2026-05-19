import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/services/goal_progress_service.dart';
import 'package:cc_domain/features/governance/domain/services/heartbeat_monitor_service.dart';
import 'package:cc_domain/features/governance/domain/services/org_chart_service.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:cc_domain/features/messaging/domain/ports/channel_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/channel_extras_dao.dart';
import 'package:cc_persistence/repositories/team_activity_repository_impl.dart';
import 'package:uuid/uuid.dart';

/// Builds the MCP tool registry the headless `cc_server` exposes over its
/// RPC/MCP endpoint. This is the ONLY tool registry — the desktop's
/// in-process MCP stack was deleted with the thin-client migration; every
/// client reaches these tools through `cc_server`.
///
/// This registers the tools whose dependencies are wholly server-side data
/// (repositories backed by the server's Drift DB). The three pre-built repos
/// (newsfeed / ticket / messaging) are threaded in from `runCcServer`; the rest
/// are constructed here straight from the DAOs. Write/orchestration tools that
/// need stateful services (TicketWorkflowService, the pipeline engine, the
/// dispatch/sandbox stack) are wired in as those services land server-side.
///
/// The full catalogue is advertised in `tools/list` — no discovery gating.
/// External MCP clients (pi, Claude Code) refuse to call tools absent from
/// their cached `tools/list`, so an "essential subset + hidden-but-callable"
/// list makes every hidden tool unreachable in practice (this broke all agent
/// writes: `todo_write`, `propose_fact`, …). `search_tool_bm25` and
/// `list_my_tools` stay registered as navigation aids over the large catalogue;
/// both take the optional [modeGuard] so they can report which tools are
/// callable in the caller's conversation mode.
McpToolRegistry buildServerMcpRegistry({
  // The two halves of the schema: `globalDb` for the workspace registry and the
  // pre-auth route index, `workspaceDbs` for everything workspace-scoped (each
  // repository resolves `of(workspaceId)` per call).
  required GlobalDatabase globalDb,
  required WorkspaceDatabaseManager workspaceDbs,
  required NewsfeedRepository newsfeedRepository,
  required TicketRepository ticketRepository,
  required MessagingRepository messagingRepository,
  // Per-conversation todo lists — the [TodoWriteTool]'s persistence backend.
  required TodoRepository todoRepository,
  // Pipeline structured-output contract: [SubmitOutputTool] resolves the
  // calling agent's active run and writes its `outputJson`.
  required AgentRunLogRepository agentRunLogRepository,
  // Memory cluster (read + write). These repos + use cases must be
  // constructed in [runCcServer] and passed here — the DAOs alone aren't
  // enough (the use cases enforce access grants + deduplication logic).
  required MemoryFactRepository memoryFactRepository,
  required MemoryPolicyRepository memoryPolicyRepository,
  required MemoryDomainRepository memoryDomainRepository,
  required MemoryAccessGrantRepository memoryAccessGrantRepository,
  required AgentWorkingMemoryRepository agentWorkingMemoryRepository,
  required ResolveOrCreateDomainUseCase resolveDomainUseCase,
  required PromoteFactsToPolicyUseCase promoteFactsUseCase,
  required SupersedeFactUseCase supersedeFactUseCase,
  required SupersedePolicyUseCase supersedePolicyUseCase,
  // PRD 04 memory intelligence: shared writer (conflict-aware) + the hot tier /
  // consolidation / harmonization / conflict surfaces.
  required RecordMemoryFactUseCase recordFactUseCase,
  required MemoryConflictRepository memoryConflictRepository,
  required WorkingMemoryItemRepository workingMemoryItemRepository,
  required ExtractMemoryUseCase extractMemoryUseCase,
  required MemoryConsolidationService consolidationService,
  required HarmonizeMemoryUseCase harmonizeMemoryUseCase,
  // Code graph (semantic search over indexed repo symbols).
  CodeGraphRepository? codeGraphRepository,
  // Verifies indexed paths against the caller's working copy (degradable — the
  // code-graph tools serve unverified results when absent, exactly as before).
  CodeGraphTreePort? codeGraphTree,
  // Embedding service (degradable — keyword-only search when absent).
  EmbeddingPort? embeddingService,
  // Schema validator for the pipeline output contract (degradable — when null
  // a schema-bearing payload is accepted unvalidated rather than enforced).
  SchemaValidatorPort? schemaValidator,
  // Per-conversation mode guard. Passed so the discovery tools
  // (`search_tool_bm25`, `list_my_tools`) can report which tools are callable
  // in the caller's conversation mode. Null → the tools report everything as
  // callable. The dispatcher enforces the same guard independently.
  ModeToolGuard? modeGuard,
  // The domain event bus, for tools whose result other features react to
  // (`publish_artifact` → `ArtifactPublished`). Degradable: without a bus the
  // artifact still persists and still posts its channel message, it just does
  // not notify.
  DomainEventBus? eventBus,
}) {
  final workspaceRepository = DaoWorkspaceRepository(
    globalDb.workspaceRegistryDao,
    workspaceDbs,
  );
  final agentRepository = DaoAgentRepository(workspaceDbs);
  final repoRepository = DaoRepoRepository(workspaceDbs);

  // ── Governance (PRD 09) ── repositories + services over the per-workspace
  // databases.
  final goalRepository = DaoGoalRepository(workspaceDbs);
  final approvalRepository = DaoApprovalRepository(workspaceDbs);
  final workProductRepository = DaoWorkProductRepository(workspaceDbs);
  final runtimeStateRepository = DaoAgentRuntimeStateRepository(workspaceDbs);
  final runtimeProfileRepository = DaoRuntimeProfileRepository(workspaceDbs);
  final goalProgressService = GoalProgressService(repository: goalRepository);
  final approvalWorkflowService = ApprovalWorkflowService(
    repository: approvalRepository,
  );
  final workProductService = WorkProductService(
    repository: workProductRepository,
  );
  final heartbeatMonitorService = HeartbeatMonitorService(
    repository: runtimeStateRepository,
  );
  final orgChartService = OrgChartService(agentRepository: agentRepository);
  final agentPresenceService = AgentPresenceService(
    agentRepository: agentRepository,
    runtimeStateRepository: runtimeStateRepository,
    runLogRepository: agentRunLogRepository,
    ticketRepository: ticketRepository,
  );

  // ── Teams + pipeline triggers (PRD 10) ──
  final teamActivityRepository = TeamActivityRepositoryImpl(workspaceDbs);
  final pipelineTriggerRepository = PipelineTriggerRepositoryImpl(
    workspaceDbs,
    globalDb.workspaceRouteDao,
  );
  final pipelineTemplateRepository = PipelineTemplateRepositoryImpl(
    workspaceDbs,
    validator: PipelineValidator(schemaValidator: schemaValidator),
  );

  final registry = McpToolRegistry([
    // Newsfeed (global; RSS fetched + persisted server-side).
    ListFeedsTool(repository: newsfeedRepository),
    ListArticlesTool(repository: newsfeedRepository),
    GetArticleTool(repository: newsfeedRepository),
    SetArticleReadTool(repository: newsfeedRepository),
    SetArticleSavedTool(repository: newsfeedRepository),
    RefreshFeedsTool(repository: newsfeedRepository),
    // Tickets (read).
    GetTicketTool(repository: ticketRepository),
    ListTicketsTool(repository: ticketRepository),
    // ── Teams + pipeline triggers (PRD 10) ──
    RecordTeamActivityTool(
      ticketRepository: ticketRepository,
      activityRepository: teamActivityRepository,
    ),
    PreviewTriggerTool(
      triggerRepository: pipelineTriggerRepository,
      templateRepository: pipelineTemplateRepository,
    ),
    // Ticket WRITE tools (create/update/assign/comment/close/link/…) are typed
    // MCP tools registered post-construction in `cc_server_runtime` — they need
    // the workflow + link + messaging services, which are built after this
    // DB-only registry. The legacy `ticket_cli` (CLI-args-in-JSON) surface was
    // removed in favour of them.
    // Messaging (read + write). `send_channel_message` was long referenced by
    // the mode-guard allow-lists and the review-mode prompt but never
    // registered — agents were instructed to call a tool that did not exist.
    ListChannelsTool(repository: messagingRepository),
    GetChannelMessagesTool(repository: messagingRepository),
    SendChannelMessageTool(repository: messagingRepository),
    // Channel notes (PRD 16 §11): the shared handoff doc agents read/write.
    GetChannelNotesTool(
      notesPort: _DaoChannelNotesPort(workspaceDbs),
      messagingRepository: messagingRepository,
    ),
    UpdateChannelNotesTool(
      notesPort: _DaoChannelNotesPort(workspaceDbs),
      messagingRepository: messagingRepository,
    ),
    TodoWriteTool(
      todoRepository: todoRepository,
      messagingRepository: messagingRepository,
    ),
    // Workspaces / agents / repos.
    ListWorkspacesTool(repository: workspaceRepository),
    ListAgentsTool(repository: agentRepository),
    // Conversation-aware: agent callers get their conversation's isolated
    // CoW worktree paths, never the original checkouts.
    ListReposTool(
      repoRepository: repoRepository,
      isolatedRepoRepository: DaoIsolatedRepoRepository(workspaceDbs),
    ),
    // ── Memory (read + write) ──
    ListMemoryDomainsTool(
      domainRepository: memoryDomainRepository,
      factRepository: memoryFactRepository,
      policyRepository: memoryPolicyRepository,
    ),
    SearchMemoryTool(
      factRepository: memoryFactRepository,
      policyRepository: memoryPolicyRepository,
      embeddingService: embeddingService,
    ),
    ProposeFactTool(recordFact: recordFactUseCase),
    ProposePolicyTool(
      useCase: promoteFactsUseCase,
      resolveDomainUseCase: resolveDomainUseCase,
    ),
    ListPoliciesTool(repository: memoryPolicyRepository),
    SupersedeFactTool(useCase: supersedeFactUseCase),
    SupersedePolicyTool(useCase: supersedePolicyUseCase),
    RecordObservationTool(repository: agentWorkingMemoryRepository),
    GetMyNotesTool(repository: agentWorkingMemoryRepository),
    UpdateMyNotesTool(repository: agentWorkingMemoryRepository),
    // ── Memory intelligence (PRD 04) ──
    RememberTool(
      workingMemory: workingMemoryItemRepository,
      extractMemory: extractMemoryUseCase,
    ),
    ConsolidateMemoryTool(service: consolidationService),
    HarmonizeMemoryTool(useCase: harmonizeMemoryUseCase),
    ListMemoryConflictsTool(repository: memoryConflictRepository),
    // ── Pipeline structured output ──
    // submit_output writes the run's `outputJson`, which the pipeline step
    // resume listener harvests to advance an agent-dispatching step. Without
    // it, a schema-bearing step fails harvest ('no structured output payload')
    // and a schemaless one falls back to the agent's last chat message.
    SubmitOutputTool(
      runLogRepository: agentRunLogRepository,
      schemaValidator: schemaValidator,
    ),
    // ── Governance (PRD 09) ──
    CreateGoalTool(service: goalProgressService),
    ListGoalsTool(repository: goalRepository),
    UpdateGoalProgressTool(service: goalProgressService),
    CreateApprovalTool(service: approvalWorkflowService),
    ListApprovalsTool(repository: approvalRepository),
    DecideApprovalTool(service: approvalWorkflowService),
    CommentApprovalTool(service: approvalWorkflowService),
    // The hard plan-exit gate: opens (and, once approved, consumes) a
    // `plan_exit` approval, flipping the conversation out of plan mode.
    ExitPlanModeTool(
      runLogRepository: agentRunLogRepository,
      approvalWorkflow: approvalWorkflowService,
      approvalRepository: approvalRepository,
      messagingRepository: messagingRepository,
    ),
    AgentHeartbeatTool(service: heartbeatMonitorService),
    ListRuntimeHealthTool(repository: runtimeStateRepository),
    ListAgentPresenceTool(service: agentPresenceService),
    GetOrgChartTool(service: orgChartService),
    CreateWorkProductTool(service: workProductService),
    SaveWorkProductRevisionTool(service: workProductService),
    ListWorkProductsTool(repository: workProductRepository),
    GetWorkProductTool(repository: workProductRepository),
    // ── Artifacts: typed block documents, publishable in EVERY mode ──
    // Same storage as the work products above (`content` holds the
    // `blocks@1` JSON envelope, so revision history + restore come free), plus
    // the two things a work product lacked: a typed `artifact` channel message
    // so the document is visible from the room it was authored in, and a
    // block schema the client renders natively instead of as prose.
    PublishArtifactTool(
      runLogRepository: agentRunLogRepository,
      workProducts: workProductService,
      messaging: messagingRepository,
      eventBus: eventBus,
    ),
    ReviseArtifactTool(
      runLogRepository: agentRunLogRepository,
      workProducts: workProductService,
      repository: workProductRepository,
      eventBus: eventBus,
    ),
    ListArtifactsTool(repository: workProductRepository),
    GetArtifactTool(repository: workProductRepository),
    CreateRuntimeProfileTool(repository: runtimeProfileRepository),
    ListRuntimeProfilesTool(repository: runtimeProfileRepository),
    // ── Code graph (semantic code search) ──
    if (codeGraphRepository != null) ...[
      SearchCodeTool(
        repository: codeGraphRepository,
        workspaceRepository: workspaceRepository,
        embeddingService: embeddingService,
        tree: codeGraphTree,
      ),
      CodeSymbolTool(
        repository: codeGraphRepository,
        workspaceRepository: workspaceRepository,
        tree: codeGraphTree,
      ),
      CodeCallersTool(repository: codeGraphRepository, tree: codeGraphTree),
      CodeCalleesTool(repository: codeGraphRepository, tree: codeGraphTree),
      CodeImpactTool(repository: codeGraphRepository, tree: codeGraphTree),
    ],
  ]);

  // Discovery aids over the (large, fully listed) catalogue. Both take the
  // mode guard so they can tell the agent which tools are callable *right now*
  // in its conversation mode — the fix for "search says it exists, the call
  // then fails". `search_tool_bm25` finds by intent; `list_my_tools` is the
  // authoritative "what can I call" view.
  registry
    ..register(SearchToolBm25(catalog: registry, modeGuard: modeGuard))
    ..register(ListMyToolsTool(catalog: registry, modeGuard: modeGuard));
  return registry;
}

/// DAO-backed [ChannelNotesPort] — adapts [ChannelExtrasDao] to the domain
/// port so MCP tools can read/write the shared channel notes doc without
/// reaching into cc_persistence.
class _DaoChannelNotesPort implements ChannelNotesPort {
  _DaoChannelNotesPort(this._dbs);
  final WorkspaceDatabaseManager _dbs;

  ChannelExtrasDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).channelExtrasDao;

  @override
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})?>
  getNote(String workspaceId, String channelId) async {
    final row = await _dao(workspaceId).noteForChannel(workspaceId, channelId);
    if (row == null) {
      return null;
    }
    return (
      contentMarkdown: row.contentMarkdown,
      updatedBy: row.updatedByPrincipal,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})>
  upsertNote({
    required String workspaceId,
    required String channelId,
    required String contentMarkdown,
    required String updatedBy,
  }) async {
    final row = await _dao(workspaceId).upsertNote(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      channelId: channelId,
      contentMarkdown: contentMarkdown,
      updatedByPrincipal: updatedBy,
    );
    return (
      contentMarkdown: row.contentMarkdown,
      updatedBy: row.updatedByPrincipal,
      updatedAt: row.updatedAt,
    );
  }

  static const _uuid = Uuid();
}
