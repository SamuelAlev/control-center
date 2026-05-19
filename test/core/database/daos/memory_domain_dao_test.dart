import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // memory_domains_table FKs to workspaces, so seed the workspaces first.
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'w-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'w-2', name: 'WS 2'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemoryDomainDao.upsert', () {
    MemoryDomainsTableCompanion domain({
      required String id,
      String workspaceId = 'w-1',
      String name = 'features',
      String label = 'Features',
      String? description,
      String createdByRole = 'general',
    }) =>
        MemoryDomainsTableCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          name: name,
          label: label,
          description: Value.absentIfNull(description),
          createdByRole: createdByRole,
        );

    test('creates a new domain', () async {
      await db.memoryDomainDao.upsert(domain(id: 'd-1'));

      final row = await db.memoryDomainDao.findByName('w-1', 'features');
      expect(row, isNotNull);
      expect(row!.id, 'd-1');
      expect(row.label, 'Features');
    });

    test(
      're-proposing the same slug with a fresh id does not throw and keeps one '
      'row (regression: UNIQUE constraint on workspace_id, name)',
      () async {
        // Two racing propose_fact calls both believe the domain is new and
        // mint different UUIDs for the same (workspaceId, name).
        await db.memoryDomainDao.upsert(domain(id: 'd-first', label: 'First'));
        await db.memoryDomainDao
            .upsert(domain(id: 'd-second', label: 'Second'));

        final rows = await db.memoryDomainDao.getByWorkspace('w-1');
        expect(rows, hasLength(1), reason: 'must not create a duplicate row');

        final row = rows.single;
        expect(row.id, 'd-first', reason: 'original id is preserved');
        expect(row.label, 'Second', reason: 'metadata is refreshed on conflict');
      },
    );

    test('preserves createdAt across a conflicting upsert', () async {
      await db.memoryDomainDao.upsert(domain(id: 'd-1'));
      final original = await db.memoryDomainDao.findByName('w-1', 'features');

      await db.memoryDomainDao.upsert(domain(id: 'd-2', label: 'Renamed'));
      final updated = await db.memoryDomainDao.findByName('w-1', 'features');

      expect(updated!.createdAt, original!.createdAt);
    });

    test('same slug in a different workspace is a distinct row', () async {
      await db.memoryDomainDao.upsert(domain(id: 'd-a', workspaceId: 'w-1'));
      await db.memoryDomainDao.upsert(domain(id: 'd-b', workspaceId: 'w-2'));

      final a = await db.memoryDomainDao.getByWorkspace('w-1');
      final b = await db.memoryDomainDao.getByWorkspace('w-2');
      expect(a, hasLength(1));
      expect(b, hasLength(1));
      expect(a.single.id, 'd-a');
      expect(b.single.id, 'd-b');
    });
  });
}
