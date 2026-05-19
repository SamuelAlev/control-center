import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/mappers/memory_access_grant_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryAccessGrantMapper', () {
    const mapper = MemoryAccessGrantMapper();

    db.MemoryAccessGrantsTableData createRow({
      String workspaceId = 'ws1',
      String agentRole = 'coder',
      String memoryDomain = 'codebase',
      String permission = 'write',
    }) {
      return db.MemoryAccessGrantsTableData(
        workspaceId: workspaceId,
        agentRole: agentRole,
        memoryDomain: memoryDomain,
        permission: permission,
      );
    }

    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final row = createRow(
        workspaceId: 'ws-1',
        agentRole: 'coder',
        memoryDomain: 'preferences',
        permission: 'write',
      );

      final grant = mapper.toDomain(row);

      expect(grant.workspaceId, 'ws-1');
      expect(grant.agentRole, AgentRole.coder);
      expect(grant.memoryDomain, 'preferences');
      expect(grant.permission, MemoryPermission.write);
    });

    test('parses read permission', timeout: const Timeout.factor(2), () {
      final row = createRow(permission: 'read');

      final grant = mapper.toDomain(row);

      expect(grant.permission, MemoryPermission.read);
    });

    test('parses write permission', timeout: const Timeout.factor(2), () {
      final row = createRow(permission: 'write');

      final grant = mapper.toDomain(row);

      expect(grant.permission, MemoryPermission.write);
    });

    test('defaults to general role for unknown agent role', timeout: const Timeout.factor(2), () {
      final row = createRow(agentRole: 'unknown_role');

      final grant = mapper.toDomain(row);

      expect(grant.agentRole, AgentRole.general);
    });

    test('defaults to read permission for unknown permission string', timeout: const Timeout.factor(2), () {
      final row = createRow(permission: 'unknown_permission');

      final grant = mapper.toDomain(row);

      expect(grant.permission, MemoryPermission.read);
    });

    test('parses all agent roles', timeout: const Timeout.factor(2), () {
      for (final role in AgentRole.values) {
        final row = createRow(agentRole: role.name);
        final grant = mapper.toDomain(row);
        expect(grant.agentRole, role, reason: 'Failed for role: ${role.name}');
      }
    });

    test('is case-insensitive for agent role parsing', timeout: const Timeout.factor(2), () {
      final row = createRow(agentRole: 'CODER');

      final grant = mapper.toDomain(row);

      expect(grant.agentRole, AgentRole.coder);
    });

    test('is case-insensitive for permission parsing', timeout: const Timeout.factor(2), () {
      final row = createRow(permission: 'WRITE');

      final grant = mapper.toDomain(row);

      expect(grant.permission, MemoryPermission.write);
    });
  });
}
