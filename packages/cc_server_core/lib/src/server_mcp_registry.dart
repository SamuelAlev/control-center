import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
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
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Builds the MCP tool registry the headless `cc_server` exposes over its
/// RPC/MCP endpoint.
///
/// This registers the tools whose dependencies are wholly server-side data
/// (repositories backed by the server's Drift DB). The three pre-built repos
/// (newsfeed / ticket / messaging) are threaded in from `runCcServer`; the rest
/// are constructed here straight from the DAOs. Write/orchestration tools that
/// need stateful services (TicketWorkflowService, the pipeline engine, the
/// dispatch/sandbox stack) are wired in as those services land server-side —
/// the desktop's `mcpToolRegistryProvider` remains the full set for the local
/// MCP HTTP server. Both hosts construct the SAME `cc_mcp` tool classes.
McpToolRegistry buildServerMcpRegistry({
  required AppDatabase db,
  required NewsfeedRepository newsfeedRepository,
  required TicketRepository ticketRepository,
  required MessagingRepository messagingRepository,
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
  // Embedding service (degradable — keyword-only search when absent).
  EmbeddingPort? embeddingService,
  // Schema validator for the pipeline output contract (degradable — when null
  // a schema-bearing payload is accepted unvalidated rather than enforced).
  SchemaValidatorPort? schemaValidator,
}) {
  final workspaceRepository = DaoWorkspaceRepository(db.workspaceDao);
  final agentRepository = DaoAgentRepository(db.agentDao);
  final repoRepository = DaoRepoRepository(db.repoDao);

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
    // Messaging (read).
    ListChannelsTool(repository: messagingRepository),
    GetChannelMessagesTool(repository: messagingRepository),
    ListPrivateMessagesTool(repository: messagingRepository),
    // Workspaces / agents / repos.
    ListWorkspacesTool(repository: workspaceRepository),
    ListAgentsTool(repository: agentRepository),
    ListReposTool(
      repoRepository: repoRepository,
      workspaceRepository: workspaceRepository,
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
    // ── Code graph (semantic code search) ──
    if (codeGraphRepository != null) ...[
      SearchCodeTool(
        repository: codeGraphRepository,
        workspaceRepository: workspaceRepository,
        embeddingService: embeddingService,
      ),
      CodeSymbolTool(
        repository: codeGraphRepository,
        workspaceRepository: workspaceRepository,
      ),
      CodeCallersTool(repository: codeGraphRepository),
      CodeCalleesTool(repository: codeGraphRepository),
      CodeImpactTool(repository: codeGraphRepository),
    ],
  ], discoveryThreshold: ToolIndex.autoThreshold, essentialToolNames: defaultEssentialToolNames);

  // BM25 tool discovery (PRD 01 phase 1.4): once the catalogue (native tools +
  // any bridged external ones) exceeds the threshold, `tools/list` ships only
  // the essential set + this search tool; the rest are found by query and
  // remain callable by name. Always essential so it is never hidden.
  registry.register(SearchToolBm25(catalog: registry), essential: true);
  return registry;
}
