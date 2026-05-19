import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/workspace_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  // The workspace registry lives in the GLOBAL half post-split, so this mapper's
  // rows come from `global.workspaceRegistryDao`, not a workspace database.
  late GlobalDatabase db;
  const mapper = WorkspaceMapper();

  setUp(() {
    db = createTestGlobalDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<WorkspacesTableData> createWorkspace({
    String id = 'ws-1',
    String name = 'Test WS',
    String? logoPath,
  }) async {
    await db.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: id,
        name: name,
        logoPath: Value.absentIfNull(logoPath),
      ),
    );
    return (await db.workspaceRegistryDao.getById(id))!;
  }

  group('WorkspaceMapper', () {
    test('toDomain maps all fields correctly', () async {
      final row = await createWorkspace();

      final domain = mapper.toDomain(row);

      expect(domain, isA<Workspace>());
      expect(domain.id, 'ws-1');
      expect(domain.name, 'Test WS');
    });

    test('toDomain maps workspace with different name', () async {
      final row = await createWorkspace(name: 'Active Project');

      final domain = mapper.toDomain(row);
      expect(domain.id, 'ws-1');
      expect(domain.name, 'Active Project');
    });

    test('toDomain maps null fields', () async {
      final row = await createWorkspace();

      final domain = mapper.toDomain(row);
      expect(domain.logoPath, isNull);
    });

    test('toDomain maps optional fields when present', () async {
      final row = await createWorkspace(logoPath: '/path/to/logo.png');

      final domain = mapper.toDomain(row);
      expect(domain.logoPath, '/path/to/logo.png');
    });

    test('toDomainList maps multiple rows', () async {
      await createWorkspace(id: 'ws-a', name: 'Workspace A');
      await createWorkspace(id: 'ws-b', name: 'Workspace B');
      final rows = [
        (await db.workspaceRegistryDao.getById('ws-a'))!,
        (await db.workspaceRegistryDao.getById('ws-b'))!,
      ];

      final domains = mapper.toDomainList(rows);
      expect(domains.length, 2);
      expect(domains[0].id, 'ws-a');
      expect(domains[1].id, 'ws-b');
    });

    test('toDomainList returns empty list for empty input', () {
      final domains = mapper.toDomainList([]);
      expect(domains, isEmpty);
    });

    test('toDomain preserves createdAt and updatedAt', () async {
      final row = await createWorkspace();

      final domain = mapper.toDomain(row);
      expect(domain.createdAt, isA<DateTime>());
      expect(domain.updatedAt, isA<DateTime>());
    });

    test('toDomain with special characters in name', () async {
      final row = await createWorkspace(
        name: 'Project (Phase 2) - Build & Test',
      );

      final domain = mapper.toDomain(row);
      expect(domain.name, 'Project (Phase 2) - Build & Test');
    });
  });
}
