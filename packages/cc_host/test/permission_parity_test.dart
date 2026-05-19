import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/services/permission_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// The safety argument for moving the human lane onto a permission catalog.
///
/// The cutover is only safe if it changes NO answer: for every op and every
/// built-in preset, `can(preset, op.permission)` must equal the role-floor
/// check the dispatcher has always run. Once this is green, divergence from
/// the old model is deliberate (a custom role denying a permission), never
/// accidental.
void main() {
  const resolver = PermissionResolver();

  PermissionPrincipal principal(
    WorkspaceRole role, {
    Map<String, RepoGrantLevel> grants = const {},
  }) => PermissionPrincipal(
    userId: 'u1',
    role: RoleDefinition.preset(role),
    repoGrants: grants,
  );

  RepoOp op(
    String name, {
    RepoOpKind kind = RepoOpKind.read,
    WorkspaceRole? minRole,
  }) => RepoOp(
    name: name,
    kind: kind,
    minRole: minRole,
    handler: (_) async => const {},
  );

  group('permission derivation mirrors the role floor', () {
    test('kind alone derives the tier', () {
      expect(op('tickets.list').permission.wire, 'tickets:read');
      expect(
        op('tickets.assign', kind: RepoOpKind.mutate).permission.wire,
        'tickets:write',
      );
      expect(
        op('skills.uninstall', kind: RepoOpKind.destructive).permission.wire,
        'skills:administer',
      );
    });

    test('an explicit minRole raises the tier', () {
      expect(
        op(
          'action_policy.upsert',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.admin,
        ).permission.wire,
        'action_policy:administer',
      );
      // A read raised to member is a WRITE-tier permission: the tier tracks
      // the privilege required, not the verb.
      expect(
        op('action_policy.list', minRole: WorkspaceRole.member).permission.wire,
        'action_policy:write',
      );
    });

    test('owner-floored ops land on the own tier, NOT administer', () {
      // Collapsing owner into `administer` would hand every admin a
      // permission the dispatcher refuses them — the parity matrix below
      // caught exactly that widening.
      expect(
        op(
          'workspace.transferOwnership',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.owner,
        ).permission.tier,
        PermissionTier.own,
      );
      expect(
        const Permission('workspace', PermissionTier.own).impliedMinRole,
        WorkspaceRole.owner,
      );
    });

    test('the domain is the op-name prefix', () {
      expect(op('pr_review.watchDiff').permission.domain, 'pr_review');
      expect(op('healthz').permission.domain, 'healthz');
    });
  });

  group('preset parity: can() == role.atLeast(floor)', () {
    // A representative matrix over every (kind × explicit floor) combination
    // the catalog actually uses. The property is checked for every preset.
    final ops = <RepoOp>[
      op('tickets.list'),
      op('tickets.create', kind: RepoOpKind.mutate),
      op('skills.uninstall', kind: RepoOpKind.destructive),
      op('space_read.markSpaceRead',
          kind: RepoOpKind.mutate, minRole: WorkspaceRole.guest),
      op('action_policy.list', minRole: WorkspaceRole.member),
      op('members.setRole',
          kind: RepoOpKind.mutate, minRole: WorkspaceRole.admin),
      op('workspace.transferOwnership',
          kind: RepoOpKind.mutate, minRole: WorkspaceRole.owner),
    ];

    for (final o in ops) {
      for (final role in WorkspaceRole.values) {
        test('${o.name} × ${role.wireName}', () {
          final legacy = role.atLeast(o.effectiveMinRole);
          final viaCatalog = resolver.allows(principal(role), o.permission);
          expect(
            viaCatalog,
            legacy,
            reason:
                'catalog says $viaCatalog, role floor says $legacy for '
                '${o.name} (floor ${o.effectiveMinRole.wireName}, '
                'permission ${o.permission.wire})',
          );
        });
      }
    }

    test('a non-member is refused everything', () {
      const nobody = PermissionPrincipal(userId: 'u1', role: null);
      for (final o in ops) {
        final verdict = resolver.can(nobody, o.permission);
        expect(verdict.allowed, isFalse);
        expect(verdict.source, PermissionSource.membership);
      }
    });
  });

  group('repo grants mirror the dispatcher gate', () {
    final codeOp = op('repos.readFile');

    test('a member without a grant is refused', () {
      final verdict = resolver.can(
        principal(WorkspaceRole.member),
        codeOp.permission,
        resource: const ResourceRef.repo('r1'),
      );
      expect(verdict.allowed, isFalse);
      expect(verdict.source, PermissionSource.grant);
    });

    test('a member with a read grant passes', () {
      final verdict = resolver.can(
        principal(
          WorkspaceRole.member,
          grants: const {'r1': RepoGrantLevel.read},
        ),
        codeOp.permission,
        resource: const ResourceRef.repo('r1'),
      );
      expect(verdict.allowed, isTrue);
    });

    test('a grant on another repo does not carry over', () {
      final verdict = resolver.can(
        principal(
          WorkspaceRole.member,
          grants: const {'other': RepoGrantLevel.write},
        ),
        codeOp.permission,
        resource: const ResourceRef.repo('r1'),
      );
      expect(verdict.allowed, isFalse);
    });

    test('admins hold every grant implicitly, exactly as the gate does', () {
      for (final role in [WorkspaceRole.admin, WorkspaceRole.owner]) {
        expect(
          resolver.allows(
            principal(role),
            codeOp.permission,
            resource: const ResourceRef.repo('r1'),
          ),
          isTrue,
        );
      }
    });

    test('a write-level resource needs a write grant', () {
      final read = principal(
        WorkspaceRole.member,
        grants: const {'r1': RepoGrantLevel.read},
      );
      expect(
        resolver.allows(
          read,
          codeOp.permission,
          resource: const ResourceRef.repo('r1', level: RepoGrantLevel.write),
        ),
        isFalse,
      );
    });
  });

  group('custom roles are subtractive and can never exceed their base', () {
    const denyPush = RoleDefinition(
      id: 'r-no-members',
      name: 'Admin without member management',
      basePreset: WorkspaceRole.admin,
      deniedPermissions: {'members:administer'},
      isCustom: true,
    );

    test('the denied permission is refused', () {
      const p = PermissionPrincipal(userId: 'u1', role: denyPush);
      expect(
        resolver.allows(p, const Permission('members', PermissionTier.administer)),
        isFalse,
      );
    });

    test('everything else the base grants still passes', () {
      const p = PermissionPrincipal(userId: 'u1', role: denyPush);
      expect(
        resolver.allows(p, const Permission('tickets', PermissionTier.write)),
        isTrue,
      );
      expect(
        resolver.allows(
          p,
          const Permission('action_policy', PermissionTier.administer),
        ),
        isTrue,
      );
    });

    test('a custom role NEVER grants above its base preset', () {
      // The property the whole design rests on: every hand-rolled
      // `role.isAdmin` check in the catalog stays a sound upper bound.
      const memberBased = RoleDefinition(
        id: 'r-member-plus',
        name: 'Member (attempted escalation)',
        basePreset: WorkspaceRole.member,
        isCustom: true,
      );
      const p = PermissionPrincipal(userId: 'u1', role: memberBased);
      expect(
        resolver.allows(
          p,
          const Permission('members', PermissionTier.administer),
        ),
        isFalse,
      );
    });

    test('the wire form round-trips through custom:<id>', () {
      expect(denyPush.wire, 'custom:r-no-members');
      expect(RoleDefinition.customIdOf('custom:r-no-members'), 'r-no-members');
      expect(RoleDefinition.customIdOf('admin'), isNull);
      // An old client meeting a custom role parses null and fails safe to
      // guest — that is what makes rollout safe.
      expect(WorkspaceRole.fromWire('custom:r-no-members'), isNull);
    });
  });
}
