import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
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

    test('only a vouched address identifies a user by email', () async {
      // u-1's address is self-set: it is held, but identifies nobody.
      expect(await userRepo.getByVerifiedEmail('u-1@example.com'), isNull);
      expect(
        (await userRepo.getAllByEmail('u-1@example.com')).map((u) => u.id),
        ['u-1'],
      );
      final u1 = (await userRepo.getById('u-1'))!;
      await userRepo.upsert(u1.copyWith(emailVerified: true));
      expect((await userRepo.getByVerifiedEmail('u-1@example.com'))?.id, 'u-1');
      expect(await userRepo.getByVerifiedEmail('missing@x.com'), isNull);
    });

    test('an address is matched in any case, and stored normalized', () async {
      final u1 = (await userRepo.getById('u-1'))!;
      await userRepo.upsert(
        u1.copyWith(email: '  U-1@Example.COM ', emailVerified: true),
      );
      expect((await userRepo.getById('u-1'))!.email, 'u-1@example.com');
      expect((await userRepo.getByVerifiedEmail('u-1@EXAMPLE.com'))?.id, 'u-1');
      expect(
        (await userRepo.getAllByEmail(' U-1@example.com')).map((u) => u.id),
        ['u-1'],
      );
    });

    test('a stored address that is not normalized matches nothing', () async {
      // Written past the entity, which always stores the normalized form.
      await global.customStatement(
        'UPDATE users SET email = ?, email_verified = 1 WHERE id = ?',
        ['Shared@Example.com', 'u-1'],
      );
      expect(await userRepo.getByVerifiedEmail('shared@example.com'), isNull);
      expect(await userRepo.getAllByEmail('SHARED@example.com'), isEmpty);
    });

    test('a different address is not vouched; the same one stays', () async {
      final u1 = (await userRepo.getById('u-1'))!;
      await userRepo.upsert(u1.copyWith(emailVerified: true));
      final vouched = (await userRepo.getById('u-1'))!;
      await userRepo.upsert(vouched.copyWith(displayName: 'Renamed'));
      expect((await userRepo.getById('u-1'))!.emailVerified, isTrue);
      await userRepo.upsert(vouched.copyWith(email: 'elsewhere@example.com'));
      expect((await userRepo.getById('u-1'))!.emailVerified, isFalse);
      expect(
        () => User(
          id: 'u-x',
          handle: 'ux',
          displayName: 'X',
          emailVerified: true,
          createdAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
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

    User user(String id, String handle) => User(
      id: id,
      handle: handle,
      displayName: 'User $id',
      createdAt: DateTime.utc(2026, 1, 2),
    );

    test('upsert refuses a username another user holds', () async {
      await expectLater(
        userRepo.upsert(user('u-1', 'u-2')),
        throwsA(
          isA<UsernameRefusedException>().having(
            (e) => e.reason,
            'reason',
            UsernameRefusal.taken,
          ),
        ),
      );
      expect((await userRepo.getById('u-1'))?.handle, 'u-1');
    });

    test("upsert keeps a user's own username", () async {
      await userRepo.upsert(user('u-1', 'u-1'));
      expect((await userRepo.getById('u-1'))?.displayName, 'User u-1');
    });

    test('a freed username can be taken', () async {
      await userRepo.upsert(user('u-2', 'renamed'));
      await userRepo.upsert(user('u-1', 'u-2'));
      expect((await userRepo.getById('u-1'))?.handle, 'u-2');
    });

    test('two concurrent writers of one username: exactly one wins', () async {
      final results = await Future.wait([
        for (final id in ['u-1', 'u-2'])
          userRepo
              .upsert(user(id, 'contested'))
              .then((_) => 'ok')
              .catchError(
                (Object e) => (e as UsernameRefusedException).reason.wire,
              ),
      ]);
      expect(results..sort(), ['ok', 'taken']);
      final holders = (await userRepo.getAll()).where(
        (u) => u.handle == 'contested',
      );
      expect(holders, hasLength(1));
    });

    test('insertWithFreeHandle takes the next free name', () async {
      final first = await userRepo.insertWithFreeHandle(user('u-3', 'u-1'));
      final second = await userRepo.insertWithFreeHandle(user('u-4', 'u-1'));
      expect(first.handle, 'u-12');
      expect(second.handle, 'u-13');
      expect((await userRepo.getById('u-4'))?.handle, 'u-13');
    });

    test('concurrent allocations never share a name', () async {
      final users = await Future.wait([
        for (var i = 0; i < 6; i++)
          userRepo.insertWithFreeHandle(user('n-$i', 'sam')),
      ]);
      expect(users.map((u) => u.handle).toSet(), hasLength(6));
      expect(users.map((u) => u.handle), contains('sam'));
    });

    test('the unique index refuses a duplicate written around the DAO', () async {
      await expectLater(
        global.customStatement(
          "INSERT INTO users (id, handle, display_name) VALUES ('x', 'u-1', 'X')",
        ),
        throwsA(anything),
      );
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

    test(
      'profile overlay is workspace-scoped and survives a role upsert',
      () async {
        await memberRepo.upsert(member('m-1', 'w-1', 'u-1'));
        await memberRepo.upsert(member('m-2', 'w-2', 'u-1'));
        await memberRepo.updateProfileOverlay(
          'w-1',
          'u-1',
          displayName: 'Sam Here',
          gitAuthorEmail: 'sam@w1.example',
        );
        await memberRepo.upsert(
          member('m-1', 'w-1', 'u-1', role: WorkspaceRole.admin),
        );
        final inW1 = await memberRepo.getMember('w-1', 'u-1');
        final inW2 = await memberRepo.getMember('w-2', 'u-1');
        expect(inW1?.displayName, 'Sam Here');
        expect(inW1?.gitAuthorEmail, 'sam@w1.example');
        expect(inW1?.role, WorkspaceRole.admin);
        expect(inW2?.displayName, isNull);
        expect(inW2?.gitAuthorEmail, isNull);
      },
    );

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

    test('append round-trips a details snapshot', () async {
      await activityRepo.append(
        UserActivityEntry(
          id: 'a-details',
          workspaceId: 'w-details',
          userId: 'u-1',
          action: 'workspace_settings.set',
          targetType: 'workspace_settings',
          targetId: 'theme',
          details: const {'key': 'theme', 'value': 'dark'},
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      );
      final row = (await activityRepo.getForWorkspace('w-details')).single;
      expect(row.details, {'key': 'theme', 'value': 'dark'});
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

    test('pages walk the trail by keyset with real counts', () async {
      for (var i = 0; i < 12; i++) {
        await activityRepo.append(
          UserActivityEntry(
            id: 'p-$i',
            workspaceId: 'w-1',
            userId: 'u-1',
            action: 'agents.upsert',
            targetId: 'a-$i',
            createdAt: DateTime.utc(2026, 1, 3, 0, i),
          ),
        );
      }
      final page1 = await activityRepo.pageRows('w-1', limit: 10);
      expect(page1.length, 10);
      expect(page1.first.id, 'p-11');
      expect(await activityRepo.count('w-1'), 12);

      final cursor = ActivityCursor.fromEntry(page1.last);
      final page2 = await activityRepo.pageRows(
        'w-1',
        olderThan: cursor,
        limit: 10,
      );
      expect(page2.map((e) => e.id), ['p-1', 'p-0']);
      expect(await activityRepo.count('w-1', newerThan: cursor), 9);
      final newer = await activityRepo.newerRows(
        'w-1',
        newerThan: cursor,
        limit: 2,
      );
      expect(newer.map((e) => e.id), ['p-3', 'p-4']);
    });

    test('filters narrow rows, counts and the actor facet', () async {
      await activityRepo.append(
        UserActivityEntry(
          id: 'f-1',
          workspaceId: 'w-1',
          userId: 'u-1',
          action: 'agents.upsert',
          targetId: 'ceo',
          ip: '203.0.113.7',
          countryCode: 'FR',
          createdAt: DateTime.utc(2026, 1, 4, 1),
        ),
      );
      await activityRepo.append(
        UserActivityEntry(
          id: 'f-2',
          workspaceId: 'w-1',
          userId: 'u-2',
          action: 'tickets.create',
          targetId: 'T-9',
          ip: '192.168.1.4',
          createdAt: DateTime.utc(2026, 1, 4, 2),
        ),
      );
      Future<List<String>> where(AuditLogFilter f) async => [
        for (final e in await activityRepo.pageRows(
          'w-1',
          limit: 10,
          filter: f,
        ))
          e.id,
      ];

      expect(await where(const AuditLogFilter(ip: '203.0.113.7')), ['f-1']);
      expect(await where(const AuditLogFilter(query: 'ceo')), ['f-1']);
      expect(await where(const AuditLogFilter(countryCode: 'FR')), ['f-1']);
      expect(await where(const AuditLogFilter(localNetwork: true)), ['f-2']);
      expect(await where(const AuditLogFilter(actorIds: {'u-2'})), ['f-2']);
      expect(
        await where(
          AuditLogFilter(
            time: [
              AuditTimeCondition(
                op: AuditTimeOperator.after,
                at: DateTime.utc(2026, 1, 4, 1),
              ),
            ],
          ),
        ),
        ['f-2'],
      );
      // Workspace records all returned: only an `ok` outcome matches them.
      expect(
        await where(const AuditLogFilter(outcomes: {AuditOutcome.denied})),
        isEmpty,
      );
      expect(await where(const AuditLogFilter(outcomes: {AuditOutcome.ok})), [
        'f-2',
        'f-1',
      ]);
      expect(
        await activityRepo.count(
          'w-1',
          filter: const AuditLogFilter(query: 'ceo'),
        ),
        1,
      );
      expect(await activityRepo.countByActor('w-1'), {'u-1': 1, 'u-2': 1});
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
