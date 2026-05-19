import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
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
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Proves the headless `cc_server` now serves a REAL MCP tool surface over
/// `tools/list` — it used to mount `NoToolsRpcDispatcher` (method-not-found for
/// every tool call). The same `cc_mcp` tool classes the desktop registers are
/// constructed server-side from the server's own Drift-backed repositories.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('server MCP dispatcher lists the data-backed tools', () async {
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

    final registry = buildServerMcpRegistry(
      globalDb: global,
      workspaceDbs: dbs,
      newsfeedRepository: DaoNewsfeedRepository(
        global.rssDao,
        RssFetcherService(createDio()),
      ),
      newsfeedOwnerUserId: 'owner-user',
      ticketRepository: DaoTicketRepository(dbs, global.workspaceRouteDao),
      messagingRepository: DaoMessagingRepository(dbs),
      todoRepository: DaoTodoRepository(dbs),
      agentRunLogRepository: DaoAgentRunLogRepository(dbs),
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
    final dispatcher = McpToolDispatcher(registry: registry);

    final response = await dispatcher.handleRequest(
      JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
    );

    final tools = (response['result'] as Map<String, dynamic>)['tools'] as List;
    final names = {for (final t in tools) (t as Map<String, dynamic>)['name']};

    // `tools/list` advertises the FULL catalogue. Discovery gating (essential
    // subset + hidden-but-callable lookup) was removed: external MCP clients
    // (pi's mcp-adapter, Claude Code) validate calls against their cached
    // tools/list CLIENT-side, so every hidden tool — all agent writes included
    // (`todo_write`, `ticket_cli`, `propose_fact`, …) — was unreachable in
    // practice. The BM25 search tool remains as a catalogue navigation aid.
    expect(tools.length, greaterThanOrEqualTo(40));
    expect(names, contains('search_tool_bm25'));
    expect(
      names,
      containsAll(<String>[
        'list_workspaces',
        'list_agents',
        'list_channels',
        'get_channel_messages',
        // Long instructed by prompts/mode-guard but historically never
        // registered server-side — now real.
        'send_channel_message',
        'list_tickets',
        'get_ticket',
        // The per-conversation checklist agents plan with.
        'todo_write',
        // The pipeline output contract: server-run agents can now write their
        // structured output so the step resume listener can harvest + advance.
        'submit_output',
        // The write surface the old gating hid from every external client —
        // memory, governance, work products.
        'propose_fact',
        'propose_policy',
        'record_observation',
        'create_goal',
        'create_approval',
        'create_work_product',
        'list_repos',
        'list_articles',
        'list_goals',
        'agent_heartbeat',
        'get_org_chart',
      ]),
    );

    // The advertised list and the callable set are the SAME set: everything
    // listed resolves and the catalogue view matches the list.
    for (final name in names) {
      expect(
        registry.lookup(name as String),
        isNotNull,
        reason: '$name listed but not resolvable',
      );
    }
    expect(
      registry.allToolDefinitions().map((d) => d.name).toSet(),
      names,
      reason: 'BM25 catalogue must mirror tools/list exactly',
    );
  });
}
