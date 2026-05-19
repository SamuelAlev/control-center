import 'package:cc_domain/cc_domain.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers the [TicketDao] paths the basic `ticket_dao_test.dart` does not
/// exercise: optimistic-concurrency updateById, patchFields, getByExternalKey,
/// forAgent, childrenOf, watchByStatus, watchByAssignee, removeCollaborator.
void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    String ws = 'w-1',
    String title = 'T',
    String? externalKey,
    String status = 'open',
    String? assignedAgentId,
    String? parentTicketId,
    int version = 0,
  }) => db.ticketDao.insert(
    TicketsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      title: title,
      externalKey: externalKey == null
          ? const Value.absent()
          : Value(externalKey),
      status: Value(status),
      assignedAgentId: assignedAgentId == null
          ? const Value.absent()
          : Value(assignedAgentId),
      parentTicketId: parentTicketId == null
          ? const Value.absent()
          : Value(parentTicketId),
      version: Value(version),
    ),
  );

  group('TicketDao optimistic concurrency', () {
    test(
      'updateById throws ConcurrencyConflictException on stale version',
      () async {
        await seed(id: 't-1', version: 1);
        await expectLater(
          db.ticketDao.updateById(
            't-1',
            const TicketsTableCompanion(status: Value('done')),
            expectedVersion: 99,
          ),
          throwsA(isA<ConcurrencyConflictException>()),
        );
        // Row is unchanged.
        expect((await db.ticketDao.getById('t-1'))?.status, 'open');
      },
    );

    test('updateById applies when the expected version matches', () async {
      await seed(id: 't-1', version: 1);
      await db.ticketDao.updateById(
        't-1',
        const TicketsTableCompanion(status: Value('done')),
        expectedVersion: 1,
      );
      expect((await db.ticketDao.getById('t-1'))?.status, 'done');
    });

    test('updateById without expectedVersion matches any version', () async {
      await seed(id: 't-1', version: 5);
      await db.ticketDao.updateById(
        't-1',
        const TicketsTableCompanion(title: Value('Renamed')),
      );
      expect((await db.ticketDao.getById('t-1'))?.title, 'Renamed');
    });
  });

  group('TicketDao patchFields', () {
    test('patches only the provided columns and bumps version', () async {
      await seed(id: 't-1', title: 'Original', status: 'open', version: 0);
      final written = await db.ticketDao.patchFields(
        'w-1',
        't-1',
        const TicketsTableCompanion(status: Value('inProgress')),
      );
      expect(written, 1);
      final row = await db.ticketDao.getById('t-1');
      expect(row?.status, 'inProgress');
      expect(row?.title, 'Original'); // untouched
      expect(row?.version, 1); // bumped
    });

    test(
      'patchFields is workspace-scoped — foreign/unknown ticket returns 0',
      () async {
        await seed(id: 't-1', ws: 'w-1');
        expect(
          await db.ticketDao.patchFields(
            'w-2',
            't-1',
            const TicketsTableCompanion(status: Value('done')),
          ),
          0,
        );
        expect(
          await db.ticketDao.patchFields(
            'w-1',
            'missing',
            const TicketsTableCompanion(status: Value('done')),
          ),
          0,
        );
        // The owned row is untouched.
        expect((await db.ticketDao.getById('t-1'))?.status, 'open');
      },
    );
  });

  group('TicketDao reads', () {
    test('getByExternalKey resolves by (provider, externalKey)', () async {
      // The seed uses provider default 'local', so the lookup must match both
      // the provider AND the external key.
      await seed(id: 't-1', externalKey: 'LIN-123');
      expect(
        (await db.ticketDao.getByExternalKey('local', 'LIN-123'))?.id,
        't-1',
      );
      // Wrong provider: no match.
      expect(await db.ticketDao.getByExternalKey('linear', 'LIN-123'), isNull);
      // Wrong key: no match.
      expect(await db.ticketDao.getByExternalKey('local', 'missing'), isNull);
    });

    test('forAgent is workspace-scoped', () async {
      await seed(id: 't-1', ws: 'w-1', assignedAgentId: 'a-1');
      await seed(id: 't-2', ws: 'w-2', assignedAgentId: 'a-1');
      final rows = await db.ticketDao.forAgent('w-1', 'a-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 't-1');
    });

    test('childrenOf lists direct children', () async {
      await seed(id: 't-1');
      await seed(id: 't-2', parentTicketId: 't-1');
      await seed(id: 't-3', parentTicketId: 't-1');
      await seed(id: 't-4', parentTicketId: 't-2');
      final rows = await db.ticketDao.childrenOf('w-1', 't-1');
      expect(rows.map((r) => r.id).toSet(), {'t-2', 't-3'});
    });
  });

  group('TicketDao watches', () {
    test('watchByStatus filters by status within the workspace', () async {
      await seed(id: 't-1', ws: 'w-1', status: 'open');
      await seed(id: 't-2', ws: 'w-1', status: 'done');
      await seed(id: 't-3', ws: 'w-2', status: 'open');
      final rows = await db.ticketDao.watchByStatus('w-1', 'open').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 't-1');
    });

    test('watchByAssignee is workspace-scoped', () async {
      await seed(id: 't-1', ws: 'w-1', assignedAgentId: 'a-1');
      await seed(id: 't-2', ws: 'w-2', assignedAgentId: 'a-1');
      final rows = await db.ticketDao.watchByAssignee('w-1', 'a-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 't-1');
    });
  });

  group('TicketDao collaborators', () {
    test(
      'addCollaborator is idempotent + removeCollaborator clears it',
      () async {
        await seed(id: 't-1');
        await db.ticketDao.addCollaborator(
          TicketCollaboratorsTableCompanion.insert(
            id: 'col-1',
            ticketId: 't-1',
            principalId: 'p-1',
          ),
        );
        // duplicate ignored
        await db.ticketDao.addCollaborator(
          TicketCollaboratorsTableCompanion.insert(
            id: 'col-2',
            ticketId: 't-1',
            principalId: 'p-1',
          ),
        );
        expect(await db.ticketDao.getCollaborators('t-1'), hasLength(1));

        await db.ticketDao.removeCollaborator('t-1', 'p-1');
        expect(await db.ticketDao.getCollaborators('t-1'), isEmpty);
      },
    );
  });
}
