import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_episodic_edge_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_access_grant_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_belief_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_conflict_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_domain_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_fact_repository.dart';
import 'package:cc_persistence/repositories/dao_working_memory_item_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoMemoryFactRepository factRepo;
  late DaoMemoryConflictRepository conflictRepo;
  late DaoEpisodicEdgeRepository edgeRepo;
  late DaoMemoryBeliefRepository beliefRepo;
  late DaoWorkingMemoryItemRepository workingRepo;
  late RecordMemoryFactUseCase record;
  const ws = 'ws';
  const uuid = Uuid();

  setUp(() async {
    db = createTestDatabase();
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: ws, name: 'WS'),
        );
    final edgeDao = db.episodicEdgeDao;
    factRepo = DaoMemoryFactRepository(db.memoryFactDao, edgeDao: edgeDao);
    conflictRepo = DaoMemoryConflictRepository(db.memoryConflictDao);
    edgeRepo = DaoEpisodicEdgeRepository(edgeDao);
    beliefRepo = DaoMemoryBeliefRepository(db.memoryBeliefDao);
    workingRepo = DaoWorkingMemoryItemRepository(
      db.workingMemoryItemDao,
      db.memoryConsolidationLogDao,
    );
    final resolveDomain = ResolveOrCreateDomainUseCase(
      domainRepository: DaoMemoryDomainRepository(db.memoryDomainDao),
      grantRepository: DaoMemoryAccessGrantRepository(db.memoryAccessGrantDao),
    );
    record = RecordMemoryFactUseCase(
      factRepository: factRepo,
      resolveDomainUseCase: resolveDomain,
      conflictRepository: conflictRepo,
      edgeRepository: edgeRepo,
    );
  });

  tearDown(() async => db.close());

  test('AC: contradictory fact is detected and the old one superseded', () async {
    final prod = await record.record(
      workspaceId: ws,
      domain: 'deployment',
      topic: 'deploy target',
      content: 'the deploy target is prod',
    );
    final staging = await record.record(
      workspaceId: ws,
      domain: 'deployment',
      topic: 'deploy target',
      content: 'the deploy target is staging',
    );

    expect(staging!.outcome, RecordOutcome.created);
    expect(staging.conflictsDetected, 1);

    final active = await factRepo.getActiveByWorkspace(ws);
    expect(active.map((f) => f.content), ['the deploy target is staging']);

    final superseded = await factRepo.getById(ws, prod!.fact.id);
    expect(superseded!.supersededBy, staging.fact.id);

    final conflicts = await conflictRepo.getByWorkspace(ws);
    expect(conflicts, hasLength(1));
    expect(conflicts.single.winningFactId, staging.fact.id);
  });

  test('re-mention deduplicates and bumps confidence + mentionCount', () async {
    final first = await record.record(
      workspaceId: ws,
      domain: 'arch',
      topic: 'cache',
      content: 'we use redis for caching',
      confidence: 0.6,
      veracity: MemoryVeracity.tool,
    );
    final second = await record.record(
      workspaceId: ws,
      domain: 'arch',
      topic: 'cache',
      content: 'we use redis for caching',
      veracity: MemoryVeracity.stated,
    );

    expect(second!.outcome, RecordOutcome.deduplicated);
    expect(second.fact.id, first!.fact.id);
    expect(second.fact.mentionCount, 2);
    expect(second.fact.confidence, greaterThan(0.6));
    final active = await factRepo.getActiveByWorkspace(ws);
    expect(active, hasLength(1));
  });

  test('records auto-classify their memory type from content', () async {
    final decision = await record.record(
      workspaceId: ws,
      domain: 'arch',
      topic: 'orm',
      content: 'we decided to adopt Drift for persistence',
    );
    expect(decision!.fact.memoryType, MemoryType.decision);
  });

  test('AC: 4-voice recall surfaces graph-connected, time-relevant facts',
      () async {
    // Two facts sharing the "Auth Service" entity → linked on ingest.
    final f1 = await record.record(
      workspaceId: ws,
      domain: 'auth',
      topic: 'auth tokens',
      content: 'Auth Service validates JWT tokens',
    );
    final f2 = await record.record(
      workspaceId: ws,
      domain: 'auth',
      topic: 'auth deploy',
      content: 'Auth Service deployment runs on Fridays',
    );
    // An unrelated, recent fact that does not match the query and shares nothing.
    await record.record(
      workspaceId: ws,
      domain: 'misc',
      topic: 'weather',
      content: 'the office plants need watering twice weekly',
    );

    // An episodic edge was proactively created between the two Auth facts.
    final edges = await edgeRepo.getByWorkspace(ws);
    expect(edges, isNotEmpty);
    expect(
      edges.any((e) =>
          {e.sourceFactId, e.targetFactId}.containsAll({f1!.fact.id, f2!.fact.id})),
      isTrue,
    );

    // Query matches f1 lexically; f2 is pulled in by the graph voice (shared
    // entity edge) even though it lacks the query terms.
    final results = await factRepo.recallPolyphonic(ws, 'JWT validates');
    final ids = results.map((f) => f.id).toList();
    expect(ids, contains(f1!.fact.id));
    expect(ids, contains(f2!.fact.id),
        reason: 'graph-connected fact should be recalled');
  });

  test('AC: extraction yields facts from conversation without propose_fact',
      () async {
    final extract = ExtractMemoryUseCase(
      extractor: const MemoryExtractor(),
      recordFact: record,
    );
    final count = await extract.extractAndRecord(
      workspaceId: ws,
      text: 'my name is Sam and I work at Frontify. I prefer dark mode.',
    );
    expect(count, greaterThan(0));

    final active = await factRepo.getActiveByWorkspace(ws);
    final contents = active.map((f) => f.content.toLowerCase()).join(' | ');
    expect(contents, contains('sam'));
    expect(active.any((f) => f.memoryType == MemoryType.preference), isTrue);
  });

  test('AC: SHMR flags a cross-agent contradiction', () async {
    // Same topic, DIFFERENT domains → no write-time conflict (that scopes to
    // domain+topic), but SHMR clusters them by content and flags the clash.
    await record.record(
      workspaceId: ws,
      domain: 'backend',
      topic: 'primary database',
      content: 'the primary database is postgres',
      authoredByAgentId: 'agent-1',
    );
    await record.record(
      workspaceId: ws,
      domain: 'data',
      topic: 'primary database',
      content: 'the primary database is mysql',
      authoredByAgentId: 'agent-2',
    );

    final harmonize = HarmonizeMemoryUseCase(
      factRepository: factRepo,
      beliefRepository: beliefRepo,
      conflictRepository: conflictRepo,
    );
    final summary = await harmonize.harmonize(ws);
    expect(summary.contradictionsFlagged, greaterThanOrEqualTo(1));

    final conflicts = await conflictRepo.getByWorkspace(ws);
    expect(conflicts.any((c) => c.conflictType == 'cross_agent'), isTrue);
  });

  test('SHMR emits a corroborated belief from two agreeing agents', () async {
    await record.record(
      workspaceId: ws,
      domain: 'backend',
      topic: 'api base',
      content: 'the api base url is https://api.example.com',
      authoredByAgentId: 'agent-1',
    );
    await record.record(
      workspaceId: ws,
      domain: 'frontend',
      topic: 'api base',
      content: 'the api base url is https://api.example.com',
      authoredByAgentId: 'agent-2',
    );
    final harmonize = HarmonizeMemoryUseCase(
      factRepository: factRepo,
      beliefRepository: beliefRepo,
      conflictRepository: conflictRepo,
    );
    await harmonize.harmonize(ws);

    final beliefs = await beliefRepo.getByWorkspace(ws);
    expect(beliefs, isNotEmpty);
    expect(beliefs.first.provenanceAgentIds, containsAll(['agent-1', 'agent-2']));
  });

  test('consolidation rolls working items into durable facts and evicts', () async {
    final now = DateTime.now();
    // A consolidatable item + an expired one.
    await workingRepo.add(
      WorkingMemoryItem(
        id: uuid.v4(),
        workspaceId: ws,
        agentId: 'agent-1',
        content: 'learned that the deploy script needs sudo',
        memoryType: MemoryType.learning,
        createdAt: now,
      ),
    );
    await workingRepo.add(
      WorkingMemoryItem(
        id: uuid.v4(),
        workspaceId: ws,
        agentId: 'agent-1',
        content: 'transient note that should expire',
        memoryType: MemoryType.context,
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      ),
    );

    final service = MemoryConsolidationService(
      workingMemory: workingRepo,
      recordFact: record,
    );
    final report = await service.sleep(workspaceId: ws, agentId: 'agent-1');

    expect(report.factsCreated, greaterThanOrEqualTo(1));
    expect(report.evicted, greaterThanOrEqualTo(1));

    final remaining = await workingRepo.getForAgent(ws, 'agent-1');
    expect(remaining, isEmpty);

    final facts = await factRepo.getActiveByWorkspace(ws);
    expect(facts.any((f) => f.content.contains('sudo')), isTrue);
  });
}
