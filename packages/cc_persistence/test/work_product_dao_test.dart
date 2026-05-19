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

  Future<void> seedProduct({
    required String id,
    required String ws,
    String? ticketId,
    String artifactType = 'document',
  }) => db.workProductDao.upsert(
    WorkProductsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      ticketId: ticketId == null ? const Value.absent() : Value(ticketId),
      title: 'Title $id',
      artifactType: Value(artifactType),
    ),
  );

  group('WorkProductDao products', () {
    test('watchByWorkspace emits scoped rows', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1');
      await seedProduct(id: 'wp-2', ws: 'w-2');
      final rows = await db.workProductDao.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'wp-1');
    });

    test('forTicket is workspace-scoped', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1', ticketId: 'tk-1');
      await seedProduct(id: 'wp-2', ws: 'w-1', ticketId: 'tk-2');
      await seedProduct(id: 'wp-3', ws: 'w-2', ticketId: 'tk-1');
      final rows = await db.workProductDao.forTicket('w-1', 'tk-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'wp-1');
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1', artifactType: 'document');
      await seedProduct(id: 'wp-1', ws: 'w-1', artifactType: 'plan');
      final row = await db.workProductDao.getById('w-1', 'wp-1');
      expect(row?.artifactType, 'plan');
    });

    test('getById is workspace-scoped', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1');
      expect((await db.workProductDao.getById('w-1', 'wp-1'))?.id, 'wp-1');
      expect(await db.workProductDao.getById('w-2', 'wp-1'), isNull);
      expect(await db.workProductDao.getById('w-1', 'missing'), isNull);
    });

    test(
      'deleteById is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seedProduct(id: 'wp-1', ws: 'w-1');
        expect(await db.workProductDao.deleteById('w-2', 'wp-1'), 0);
        expect(await db.workProductDao.getById('w-1', 'wp-1'), isNotNull);
        expect(await db.workProductDao.deleteById('w-1', 'wp-1'), 1);
        expect(await db.workProductDao.getById('w-1', 'wp-1'), isNull);
      },
    );
  });

  group('WorkProductDao revisions', () {
    test(
      'insertRevision + getRevisions is workspace-scoped, newest-first',
      () async {
        await seedProduct(id: 'wp-1', ws: 'w-1');
        await db.workProductDao.insertRevision(
          WorkProductRevisionsTableCompanion.insert(
            id: 'rev-1',
            workProductId: 'wp-1',
            workspaceId: 'w-1',
            revisionNumber: 1,
            content: 'v1',
          ),
        );
        await db.workProductDao.insertRevision(
          WorkProductRevisionsTableCompanion.insert(
            id: 'rev-2',
            workProductId: 'wp-1',
            workspaceId: 'w-1',
            revisionNumber: 2,
            content: 'v2',
          ),
        );
        // A foreign workspace cannot see the revisions.
        expect(await db.workProductDao.getRevisions('w-2', 'wp-1'), isEmpty);

        final rows = await db.workProductDao.getRevisions('w-1', 'wp-1');
        expect(rows, hasLength(2));
        // newest (highest revisionNumber) first
        expect(rows.first.revisionNumber, 2);
      },
    );

    test('watchRevisions emits scoped rows', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1');
      await db.workProductDao.insertRevision(
        WorkProductRevisionsTableCompanion.insert(
          id: 'rev-1',
          workProductId: 'wp-1',
          workspaceId: 'w-1',
          revisionNumber: 1,
          content: 'v1',
        ),
      );
      final rows = await db.workProductDao.watchRevisions('w-1', 'wp-1').first;
      expect(rows, hasLength(1));
    });

    test('getRevisionById is workspace-scoped', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1');
      await db.workProductDao.insertRevision(
        WorkProductRevisionsTableCompanion.insert(
          id: 'rev-1',
          workProductId: 'wp-1',
          workspaceId: 'w-1',
          revisionNumber: 1,
          content: 'v1',
        ),
      );
      expect(
        (await db.workProductDao.getRevisionById('w-1', 'rev-1'))?.content,
        'v1',
      );
      expect(await db.workProductDao.getRevisionById('w-2', 'rev-1'), isNull);
      expect(await db.workProductDao.getRevisionById('w-1', 'missing'), isNull);
    });

    test('revisions cascade with the parent work product', () async {
      await seedProduct(id: 'wp-1', ws: 'w-1');
      await db.workProductDao.insertRevision(
        WorkProductRevisionsTableCompanion.insert(
          id: 'rev-1',
          workProductId: 'wp-1',
          workspaceId: 'w-1',
          revisionNumber: 1,
          content: 'v1',
        ),
      );
      await db.workProductDao.deleteById('w-1', 'wp-1');
      expect(await db.workProductDao.getRevisions('w-1', 'wp-1'), isEmpty);
    });
  });
}
