import 'dart:io';

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

  test('a fresh file is created at the current version, no chain replayed', () async {
    final db = open();
    await db.userDao.upsert(
      UsersTableCompanion.insert(id: 'u-1', handle: 'sam', displayName: 'Sam'),
    );
    expect((await db.userDao.getById('u-1'))!.onboardingFinishedAt, isNull);
    expect(db.schemaVersion, greaterThanOrEqualTo(2));
  });
}
