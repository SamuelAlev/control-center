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
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/newsfeed/rss_fetcher_service.dart';
import 'package:cc_infra/src/util/json_schema_validator.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:cc_server_core/src/server_mcp_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// Proves the headless `cc_server` now serves a REAL MCP tool surface over
/// `tools/list` — it used to mount `NoToolsRpcDispatcher` (method-not-found for
/// every tool call). The same `cc_mcp` tool classes the desktop registers are
/// constructed server-side from the server's own Drift-backed repositories.
void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('server MCP dispatcher lists the data-backed tools', () async {
    final memoryFactRepository = DaoMemoryFactRepository(db.memoryFactDao);
    final memoryPolicyRepository = DaoMemoryPolicyRepository(db.memoryPolicyDao);
    final memoryDomainRepository = DaoMemoryDomainRepository(db.memoryDomainDao);
    final memoryAccessGrantRepository =
        DaoMemoryAccessGrantRepository(db.memoryAccessGrantDao);
    final agentWorkingMemoryRepository =
        DaoAgentWorkingMemoryRepository(db.agentWorkingMemoryDao);
    final memoryConflictRepository =
        DaoMemoryConflictRepository(db.memoryConflictDao);
    final episodicEdgeRepository = DaoEpisodicEdgeRepository(db.episodicEdgeDao);
    final workingMemoryItemRepository = DaoWorkingMemoryItemRepository(
      db.workingMemoryItemDao,
      db.memoryConsolidationLogDao,
    );
    final memoryBeliefRepository = DaoMemoryBeliefRepository(db.memoryBeliefDao);
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
      db: db,
      newsfeedRepository: DaoNewsfeedRepository(
        db.rssDao,
        RssFetcherService(createDio()),
      ),
      ticketRepository: DaoTicketRepository(db.ticketDao),
      messagingRepository: DaoMessagingRepository(db.messagingDao),
      agentRunLogRepository: DaoAgentRunLogRepository(db.agentDao),
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

    expect(tools.length, greaterThanOrEqualTo(14));
    expect(
      names,
      containsAll(<String>[
        'list_workspaces',
        'list_agents',
        'list_repos',
        'list_channels',
        'get_channel_messages',
        'list_tickets',
        'list_articles',
        // The pipeline output contract: server-run agents can now write their
        // structured output so the step resume listener can harvest + advance.
        'submit_output',
      ]),
    );
  });
}
