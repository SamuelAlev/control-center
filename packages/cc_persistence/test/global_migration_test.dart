import 'dart:io';

import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// Migration coverage for [GlobalDatabase].
///
/// Version 1 is the squashed baseline, so `onCreate` alone describes a fresh
/// file and the chain is only ever exercised by an install that already exists
/// on disk — which is exactly the case no unit test sees by default. Each step
/// therefore gets a test that builds the OLD shape and opens the current
/// database over it.
///
/// The old shape is produced by taking the current schema apart again (drop the
/// column, rewind `user_version`) rather than by checking in a v1 dump: it is
/// the same file the migration will meet in the field, and it cannot drift away
/// from the baseline the way a copied dump silently does.
void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    // Two GlobalDatabase instances over one file is the whole point here; the
    // duplicate-instance warning would just bury the assertions.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    tmp = Directory.systemTemp.createTempSync('cc_global_migration');
    file = File('${tmp.path}/global.db');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Opens the current [GlobalDatabase] over [file], running any migration.
  GlobalDatabase open() {
    final db = GlobalDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    return db;
  }

  /// Builds the current schema at [file], lets [seed] populate it, then takes
  /// it back apart into the v1 shape so the next [open] meets a real upgrade.
  Future<void> seedAtV1(Future<void> Function(GlobalDatabase db) seed) async {
    final db = GlobalDatabase.forTesting(NativeDatabase(file));
    await seed(db);
    await db.close();
    sqlite3.sqlite3.open(file.path)
      ..execute('ALTER TABLE users DROP COLUMN onboarding_finished_at')
      ..execute('PRAGMA user_version = 1')
      ..close();
  }

  Future<void> seedUser(GlobalDatabase db) => db.userDao.upsert(
    UsersTableCompanion.insert(id: 'u-1', handle: 'sam', displayName: 'Sam'),
  );

  group('v1 -> v2: users.onboarding_finished_at', () {
    test('adds the column and leaves the existing rows intact', () async {
      await seedAtV1(seedUser);

      final migrated = open();
      final user = await migrated.userDao.getById('u-1');
      expect(user, isNotNull);
      expect(user!.displayName, 'Sam');
      expect(user.onboardingFinishedAt, isNull);
    });

    test('does NOT backfill the flag from the old preference row', () async {
      // The reason the step is not a backfill. `onboarding_finished` used to be
      // a synced preference, and the preference sync promotes a DEVICE's local
      // values onto whichever account first signs in there — so this row can
      // say `true` about a person who never onboarded. Carrying it forward
      // would migrate the bug onto the new column and keep sending them to the
      // re-auth screen instead of the first-run flow.
      await seedAtV1((db) async {
        await seedUser(db);
        await db.userPreferenceDao.setValue(
          'u-1',
          'onboarding_finished',
          'true',
        );
      });

      final migrated = open();
      expect(
        (await migrated.userDao.getById('u-1'))!.onboardingFinishedAt,
        isNull,
      );
    });

    test('the migrated column is writable and reads back', () async {
      await seedAtV1(seedUser);

      final migrated = open();
      final at = DateTime(2026, 3, 4, 5, 6, 7);
      await migrated.userDao.upsert(
        UsersTableCompanion.insert(
          id: 'u-1',
          handle: 'sam',
          displayName: 'Sam',
          onboardingFinishedAt: Value(at),
        ),
      );
      expect((await migrated.userDao.getById('u-1'))!.onboardingFinishedAt, at);
    });
  });

  test(
    'a fresh file is created at the current version, no chain replayed',
    () async {
      final db = open();
      await db.userDao.upsert(
        UsersTableCompanion.insert(
          id: 'u-1',
          handle: 'sam',
          displayName: 'Sam',
        ),
      );
      expect((await db.userDao.getById('u-1'))!.onboardingFinishedAt, isNull);
      expect(db.schemaVersion, greaterThanOrEqualTo(2));
    },
  );

  /// Takes the current workspaces table back to the shape it had before
  /// v9: no `connect_mode`/`connect_url`, and the old `github_auth_mode`
  /// column, set per row by [modes].
  void rewindWorkspacesToV8(Map<String, String> modes, {required int version}) {
    final raw = sqlite3.sqlite3.open(file.path)
      ..execute('ALTER TABLE workspaces DROP COLUMN connect_mode')
      ..execute('ALTER TABLE workspaces DROP COLUMN connect_url')
      ..execute(
        'ALTER TABLE workspaces ADD COLUMN github_auth_mode TEXT NOT NULL '
        "DEFAULT 'inherit'",
      );
    for (final MapEntry(:key, :value) in modes.entries) {
      raw.execute('UPDATE workspaces SET github_auth_mode = ? WHERE id = ?', [
        value,
        key,
      ]);
    }
    raw
      ..execute('PRAGMA user_version = $version')
      ..close();
  }

  Future<Set<String>> workspaceColumns(GlobalDatabase db) async =>
      (await db.customSelect("PRAGMA table_info('workspaces')").get())
          .map((r) => r.read<String>('name'))
          .toSet();

  group('v3 -> v4: workspaces GitHub identity', () {
    test('adds github_app_id and ends on the v9 Connect columns', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Alpha'),
      );
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('ALTER TABLE workspaces DROP COLUMN connect_mode')
        ..execute('ALTER TABLE workspaces DROP COLUMN connect_url')
        ..execute('ALTER TABLE workspaces DROP COLUMN github_app_id')
        ..execute('PRAGMA user_version = 3')
        ..close();

      final migrated = open();
      final columns = await workspaceColumns(migrated);
      expect(
        columns,
        containsAll({'github_app_id', 'connect_mode', 'connect_url'}),
      );
      expect(columns, isNot(contains('github_auth_mode')));
      final row = await migrated.workspaceRegistryDao.getById('ws-1');
      expect(row, isNotNull);
      expect(row!.connectMode, 'inherit');
      expect(row.connectUrl, '');
      expect(row.githubAppId, '');
    });
  });

  group('v5 -> v6: opt-in review publishing', () {
    test(
      'existing workspaces remain readable with publishing disabled',
      () async {
        final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
        await seeded.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-1',
            name: 'Alpha',
            reviewConcurrency: const Value(7),
          ),
        );
        await seeded.close();
        sqlite3.sqlite3.open(file.path)
          ..execute('ALTER TABLE workspaces DROP COLUMN auto_publish_review')
          ..execute('PRAGMA user_version = 5')
          ..close();

        final row = (await open().workspaceRegistryDao.getById('ws-1'))!;
        expect(row.name, 'Alpha');
        expect(row.reviewConcurrency, 7);
        expect(row.autoPublishReview, isFalse);
      },
    );

    test(
      'replaying the migration preserves an explicit publishing opt-in',
      () async {
        final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
        await seeded.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-1',
            name: 'Alpha',
            autoPublishReview: const Value(true),
          ),
        );
        await seeded.close();
        sqlite3.sqlite3.open(file.path)
          ..execute('PRAGMA user_version = 5')
          ..close();

        final row = (await open().workspaceRegistryDao.getById('ws-1'))!;
        expect(row.autoPublishReview, isTrue);
      },
    );
  });

  group('v6 -> v7: environment port leases', () {
    test('creates the table with its unique keys', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Alpha'),
      );
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('DROP TABLE environment_slot_leases')
        ..execute('PRAGMA user_version = 6')
        ..close();

      final migrated = open();
      expect(await migrated.workspaceRegistryDao.getById('ws-1'), isNotNull);
      final repository = DaoEnvironmentLeaseRepository(
        migrated.environmentLeaseDao,
      );
      EnvironmentLease lease(int block, String spaceId) => EnvironmentLease(
        block: block,
        firstPort: 42000 + block * 32,
        size: 32,
        workspaceId: 'ws-1',
        spaceId: spaceId,
        definitionId: 'def-1',
        createdAt: DateTime.utc(2026),
      );
      expect(await repository.tryInsert(lease(0, 'space-1')), isTrue);
      expect(await repository.tryInsert(lease(0, 'space-2')), isFalse);
    });

    test('re-entering the step keeps existing leases', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.environmentLeaseDao.tryInsert(
        EnvironmentSlotLeasesTableCompanion.insert(
          block: const Value(3),
          firstPort: 42096,
          size: 32,
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          definitionId: 'def-1',
          createdAt: DateTime.utc(2026),
        ),
      );
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA user_version = 6')
        ..close();

      expect(await open().environmentLeaseDao.all(), hasLength(1));
    });
  });
  group('v8 -> v9: one per-workspace Connect choice', () {
    test("starts every workspace on the server's choice and drops the old "
        'column', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      for (final id in ['ws-app', 'ws-inherit', 'ws-junk']) {
        await seeded.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: id,
            name: id,
            githubAppId: Value(id == 'ws-app' ? '42' : ''),
          ),
        );
      }
      await seeded.close();
      rewindWorkspacesToV8({
        'ws-app': 'app',
        'ws-inherit': 'inherit',
        'ws-junk': 'bogus',
      }, version: 8);

      final migrated = open();
      final columns = await workspaceColumns(migrated);
      expect(columns, containsAll({'connect_mode', 'connect_url'}));
      expect(columns, isNot(contains('github_auth_mode')));
      for (final id in ['ws-app', 'ws-inherit', 'ws-junk']) {
        final row = (await migrated.workspaceRegistryDao.getById(id))!;
        expect(row.connectMode, 'inherit', reason: id);
        expect(row.connectUrl, '', reason: id);
      }
      expect(
        (await migrated.workspaceRegistryDao.getById('ws-app'))!.githubAppId,
        '42',
      );
    });

    test('re-entering the step on a migrated file changes nothing', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-1',
          name: 'One',
          connectMode: const Value('custom'),
          connectUrl: const Value('https://connect.example'),
        ),
      );
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA user_version = 8')
        ..close();

      final row = (await open().workspaceRegistryDao.getById('ws-1'))!;
      expect(row.connectMode, 'custom');
      expect(row.connectUrl, 'https://connect.example');
    });
  });

  group('v9 -> v10: every handle is a valid, unique username', () {
    /// Writes [handles] (id -> handle, with ascending creation times in map
    /// order) straight into the file, bypassing the DAO's checks the way an
    /// older build's writers did, and rewinds to v9.
    Future<void> seedAtV9(Map<String, String> handles) async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.customSelect('SELECT 1').get();
      await seeded.close();
      final raw = sqlite3.sqlite3.open(file.path);
      var at = 1000;
      for (final MapEntry(key: id, value: handle) in handles.entries) {
        raw.execute(
          'INSERT INTO users (id, handle, display_name, created_at) '
          'VALUES (?, ?, ?, ?)',
          [id, handle, id, at++],
        );
      }
      raw
        ..execute('PRAGMA user_version = 9')
        ..close();
    }

    Future<Map<String, String>> handlesOf(GlobalDatabase db) async => {
      for (final row in await db.userDao.getAll()) row.id: row.handle,
    };

    test('keeps valid handles and rewrites the rest', () async {
      final warnings = <String>[];
      await seedAtV9({
        'u-ok': 'sam',
        'u-upper': 'Ada.Lovelace',
        'u-short': 'x',
        'u-reserved': 'system',
        'u-edge': '-dash-',
        'u-long': 'a' * 40,
      });

      final db = GlobalDatabase(
        NativeDatabase(file),
        onWarn: (_, message) => warnings.add(message),
      );
      addTearDown(db.close);
      final handles = await handlesOf(db);
      expect(handles, {
        'u-ok': 'sam',
        'u-upper': 'ada.lovelace',
        'u-short': 'member',
        'u-reserved': 'member2',
        'u-edge': 'dash',
        'u-long': 'a' * 32,
      });
      expect(handles.values.every(Username.isValid), isTrue);
      expect(warnings, hasLength(5));
      expect(warnings.join('\n'), contains('"system" to "member2"'));
      expect(db.schemaVersion, greaterThanOrEqualTo(10));
    });

    test('names that differ only in case: the oldest row keeps it', () async {
      await seedAtV9({'u-old': 'Sam', 'u-new': 'sam', 'u-newer': 'SAM'});

      final handles = await handlesOf(open());
      expect(handles, {'u-old': 'sam', 'u-new': 'sam2', 'u-newer': 'sam3'});
    });

    test('a rewritten name never takes a valid one from a newer row', () async {
      await seedAtV9({'u-old': 'Bob Smith', 'u-new': 'bob-smith'});

      final handles = await handlesOf(open());
      expect(handles, {'u-old': 'bob-smith2', 'u-new': 'bob-smith'});
    });

    test('every migrated row reads as a User', () async {
      await seedAtV9({'u-1': 'Weird Name!', 'u-2': 'me', 'u-3': 'ok'});

      final users = await DaoUserRepository(open().userDao).getAll();
      expect(users.map((u) => u.handle), ['weird-name', 'member', 'ok']);
    });

    test('re-entering the step on a conforming file changes nothing', () async {
      await seedAtV9({'u-1': 'sam', 'u-2': 'sam2'});

      expect(await handlesOf(open()), {'u-1': 'sam', 'u-2': 'sam2'});
    });
  });

  group('v10 -> v11: the server-scope audit trail', () {
    ServerAuditEntry entry(String id) => ServerAuditEntry(
      id: id,
      userId: 'u-1',
      op: 'connect.setChoice',
      argNames: const ['mode'],
      outcome: AuditOutcome.ok,
      createdAt: DateTime.utc(2026, 11, 10),
    );

    test('creates the table and its index on an existing file', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seedUser(seeded);
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('DROP TABLE server_audit')
        ..execute('PRAGMA user_version = 10')
        ..close();

      final migrated = open();
      expect(await migrated.userDao.getById('u-1'), isNotNull);
      final indexes = await migrated
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'server_audit'",
          )
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')),
        contains('idx_server_audit_created'),
      );
      final audit = DaoServerAuditRepository(migrated.serverAuditDao);
      await audit.append(entry('a-1'));
      expect(await audit.pageRows(limit: 10), [entry('a-1')]);
    });

    test('re-entering the step keeps existing rows', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await DaoServerAuditRepository(
        seeded.serverAuditDao,
      ).append(entry('a-1'));
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA user_version = 10')
        ..close();

      expect(
        await DaoServerAuditRepository(
          open().serverAuditDao,
        ).pageRows(limit: 10),
        [entry('a-1')],
      );
    });
  });

  group('v11 -> v12: users.email_verified', () {
    /// The v11 shape: no `email_verified` column yet.
    Future<void> seedAtV11(List<List<Object?>> rows) async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.customSelect('SELECT 1').get();
      await seeded.close();
      final raw = sqlite3.sqlite3.open(file.path)
        ..execute('ALTER TABLE users DROP COLUMN email_verified');
      var at = 1000;
      for (final row in rows) {
        raw.execute(
          'INSERT INTO users (id, handle, display_name, email, sso_subject, '
          'sso_issuer, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [row[0], row[0], row[0], row[1], row[2], row[3], at++],
        );
      }
      raw
        ..execute('PRAGMA user_version = 11')
        ..close();
    }

    test('adds the column; every existing row starts unverified', () async {
      await seedAtV11([
        ['self-set', 'a@x.test', null, null],
        ['sso-pinned', 'b@x.test', 'sub-b', 'https://idp.test'],
        ['scim-subject', 'd@x.test', 'ext-d', 'scim'],
      ]);

      final users = {
        for (final u in await DaoUserRepository(open().userDao).getAll())
          u.id: u.emailVerified,
      };
      expect(users, {
        'self-set': false,
        'sso-pinned': false,
        'scim-subject': false,
      });
    });

    test('re-entering the step keeps a stored flag', () async {
      final seeded = GlobalDatabase.forTesting(NativeDatabase(file));
      await seeded.customSelect('SELECT 1').get();
      await seeded.close();
      sqlite3.sqlite3.open(file.path)
        ..execute(
          'INSERT INTO users (id, handle, display_name, email, '
          'email_verified, created_at) VALUES '
          "('u-1', 'one', 'One', 'one@x.test', 1, 1000)",
        )
        ..execute('PRAGMA user_version = 11')
        ..close();

      final user = await DaoUserRepository(open().userDao).getById('u-1');
      expect(user!.emailVerified, isTrue);
    });
  });
}
