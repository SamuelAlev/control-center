

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_access_grant_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoMemoryAccessGrantRepository repo;

  setUp(() async {
    db = createTestDatabase();
    // FK constraint: memory_access_grants.workspaceId → workspaces.id
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'WS 2'),
        );
    repo = DaoMemoryAccessGrantRepository(db.memoryAccessGrantDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('upsert', () {
    test('inserts a new grant and retrieves it', () async {
      final grant = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.read,
      );

      await repo.upsert(grant);

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      expect(results.first.workspaceId, 'ws-1');
      expect(results.first.agentRole, AgentRole.coder);
      expect(results.first.memoryDomain, 'codebase');
      expect(results.first.permission, MemoryPermission.read);
    });

    test('upsert overwrites existing grant with same PK', () async {
      final grant1 = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.read,
      );
      final grant2 = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.write,
      );

      await repo.upsert(grant1);
      await repo.upsert(grant2);

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      expect(results.first.permission, MemoryPermission.write);
    });

    test('multiple grants with different PKs coexist', () async {
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.read,
      ));
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.reviewer,
        memoryDomain: 'codebase',
        permission: MemoryPermission.write,
      ));
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'docs',
        permission: MemoryPermission.none,
      ));

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 3);
    });
  });

  group('upsertAll', () {
    test('inserts multiple grants at once', () async {
      final grants = [
        MemoryAccessGrant(
          workspaceId: 'ws-1',
          agentRole: AgentRole.coder,
          memoryDomain: 'codebase',
          permission: MemoryPermission.read,
        ),
        MemoryAccessGrant(
          workspaceId: 'ws-1',
          agentRole: AgentRole.reviewer,
          memoryDomain: 'codebase',
          permission: MemoryPermission.write,
        ),
      ];

      await repo.upsertAll(grants);

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 2);
    });

    test('upsertAll replaces existing grants', () async {
      // Seed a grant
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.none,
      ));

      // upsertAll with modified permission
      await repo.upsertAll([
        MemoryAccessGrant(
          workspaceId: 'ws-1',
          agentRole: AgentRole.coder,
          memoryDomain: 'codebase',
          permission: MemoryPermission.write,
        ),
      ]);

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      expect(results.first.permission, MemoryPermission.write);
    });

    test('upsertAll with empty list does not throw', () async {
      await repo.upsertAll([]);

      final results = await repo.getByWorkspace('ws-1');
      expect(results, isEmpty);
    });
  });

  group('getByWorkspace', () {
    test('returns empty for workspace with no grants', () async {
      final results = await repo.getByWorkspace('ws-1');
      expect(results, isEmpty);
    });

    test('returns empty for nonexistent workspace', () async {
      final results = await repo.getByWorkspace('nonexistent');
      expect(results, isEmpty);
    });

    test('scopes results to workspace', () async {
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.read,
      ));
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-2',
        agentRole: AgentRole.designer,
        memoryDomain: 'design-specs',
        permission: MemoryPermission.write,
      ));

      final ws1 = await repo.getByWorkspace('ws-1');
      expect(ws1.length, 1);
      expect(ws1.first.workspaceId, 'ws-1');

      final ws2 = await repo.getByWorkspace('ws-2');
      expect(ws2.length, 1);
      expect(ws2.first.workspaceId, 'ws-2');
    });
  });

  group('watchByWorkspace', () {
    test('emits current grants', () async {
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'codebase',
        permission: MemoryPermission.read,
      ));

      final emitted = await repo.watchByWorkspace('ws-1').first;
      expect(emitted.length, 1);
      expect(emitted.first.memoryDomain, 'codebase');
    });

    test('emits empty when no grants', () async {
      final emitted = await repo.watchByWorkspace('ws-1').first;
      expect(emitted, isEmpty);
    });

    test('streams updates after upsert', () async {
      final stream = repo.watchByWorkspace('ws-1');

      // First emission — empty
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert should trigger another emission
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.pm,
        memoryDomain: 'roadmap',
        permission: MemoryPermission.read,
      ));
      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.agentRole, AgentRole.pm);
    });

    test('does not emit grants from other workspaces', () async {
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.coder,
        memoryDomain: 'code',
        permission: MemoryPermission.read,
      ));
      await repo.upsert(MemoryAccessGrant(
        workspaceId: 'ws-2',
        agentRole: AgentRole.designer,
        memoryDomain: 'design',
        permission: MemoryPermission.write,
      ));

      final results = await repo.watchByWorkspace('ws-1').first;
      expect(results.length, 1);
      expect(results.single.workspaceId, 'ws-1');
    });
  });

  group('mapper fallbacks', () {
    test('unknown agentRole string falls back to general', () async {
      await db.into(db.memoryAccessGrantsTable).insert(
            const MemoryAccessGrantsTableCompanion(
              workspaceId: Value('ws-1'),
              agentRole: Value('nonexistent_role'),
              memoryDomain: Value('domain'),
              permission: Value('read'),
            ),
          );

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      expect(results.first.agentRole, AgentRole.general);
    });

    test('unknown permission string falls back to read', () async {
      await db.into(db.memoryAccessGrantsTable).insert(
            const MemoryAccessGrantsTableCompanion(
              workspaceId: Value('ws-1'),
              agentRole: Value('coder'),
              memoryDomain: Value('domain'),
              permission: Value('super_admin'),
            ),
          );

      final results = await repo.getByWorkspace('ws-1');
      expect(results.length, 1);
      expect(results.first.permission, MemoryPermission.read);
    });

    test('case-insensitive agentRole matching', () async {
      await db.into(db.memoryAccessGrantsTable).insert(
            const MemoryAccessGrantsTableCompanion(
              workspaceId: Value('ws-1'),
              agentRole: Value('CODER'),
              memoryDomain: Value('domain'),
              permission: Value('write'),
            ),
          );

      final results = await repo.getByWorkspace('ws-1');
      expect(results.first.agentRole, AgentRole.coder);
    });

    test('case-insensitive permission matching', () async {
      await db.into(db.memoryAccessGrantsTable).insert(
            const MemoryAccessGrantsTableCompanion(
              workspaceId: Value('ws-1'),
              agentRole: Value('reviewer'),
              memoryDomain: Value('domain'),
              permission: Value('WRITE'),
            ),
          );

      final results = await repo.getByWorkspace('ws-1');
      expect(results.first.permission, MemoryPermission.write);
    });
  });
}
