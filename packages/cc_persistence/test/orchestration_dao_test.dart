import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    required String ws,
    String? parentTicketId,
    String? pipelineRunId,
    String status = 'proposed',
  }) => db.orchestrationDao.insert(
    OrchestrationsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      proposalJson: '{}',
      parentTicketId: parentTicketId == null
          ? const Value.absent()
          : Value(parentTicketId),
      pipelineRunId: pipelineRunId == null
          ? const Value.absent()
          : Value(pipelineRunId),
      status: Value(status),
    ),
  );

  group('OrchestrationDao writes + reads', () {
    test('getById is workspace-scoped', () async {
      await seed(id: 'o-1', ws: 'w-1');
      expect((await db.orchestrationDao.getById('o-1', 'w-1'))?.id, 'o-1');
      expect(await db.orchestrationDao.getById('o-1', 'w-2'), isNull);
      expect(await db.orchestrationDao.getById('missing', 'w-1'), isNull);
    });

    test('forParentTicket is workspace-scoped', () async {
      await seed(id: 'o-1', ws: 'w-1', parentTicketId: 'tk-1');
      await seed(id: 'o-2', ws: 'w-2', parentTicketId: 'tk-1');
      final row = await db.orchestrationDao.forParentTicket('w-1', 'tk-1');
      expect(row?.id, 'o-1');
      // foreign workspace resolves to its own row
      expect(
        (await db.orchestrationDao.forParentTicket('w-2', 'tk-1'))?.id,
        'o-2',
      );
      expect(await db.orchestrationDao.forParentTicket('w-1', 'other'), isNull);
    });

    test('forPipelineRun is workspace-scoped', () async {
      await seed(id: 'o-1', ws: 'w-1', pipelineRunId: 'run-1');
      await seed(id: 'o-2', ws: 'w-2', pipelineRunId: 'run-1');
      expect(
        (await db.orchestrationDao.forPipelineRun('w-1', 'run-1'))?.id,
        'o-1',
      );
      expect(
        await db.orchestrationDao.forPipelineRun('w-2', 'run-1'),
        isNotNull,
      );
      expect(
        await db.orchestrationDao.forPipelineRun('w-1', 'missing'),
        isNull,
      );
    });

    test('forPipelineRunAnyWorkspace spans every workspace', () async {
      await seed(id: 'o-1', ws: 'w-2', pipelineRunId: 'run-x');
      expect(
        (await db.orchestrationDao.forPipelineRunAnyWorkspace('run-x'))?.id,
        'o-1',
      );
      expect(
        await db.orchestrationDao.forPipelineRunAnyWorkspace('nope'),
        isNull,
      );
    });

    test(
      'updateById is workspace-scoped and writes only provided columns',
      () async {
        await seed(id: 'o-1', ws: 'w-1', status: 'proposed');
        // foreign workspace update is a no-op.
        expect(
          await db.orchestrationDao.updateById(
            'o-1',
            'w-2',
            const OrchestrationsTableCompanion(status: Value('approved')),
          ),
          0,
        );
        expect(
          (await db.orchestrationDao.getById('o-1', 'w-1'))?.status,
          'proposed',
        );
        // owning workspace update lands.
        expect(
          await db.orchestrationDao.updateById(
            'o-1',
            'w-1',
            const OrchestrationsTableCompanion(
              status: Value('approved'),
              pipelineRunId: Value('run-1'),
            ),
          ),
          1,
        );
        final row = await db.orchestrationDao.getById('o-1', 'w-1');
        expect(row?.status, 'approved');
        expect(row?.pipelineRunId, 'run-1');
      },
    );
  });

  group('OrchestrationDao watches', () {
    test('watchForWorkspace emits scoped + newest-first rows', () async {
      await seed(id: 'o-1', ws: 'w-1');
      await seed(id: 'o-2', ws: 'w-2');
      final rows = await db.orchestrationDao.watchForWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'o-1');
    });

    test('watchById emits the row within its workspace', () async {
      await seed(id: 'o-1', ws: 'w-1');
      expect(
        (await db.orchestrationDao.watchById('o-1', 'w-1').first)?.id,
        'o-1',
      );
      // foreign workspace sees null.
      expect(await db.orchestrationDao.watchById('o-1', 'w-2').first, isNull);
      expect(
        await db.orchestrationDao.watchById('missing', 'w-1').first,
        isNull,
      );
    });
  });

  group('OrchestrationDao resume query', () {
    test(
      'approvedNeedingMaterialization returns approved + null run rows',
      () async {
        await seed(id: 'o-1', ws: 'w-1', status: 'approved');
        await seed(
          id: 'o-2',
          ws: 'w-1',
          status: 'approved',
          pipelineRunId: 'run-1',
        );
        await seed(id: 'o-3', ws: 'w-1', status: 'proposed');
        final rows = await db.orchestrationDao.approvedNeedingMaterialization();
        expect(rows.map((r) => r.id).toList(), ['o-1']);
      },
    );
  });
}
