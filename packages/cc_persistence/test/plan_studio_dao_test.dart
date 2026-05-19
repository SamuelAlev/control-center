import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Plan Studio persistence (PRD 17): the append-only orchestration revision
/// timeline (§5), single-agent plan-mode documents (§8), and reusable
/// playbooks (§10). Every read is workspace-scoped — the CLAUDE.md
/// invariant: a query for one workspace must never surface another's rows.
///
/// Post-split each workspace is its own database file, so the repositories hold
/// a [WorkspaceDatabaseManager] and the "ws2 cannot see ws1's row" assertions
/// now prove the repository ROUTES on `workspaceId` rather than filtering on it.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoOrchestrationRevisionRepository revisionRepo;
  late DaoPlanDocumentRepository planDocRepo;
  late DaoPlaybookRepository playbookRepo;

  OrchestrationProposal buildProposal({String goal = 'Ship the thing'}) =>
      OrchestrationProposal(
        goal: goal,
        roles: const [],
        subTickets: const [],
        synthesis: const SynthesisSpec(
          roleKey: 'lead',
          prompt: 'Wrap up',
          outputSchema: {},
        ),
      );

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
    revisionRepo = DaoOrchestrationRevisionRepository(dbs);
    planDocRepo = DaoPlanDocumentRepository(dbs);
    playbookRepo = DaoPlaybookRepository(dbs);

    for (final (id, ws) in [('orch1', 'ws1'), ('orch2', 'ws2')]) {
      final db = dbs.of(ws);
      await db
          .into(db.orchestrationsTable)
          .insert(
            OrchestrationsTableCompanion.insert(
              id: id,
              workspaceId: ws,
              proposalJson: buildProposal().toJsonString(),
            ),
          );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('orchestration revisions', () {
    test('record + forOrchestration round-trip, oldest first', () async {
      await revisionRepo.record(
        OrchestrationRevision(
          id: 'r1',
          workspaceId: 'ws1',
          orchestrationId: 'orch1',
          revision: 1,
          proposal: buildProposal(goal: 'v1'),
          authoredBy: 'user:u1',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await revisionRepo.record(
        OrchestrationRevision(
          id: 'r2',
          workspaceId: 'ws1',
          orchestrationId: 'orch1',
          revision: 2,
          proposal: buildProposal(goal: 'v2'),
          authoredBy: 'agent:a1',
          authorKind: 'agent',
          createdAt: DateTime(2026, 1, 2),
        ),
      );

      final revisions = await revisionRepo.forOrchestration('ws1', 'orch1');
      expect(revisions.map((r) => r.revision).toList(), [1, 2]);
      expect(revisions[0].proposal.goal, 'v1');
      expect(revisions[1].authorKind, 'agent');
    });

    test('byRevision returns one snapshot, or null', () async {
      await revisionRepo.record(
        OrchestrationRevision(
          id: 'r1',
          workspaceId: 'ws1',
          orchestrationId: 'orch1',
          revision: 1,
          proposal: buildProposal(),
          authoredBy: 'user:u1',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final rev = await revisionRepo.byRevision('ws1', 'orch1', 1);
      expect(rev, isNotNull);
      expect(rev!.id, 'r1');
      expect(await revisionRepo.byRevision('ws1', 'orch1', 2), isNull);
    });

    test(
      'recording the same (orchestrationId, revision) twice keeps the first',
      () async {
        await revisionRepo.record(
          OrchestrationRevision(
            id: 'r1',
            workspaceId: 'ws1',
            orchestrationId: 'orch1',
            revision: 1,
            proposal: buildProposal(goal: 'first'),
            authoredBy: 'user:u1',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await revisionRepo.record(
          OrchestrationRevision(
            id: 'r1-dup',
            workspaceId: 'ws1',
            orchestrationId: 'orch1',
            revision: 1,
            proposal: buildProposal(goal: 'second'),
            authoredBy: 'user:u2',
            createdAt: DateTime(2026, 1, 2),
          ),
        );
        final revisions = await revisionRepo.forOrchestration('ws1', 'orch1');
        expect(revisions, hasLength(1));
        expect(revisions.single.id, 'r1');
        expect(revisions.single.proposal.goal, 'first');
      },
    );

    test('watchForOrchestration streams the live revision list', () async {
      await revisionRepo.record(
        OrchestrationRevision(
          id: 'r1',
          workspaceId: 'ws1',
          orchestrationId: 'orch1',
          revision: 1,
          proposal: buildProposal(),
          authoredBy: 'user:u1',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final rows = await revisionRepo
          .watchForOrchestration('ws1', 'orch1')
          .first;
      expect(rows, hasLength(1));
      expect(rows.single.id, 'r1');
    });

    group('workspace isolation', () {
      test('forOrchestration/byRevision never see another workspace', () async {
        await revisionRepo.record(
          OrchestrationRevision(
            id: 'r1',
            workspaceId: 'ws1',
            orchestrationId: 'orch1',
            revision: 1,
            proposal: buildProposal(),
            authoredBy: 'user:u1',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        expect(await revisionRepo.forOrchestration('ws2', 'orch1'), isEmpty);
        expect(await revisionRepo.byRevision('ws2', 'orch1', 1), isNull);
      });
    });
  });

  group('plan documents', () {
    PlanDocument buildDoc({
      required String id,
      required String workspaceId,
      String conversationId = 'conv1',
      String goal = 'Do the thing',
      PlanDocumentStatus status = PlanDocumentStatus.proposed,
      int revision = 1,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) => PlanDocument(
      id: id,
      workspaceId: workspaceId,
      conversationId: conversationId,
      agentId: 'agent1',
      goal: goal,
      graph: const PlanGraph(nodes: []),
      status: status,
      revision: revision,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

    test('upsert + getById round-trip', () async {
      await planDocRepo.upsert(buildDoc(id: 'p1', workspaceId: 'ws1'));
      final doc = await planDocRepo.getById('ws1', 'p1');
      expect(doc, isNotNull);
      expect(doc!.goal, 'Do the thing');
      expect(doc.status, PlanDocumentStatus.proposed);
      expect(doc.graph.nodes, isEmpty);
    });

    test('upsert replaces an existing row by id', () async {
      await planDocRepo.upsert(
        buildDoc(id: 'p1', workspaceId: 'ws1', goal: 'v1'),
      );
      await planDocRepo.upsert(
        buildDoc(id: 'p1', workspaceId: 'ws1', goal: 'v2', revision: 2),
      );
      final doc = await planDocRepo.getById('ws1', 'p1');
      expect(doc!.goal, 'v2');
      expect(doc.revision, 2);
    });

    test('latestForConversation picks the newest by updatedAt', () async {
      await planDocRepo.upsert(
        buildDoc(id: 'p1', workspaceId: 'ws1', updatedAt: DateTime(2026, 1, 1)),
      );
      await planDocRepo.upsert(
        buildDoc(id: 'p2', workspaceId: 'ws1', updatedAt: DateTime(2026, 1, 3)),
      );
      await planDocRepo.upsert(
        buildDoc(id: 'p3', workspaceId: 'ws1', updatedAt: DateTime(2026, 1, 2)),
      );
      final latest = await planDocRepo.latestForConversation('ws1', 'conv1');
      expect(latest!.id, 'p2');
    });

    test('watchForWorkspace streams the live list, newest first', () async {
      await planDocRepo.upsert(
        buildDoc(id: 'p1', workspaceId: 'ws1', updatedAt: DateTime(2026, 1, 1)),
      );
      await planDocRepo.upsert(
        buildDoc(id: 'p2', workspaceId: 'ws1', updatedAt: DateTime(2026, 1, 2)),
      );
      final list = await planDocRepo.watchForWorkspace('ws1').first;
      expect(list.map((d) => d.id).toList(), ['p2', 'p1']);
    });

    test('watchById streams a single document', () async {
      await planDocRepo.upsert(buildDoc(id: 'p1', workspaceId: 'ws1'));
      final doc = await planDocRepo.watchById('ws1', 'p1').first;
      expect(doc!.id, 'p1');
    });

    test('deleteById removes the row', () async {
      await planDocRepo.upsert(buildDoc(id: 'p1', workspaceId: 'ws1'));
      await planDocRepo.deleteById('ws1', 'p1');
      expect(await planDocRepo.getById('ws1', 'p1'), isNull);
    });

    group('workspace isolation', () {
      test('getById/latestForConversation/watchForWorkspace never cross '
          'workspaces', () async {
        await planDocRepo.upsert(buildDoc(id: 'p1', workspaceId: 'ws1'));
        expect(await planDocRepo.getById('ws2', 'p1'), isNull);
        expect(await planDocRepo.latestForConversation('ws2', 'conv1'), isNull);
        expect(await planDocRepo.watchForWorkspace('ws2').first, isEmpty);
      });

      test(
        'deleteById is scoped — cannot delete another workspace document',
        () async {
          await planDocRepo.upsert(buildDoc(id: 'p1', workspaceId: 'ws1'));
          await planDocRepo.deleteById('ws2', 'p1');
          expect(await planDocRepo.getById('ws1', 'p1'), isNotNull);
        },
      );
    });
  });

  group('playbooks', () {
    Playbook buildPlaybook({
      required String id,
      required String workspaceId,
      String name = 'deploy',
      int version = 1,
      DateTime? updatedAt,
    }) => Playbook(
      id: id,
      workspaceId: workspaceId,
      name: name,
      description: 'Deploys the service',
      params: [PlaybookParam(name: 'target')],
      sourceProposal: buildProposal(),
      version: version,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

    test('upsert + getById + getByName round-trip', () async {
      await playbookRepo.upsert(buildPlaybook(id: 'pb1', workspaceId: 'ws1'));
      final byId = await playbookRepo.getById('ws1', 'pb1');
      expect(byId, isNotNull);
      expect(byId!.name, 'deploy');
      expect(byId.params.single.name, 'target');
      final byName = await playbookRepo.getByName('ws1', 'deploy');
      expect(byName!.id, 'pb1');
    });

    test('upsert replaces an existing row and bumps version', () async {
      await playbookRepo.upsert(buildPlaybook(id: 'pb1', workspaceId: 'ws1'));
      await playbookRepo.upsert(
        buildPlaybook(id: 'pb1', workspaceId: 'ws1', version: 2),
      );
      final playbook = await playbookRepo.getById('ws1', 'pb1');
      expect(playbook!.version, 2);
    });

    test('forWorkspace lists playbooks by name', () async {
      await playbookRepo.upsert(
        buildPlaybook(id: 'pb1', workspaceId: 'ws1', name: 'zeta'),
      );
      await playbookRepo.upsert(
        buildPlaybook(id: 'pb2', workspaceId: 'ws1', name: 'alpha'),
      );
      final list = await playbookRepo.forWorkspace('ws1');
      expect(list.map((p) => p.name).toList(), ['alpha', 'zeta']);
    });

    test('watchForWorkspace streams the live list, by name', () async {
      await playbookRepo.upsert(buildPlaybook(id: 'pb1', workspaceId: 'ws1'));
      final list = await playbookRepo.watchForWorkspace('ws1').first;
      expect(list.map((p) => p.id).toList(), ['pb1']);
    });

    test('deleteById removes the row', () async {
      await playbookRepo.upsert(buildPlaybook(id: 'pb1', workspaceId: 'ws1'));
      await playbookRepo.deleteById('ws1', 'pb1');
      expect(await playbookRepo.getById('ws1', 'pb1'), isNull);
    });

    group('workspace isolation', () {
      test('getById/getByName/forWorkspace never cross workspaces', () async {
        await playbookRepo.upsert(
          buildPlaybook(id: 'pb1', workspaceId: 'ws1', name: 'shared-name'),
        );
        expect(await playbookRepo.getById('ws2', 'pb1'), isNull);
        expect(await playbookRepo.getByName('ws2', 'shared-name'), isNull);
        expect(await playbookRepo.forWorkspace('ws2'), isEmpty);
      });

      test(
        'deleteById is scoped — cannot delete another workspace playbook',
        () async {
          await playbookRepo.upsert(
            buildPlaybook(id: 'pb1', workspaceId: 'ws1'),
          );
          await playbookRepo.deleteById('ws2', 'pb1');
          expect(await playbookRepo.getById('ws1', 'pb1'), isNotNull);
        },
      );
    });
  });

  group('orchestration approvedNodeKeys (PRD 17 §4 partial approval)', () {
    late DaoOrchestrationRepository orchestrationRepo;

    setUp(() {
      orchestrationRepo = DaoOrchestrationRepository(dbs);
    });

    test('approvedNodeKeys round-trips through the JSON column', () async {
      await orchestrationRepo.insert(
        Orchestration(
          id: 'orch-partial',
          workspaceId: 'ws1',
          proposal: buildProposal(),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          approvedNodeKeys: ['a', 'b'],
        ),
      );
      final fetched = await orchestrationRepo.getById('ws1', 'orch-partial');
      expect(fetched, isNotNull);
      expect(fetched!.approvedNodeKeys, ['a', 'b']);
    });

    test('a null approvedNodeKeys means whole-plan approval', () async {
      await orchestrationRepo.insert(
        Orchestration(
          id: 'orch-full',
          workspaceId: 'ws1',
          proposal: buildProposal(),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      final fetched = await orchestrationRepo.getById('ws1', 'orch-full');
      expect(fetched!.approvedNodeKeys, isNull);
    });
  });
}
