import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises the identity repositories backed by the identity DAOs against the
/// real Drift database: users, workspace memberships, invites, user activity,
/// and per-user preferences. Each repository is a thin mapper+delegate; these
/// tests assert the round-trip through the domain entities and the
/// workspace-scoped reads.
void main() {
  // Identity straddles the split: users and their preferences are GLOBAL (one
  // human is one user across every workspace), while membership, invites and
  // activity are per-workspace and live in the workspace's own file.
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoUserRepository userRepo;
  late DaoWorkspaceMembershipRepository memberRepo;
  late DaoWorkspaceInviteRepository inviteRepo;
  late DaoUserActivityRepository activityRepo;
  late DaoUserPreferencesRepository prefRepo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    userRepo = DaoUserRepository(global.userDao);
    memberRepo = DaoWorkspaceMembershipRepository(dbs);
    inviteRepo = DaoWorkspaceInviteRepository(dbs, global.workspaceRouteDao);
    activityRepo = DaoUserActivityRepository(dbs);
    prefRepo = DaoUserPreferencesRepository(global.userPreferenceDao);
    for (final u in ['u-1', 'u-2']) {
      await userRepo.upsert(
        User(
          id: u,
          handle: u,
          displayName: 'User $u',
          email: '$u@example.com',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoUserRepository', () {
    test('upsert + getAll round-trips the entity', () async {
      final users = await userRepo.getAll();
      expect(users.map((u) => u.id).toSet(), {'u-1', 'u-2'});
      expect(users.first.displayName, 'User u-1');
    });

    test('getById returns the user or null', () async {
      expect((await userRepo.getById('u-1'))?.handle, 'u-1');
      expect(await userRepo.getById('nope'), isNull);
    });

    test('getByHandle resolves a user', () async {
      expect((await userRepo.getByHandle('u-2'))?.id, 'u-2');
      expect(await userRepo.getByHandle('missing'), isNull);
    });

    test('getByEmail resolves a user', () async {
      expect((await userRepo.getByEmail('u-1@example.com'))?.id, 'u-1');
      expect(await userRepo.getByEmail('missing@x.com'), isNull);
    });

    test('upsert replaces on the same id', () async {
      await userRepo.upsert(
        User(
          id: 'u-1',
          handle: 'u-1',
          displayName: 'Renamed',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect((await userRepo.getById('u-1'))?.displayName, 'Renamed');
    });

    test('count returns the number of users', () async {
      expect(await userRepo.count(), 2);
    });

    test('watchAll emits live updates', () async {
      expect((await userRepo.watchAll().first).map((u) => u.id).toSet(), {
        'u-1',
        'u-2',
      });
    });
  });

  group('DaoWorkspaceMembershipRepository', () {
    WorkspaceMember member(
      String id,
      String ws,
      String userId, {
      WorkspaceRole role = WorkspaceRole.member,
    }) => WorkspaceMember(
      id: id,
      workspaceId: ws,
      userId: userId,
      role: role,
      joinedAt: DateTime.utc(2026, 1, 2),
    );

    test('upsert + getForWorkspace round-trips the entity', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      final rows = await memberRepo.getForWorkspace('w-1');
      expect(rows.single.id, 'm-1');
      expect(rows.single.role, WorkspaceRole.member);
    });

    test('getForWorkspace is workspace-scoped', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      await memberRepo.upsert(member('m-2', 'w-2', 'u-2'));
      expect((await memberRepo.getForWorkspace('w-1')).single.id, 'm-1');
      expect((await memberRepo.getForWorkspace('w-2')).single.id, 'm-2');
    });

    test('watchForWorkspace emits only the workspace rows', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      await memberRepo.upsert(member('m-2', 'w-2', 'u-2'));
      expect(
        (await memberRepo.watchForWorkspace('w-1').first).single.id,
        'm-1',
      );
    });

    test('getMember resolves one membership or null', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      expect((await memberRepo.getMember('w-1', 'u-1'))?.id, 'm-1');
      expect(await memberRepo.getMember('w-1', 'u-2'), isNull);
    });

    test('getForUser lists memberships across workspaces', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      await memberRepo.upsert(member('m-2', 'w-2', 'u-1'));
      expect((await memberRepo.getForUser('u-1')).map((m) => m.id).toSet(), {
        'm-1',
        'm-2',
      });
    });

    test('setRole updates the membership role', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      await memberRepo.setRole('w-1', 'u-1', WorkspaceRole.admin);
      expect(
        (await memberRepo.getMember('w-1', 'u-1'))?.role,
        WorkspaceRole.admin,
      );
    });

    test('remove deletes a membership', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      await memberRepo.remove('w-1', 'u-1');
      expect(await memberRepo.getMember('w-1', 'u-1'), isNull);
    });

    test('getRepoGrants returns empty when no grants exist', () async {
      await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
      expect(await memberRepo.getRepoGrants('w-1', 'u-1'), isEmpty);
    });

    test(
      'setRepoGrant with none removes the grant; otherwise upserts it',
      () async {
        // Seed a repo in w-1's own file so the grant FK is satisfied.
        final db = dbs.of('w-1');
        await db
            .into(db.reposTable)
            .insert(
              ReposTableCompanion.insert(id: 'r-1', name: 'one', path: '/r/1'),
            );
        await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));

        await memberRepo.setRepoGrant(
          'w-1',
          'u-1',
          'r-1',
          RepoGrantLevel.write,
        );
        expect(await memberRepo.getRepoGrants('w-1', 'u-1'), {
          'r-1': RepoGrantLevel.write,
        });

        // Setting back to none removes the row.
        await memberRepo.setRepoGrant('w-1', 'u-1', 'r-1', RepoGrantLevel.none);
        expect(await memberRepo.getRepoGrants('w-1', 'u-1'), isEmpty);
      },
    );
  });

  group('DaoWorkspaceInviteRepository', () {
    final expiresAt = DateTime.utc(2027, 1, 1);

    WorkspaceInvite invite(
      String id,
      String ws, {
      String codeHash = 'hash',
      WorkspaceRole role = WorkspaceRole.member,
      Map<String, RepoGrantLevel> repoGrants = const {},
    }) => WorkspaceInvite(
      id: id,
      workspaceId: ws,
      codeHash: codeHash,
      role: role,
      repoGrants: repoGrants,
      createdBy: 'u-1',
      createdAt: DateTime.utc(2026, 1, 1),
      expiresAt: expiresAt,
    );

    test('upsert + getForWorkspace round-trips the entity', () async {
      await inviteRepo.upsert(
        invite(
          'i-1',
          'w-1',
          codeHash: 'hash-1',
          repoGrants: {'r-1': RepoGrantLevel.read},
        ),
      );
      final rows = await inviteRepo.getForWorkspace('w-1');
      expect(rows.single.id, 'i-1');
      expect(rows.single.codeHash, 'hash-1');
      expect(rows.single.repoGrants, {'r-1': RepoGrantLevel.read});
    });

    test('getForWorkspace is workspace-scoped', () async {
      await inviteRepo.upsert(invite('i-1', 'w-1', codeHash: 'h-1'));
      await inviteRepo.upsert(invite('i-2', 'w-2', codeHash: 'h-2'));
      expect((await inviteRepo.getForWorkspace('w-1')).single.id, 'i-1');
      expect((await inviteRepo.getForWorkspace('w-2')).single.id, 'i-2');
    });

    test('watchForWorkspace emits only the workspace rows', () async {
      await inviteRepo.upsert(invite('i-1', 'w-1', codeHash: 'h-1'));
      await inviteRepo.upsert(invite('i-2', 'w-2', codeHash: 'h-2'));
      expect(
        (await inviteRepo.watchForWorkspace('w-1').first).single.id,
        'i-1',
      );
    });

    test('getByCodeHash resolves an invite or null', () async {
      await inviteRepo.upsert(invite('i-1', 'w-1', codeHash: 'h-1'));
      expect((await inviteRepo.getByCodeHash('h-1'))?.id, 'i-1');
      expect(await inviteRepo.getByCodeHash('missing'), isNull);
    });

    test('delete removes the invite', () async {
      await inviteRepo.upsert(invite('i-1', 'w-1', codeHash: 'h-1'));
      await inviteRepo.delete('w-1', 'i-1');
      expect(await inviteRepo.getForWorkspace('w-1'), isEmpty);
    });
  });

  group('DaoUserActivityRepository', () {
    test('append + getForWorkspace round-trips the entity', () async {
      await activityRepo.append(
        UserActivityEntry(
          id: 'a-1',
          workspaceId: 'w-1',
          userId: 'u-1',
          action: 'ticket.upsert',
          targetType: 'ticket',
          targetId: 't-1',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      );
      final rows = await activityRepo.getForWorkspace('w-1');
      expect(rows.single.id, 'a-1');
      expect(rows.single.action, 'ticket.upsert');
      expect(rows.single.targetType, 'ticket');
    });

    test('getForWorkspace is workspace-scoped', () async {
      await activityRepo.append(
        UserActivityEntry(
          id: 'a-1',
          workspaceId: 'w-1',
          userId: 'u-1',
          action: 'ticket.upsert',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      );
      await activityRepo.append(
        UserActivityEntry(
          id: 'a-2',
          workspaceId: 'w-2',
          userId: 'u-2',
          action: 'ticket.upsert',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      );
      expect((await activityRepo.getForWorkspace('w-1')).single.id, 'a-1');
      expect((await activityRepo.getForWorkspace('w-2')).single.id, 'a-2');
    });

    test('getForWorkspace honors the limit', () async {
      for (var i = 0; i < 5; i++) {
        await activityRepo.append(
          UserActivityEntry(
            id: 'a-$i',
            workspaceId: 'w-1',
            userId: 'u-1',
            action: 'op.$i',
            createdAt: DateTime.utc(2026, 1, 3, 0, i),
          ),
        );
      }
      expect((await activityRepo.getForWorkspace('w-1', limit: 2)).length, 2);
    });

    test('watchForWorkspace emits only the workspace rows', () async {
      await activityRepo.append(
        UserActivityEntry(
          id: 'a-1',
          workspaceId: 'w-1',
          userId: 'u-1',
          action: 'ticket.upsert',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      );
      expect(
        (await activityRepo.watchForWorkspace('w-1').first).single.id,
        'a-1',
      );
    });
  });

  group('DaoUserPreferencesRepository', () {
    test('set + get round-trips a value', () async {
      await prefRepo.set('u-1', 'theme', 'dark');
      expect(await prefRepo.get('u-1', 'theme'), 'dark');
    });

    test('get returns null for an unknown key', () async {
      expect(await prefRepo.get('u-1', 'missing'), isNull);
    });

    test('set with null deletes the value', () async {
      await prefRepo.set('u-1', 'theme', 'dark');
      await prefRepo.set('u-1', 'theme', null);
      expect(await prefRepo.get('u-1', 'theme'), isNull);
    });

    test('getAll returns all keys for the user', () async {
      await prefRepo.set('u-1', 'theme', 'dark');
      await prefRepo.set('u-1', 'font', 'mono');
      final all = await prefRepo.getAll('u-1');
      expect(all, {'theme': 'dark', 'font': 'mono'});
    });

    test('watchAll emits the live preferences map', () async {
      await prefRepo.set('u-1', 'theme', 'dark');
      expect(await prefRepo.watchAll('u-1').first, {'theme': 'dark'});
    });

    // The store is an opaque, client-defined key space, every row is streamed
    // back in full to every signed-in device by `prefs.watchOwn` and it lives
    // in the one database the server always has open. Unbounded writes are a
    // denial-of-service on every workspace at once.
    group('quotas', () {
      test('accepts a value at the byte limit', () async {
        final atLimit = 'x' * DaoUserPreferencesRepository.maxValueBytes;
        await prefRepo.set('u-1', 'big', atLimit);
        expect(await prefRepo.get('u-1', 'big'), atLimit);
      });

      test('rejects a value over the byte limit', () async {
        final tooBig = 'x' * (DaoUserPreferencesRepository.maxValueBytes + 1);
        await expectLater(
          prefRepo.set('u-1', 'big', tooBig),
          throwsA(isA<ValidationException>()),
        );
        expect(await prefRepo.get('u-1', 'big'), isNull);
      });

      test('measures the limit in UTF-8 bytes, not code units', () async {
        // 'é' is one code unit but two UTF-8 bytes, so a string of half the
        // limit in characters is exactly at the limit in bytes.
        final overInBytes =
            'é' * (DaoUserPreferencesRepository.maxValueBytes ~/ 2 + 1);
        expect(
          overInBytes.length,
          lessThan(DaoUserPreferencesRepository.maxValueBytes),
        );
        await expectLater(
          prefRepo.set('u-1', 'accents', overInBytes),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects an empty key', () async {
        await expectLater(
          prefRepo.set('u-1', '', 'v'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects a new key once the per-user key cap is reached', () async {
        for (var i = 0; i < DaoUserPreferencesRepository.maxKeysPerUser; i++) {
          await prefRepo.set('u-1', 'k$i', 'v');
        }
        await expectLater(
          prefRepo.set('u-1', 'one-too-many', 'v'),
          throwsA(isA<ValidationException>()),
        );
      });

      test(
        'an at-quota user can still edit and delete existing keys',
        () async {
          for (
            var i = 0;
            i < DaoUserPreferencesRepository.maxKeysPerUser;
            i++
          ) {
            await prefRepo.set('u-1', 'k$i', 'v');
          }
          // Overwriting an existing key does not grow the row count.
          await prefRepo.set('u-1', 'k0', 'updated');
          expect(await prefRepo.get('u-1', 'k0'), 'updated');
          // And deleting frees a slot.
          await prefRepo.set('u-1', 'k0', null);
          await prefRepo.set('u-1', 'fresh', 'v');
          expect(await prefRepo.get('u-1', 'fresh'), 'v');
        },
      );

      test('the key cap is per user, not global', () async {
        for (var i = 0; i < DaoUserPreferencesRepository.maxKeysPerUser; i++) {
          await prefRepo.set('u-1', 'k$i', 'v');
        }
        await prefRepo.set('u-2', 'mine', 'v');
        expect(await prefRepo.get('u-2', 'mine'), 'v');
      });
    });
  });
}
