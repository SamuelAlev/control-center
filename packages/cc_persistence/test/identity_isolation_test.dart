import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Workspace isolation for the identity tables: members, invites, repo grants
/// and the audit trail are workspace-scoped — a query for one workspace must
/// never surface another's rows (the CLAUDE.md invariant: every new scoped
/// surface ships a cross-workspace denial test).
///
/// After the database split there are TWO mechanisms to hold, and this file
/// checks both, because each catches a different bug:
///
///  * **Routing** — a row written for `ws-b` lands in `ws-b`'s own database
///    file, so `ws-a`'s connection cannot see it at all. This is what the
///    production path exercises, and it is what makes the isolation structural.
///  * **Filtering** — every one of these DAO reads still carries
///    `WHERE workspace_id = ?`. It is now belt-and-braces, but it is the thing
///    that contains a row that was somehow stamped with the WRONG workspace id
///    (a bad mapper, a copied companion) inside an otherwise correct file.
///
/// Identity also straddles the split: users and their preferences are global,
/// membership/invites/activity are per-workspace.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in ['ws-a', 'ws-b']) {
      await seedTestWorkspace(global, dbs, ws);
    }
    for (final user in ['u-1', 'u-2']) {
      await global.userDao.upsert(
        UsersTableCompanion(
          id: Value(user),
          handle: Value(user),
          displayName: Value(user),
        ),
      );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test(
    'members: a workspace query never returns a foreign membership',
    () async {
      await dbs
          .of('ws-a')
          .workspaceMemberDao
          .upsert(
            const WorkspaceMembersTableCompanion(
              id: Value('m-a'),
              workspaceId: Value('ws-a'),
              userId: Value('u-1'),
              role: Value('member'),
            ),
          );
      await dbs
          .of('ws-b')
          .workspaceMemberDao
          .upsert(
            const WorkspaceMembersTableCompanion(
              id: Value('m-b'),
              workspaceId: Value('ws-b'),
              userId: Value('u-2'),
              role: Value('admin'),
            ),
          );

      final a = await dbs.of('ws-a').workspaceMemberDao.getForWorkspace('ws-a');
      expect(a.map((m) => m.id), ['m-a']);
      // An id-only lookup is scoped too: u-2's membership in ws-b is not
      // reachable through ws-a.
      expect(
        await dbs.of('ws-a').workspaceMemberDao.getMember('ws-a', 'u-2'),
        isNull,
      );
    },
  );

  test(
    'members: a row mis-stamped with a foreign workspace id is filtered out',
    () async {
      // The row is in ws-a's FILE but claims ws-b. Routing cannot save us here —
      // only the WHERE clause can, so this pins that it is still there.
      await dbs
          .of('ws-a')
          .workspaceMemberDao
          .upsert(
            const WorkspaceMembersTableCompanion(
              id: Value('m-mislabelled'),
              workspaceId: Value('ws-b'),
              userId: Value('u-1'),
              role: Value('member'),
            ),
          );

      expect(
        await dbs.of('ws-a').workspaceMemberDao.getForWorkspace('ws-a'),
        isEmpty,
      );
      expect(
        await dbs.of('ws-a').workspaceMemberDao.getMember('ws-a', 'u-1'),
        isNull,
      );
    },
  );

  test('invites: listing is workspace-scoped; deletion is too', () async {
    for (final (id, ws) in [('i-a', 'ws-a'), ('i-b', 'ws-b')]) {
      await dbs
          .of(ws)
          .workspaceInviteDao
          .upsert(
            WorkspaceInvitesTableCompanion(
              id: Value(id),
              workspaceId: Value(ws),
              codeHash: Value('hash-$id'),
              createdBy: const Value('u-1'),
              expiresAt: Value(DateTime(2027)),
            ),
          );
    }
    final a = await dbs.of('ws-a').workspaceInviteDao.getForWorkspace('ws-a');
    expect(a.map((i) => i.id), ['i-a']);

    // Deleting a foreign invite through the wrong workspace is a no-op — the
    // row survives (and here it is not even in the file being deleted from).
    expect(
      await dbs.of('ws-a').workspaceInviteDao.deleteInvite('ws-a', 'i-b'),
      0,
    );
    expect(
      await dbs.of('ws-b').workspaceInviteDao.getForWorkspace('ws-b'),
      hasLength(1),
    );
  });

  test('repo grants: reads and removals are workspace-scoped', () async {
    for (final ws in ['ws-a', 'ws-b']) {
      // A repo can be checked out in several workspaces, so each workspace file
      // carries its own row for it.
      await dbs
          .of(ws)
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'r-1', name: 'one', path: '/r/1'),
          );
    }
    for (final (id, ws) in [('g-a', 'ws-a'), ('g-b', 'ws-b')]) {
      await dbs
          .of(ws)
          .workspaceMemberDao
          .upsertRepoGrant(
            WorkspaceMemberRepoGrantsTableCompanion(
              id: Value(id),
              workspaceId: Value(ws),
              userId: const Value('u-1'),
              repoId: const Value('r-1'),
              level: const Value('read'),
            ),
          );
    }
    final a = await dbs
        .of('ws-a')
        .workspaceMemberDao
        .getRepoGrants('ws-a', 'u-1');
    expect(a.map((g) => g.id), ['g-a']);
    expect(
      await dbs
          .of('ws-a')
          .workspaceMemberDao
          .removeRepoGrant('ws-a', 'u-1', 'r-1'),
      1,
    );
    // ws-b's grant is untouched.
    expect(
      await dbs.of('ws-b').workspaceMemberDao.getRepoGrants('ws-b', 'u-1'),
      hasLength(1),
    );
  });

  test('audit trail: reads are workspace-scoped', () async {
    for (final (id, ws) in [('e-a', 'ws-a'), ('e-b', 'ws-b')]) {
      await dbs
          .of(ws)
          .userActivityDao
          .append(
            UserActivityTableCompanion(
              id: Value(id),
              workspaceId: Value(ws),
              userId: const Value('u-1'),
              action: const Value('tickets.assign'),
            ),
          );
    }
    final a = await dbs.of('ws-a').userActivityDao.getForWorkspace('ws-a');
    expect(a.map((e) => e.id), ['e-a']);
  });

  test(
    'user preferences are keyed per user, never leaking across users',
    () async {
      // Preferences are GLOBAL: one human carries one set of preferences across
      // every workspace, so these live in global.db and are keyed by user only.
      await global.userPreferenceDao.setValue('u-1', 'theme_mode', 'dark');
      await global.userPreferenceDao.setValue('u-2', 'theme_mode', 'light');
      expect(
        await global.userPreferenceDao.getValue('u-1', 'theme_mode'),
        'dark',
      );
      expect(
        await global.userPreferenceDao.getValue('u-2', 'theme_mode'),
        'light',
      );
      final u1 = await global.userPreferenceDao.getForUser('u-1');
      expect(u1.map((p) => p.value), ['dark']);
    },
  );
}
