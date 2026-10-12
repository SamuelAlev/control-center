import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
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

  test('public invite routing never exposes the Noise PSK', () async {
    final created = await service.create(
      workspaceId: 'ws-1',
      createdBy: 'owner-1',
      role: WorkspaceRole.member,
    );
    final hash = WorkspaceInviteService.hashInviteCode(created.code);
    expect(InvitePairingProof.codeHash(created.code), hash);
    final routeId = InvitePairingProof.routeIdFromHash(hash);
    final psk = InvitePairingProof.pskFromHash(hash);
    expect(routeId, isNot(hash));
    expect(psk, isNot(created.code));
    expect(await service.resolveInvitePsk(routeId), psk);
    expect(await service.resolveInvitePsk(hash), isNull);
    expect(await service.resolveInvitePsk('0' * 64), isNull);

    await service.redeem(code: created.code);
    expect(await service.resolveInvitePsk(routeId), isNull);
  });

  test('secure route closes for expired and revoked invites', () async {
    final expires = await service.create(
      workspaceId: 'ws-1',
      createdBy: 'owner-1',
      role: WorkspaceRole.member,
      ttl: const Duration(hours: 1),
    );
    final revoked = await service.create(
      workspaceId: 'ws-1',
      createdBy: 'owner-1',
      role: WorkspaceRole.member,
    );
    final expiresId = InvitePairingProof.routeIdFromHash(
      WorkspaceInviteService.hashInviteCode(expires.code),
    );
    final revokedId = InvitePairingProof.routeIdFromHash(
      WorkspaceInviteService.hashInviteCode(revoked.code),
    );
    await service.revoke('ws-1', revoked.invite.id);
    expect(await service.resolveInvitePsk(revokedId), isNull);
    now = now.add(const Duration(hours: 2));
    expect(await service.resolveInvitePsk(expiresId), isNull);
  });

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
    'redeeming JIT-provisions the user, membership and repo grants',
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

  test(
    'concurrent redemption provisions only one membership and user',
    () async {
      final created = await service.create(
        workspaceId: 'ws-1',
        createdBy: 'owner-1',
        role: WorkspaceRole.admin,
      );
      final results = await Future.wait([
        for (final name in ['First', 'Second'])
          service
              .redeem(code: created.code, displayName: name)
              .then<Object>(
                (result) => result,
                onError: (Object error) => error,
              ),
      ]);
      expect(results.whereType<RedeemedInvite>(), hasLength(1));
      expect(results.whereType<AuthException>(), hasLength(1));
      final admitted = results.whereType<RedeemedInvite>().single;
      final stored = (await db.workspaceInviteDao.getForWorkspace(
        'ws-1',
      )).single;
      expect(stored.usedBy, admitted.user.id);
      expect(stored.usedAt, isNotNull);
      expect((await global.userDao.getAll()).map((user) => user.id), [
        admitted.user.id,
      ]);
      expect(
        (await db.workspaceMemberDao.getForWorkspace(
          'ws-1',
        )).map((member) => member.userId),
        [admitted.user.id],
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
