import 'package:cc_domain/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_infra/src/git/review_publisher_service.dart';
import 'package:cc_mcp/src/tools/add_review_node_tool.dart';
import 'package:cc_mcp/src/tools/ask_user_question_tool.dart';
import 'package:cc_mcp/src/tools/code_graph_tools.dart';
import 'package:cc_mcp/src/tools/confirm_review_node_tool.dart';
import 'package:cc_mcp/src/tools/consolidate_memory_tool.dart';
import 'package:cc_mcp/src/tools/consult_agent_tool.dart';
import 'package:cc_mcp/src/tools/create_skill_tool.dart';
import 'package:cc_mcp/src/tools/create_workspace_tool.dart';
import 'package:cc_mcp/src/tools/dismiss_review_node_tool.dart';
import 'package:cc_mcp/src/tools/dispatch_reviewers_tool.dart';
import 'package:cc_mcp/src/tools/doctor_tool.dart';
import 'package:cc_mcp/src/tools/finalize_review_tool.dart';
import 'package:cc_mcp/src/tools/fire_agent_tool.dart';
import 'package:cc_mcp/src/tools/get_agent_run_logs_tool.dart';
import 'package:cc_mcp/src/tools/get_channel_messages_tool.dart';
import 'package:cc_mcp/src/tools/get_my_notes_tool.dart';
import 'package:cc_mcp/src/tools/harmonize_memory_tool.dart';
import 'package:cc_mcp/src/tools/hire_agent_tool.dart';
import 'package:cc_mcp/src/tools/kill_agent_tool.dart';
import 'package:cc_mcp/src/tools/list_agents_tool.dart';
import 'package:cc_mcp/src/tools/list_channels_tool.dart';
import 'package:cc_mcp/src/tools/list_memory_conflicts_tool.dart';
import 'package:cc_mcp/src/tools/list_memory_domains_tool.dart';
import 'package:cc_mcp/src/tools/list_policies_tool.dart';
import 'package:cc_mcp/src/tools/list_private_messages_tool.dart';
import 'package:cc_mcp/src/tools/list_pull_requests_tool.dart';
import 'package:cc_mcp/src/tools/list_repos_tool.dart';
import 'package:cc_mcp/src/tools/list_skills_tool.dart';
import 'package:cc_mcp/src/tools/list_workspaces_tool.dart';
import 'package:cc_mcp/src/tools/newsfeed_tools.dart';
import 'package:cc_mcp/src/tools/project_tools.dart';
import 'package:cc_mcp/src/tools/propose_fact_tool.dart';
import 'package:cc_mcp/src/tools/propose_hire_tool.dart';
import 'package:cc_mcp/src/tools/propose_orchestration_tool.dart';
import 'package:cc_mcp/src/tools/propose_policy_tool.dart';
import 'package:cc_mcp/src/tools/publish_review_to_github_tool.dart';
import 'package:cc_mcp/src/tools/read/handlers/agent_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/artifact_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/gh_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/issue_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/local_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/memory_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/pr_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/rule_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/skill_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';
import 'package:cc_mcp/src/tools/read/read_tool.dart';
import 'package:cc_mcp/src/tools/record_observation_tool.dart';
import 'package:cc_mcp/src/tools/remember_tool.dart';
import 'package:cc_mcp/src/tools/request_confirmation_tool.dart';
import 'package:cc_mcp/src/tools/request_peer_review_tool.dart';
import 'package:cc_mcp/src/tools/search_memory_tool.dart';
import 'package:cc_mcp/src/tools/send_channel_message_tool.dart';
import 'package:cc_mcp/src/tools/send_thread_reply_tool.dart';
import 'package:cc_mcp/src/tools/start_ai_review_tool.dart';
import 'package:cc_mcp/src/tools/submit_output_tool.dart';
import 'package:cc_mcp/src/tools/submit_reviewer_verdict_tool.dart';
import 'package:cc_mcp/src/tools/supersede_fact_tool.dart';
import 'package:cc_mcp/src/tools/supersede_policy_tool.dart';
import 'package:cc_mcp/src/tools/ticket_crud_tools.dart';
import 'package:cc_mcp/src/tools/ticket_lifecycle_tools.dart';
import 'package:cc_mcp/src/tools/ticket_link_tools.dart';
import 'package:cc_mcp/src/tools/ticket_orchestration_tools.dart';
import 'package:cc_mcp/src/tools/update_agent_tool.dart';
import 'package:cc_mcp/src/tools/update_my_notes_tool.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/agents/providers/agent_server_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_server_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/pipelines/pipeline_server_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_server_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that assembles and exposes all available MCP tools as a [McpToolRegistry].
final mcpToolRegistryProvider = Provider<McpToolRegistry>((ref) {
  // Stable for the process lifetime so the MCP client service can push bridged
  // external tools into its dynamic layer durably (the registry is mutated in
  // place; recreating it would drop the bridged tools).
  ref.keepAlive();
  // The MCP tool surface is SERVER-SIDE — it is served by the same in-process
  // RPC server `rpcClientProvider` builds, so it must read the Dao-backed
  // (`dao*`) repositories directly, NOT the RPC-flipped public providers. Using
  // the RPC providers here would cycle: registry → Rpc repo → rpcClient → MCP
  // dispatcher → registry. (The workflow/link/project services + pipeline engine
  // are already Dao-backed for the same reason; slice 2 adds agent, repo,
  // run-log, memory, review-channel, and newsfeed to that list; slice 3 adds
  // workspace and messaging.)
  final agentRepo = ref.watch(daoAgentRepositoryProvider);
  final workspaceRepo = ref.watch(daoWorkspaceRepositoryProvider);
  final messagingRepo = ref.watch(daoMessagingRepositoryProvider);
  final prLifecycleRepo = ref.watch(prLifecycleRepositoryProvider);
  final ticketWorkflow = ref.watch(ticketWorkflowServiceProvider);
  final ticketRepo = ref.watch(daoTicketRepositoryProvider);
  final ticketLinkService = ref.watch(ticketLinkServiceProvider);
  final ticketLinkRepo = ref.watch(daoTicketLinkRepositoryProvider);
  final projectService = ref.watch(projectServiceProvider);
  final projectRepo = ref.watch(daoProjectRepositoryProvider);
  final activeTicketProvider = ref.watch(activeTicketProviderProvider);
  final messagingPort = ref.watch(messagingServiceProvider);
  final pipelineEngine = ref.watch(pipelineEngineServerProvider);
  final filesystem = ref.watch(workspaceFilesystemPortProvider);
  final githubApiClient = ref.watch(githubApiClientProvider);
  final repoRepo = ref.watch(daoRepoRepositoryProvider);
  final runLogRepo = ref.watch(daoAgentRunLogRepositoryProvider);
  final processDetection = ref.watch(processDetectionServiceProvider);
  final memoryFactRepo = ref.watch(daoMemoryFactRepositoryProvider);
  final memoryPolicyRepo = ref.watch(daoMemoryPolicyRepositoryProvider);
  final memoryDomainRepo = ref.watch(daoMemoryDomainRepositoryProvider);
  final agentWorkingMemoryRepo = ref.watch(
    daoAgentWorkingMemoryRepositoryProvider,
  );
  final reviewChannelRepo = ref.watch(daoReviewChannelRepositoryProvider);
  final promoteFactsUseCase = ref.watch(promoteFactsToPolicyUseCaseProvider);
  final supersedeFactUseCase = ref.watch(supersedeFactUseCaseProvider);
  final supersedePolicyUseCase = ref.watch(supersedePolicyUseCaseProvider);
  final resolveDomainUseCase = ref.watch(resolveOrCreateDomainUseCaseProvider);
  final recordFactUseCase = ref.watch(recordMemoryFactUseCaseProvider);
  final memoryConflictRepo = ref.watch(daoMemoryConflictRepositoryProvider);
  final workingMemoryItemRepo =
      ref.watch(daoWorkingMemoryItemRepositoryProvider);
  final extractMemoryUseCase = ref.watch(extractMemoryUseCaseProvider);
  final consolidationService = ref.watch(memoryConsolidationServiceProvider);
  final harmonizeMemoryUseCase = ref.watch(harmonizeMemoryUseCaseProvider);
  final newsfeedRepo = ref.watch(daoNewsfeedRepositoryProvider);

  final tools = [
    // Newsfeed (global — not workspace-scoped).
    ListFeedsTool(repository: newsfeedRepo),
    ListArticlesTool(repository: newsfeedRepo),
    GetArticleTool(repository: newsfeedRepo),
    SetArticleReadTool(repository: newsfeedRepo),
    SetArticleSavedTool(repository: newsfeedRepo),
    RefreshFeedsTool(repository: newsfeedRepo),

    CreateTicketTool(service: ticketWorkflow, provider: activeTicketProvider),
    GetTicketTool(repository: ticketRepo),
    ListTicketsTool(repository: ticketRepo),
    UpdateTicketTool(service: ticketWorkflow),
    AssignTicketTool(service: ticketWorkflow),
    ReassignTicketTool(service: ticketWorkflow),
    AddTicketCollaboratorTool(service: ticketWorkflow),
    CommentOnTicketTool(repository: ticketRepo, messagingPort: messagingPort),
    LinkTicketToPrTool(service: ticketWorkflow),
    UnlinkTicketFromPrTool(service: ticketWorkflow),
    CloseTicketTool(service: ticketWorkflow),
    ListAgentsTool(repository: agentRepo),
    HireAgentTool(hireAgent: ref.watch(hireAgentUseCaseProvider)),
    UpdateAgentTool(repository: agentRepo, filesystem: filesystem),
    FireAgentTool(repository: agentRepo),
    KillAgentTool(
      agentRepository: agentRepo,
      killAgentProcessesUseCase: KillAgentProcessesUseCase(
        runLogRepository: runLogRepo,
        processDetection: processDetection,
      ),
    ),
    GetAgentRunLogsTool(repository: runLogRepo),
    ListSkillsTool(filesystem: filesystem),
    CreateSkillTool(filesystem: filesystem),
    ListWorkspacesTool(repository: workspaceRepo),
    CreateWorkspaceTool(repository: workspaceRepo),
    ListPrivateMessagesTool(repository: messagingRepo),
    ListChannelsTool(repository: messagingRepo),
    GetChannelMessagesTool(repository: messagingRepo),

    SendChannelMessageTool(repository: messagingRepo),
    ListPullRequestsTool(prRepo: prLifecycleRepo, workspaceRepo: workspaceRepo),
    ReadTool(
      router: InternalUrlRouter(
        pr: PrProtocolHandler(client: githubApiClient.pr),
        issue: IssueProtocolHandler(client: githubApiClient.pr),
        gh: GhProtocolHandler(client: githubApiClient.content),
        skill: SkillProtocolHandler(filesystem: filesystem),
        rule: RuleProtocolHandler(policies: memoryPolicyRepo),
        local: LocalProtocolHandler(filesystem: filesystem),
        agent: AgentProtocolHandler(runLogs: runLogRepo),
        artifact: ArtifactProtocolHandler(runLogs: runLogRepo),
        memory: MemoryProtocolHandler(
          facts: memoryFactRepo,
          policies: memoryPolicyRepo,
          workingMemory: agentWorkingMemoryRepo,
          filesystem: filesystem,
        ),
      ),
    ),
    StartAiReviewTool(engine: pipelineEngine),
    AddReviewNodeTool(repository: messagingRepo),
    ConfirmReviewNodeTool(repository: messagingRepo),
    DismissReviewNodeTool(
      repository: messagingRepo,
      reviewChannels: reviewChannelRepo,
      memoryFacts: memoryFactRepo,
      resolveDomain: resolveDomainUseCase,
    ),
    DispatchReviewersTool(service: ref.watch(dispatchReviewersServiceProvider)),
    SubmitReviewerVerdictTool(repository: messagingRepo),
    ConsultAgentTool(
      agents: agentRepo,
      messaging: messagingRepo,
      messagingPort: ref.watch(messagingServiceProvider),
    ),
    ProposeHireTool(messaging: messagingRepo),
    RequestPeerReviewTool(messaging: messagingRepo),
    FinalizeReviewTool(
      messaging: messagingRepo,
      reviewChannels: reviewChannelRepo,
    ),
    PublishReviewToGithubTool(
      service: ReviewPublisherService(
        githubPrClient: githubApiClient.pr,
        messaging: messagingRepo,
        reviewChannels: reviewChannelRepo,
      ),
    ),
    SendThreadReplyTool(repository: messagingRepo),
    RecordObservationTool(repository: agentWorkingMemoryRepo),
    SearchMemoryTool(
      factRepository: memoryFactRepo,
      policyRepository: memoryPolicyRepo,
      embeddingService: ref.watch(embeddingServiceProvider),
    ),
    SearchCodeTool(
      repository: ref.watch(codeGraphRepositoryProvider),
      workspaceRepository: workspaceRepo,
      embeddingService: ref.watch(embeddingServiceProvider),
    ),
    CodeSymbolTool(
      repository: ref.watch(codeGraphRepositoryProvider),
      workspaceRepository: workspaceRepo,
    ),
    CodeCallersTool(repository: ref.watch(codeGraphRepositoryProvider)),
    CodeCalleesTool(repository: ref.watch(codeGraphRepositoryProvider)),
    CodeImpactTool(repository: ref.watch(codeGraphRepositoryProvider)),
    ProposeFactTool(recordFact: recordFactUseCase),
    ProposePolicyTool(
      useCase: promoteFactsUseCase,
      resolveDomainUseCase: resolveDomainUseCase,
    ),
    ListPoliciesTool(repository: memoryPolicyRepo),
    // ── Memory intelligence (PRD 04) ──
    RememberTool(
      workingMemory: workingMemoryItemRepo,
      extractMemory: extractMemoryUseCase,
    ),
    ConsolidateMemoryTool(service: consolidationService),
    HarmonizeMemoryTool(useCase: harmonizeMemoryUseCase),
    ListMemoryConflictsTool(repository: memoryConflictRepo),
    ListMemoryDomainsTool(
      domainRepository: memoryDomainRepo,
      factRepository: memoryFactRepo,
      policyRepository: memoryPolicyRepo,
    ),
    SupersedeFactTool(useCase: supersedeFactUseCase),
    SupersedePolicyTool(useCase: supersedePolicyUseCase),
    UpdateMyNotesTool(repository: agentWorkingMemoryRepo),
    GetMyNotesTool(repository: agentWorkingMemoryRepo),
    ListReposTool(repoRepository: repoRepo, workspaceRepository: workspaceRepo),
    ProposeOrchestrationTool(
      orchestrations: ref.watch(daoOrchestrationRepositoryProvider),
      validator: ref.watch(orchestrationProposalValidatorProvider),
      tickets: ticketRepo,
      ticketWorkflow: ticketWorkflow,
      messaging: messagingRepo,
      eventBus: ref.watch(domainEventBusProvider),
    ),
    AskUserQuestionTool(questionPort: ref.watch(agentQuestionServiceProvider)),
    RequestConfirmationTool(
      questionPort: ref.watch(agentQuestionServiceProvider),
    ),
    DoctorTool(doctorPort: ref.watch(doctorServiceProvider)),
    DelegateTicketTool(service: ticketWorkflow),
    FailTicketTool(service: ticketWorkflow),
    SubmitOutputTool(
      runLogRepository: runLogRepo,
      schemaValidator: ref.watch(schemaValidatorProvider),
    ),
    // Dependencies + projects.
    LinkTicketsTool(linkService: ticketLinkService, workflow: ticketWorkflow),
    UnlinkTicketsTool(linkService: ticketLinkService, workflow: ticketWorkflow),
    ListTicketRelationsTool(
      linkRepository: ticketLinkRepo,
      ticketRepository: ticketRepo,
    ),
    CreateProjectTool(service: projectService),
    ListProjectsTool(repository: projectRepo),
    UpdateProjectTool(service: projectService),
    DeleteProjectTool(service: projectService),
    SetTicketProjectTool(
      service: ticketWorkflow,
      projectRepository: projectRepo,
    ),
  ];
  // PRD 01 phase 1.4: gate `tools/list` to the essentials + BM25 search tool
  // once the catalogue (these + any bridged external tools) crosses the
  // threshold, keeping the prompt-cache prefix small and stable. The bridged
  // external tools are pushed into the registry's dynamic layer by
  // `mcpClientServiceProvider`.
  final registry = McpToolRegistry(
    tools,
    discoveryThreshold: ToolIndex.autoThreshold,
    essentialToolNames: defaultEssentialToolNames,
  );
  registry.register(SearchToolBm25(catalog: registry), essential: true);
  return registry;
});
