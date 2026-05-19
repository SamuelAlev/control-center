import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// The v3→v4 step that turns the Slack-named link tables into the generic ones.
///
/// It exists for exactly one population: a machine that opened a database while
/// the chat bridge was still called Slack. Nothing shipped with those tables, so
/// the step cannot be reasoned about from the released schema — it has to be
/// exercised against a database in that shape, which is what this test builds.
///
/// A v2 database (the released shape) takes the same step and simply creates the
/// tables, because `from < step.to` means one step covers both paths.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    dir = Directory.systemTemp.createTempSync('cc-chat-links-migration');
    file = File('${dir.path}/workspace.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds a database in the superseded v3 shape: the current schema with the
  /// chat tables swapped back for the Slack-named ones and `user_version` wound
  /// back, which is byte-for-byte what a dev machine that ran v3 has.
  Future<void> writeV3Database({required bool withRows}) async {
    final current = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    // The link's `cc_channel_id` is a real foreign key, so the channel it points
    // at has to exist for the copied row to be legal after the migration.
    await current.into(current.channelsTable).insert(
      ChannelsTableCompanion.insert(
        id: 'chan-1',
        name: 'Bridged thread',
        workspaceId: const Value('w-1'),
      ),
    );
    await current.close();

    final raw = sqlite3.sqlite3.open(file.path);
    raw
      ..execute('DROP TABLE chat_channel_links')
      ..execute('DROP TABLE chat_user_links')
      ..execute('''
CREATE TABLE slack_channel_links (
  id TEXT NOT NULL,
  workspace_id TEXT NOT NULL,
  slack_team_id TEXT NOT NULL,
  slack_channel_id TEXT NOT NULL,
  slack_thread_ts TEXT NULL,
  cc_channel_id TEXT NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
  created_by_user_id TEXT NULL,
  created_at INTEGER NOT NULL,
  last_activity_at INTEGER NOT NULL,
  PRIMARY KEY (id)
)''')
      ..execute('''
CREATE TABLE slack_user_links (
  id TEXT NOT NULL,
  workspace_id TEXT NOT NULL,
  slack_team_id TEXT NOT NULL,
  slack_user_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  method TEXT NOT NULL DEFAULT 'code',
  linked_at INTEGER NOT NULL,
  PRIMARY KEY (id)
)''');
    if (withRows) {
      raw
        ..execute(
          'INSERT INTO slack_channel_links VALUES '
          "('cl-1', 'w-1', 'T1', 'C1', '1700.1', 'chan-1', 'u-1', 100, 200)",
        )
        ..execute(
          'INSERT INTO slack_user_links VALUES '
          "('ul-1', 'w-1', 'T1', 'U1', 'u-1', 'email', 300)",
        );
    }
    raw.execute('PRAGMA user_version = 3');
    raw.close();
  }

  /// Opens the file through the real database, running the migration.
  Future<WorkspaceDatabase> reopen() async {
    final db = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    addTearDown(db.close);
    // Any query forces the open, and therefore the migration.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  test('carries Slack link rows over as provider = slack', () async {
    await writeV3Database(withRows: true);

    final db = await reopen();

    final channelLink = (await db
            .customSelect('SELECT * FROM chat_channel_links')
            .get())
        .single;
    expect(channelLink.read<String>('id'), 'cl-1');
    // The whole point of the step: a row that predates the abstraction has to
    // come out attributed to the provider it was always about, or the bridge
    // would look at it and see a link belonging to nobody.
    expect(channelLink.read<String>('provider'), 'slack');
    expect(channelLink.read<String>('external_team_id'), 'T1');
    expect(channelLink.read<String>('external_channel_id'), 'C1');
    expect(channelLink.read<String>('external_thread_id'), '1700.1');
    expect(channelLink.read<String>('cc_channel_id'), 'chan-1');
    expect(channelLink.read<String>('created_by_user_id'), 'u-1');

    final userLink = (await db
            .customSelect('SELECT * FROM chat_user_links')
            .get())
        .single;
    expect(userLink.read<String>('id'), 'ul-1');
    expect(userLink.read<String>('provider'), 'slack');
    expect(userLink.read<String>('external_team_id'), 'T1');
    expect(userLink.read<String>('external_user_id'), 'U1');
    expect(userLink.read<String>('user_id'), 'u-1');
    // The method survives: a link matched by email must not silently become a
    // code link, because that is the audit trail for how attribution happened.
    expect(userLink.read<String>('method'), 'email');
  });

  test('drops the Slack tables it copied from', () async {
    await writeV3Database(withRows: true);

    final db = await reopen();

    final leftovers = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name LIKE 'slack_%'",
        )
        .get();
    expect(
      leftovers,
      isEmpty,
      reason:
          'a leftover table is a second place a link could be written from, and '
          'the old uniques would keep enforcing single-provider rules',
    );
  });

  test('a migrated database still enforces the per-provider uniques', () async {
    await writeV3Database(withRows: true);

    final db = await reopen();

    // Same conversation, same provider: the unique index has to have been
    // installed by the step, not just the tables.
    await expectLater(
      db.customStatement(
        'INSERT INTO chat_channel_links '
        '(id, workspace_id, provider, external_team_id, external_channel_id, '
        'external_thread_id, cc_channel_id, created_at, last_activity_at) '
        "VALUES ('cl-2', 'w-1', 'slack', 'T1', 'C1', '1700.1', 'chan-1', "
        '100, 200)',
      ),
      throwsA(isA<sqlite3.SqliteException>()),
    );
  });

  test('an empty v3 database migrates to empty generic tables', () async {
    await writeV3Database(withRows: false);

    final db = await reopen();

    final counts = await db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM chat_channel_links) AS channels, '
          '(SELECT COUNT(*) FROM chat_user_links) AS users',
        )
        .getSingle();
    expect(counts.read<int>('channels'), 0);
    expect(counts.read<int>('users'), 0);
  });
}
