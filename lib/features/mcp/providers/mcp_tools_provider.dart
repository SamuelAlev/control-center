import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:control_center/features/mcp/application/tools/add_review_node_tool.dart';
import 'package:control_center/features/mcp/application/tools/ask_user_question_tool.dart';
import 'package:control_center/features/mcp/application/tools/code_graph_tools.dart';
import 'package:control_center/features/mcp/application/tools/confirm_review_node_tool.dart';
import 'package:control_center/features/mcp/application/tools/consult_agent_tool.dart';
import 'package:control_center/features/mcp/application/tools/create_skill_tool.dart';
import 'package:control_center/features/mcp/application/tools/create_workspace_tool.dart';
import 'package:control_center/features/mcp/application/tools/dismiss_review_node_tool.dart';
import 'package:control_center/features/mcp/application/tools/dispatch_reviewers_tool.dart';
import 'package:control_center/features/mcp/application/tools/doctor_tool.dart';
import 'package:control_center/features/mcp/application/tools/finalize_review_tool.dart';
import 'package:control_center/features/mcp/application/tools/fire_agent_tool.dart';
import 'package:control_center/features/mcp/application/tools/get_agent_run_logs_tool.dart';
import 'package:control_center/features/mcp/application/tools/get_channel_messages_tool.dart';
import 'package:control_center/features/mcp/application/tools/get_my_notes_tool.dart';
import 'package:control_center/features/mcp/application/tools/hire_agent_tool.dart';
import 'package:control_center/features/mcp/application/tools/kill_agent_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_agents_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_channels_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_memory_domains_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_policies_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_private_messages_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_pull_requests_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_repos_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_skills_tool.dart';
import 'package:control_center/features/mcp/application/tools/list_workspaces_tool.dart';
import 'package:control_center/features/mcp/application/tools/propose_fact_tool.dart';
import 'package:control_center/features/mcp/application/tools/propose_hire_tool.dart';
import 'package:control_center/features/mcp/application/tools/propose_policy_tool.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/agent_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/artifact_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/gh_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/issue_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/local_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/memory_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/pr_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/rule_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/skill_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/application/tools/read/read_tool.dart';
import 'package:control_center/features/mcp/application/tools/record_observation_tool.dart';
import 'package:control_center/features/mcp/application/tools/request_confirmation_tool.dart';
import 'package:control_center/features/mcp/application/tools/request_peer_review_tool.dart';
import 'package:control_center/features/mcp/application/tools/search_memory_tool.dart';
import 'package:control_center/features/mcp/application/tools/send_channel_message_tool.dart';
import 'package:control_center/features/mcp/application/tools/send_thread_reply_tool.dart';
import 'package:control_center/features/mcp/application/tools/start_ai_review_tool.dart';
import 'package:control_center/features/mcp/application/tools/submit_reviewer_verdict_tool.dart';
import 'package:control_center/features/mcp/application/tools/suggest_tasks_tool.dart';
import 'package:control_center/features/mcp/application/tools/supersede_fact_tool.dart';
import 'package:control_center/features/mcp/application/tools/update_agent_tool.dart';
import 'package:control_center/features/mcp/application/tools/update_my_notes_tool.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/ticketing/mcp_tools/approval_tools.dart';
import 'package:control_center/features/ticketing/mcp_tools/project_tools.dart';
import 'package:control_center/features/ticketing/mcp_tools/ticket_crud_tools.dart';
import 'package:control_center/features/ticketing/mcp_tools/ticket_lifecycle_tools.dart';
import 'package:control_center/features/ticketing/mcp_tools/ticket_link_tools.dart';
import 'package:control_center/features/ticketing/mcp_tools/ticket_orchestration_tools.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that assembles and exposes all available MCP tools as a [McpToolRegistry].
final mcpToolRegistryProvider = Provider<McpToolRegistry>((ref) {
  final agentRepo = ref.watch(agentRepositoryProvider);
  final workspaceRepo = ref.watch(workspaceRepositoryProvider);
  final messagingRepo = ref.watch(messagingRepositoryProvider);
  final prLifecycleRepo = ref.watch(prLifecycleRepositoryProvider);
  final ticketWorkflow = ref.watch(ticketWorkflowServiceProvider);
  final ticketRepo = ref.watch(ticketRepositoryProvider);
  final ticketLinkService = ref.watch(ticketLinkServiceProvider);
  final ticketLinkRepo = ref.watch(ticketLinkRepositoryProvider);
  final projectService = ref.watch(projectServiceProvider);
  final projectRepo = ref.watch(projectRepositoryProvider);
  final activeTicketProvider = ref.watch(activeTicketProviderProvider);
  final messagingPort = ref.watch(messagingServiceProvider);
  final pipelineEngine = ref.watch(pipelineEngineProvider);
  final filesystem = ref.watch(workspaceFilesystemPortProvider);
  final githubApiClient = ref.watch(githubApiClientProvider);
  final repoRepo = ref.watch(repoRepositoryProvider);
  final runLogRepo = ref.watch(agentRunLogRepositoryProvider);
  final processDetection = ref.watch(processDetectionServiceProvider);
  final memoryFactRepo = ref.watch(memoryFactRepositoryProvider);
  final memoryPolicyRepo = ref.watch(memoryPolicyRepositoryProvider);
  final memoryDomainRepo = ref.watch(memoryDomainRepositoryProvider);
  final agentWorkingMemoryRepo = ref.watch(agentWorkingMemoryRepositoryProvider);
  final promoteFactsUseCase = ref.watch(promoteFactsToPolicyUseCaseProvider);
  final supersedeFactUseCase = ref.watch(supersedeFactUseCaseProvider);
  final resolveDomainUseCase = ref.watch(resolveOrCreateDomainUseCaseProvider);

  final tools = [

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
    HireAgentTool(repository: agentRepo, filesystem: filesystem),
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
    DismissReviewNodeTool(repository: messagingRepo),
    DispatchReviewersTool(
      service: ref.watch(dispatchReviewersServiceProvider),
    ),
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
      reviewChannels: ref.watch(reviewChannelRepositoryProvider),
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
    ProposeFactTool(
      repository: memoryFactRepo,
      resolveDomainUseCase: resolveDomainUseCase,
    ),
    ProposePolicyTool(
      useCase: promoteFactsUseCase,
      resolveDomainUseCase: resolveDomainUseCase,
    ),
    ListPoliciesTool(repository: memoryPolicyRepo),
    ListMemoryDomainsTool(
      domainRepository: memoryDomainRepo,
      factRepository: memoryFactRepo,
      policyRepository: memoryPolicyRepo,
    ),
    SupersedeFactTool(useCase: supersedeFactUseCase),
    UpdateMyNotesTool(repository: agentWorkingMemoryRepo),
    GetMyNotesTool(repository: agentWorkingMemoryRepo),
    ListReposTool(
      repoRepository: repoRepo,
      workspaceRepository: workspaceRepo,
    ),
    SuggestTasksTool(repository: messagingRepo),
    AskUserQuestionTool(
      questionPort: ref.watch(agentQuestionServiceProvider),
    ),
    RequestConfirmationTool(
      questionPort: ref.watch(agentQuestionServiceProvider),
    ),
    DoctorTool(
      doctorPort: ref.watch(doctorServiceProvider),
    ),
    DelegateTicketTool(service: ticketWorkflow),
    CompleteTicketTool(service: ticketWorkflow),
    FailTicketTool(service: ticketWorkflow),
    ApproveStepTool(service: ticketWorkflow),
    RejectStepTool(service: ticketWorkflow),
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
  return McpToolRegistry(tools);
});
