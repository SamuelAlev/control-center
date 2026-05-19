import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Pins the per-workspace schema version and its migration history.
///
/// The split was introduced with a squashed v1 baseline. v2 is the first
/// carried-forward change: the audit trail gains the client IP and its resolved
/// country (`user_activity.ip` / `user_activity.country_code`). v4 adds the chat
/// bridge's link tables, and there is deliberately no v3 step — v3 created
/// Slack-named tables that were generalized before any build shipped them, so
/// the one step covers a v2 database (create) and a local v3 one (create, carry
/// the rows over, drop the originals); see
/// `workspace_chat_links_migration_test.dart`. Future changes append a step and
/// bump [WorkspaceDatabase.schemaVersion]; this test is here so every bump is a
/// deliberate act rather than a drift.
void main() {
  group('workspace baseline schema', () {
    test('is version 6', () {
      final db = createTestDatabase();
      addTearDown(db.close);

      expect(db.schemaVersion, 6);
    });

    test('a fresh database carries the workspace settings table', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'workspace_settings'",
          )
          .get();

      // `onCreate` must build the CURRENT shape rather than the v4 shape plus a
      // migration — a fresh install never runs the 4→5 step.
      expect(rows.map((r) => r.data['name'] as String), ['workspace_settings']);
    });

    test('a fresh database carries the audit ip/country columns', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect("PRAGMA table_info('user_activity')")
          .get();
      final columns = rows.map((r) => r.read<String>('name')).toSet();

      expect(columns, containsAll(<String>['ip', 'country_code']));
    });

    test('a fresh database carries the generic chat link tables', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE "
            "'chat_%' OR name LIKE 'slack_%'",
          )
          .get();

      // Both tables present under their generic names, and nothing Slack-named:
      // `onCreate` must build the current shape, never a migrated-into one.
      expect(rows.map((r) => r.read<String>('name')), <String>[
        'chat_channel_links',
        'chat_user_links',
      ]);
    });

    test('a fresh database carries none of the removed analytics tables', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
            "('agent_daily_stats_table', 'streaks_table', 'achievements_table')",
          )
          .get();

      expect(
        rows.map((r) => r.read<String>('name')),
        isEmpty,
        reason:
            'the analytics tables were removed from the baseline, so no database '
            'should ever create them',
      );
    });
  });
}
