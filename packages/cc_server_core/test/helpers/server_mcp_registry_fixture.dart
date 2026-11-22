// The server's MCP registry, built the way the runtime builds it, over the
// test databases: for tests that pin what the server's tools declare.

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:cc_server_core/src/server_mcp_registry.dart';
import 'package:rhttp/rhttp.dart';

/// The server's MCP registry over [global] and [dbs], with [repl] when code
/// mode's tool is registered.
McpToolRegistry buildTestServerMcpRegistry({
  required GlobalDatabase global,
  required WorkspaceDatabaseManager dbs,
  ReplMcpTool? repl,
}) {
  final memoryFactRepository = DaoMemoryFactRepository(dbs);
  final memoryPolicyRepository = DaoMemoryPolicyRepository(dbs);
  final memoryDomainRepository = DaoMemoryDomainRepository(dbs);
  final memoryAccessGrantRepository = DaoMemoryAccessGrantRepository(dbs);
  final agentWorkingMemoryRepository = DaoAgentWorkingMemoryRepository(dbs);
  final memoryConflictRepository = DaoMemoryConflictRepository(dbs);
  final episodicEdgeRepository = DaoEpisodicEdgeRepository(dbs);
  final workingMemoryItemRepository = DaoWorkingMemoryItemRepository(dbs);
  final memoryBeliefRepository = DaoMemoryBeliefRepository(dbs);
  final resolveDomainUseCase = ResolveOrCreateDomainUseCase(
    domainRepository: memoryDomainRepository,
    grantRepository: memoryAccessGrantRepository,
  );
  final recordFactUseCase = RecordMemoryFactUseCase(
    factRepository: memoryFactRepository,
    resolveDomainUseCase: resolveDomainUseCase,
    conflictRepository: memoryConflictRepository,
    edgeRepository: episodicEdgeRepository,
  );
  final extractMemoryUseCase = ExtractMemoryUseCase(
    extractor: const MemoryExtractor(),
    recordFact: recordFactUseCase,
  );
  final consolidationService = MemoryConsolidationService(
    workingMemory: workingMemoryItemRepository,
    recordFact: recordFactUseCase,
  );
  final harmonizeMemoryUseCase = HarmonizeMemoryUseCase(
    factRepository: memoryFactRepository,
    beliefRepository: memoryBeliefRepository,
    conflictRepository: memoryConflictRepository,
  );

  final runLogs = DaoAgentRunLogRepository(dbs);
  return buildServerMcpRegistry(
    replTool: repl,
    globalDb: global,
    workspaceDbs: dbs,
    pipelineTriggerRepository: PipelineTriggerRepositoryImpl(
      dbs,
      global.workspaceRouteDao,
      WebhookSecretVault(InMemorySecretStore()),
    ),
    servedRepos: DaoRepoRepository(dbs),
    codeGraphRepos: (workspaceId, repoId) async => true,
    newsfeedRepository: DaoNewsfeedRepository(
      global.rssDao,
      RssFetcherService(_NullRhttpClient()),
    ),
    newsfeedOwnerUserId: 'owner-user',
    ticketRepository: DaoTicketRepository(dbs, global.workspaceRouteDao),
    messagingRepository: DaoMessagingRepository(dbs),
    hiddenSpacesForCaller:
        ({required workspaceId, required callerConversationId}) async =>
            const <String>{},
    agentQuestions: _SilentQuestions(),
    mediaRenderer: _NoopRenderer(),
    todoRepository: DaoTodoRepository(dbs),
    agentRunLogRepository: runLogs,
    agentRunOutputs: runLogs,
    memoryFactRepository: memoryFactRepository,
    memoryPolicyRepository: memoryPolicyRepository,
    memoryDomainRepository: memoryDomainRepository,
    memoryAccessGrantRepository: memoryAccessGrantRepository,
    agentWorkingMemoryRepository: agentWorkingMemoryRepository,
    resolveDomainUseCase: resolveDomainUseCase,
    promoteFactsUseCase: PromoteFactsToPolicyUseCase(
      factRepository: memoryFactRepository,
      policyRepository: memoryPolicyRepository,
      grantRepository: memoryAccessGrantRepository,
      accessPolicy: const MemoryAccessPolicy(),
    ),
    supersedeFactUseCase: SupersedeFactUseCase(
      factRepository: memoryFactRepository,
    ),
    supersedePolicyUseCase: SupersedePolicyUseCase(
      policyRepository: memoryPolicyRepository,
    ),
    recordFactUseCase: recordFactUseCase,
    memoryConflictRepository: memoryConflictRepository,
    workingMemoryItemRepository: workingMemoryItemRepository,
    extractMemoryUseCase: extractMemoryUseCase,
    consolidationService: consolidationService,
    harmonizeMemoryUseCase: harmonizeMemoryUseCase,
    schemaValidator: const JsonSchemaValidator(),
  );
}

/// Never touches the network: the newsfeed HTTP path is not exercised here, so
/// this client only satisfies the `RssFetcherService` constructor.
class _NullRhttpClient implements RhttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopRenderer implements MediaRenderPort {
  @override
  Future<MediaRenderResult> render(MediaRenderRequest request) =>
      throw UnimplementedError('Registry listing must not render media.');
}

class _SilentQuestions implements AgentQuestionPort {
  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async => null;
}
