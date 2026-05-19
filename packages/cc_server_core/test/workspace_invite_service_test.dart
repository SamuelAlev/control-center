import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:test/test.dart';
import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// `ws-1`'s own database — invites, memberships and repo grants live there;
  /// only the user directory and the invite→workspace route are global.
  late WorkspaceDatabase db;
  late WorkspaceInviteService service;
  late DateTime now;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1', name: 'One');
    db = dbs.of('ws-1');
    now = DateTime(2026, 7, 7, 12);
    service = WorkspaceInviteService(
      invites: DaoWorkspaceInviteRepository(dbs, global.workspaceRouteDao),
      members: DaoWorkspaceMembershipRepository(dbs),
      users: DaoUserRepository(global.userDao),
      now: () => now,
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test(
    'creating an invite stores only the code hash, never the code',
    () async {
      final created = await service.create(
        workspaceId: 'ws-1',
        createdBy: 'owner-1',
        role: WorkspaceRole.member,
      );
      expect(created.code, isNotEmpty);
      final rows = await db.workspaceInviteDao.getForWorkspace('ws-1');
      expect(rows.single.codeHash, isNot(contains(created.code)));
      expect(
        rows.single.codeHash,
        WorkspaceInviteService.hashInviteCode(created.code),
      );
    },
  );

  test('an owner-role invite is refused', () {
    expect(
      () => service.create(
        workspaceId: 'ws-1',
        createdBy: 'owner-1',
        role: WorkspaceRole.owner,
      ),
      throwsArgumentError,
    );
  });

  test(
    'redeeming JIT-provisions the user, membership, and repo grants',
    () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'repo-9', name: 'nine', path: '/r/nine'),
      );
      final created = await service.create(
        workspaceId: 'ws-1',
        createdBy: 'owner-1',
        role: WorkspaceRole.viewer,
        repoGrants: {'repo-9': RepoGrantLevel.read},
      );
      final redeemed = await service.redeem(
        code: created.code,
        displayName: 'Noor',
        email: 'noor@example.com',
      );
      expect(redeemed.user.displayName, 'Noor');
      expect(redeemed.member.role, WorkspaceRole.viewer);
      expect(redeemed.member.workspaceId, 'ws-1');

      final grants = await db.workspaceMemberDao.getRepoGrants(
        'ws-1',
        redeemed.user.id,
      );
      expect(grants.single.repoId, 'repo-9');
      expect(grants.single.level, 'read');

      // Marked used — a second redemption of the same code is refused.
      expect(
        () => service.redeem(code: created.code, displayName: 'Eve'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test('an expired invite is refused with a generic denial', () async {
    final created = await service.create(
      workspaceId: 'ws-1',
      createdBy: 'owner-1',
      role: WorkspaceRole.member,
      ttl: const Duration(hours: 1),
    );
    now = now.add(const Duration(hours: 2));
    expect(
      () => service.redeem(code: created.code, displayName: 'Late'),
      throwsA(isA<AuthException>()),
    );
  });

  test('a revoked invite is refused', () async {
    final created = await service.create(
      workspaceId: 'ws-1',
      createdBy: 'owner-1',
      role: WorkspaceRole.member,
    );
    await service.revoke('ws-1', created.invite.id);
    expect(
      () => service.redeem(code: created.code, displayName: 'Revoked'),
      throwsA(isA<AuthException>()),
    );
  });

  test('a bogus code is refused without an existence oracle', () async {
    expect(
      () => service.redeem(code: 'not-a-real-code', displayName: 'Eve'),
      throwsA(isA<AuthException>()),
    );
  });

  test('handles are deduplicated on JIT provisioning', () async {
    for (var i = 0; i < 2; i++) {
      final created = await service.create(
        workspaceId: 'ws-1',
        createdBy: 'owner-1',
        role: WorkspaceRole.member,
      );
      await service.redeem(code: created.code, handle: 'Sam');
    }
    final users = await global.userDao.getAll();
    expect(users.map((u) => u.handle).toSet(), {'sam', 'sam2'});
  });
}
