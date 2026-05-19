import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/memory_domain_dao.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoMemoryDomainRepository repo;
  late MemoryDomainDao dao;

  setUp(() async {
    db = createTestDatabase();
    // Insert workspace rows so FK constraints on memory_domains are satisfied.
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'WS 2'),
        );
    dao = MemoryDomainDao(db);
    repo = DaoMemoryDomainRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  MemoryDomain makeDomain({
    String id = 'd-1',
    String workspaceId = 'ws-1',
    String name = 'codebase',
    String label = 'Codebase',
    String? description = 'Code-related facts',
    String createdByRole = 'architect',
  }) =>
      MemoryDomain(
        id: id,
        workspaceId: workspaceId,
        name: name,
        label: label,
        description: description,
        createdAt: DateTime(2025, 1, 1),
        createdByRole: createdByRole,
      );

  group('upsert', () {
    test('inserts a new domain', () async {
      final domain = makeDomain();
      await repo.upsert(domain);

      final result = await repo.findByName('ws-1', 'codebase');
      expect(result, isNotNull);
      expect(result!.name, 'codebase');
      expect(result.label, 'Codebase');
    });

    test('upsert with same (workspaceId, name) updates existing', () async {
      await repo.upsert(makeDomain());
      // Same natural key, different id — should update, not insert
      final updated = makeDomain(id: 'd-2', label: 'Updated Label');
      await repo.upsert(updated);

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      // The original id persists (upsert targets the natural key)
      expect(results.first.label, 'Updated Label');
    });

    test('description can be null', () async {
      final domain = makeDomain(description: null);
      await repo.upsert(domain);

      final result = await repo.findByName('ws-1', 'codebase');
      expect(result!.description, isNull);
    });
  });

  group('findByName', () {
    test('returns null for unknown name', () async {
      final result = await repo.findByName('ws-1', 'nonexistent');
      expect(result, isNull);
    });

    test('scoped to workspace', () async {
      await repo.upsert(makeDomain(workspaceId: 'ws-1', name: 'codebase'));
      final result = await repo.findByName('ws-2', 'codebase');
      expect(result, isNull);
    });
  });

  group('getByWorkspace', () {
    test('filters by workspace', () async {
      await repo.upsert(makeDomain(id: 'd-1', workspaceId: 'ws-1', name: 'a'));
      await repo.upsert(makeDomain(id: 'd-2', workspaceId: 'ws-1', name: 'b'));
      await repo.upsert(makeDomain(id: 'd-3', workspaceId: 'ws-2', name: 'c'));

      final ws1 = await repo.getByWorkspace('ws-1');
      expect(ws1.length, 2);

      final ws2 = await repo.getByWorkspace('ws-2');
      expect(ws2.length, 1);
    });

    test('returns sorted by name', () async {
      await repo.upsert(makeDomain(id: 'd-1', name: 'zebra'));
      await repo.upsert(makeDomain(id: 'd-2', name: 'alpha'));

      final results = await repo.getByWorkspace('ws-1');
      expect(results.first.name, 'alpha');
      expect(results.last.name, 'zebra');
    });

    test('returns empty for unused workspace', () async {
      final domains = await repo.getByWorkspace('empty');
      expect(domains, isEmpty);
    });
  });

  group('watchByWorkspace', () {
    test('emits current domains', () async {
      await repo.upsert(makeDomain());

      final results = await repo.watchByWorkspace('ws-1').first;
      expect(results.length, 1);
    });
  });

  group('full round-trip', () {
    test('all fields survive round-trip', () async {
      final original = makeDomain(
        id: 'full-1',
        name: 'security',
        label: 'Security',
        description: 'Security-related facts and policies',
        createdByRole: 'operator',
      );
      await repo.upsert(original);

      final result = await repo.findByName('ws-1', 'security');
      expect(result!.name, original.name);
      expect(result.label, original.label);
      expect(result.description, original.description);
      expect(result.createdByRole, original.createdByRole);
      expect(result.workspaceId, original.workspaceId);
    });
  });
}
