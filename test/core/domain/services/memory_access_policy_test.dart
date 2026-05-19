import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/services/memory_access_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryAccessPolicy', () {
    const policy = MemoryAccessPolicy();
    final grants = [
      MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'strategy',
        permission: MemoryPermission.write,
      ),
      MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.ceo,
        memoryDomain: 'tech-stack',
        permission: MemoryPermission.read,
      ),
      MemoryAccessGrant(
        workspaceId: 'ws-1',
        agentRole: AgentRole.devops,
        memoryDomain: 'tech-stack',
        permission: MemoryPermission.write,
      ),
    ];

    test('check returns correct permission', () {
      expect(
        policy.check(grants: grants, role: AgentRole.ceo, domain: 'strategy'),
        MemoryPermission.write,
      );
      expect(
        policy.check(grants: grants, role: AgentRole.ceo, domain: 'tech-stack'),
        MemoryPermission.read,
      );
    });

    test('check returns read for unconfigured role/domain', () {
      expect(
        policy.check(grants: grants, role: AgentRole.coder, domain: 'strategy'),
        MemoryPermission.read,
      );
    });

    test('canWrite returns true for write permission', () {
      expect(
        policy.canWrite(grants: grants, role: AgentRole.ceo, domain: 'strategy'),
        isTrue,
      );
    });

    test('canWrite returns false for read permission', () {
      expect(
        policy.canWrite(grants: grants, role: AgentRole.ceo, domain: 'tech-stack'),
        isFalse,
      );
    });

    test('enforceWrite succeeds for write permission', () {
      expect(
        () => policy.enforceWrite(
          grants: grants, role: AgentRole.ceo, domain: 'strategy',
        ),
        returnsNormally,
      );
    });

    test('enforceWrite throws for read permission', () {
      expect(
        () => policy.enforceWrite(
          grants: grants, role: AgentRole.ceo, domain: 'tech-stack',
        ),
        throwsA(isA<InsufficientMemoryPermission>()),
      );
    });

    test('InsufficientMemoryPermission has correct message', () {
      try {
        policy.enforceWrite(
          grants: grants, role: AgentRole.coder, domain: 'strategy',
        );
      } on InsufficientMemoryPermission catch (e) {
        expect(e.agentRole, AgentRole.coder);
        expect(e.domain, 'strategy');
        expect(e.required, MemoryPermission.write);
        expect(e.actual, MemoryPermission.read);
        expect(e.toString(), contains('coder'));
      }
    });
  });
}
