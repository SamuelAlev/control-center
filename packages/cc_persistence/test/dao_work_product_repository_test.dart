import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/work_product_mapper.dart'
    show WorkProductMapper;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [DaoWorkProductRepository] + [WorkProductMapper] end-to-end: the work
/// product and revision round trips, plus workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWorkProductRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoWorkProductRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  WorkProduct product({
    required String id,
    String ws = 'w-1',
    WorkProductType type = WorkProductType.document,
    String? ticketId,
    String? agentId,
  }) => WorkProduct(
    id: id,
    workspaceId: ws,
    title: 'Title $id',
    artifactType: type,
    ticketId: ticketId,
    agentId: agentId,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1),
  );

  group('DaoWorkProductRepository products', () {
    test('upsert + getById round-trips through the mapper', () async {
      await repo.upsert(
        product(id: 'wp-1', type: WorkProductType.plan, agentId: 'a-1'),
      );
      final fetched = await repo.getById('w-1', 'wp-1');
      expect(fetched?.title, 'Title wp-1');
      expect(fetched?.artifactType, WorkProductType.plan);
      expect(fetched?.agentId, 'a-1');
    });

    test('forTicket is workspace-scoped', () async {
      await repo.upsert(product(id: 'wp-1', ws: 'w-1', ticketId: 'tk-1'));
      await repo.upsert(product(id: 'wp-2', ws: 'w-2', ticketId: 'tk-1'));
      final rows = await repo.forTicket('w-1', 'tk-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'wp-1');
    });

    test('watchByWorkspace emits scoped + mapped rows', () async {
      await repo.upsert(product(id: 'wp-1', ws: 'w-1'));
      await repo.upsert(product(id: 'wp-2', ws: 'w-2'));
      final rows = await repo.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
    });

    test('delete is workspace-scoped via the DAO', () async {
      await repo.upsert(product(id: 'wp-1', ws: 'w-1'));
      await repo.delete('w-1', 'wp-1');
      expect(await repo.getById('w-1', 'wp-1'), isNull);
    });
  });

  group('DaoWorkProductRepository revisions', () {
    test(
      'addRevision + getRevisions + watchRevisions + getRevisionById',
      () async {
        await repo.upsert(product(id: 'wp-1'));
        await repo.addRevision(
          WorkProductRevision(
            id: 'rev-1',
            workProductId: 'wp-1',
            workspaceId: 'w-1',
            revisionNumber: 1,
            content: 'v1',
            createdAt: DateTime.utc(2025, 1, 1),
          ),
        );
        await repo.addRevision(
          WorkProductRevision(
            id: 'rev-2',
            workProductId: 'wp-1',
            workspaceId: 'w-1',
            revisionNumber: 2,
            content: 'v2',
            summary: 'second pass',
            createdAt: DateTime.utc(2025, 1, 2),
          ),
        );

        final revs = await repo.getRevisions('w-1', 'wp-1');
        expect(revs, hasLength(2));
        // newest first
        expect(revs.first.revisionNumber, 2);
        expect(revs.first.summary, 'second pass');

        final watched = await repo.watchRevisions('w-1', 'wp-1').first;
        expect(watched, hasLength(2));

        final byId = await repo.getRevisionById('w-1', 'rev-1');
        expect(byId?.content, 'v1');
        expect(await repo.getRevisionById('w-2', 'rev-1'), isNull);
        expect(await repo.getRevisionById('w-1', 'missing'), isNull);
      },
    );

    test('getById returns null for an unknown product', () async {
      expect(await repo.getById('w-1', 'missing'), isNull);
    });
  });
}
