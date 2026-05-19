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

    group('edge cases', () {
      test('check returns read for empty grants list', () {
        expect(
          policy.check(
            grants: const [],
            role: AgentRole.ceo,
            domain: 'strategy',
          ),
          MemoryPermission.read,
        );
      });

      test('check returns none when grant specifies none', () {
        final grantsWithNone = [
          MemoryAccessGrant(
            workspaceId: 'ws-1',
            agentRole: AgentRole.ceo,
            memoryDomain: 'blocked',
            permission: MemoryPermission.none,
          ),
        ];
        expect(
          policy.check(
            grants: grantsWithNone,
            role: AgentRole.ceo,
            domain: 'blocked',
          ),
          MemoryPermission.none,
        );
      });

      test('canWrite returns false for none permission', () {
        final grantsWithNone = [
          MemoryAccessGrant(
            workspaceId: 'ws-1',
            agentRole: AgentRole.ceo,
            memoryDomain: 'blocked',
            permission: MemoryPermission.none,
          ),
        ];
        expect(
          policy.canWrite(
            grants: grantsWithNone,
            role: AgentRole.ceo,
            domain: 'blocked',
          ),
          isFalse,
        );
      });

      test('enforceWrite throws for none permission', () {
        final grantsWithNone = [
          MemoryAccessGrant(
            workspaceId: 'ws-1',
            agentRole: AgentRole.ceo,
            memoryDomain: 'blocked',
            permission: MemoryPermission.none,
          ),
        ];
        expect(
          () => policy.enforceWrite(
            grants: grantsWithNone,
            role: AgentRole.ceo,
            domain: 'blocked',
          ),
          throwsA(isA<InsufficientMemoryPermission>()),
        );
      });

      test('check uses first matching grant when duplicates exist', () {
        final duplicateGrants = [
          MemoryAccessGrant(
            workspaceId: 'ws-1',
            agentRole: AgentRole.ceo,
            memoryDomain: 'dupe',
            permission: MemoryPermission.write,
          ),
          MemoryAccessGrant(
            workspaceId: 'ws-2',
            agentRole: AgentRole.ceo,
            memoryDomain: 'dupe',
            permission: MemoryPermission.read,
          ),
        ];
        // firstOrNull picks the first match
        expect(
          policy.check(
            grants: duplicateGrants,
            role: AgentRole.ceo,
            domain: 'dupe',
          ),
          MemoryPermission.write,
        );
      });

      test('InsufficientMemoryPermission with none permission has correct fields', () {
        final grantsWithNone = [
          MemoryAccessGrant(
            workspaceId: 'ws-1',
            agentRole: AgentRole.devops,
            memoryDomain: 'blocked',
            permission: MemoryPermission.none,
          ),
        ];
        try {
          policy.enforceWrite(
            grants: grantsWithNone,
            role: AgentRole.devops,
            domain: 'blocked',
          );
        } on InsufficientMemoryPermission catch (e) {
          expect(e.agentRole, AgentRole.devops);
          expect(e.domain, 'blocked');
          expect(e.required, MemoryPermission.write);
          expect(e.actual, MemoryPermission.none);
          expect(e.toString(), contains('devops'));
          expect(e.toString(), contains('none'));
        }
      });

      test('canWrite returns false for unconfigured role/domain', () {
        expect(
          policy.canWrite(grants: grants, role: AgentRole.coder, domain: 'strategy'),
          isFalse,
        );
      });

      test('enforceWrite throws for unconfigured role/domain', () {
        expect(
          () => policy.enforceWrite(
            grants: grants, role: AgentRole.coder, domain: 'strategy',
          ),
          throwsA(isA<InsufficientMemoryPermission>()),
        );
      });

      test('canWrite returns false for empty grants list', () {
        expect(
          policy.canWrite(
            grants: const [],
            role: AgentRole.ceo,
            domain: 'strategy',
          ),
          isFalse,
        );
      });

      test('enforceWrite throws for empty grants list', () {
        expect(
          () => policy.enforceWrite(
            grants: const [],
            role: AgentRole.ceo,
            domain: 'strategy',
          ),
          throwsA(isA<InsufficientMemoryPermission>()),
        );
      });
    });
  });
}
