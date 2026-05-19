import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:test/test.dart';

/// Unit coverage for the passive repo-RPC declaration types ([RepoOp],
/// [RepoOpContext], [RepoOpRegistry]): the derived role/undo floors, the
/// dry-run preview flag, and the `op/list` catalog shape. The active dispatch
/// behavior is covered in `repo_op_dispatcher_test.dart`.
void main() {
  group('RepoOpContext', () {
    test(
      'principal resolves to a UserPrincipal carrying the session userId',
      () {
        const ctx = RepoOpContext(
          args: {'workspace_id': 'ws-1'},
          workspaceId: 'ws-1',
          deviceId: 'device-1',
          userId: 'user-1',
        );
        expect(ctx.principal, isA<UserPrincipal>());
        expect((ctx.principal as UserPrincipal).id, 'user-1');
      },
    );

    test('a global op carries no workspace and no role', () {
      const ctx = RepoOpContext(
        args: {},
        workspaceId: null,
        deviceId: 'device-1',
        userId: 'user-1',
        role: null,
      );
      expect(ctx.workspaceId, isNull);
      expect(ctx.role, isNull);
    });
  });

  group('RepoOp derived floors', () {
    test('effectiveMinRole derives from kind when no minRole is set', () {
      expect(
        const RepoOp(
          name: 'r',
          kind: RepoOpKind.read,
          handler: emptyHandler,
        ).effectiveMinRole,
        WorkspaceRole.guest,
      );
      expect(
        const RepoOp(
          name: 'm',
          kind: RepoOpKind.mutate,
          handler: emptyHandler,
        ).effectiveMinRole,
        WorkspaceRole.member,
      );
      expect(
        const RepoOp(
          name: 'd',
          kind: RepoOpKind.destructive,
          handler: emptyHandler,
        ).effectiveMinRole,
        WorkspaceRole.admin,
      );
    });

    test('effectiveMinRole prefers an explicit minRole over the kind floor', () {
      const op = RepoOp(
        name: 'settings.update',
        // kind says member, but an explicit admin floor wins (settings mutation).
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.admin,
        handler: emptyHandler,
      );
      expect(op.effectiveMinRole, WorkspaceRole.admin);
    });

    test('effectiveUndoClass defaults to irreversible (fail-safe)', () {
      expect(
        const RepoOp(
          name: 'r',
          kind: RepoOpKind.mutate,
          handler: emptyHandler,
        ).effectiveUndoClass,
        UndoClass.irreversible,
      );
    });

    test(
      'effectiveUndoClass honors a declared reversible/compensable class',
      () {
        expect(
          const RepoOp(
            name: 'r',
            kind: RepoOpKind.mutate,
            undoClass: UndoClass.reversible,
            handler: emptyHandler,
          ).effectiveUndoClass,
          UndoClass.reversible,
        );
        expect(
          const RepoOp(
            name: 'c',
            kind: RepoOpKind.mutate,
            undoClass: UndoClass.compensable,
            handler: emptyHandler,
          ).effectiveUndoClass,
          UndoClass.compensable,
        );
      },
    );

    test('supportsPreview is true only when a preview handler is declared', () {
      expect(
        const RepoOp(
          name: 'nopreview',
          kind: RepoOpKind.destructive,
          handler: emptyHandler,
        ).supportsPreview,
        isFalse,
      );
      final withPreview = RepoOp(
        name: 'haspreview',
        kind: RepoOpKind.destructive,
        preview: (_) async => const ActionPreview(summary: 'boom'),
        handler: emptyHandler,
      );
      expect(withPreview.supportsPreview, isTrue);
    });

    test('the default repoArg is "repo_id"', () {
      const op = RepoOp(
        name: 'r',
        kind: RepoOpKind.read,
        handler: emptyHandler,
      );
      expect(op.repoArg, 'repo_id');
    });
  });

  group('RepoOp fields', () {
    test('declared defaults match the documented contract', () {
      const op = RepoOp(
        name: 'thing.read',
        kind: RepoOpKind.read,
        handler: emptyHandler,
      );
      expect(op.version, 1);
      expect(op.requiredArgs, isEmpty);
      expect(op.workspaceScoped, isTrue);
      expect(op.requiredCapability, isNull);
      expect(op.minRole, isNull);
      expect(op.repoAccess, isNull);
      expect(op.undoClass, isNull);
      expect(op.preview, isNull);
      expect(op.actionClasses, isEmpty);
    });

    test('an op can declare the full privilege/repo/action surface', () {
      final op = RepoOp(
        name: 'pairing.mint',
        kind: RepoOpKind.destructive,
        version: 3,
        requiredArgs: const ['device_id'],
        workspaceScoped: false,
        requiredCapability: SessionCapability.fullClient,
        minRole: WorkspaceRole.admin,
        repoAccess: RepoGrantLevel.write,
        repoArg: 'repo',
        undoClass: UndoClass.reversible,
        actionClasses: const {ActionClass.gitPush},
        preview: (_) async => const ActionPreview(summary: 'minting'),
        handler: emptyHandler,
      );
      expect(op.version, 3);
      expect(op.requiredArgs, ['device_id']);
      expect(op.workspaceScoped, isFalse);
      expect(op.requiredCapability, SessionCapability.fullClient);
      expect(op.minRole, WorkspaceRole.admin);
      expect(op.repoAccess, RepoGrantLevel.write);
      expect(op.repoArg, 'repo');
      expect(op.undoClass, UndoClass.reversible);
      expect(op.actionClasses, {ActionClass.gitPush});
    });
  });

  group('RepoOpRegistry', () {
    test(
      'lookup returns the op and null for an unknown name (default-deny)',
      () {
        final registry = RepoOpRegistry([
          const RepoOp(
            name: 'tickets.get',
            kind: RepoOpKind.read,
            handler: emptyHandler,
          ),
        ]);
        expect(registry.lookup('tickets.get')?.name, 'tickets.get');
        expect(registry.lookup('tickets.nope'), isNull);
      },
    );

    test('catalogVersion is advertised from construction', () {
      final registry = RepoOpRegistry(const [], catalogVersion: 42);
      expect(registry.catalogVersion, 42);
    });

    test('ops exposes every declared op', () {
      final registry = RepoOpRegistry([
        const RepoOp(
          name: 'a.get',
          kind: RepoOpKind.read,
          handler: emptyHandler,
        ),
        const RepoOp(
          name: 'b.set',
          kind: RepoOpKind.mutate,
          handler: emptyHandler,
        ),
      ]);
      expect(registry.ops.map((o) => o.name).toList()..sort(), [
        'a.get',
        'b.set',
      ]);
    });

    test('describe serializes each op for op/list discovery', () {
      final registry = RepoOpRegistry([
        const RepoOp(
          name: 'tickets.get',
          kind: RepoOpKind.read,
          workspaceScoped: false,
          handler: emptyHandler,
        ),
        RepoOp(
          name: 'tickets.assign',
          kind: RepoOpKind.mutate,
          undoClass: UndoClass.reversible,
          preview: (_) async => const ActionPreview(summary: 'assign'),
          handler: emptyHandler,
        ),
      ], catalogVersion: 7);

      final described = registry.describe();
      expect(described, hasLength(2));

      final read = described.firstWhere((e) => e['op'] == 'tickets.get');
      expect(read['version'], 1);
      expect(read['kind'], 'read');
      expect(read['required_args'], isEmpty);
      expect(read['workspace_scoped'], isFalse);
      expect(read['min_role'], WorkspaceRole.guest.wireName);
      expect(read['undo_class'], UndoClass.irreversible.name);
      expect(read['supports_preview'], isFalse);

      final mutate = described.firstWhere((e) => e['op'] == 'tickets.assign');
      expect(mutate['kind'], 'mutate');
      expect(mutate['workspace_scoped'], isTrue);
      expect(mutate['min_role'], WorkspaceRole.member.wireName);
      expect(mutate['undo_class'], UndoClass.reversible.name);
      expect(mutate['supports_preview'], isTrue);
    });
  });
}

const emptyHandler = _emptyHandler;

Future<Map<String, dynamic>> _emptyHandler(RepoOpContext ctx) async => {};
