import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// The appended steps of `global.db`'s schema evolution, driven against real
/// populated databases rather than trusted by symmetry with the workspace
/// half.
///
/// * v1→v2 — the install-wide settings store (the first global migration the
///   app ever ran; `_migrationSteps` was `const <MigrationStep>[]` until
///   then, so the whole `onUpgrade` path was unexercised code).
/// * v2→v3 — SSO: the `sso_connections` rows plus the users-table SSO
///   subject pin and deactivation stamp (with its partial unique index).
/// * v3→v4 — the per-user newsfeed: `rss_feeds` gains the owning `user_id`.
/// * v4→v5 — the review auto-publish opt-in: `workspaces` gains
///   `auto_publish_review` (defaults to false — publishing stays user-gated
///   unless the operator opts in).
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    dir = Directory.systemTemp.createTempSync('cc-global-settings-migration');
    file = File('${dir.path}/global.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds a database in the superseded [version] shape: the current schema
  /// created by drift, then everything a later step adds is removed and
  /// `user_version` wound back (SQLite ≥3.35 `DROP COLUMN`).
  Future<void> writeDatabaseAtVersion(int version) async {
    final current = GlobalDatabase(NativeDatabase(file));
    // Genuine global data the migration must leave alone.
    await current
        .into(current.workspacesTable)
        .insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Existing'),
        );
    await current.close();

    final raw = sqlite3.sqlite3.open(file.path);
    if (version < 2) {
      raw.execute('DROP TABLE server_settings');
    }
    if (version < 3) {
      raw
        ..execute('DROP INDEX IF EXISTS idx_users_sso_subject')
        ..execute('DROP TABLE IF EXISTS sso_connections')
        ..execute('ALTER TABLE users DROP COLUMN sso_subject')
        ..execute('ALTER TABLE users DROP COLUMN sso_issuer')
        ..execute('ALTER TABLE users DROP COLUMN deactivated_at');
    }
    if (version < 4) {
      // Recreated by hand rather than DROP COLUMN: the v4 column carries a
      // foreign key, which SQLite refuses to drop while the constraint
      // references it. The shape is drift's own generated DDL for the table
      // minus `user_id` — including the timestamp defaults, which drift
      // relies on at INSERT time for `withDefault(currentDateAndTime)`.
      raw
        ..execute('DROP TABLE rss_feeds')
        ..execute(
          'CREATE TABLE rss_feeds ('
          '"id" TEXT NOT NULL, '
          '"name" TEXT NOT NULL, '
          '"url" TEXT NOT NULL, '
          '"description" TEXT NOT NULL DEFAULT \'\', '
          '"icon_url" TEXT NOT NULL DEFAULT \'\', '
          '"user_agent" TEXT NOT NULL DEFAULT \'\', '
          '"enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), '
          '"last_fetched_at" INTEGER NULL, '
          '"last_error" TEXT NULL, '
          '"created_at" INTEGER NOT NULL DEFAULT '
          '(CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
          '"updated_at" INTEGER NOT NULL DEFAULT '
          '(CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
          'PRIMARY KEY ("id"))',
        );
    }
    if (version < 5) {
      raw.execute(
        'ALTER TABLE workspaces DROP COLUMN auto_publish_review',
      );
    }
    raw.execute('PRAGMA user_version = $version');
    raw.close();
  }

  test('adds server_settings and leaves existing data intact', () async {
    await writeDatabaseAtVersion(1);

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);

    // Opening runs the migration.
    await migrated.serverSettingDao.setValue('sandbox_enabled', 'true');
    expect(await migrated.serverSettingDao.getValue('sandbox_enabled'), 'true');

    final workspaces = await migrated.select(migrated.workspacesTable).get();
    expect(
      workspaces.map((w) => w.id),
      ['ws-1'],
      reason: 'the 1→2 step is additive; it must not touch the registry',
    );
  });

  test('a v1 database reports the new schema version after opening', () async {
    await writeDatabaseAtVersion(1);

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    await migrated.serverSettingDao.getAll();

    final raw = sqlite3.sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single['user_version'], 5);
  });

  test('a v3 database gains rss_feeds.user_id and keeps the registry', () async {
    await writeDatabaseAtVersion(3);

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);

    // The column exists and is usable: a user-owned feed round-trips.
    await migrated
        .into(migrated.usersTable)
        .insert(
          UsersTableCompanion.insert(id: 'u1', handle: 'u1', displayName: 'U1'),
        );
    await migrated.rssDao.upsertFeed(
      RssFeedsTableCompanion.insert(
        id: 'f1',
        userId: 'u1',
        name: 'Feed',
        url: 'https://example.com/rss',
      ),
    );
    expect(await migrated.rssDao.watchFeeds('u1').first, hasLength(1));

    final workspaces = await migrated.select(migrated.workspacesTable).get();
    expect(workspaces.map((w) => w.id), ['ws-1']);
  });

  test('a v2 database gains the SSO surfaces and keeps the registry', () async {
    await writeDatabaseAtVersion(2);

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);

    // The connection row round-trips.
    await migrated.ssoConnectionDao.upsert(
      SsoConnectionsTableCompanion.insert(id: 'saml', kind: 'saml'),
    );
    final rows = await migrated.ssoConnectionDao.getAll();
    expect(rows.map((r) => r.id), ['saml']);

    // The users pin columns exist and the partial unique index enforces the
    // one-account-per-(issuer, subject) rule.
    final db = migrated;
    await customInsertHelper(db);
    final raw = sqlite3.sqlite3.open(file.path);
    addTearDown(raw.close);
    final indexes = raw
        .select(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name='idx_users_sso_subject'",
        )
        .toList();
    expect(indexes, hasLength(1), reason: 'the partial index is rebuilt');
    expect(
      () => raw.execute(
        'INSERT INTO users(id, handle, display_name, sso_issuer, sso_subject) '
        "VALUES('u2', 'dupe', 'Dupe', 'https://idp', 'same-subject')",
      ),
      throwsA(isA<sqlite3.SqliteException>()),
      reason: 'the same (issuer, subject) cannot pin two accounts',
    );

    final workspaces = await migrated.select(migrated.workspacesTable).get();
    expect(workspaces.map((w) => w.id), ['ws-1']);
  });

  test('a fresh database carries everything from onCreate', () async {
    final fresh = GlobalDatabase(NativeDatabase(file));
    addTearDown(fresh.close);

    // A fresh install never runs a migration step, so `onCreate` must build
    // the CURRENT shape rather than an old shape plus migrations.
    await fresh.serverSettingDao.setValue('k', 'v');
    expect(await fresh.serverSettingDao.getValue('k'), 'v');
    await fresh.ssoConnectionDao.upsert(
      SsoConnectionsTableCompanion.insert(id: 'oidc', kind: 'oidc'),
    );
    expect(await fresh.ssoConnectionDao.getById('oidc'), isNotNull);
  });

  test('a v4 database gains workspaces.auto_publish_review defaulting to off',
      () async {
    await writeDatabaseAtVersion(4);

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    await migrated.serverSettingDao.getAll();

    final rows = await migrated.select(migrated.workspacesTable).get();
    expect(rows.map((w) => w.id), ['ws-1']);
    expect(
      rows.single.autoPublishReview,
      isFalse,
      reason: 'the column must arrive defaulted to off (user-gated)',
    );

    final raw = sqlite3.sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.userVersion, 5);
  });
}

/// Seeds one SSO-pinned user row for the index test (drift-side write).
Future<void> customInsertHelper(GlobalDatabase db) async {
  await db
      .into(db.usersTable)
      .insert(
        UsersTableCompanion.insert(
          id: 'u1',
          handle: 'pinned',
          displayName: 'Pinned',
          ssoIssuer: const Value('https://idp'),
          ssoSubject: const Value('same-subject'),
        ),
      );
}
