import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// Every migration step from v2 on must be re-runnable against a database that
/// already carries what it creates.
///
/// The step-specific migration tests build their fixture by opening the CURRENT
/// schema and winding `user_version` back, dropping only the tables the step
/// under test owns — so every LATER step runs against objects that are already
/// there. That is not just a fixture quirk: a restored backup, an imported
/// workspace file, or a half-applied upgrade lands in the same shape and a step
/// that throws there fails the open outright rather than degrading.
///
/// `createTable` is already `CREATE TABLE IF NOT EXISTS`; the trap is indexes,
/// because `Migrator.createIndex` generates a bare `CREATE INDEX` and a
/// duplicate is a hard error. This test is the ratchet: append a step that
/// creates an index with `m.createIndex` and it fails here.
///
/// It starts at v2 deliberately. The 1→2 step is `ALTER TABLE … ADD COLUMN`,
/// which SQLite has no conditional form of, so that one step cannot be made
/// idempotent and is excluded rather than papered over.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    dir = Directory.systemTemp.createTempSync('cc-workspace-migration-idem');
    file = File('${dir.path}/workspace.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds the current schema, then winds `user_version` back to [version]
  /// WITHOUT dropping anything — so reopening replays every step from there
  /// over a database that already has the whole current shape.
  Future<void> writeCurrentSchemaStampedAt(int version) async {
    final current = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    // A row of ordinary workspace data, so a replayed step can be shown not to
    // disturb what it does not own.
    await current
        .into(current.channelsTable)
        .insert(
          ChannelsTableCompanion.insert(
            id: 'chan-1',
            name: 'Existing channel',
            workspaceId: const Value('w-1'),
          ),
        );
    await current.close();

    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = $version');
    raw.close();
  }

  /// Opens the file through the real database, running the migration.
  Future<WorkspaceDatabase> reopen() async {
    final db = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    addTearDown(db.close);
    // Any query forces the open and therefore the migration.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  for (var from = 2; from < WorkspaceDatabase.currentSchemaVersion; from++) {
    test('replaying the steps from v$from over the current schema opens', () async {
      await writeCurrentSchemaStampedAt(from);

      final db = await reopen();

      // Opening at all is the assertion — a non-idempotent step throws out of
      // `beforeOpen` and every query against the database fails with it.
      final channels = await db.select(db.channelsTable).get();
      expect(
        channels.map((c) => c.id),
        ['chan-1'],
        reason: 'a replayed step must not disturb rows it does not own',
      );
    });
  }

  test('a replayed upgrade leaves exactly one of each index', () async {
    await writeCurrentSchemaStampedAt(2);

    final db = await reopen();

    // `CREATE INDEX IF NOT EXISTS` is the fix for the duplicate-index throw,
    // and this pins the other half of it: the replay must be a no-op, not a
    // second index under a generated name.
    final rows = await db
        .customSelect(
          "SELECT name, COUNT(*) AS n FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_autoindex_%' GROUP BY name HAVING n > 1",
        )
        .get();

    expect(rows.map((r) => r.read<String>('name')), isEmpty);
  });

  // v13 CHANGED two existing triggers rather than adding new ones, and
  // `CREATE TRIGGER IF NOT EXISTS` — which is what `beforeOpen` reinstalls
  // with — will not replace one that is already there. The migration
  // therefore DROPS them so `beforeOpen` rebuilds them with their guards.
  //
  // If that drop is ever lost, an upgraded database keeps the old
  // unguarded triggers and the embedding backfill silently goes back to
  // firing two FTS statements and a `sync_changes` row per no-op update —
  // a regression with no symptom other than being slow, which is exactly
  // the kind that survives.
  group('v13 trigger guards survive an upgrade', () {
    Future<String?> triggerSql(WorkspaceDatabase db, String name) async {
      // Inlined rather than bound: `name` is a test-local literal, and
      // importing drift's `Variable` here just to bind it is not worth it.
      final rows = await db
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type = 'trigger' "
            "AND name = '$name'",
          )
          .get();
      return rows.isEmpty ? null : rows.first.read<String?>('sql');
    }

    test('the FTS update trigger only fires for indexed columns', () async {
      await writeCurrentSchemaStampedAt(12);
      final db = await reopen();
      final sql = await triggerSql(db, 'channel_messages_au');
      expect(sql, isNotNull);
      expect(
        sql,
        contains('UPDATE OF content, channel_id'),
        reason:
            'an embedding-only UPDATE must not run a delete+insert of '
            'unchanged text through FTS5',
      );
    });

    test('the sync trigger skips embedding-only updates', () async {
      await writeCurrentSchemaStampedAt(12);
      final db = await reopen();
      final sql = await triggerSql(db, 'trg_sync_channel_messages_update');
      expect(sql, isNotNull);
      expect(
        sql,
        contains('NEW.embedding IS OLD.embedding'),
        reason:
            'the backfill writes one embedding UPDATE per message and no '
            'delta client can observe that column',
      );
    });

    test('a fresh database gets the same guards', () async {
      // `onCreate` and the migration path must agree — a guard that only
      // exists on upgraded databases is worse than none, because it makes
      // the two populations behave differently.
      await writeCurrentSchemaStampedAt(
        WorkspaceDatabase.currentSchemaVersion,
      );
      final db = await reopen();
      expect(
        await triggerSql(db, 'channel_messages_au'),
        contains('UPDATE OF content, channel_id'),
      );
      expect(
        await triggerSql(db, 'trg_sync_channel_messages_update'),
        contains('NEW.embedding IS OLD.embedding'),
      );
    });
  });
}
