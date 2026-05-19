import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryAccessGrant', () {
    test('constructor creates with required fields', () {
      final grant = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.write,
      );

      expect(grant.workspaceId, 'ws-1');
      expect(grant.agentRole, AgentRole.ceo);
      expect(grant.memoryDomain, 'strategy');
      expect(grant.permission, MemoryPermission.write);
    });

    test('constructor asserts workspaceId not empty', () {
      expect(
        () => MemoryAccessGrant(
          workspaceId: '',
          agentRole: AgentRole.general,
          memoryDomain: 'process',
          permission: MemoryPermission.read,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality works correctly', () {
      final a = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.write,
      );
      final b = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.write,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different permissions are not equal', () {
      final a = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.write,
      );
      final b = MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.read,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
