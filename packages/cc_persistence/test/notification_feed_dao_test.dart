import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;
  late NotificationFeedDao dao;

  setUp(() {
    db = createTestDatabase(workspaceId: 'ws-1');
    dao = db.notificationFeedDao;
  });

  tearDown(() async {
    await db.close();
  });

  NotificationFeedTableCompanion entry(
    String id,
    DateTime createdAt, {
    String workspaceId = 'ws-1',
  }) => NotificationFeedTableCompanion.insert(
    id: id,
    workspaceId: workspaceId,
    method: 'notifications/pr_merged',
    paramsJson: '{"workspace_id":"$workspaceId","pr_id":"$id"}',
    createdAt: Value(createdAt),
  );

  group('feed', () {
    test('watchRecent returns newest first, capped by limit', () async {
      final base = DateTime(2026, 8, 16, 12);
      for (var i = 0; i < 5; i++) {
        await dao.insertAndPrune(entry('n$i', base.add(Duration(minutes: i))));
      }

      final rows = await dao.watchRecent('ws-1', limit: 3).first;
      expect(rows.map((r) => r.id), ['n4', 'n3', 'n2']);
    });

    test('watchRecent only sees the given workspace id', () async {
      await dao.insertAndPrune(entry('mine', DateTime(2026, 8, 16)));
      await dao.insertAndPrune(
        entry('other', DateTime(2026, 8, 16), workspaceId: 'ws-2'),
      );

      final rows = await dao.watchRecent('ws-1').first;
      expect(rows.map((r) => r.id), ['mine']);
    });

    test('insertAndPrune retains only the newest rows', () async {
      final base = DateTime(2026, 8, 16);
      for (var i = 0; i < NotificationFeedDao.retainedRows + 10; i++) {
        await dao.insertAndPrune(entry('n$i', base.add(Duration(seconds: i))));
      }

      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM notification_feed')
          .getSingle();
      expect(count.data['c'], NotificationFeedDao.retainedRows);

      // The survivors are the newest ones.
      final rows = await dao.watchRecent('ws-1', limit: 1).first;
      expect(rows.single.id, 'n${NotificationFeedDao.retainedRows + 9}');
    });
  });

  group('read marks', () {
    test('watchReadMark emits null before the first acknowledge', () async {
      expect(await dao.watchReadMark('ws-1', 'user-1').first, isNull);
    });

    test('markAllRead upserts and preserves clearedBefore', () async {
      final cleared = DateTime(2026, 8, 15);
      await dao.clearAll('ws-1', 'user-1', cleared);

      final seen = DateTime(2026, 8, 16);
      await dao.markAllRead('ws-1', 'user-1', seen);

      final mark = await dao.watchReadMark('ws-1', 'user-1').first;
      expect(mark!.lastSeenAt, seen);
      expect(mark.clearedBefore, cleared);
    });

    test('clearAll stamps both watermarks', () async {
      final at = DateTime(2026, 8, 16);
      await dao.clearAll('ws-1', 'user-1', at);

      final mark = await dao.watchReadMark('ws-1', 'user-1').first;
      expect(mark!.lastSeenAt, at);
      expect(mark.clearedBefore, at);
    });

    test('marks are per user', () async {
      await dao.markAllRead('ws-1', 'user-1', DateTime(2026, 8, 16));

      expect(await dao.watchReadMark('ws-1', 'user-2').first, isNull);
    });
  });

  group('per-item states', () {
    test('watchItemStates is empty until an item is acted on', () async {
      expect(await dao.watchItemStates('ws-1', 'user-1').first, isEmpty);
    });

    test('setItemRead records, then clears, the read stamp', () async {
      final at = DateTime(2026, 8, 16, 12);
      await dao.setItemRead('ws-1', 'user-1', 'n1', at);

      var states = await dao.watchItemStates('ws-1', 'user-1').first;
      expect(states.single.itemId, 'n1');
      expect(states.single.readAt, at);

      // Marking unread keeps the row: "explicitly unread" is a state the
      // absence of a row cannot express, because the watermark would then
      // answer for the item instead.
      await dao.setItemRead('ws-1', 'user-1', 'n1', null);
      states = await dao.watchItemStates('ws-1', 'user-1').first;
      expect(states.single.readAt, isNull);
      expect(states.single.dismissedAt, isNull);
    });

    test('setItemRead preserves an existing dismissal', () async {
      final at = DateTime(2026, 8, 16, 12);
      await dao.dismissItem('ws-1', 'user-1', 'n1', at);
      await dao.setItemRead('ws-1', 'user-1', 'n1', null);

      final states = await dao.watchItemStates('ws-1', 'user-1').first;
      expect(states.single.dismissedAt, at, reason: 'a hide is not a read');
    });

    test('dismissItem stamps read as well as dismissed', () async {
      final at = DateTime(2026, 8, 16, 12);
      await dao.dismissItem('ws-1', 'user-1', 'n1', at);

      final states = await dao.watchItemStates('ws-1', 'user-1').first;
      // Deleting a row you never opened must not leave the bell badged for
      // something no longer in the list.
      expect(states.single.readAt, at);
      expect(states.single.dismissedAt, at);
    });

    test('states are per user', () async {
      await dao.setItemRead('ws-1', 'user-1', 'n1', DateTime(2026, 8, 16));

      expect(await dao.watchItemStates('ws-1', 'user-2').first, isEmpty);
    });

    test('markAllRead drops unread overrides but keeps dismissals', () async {
      await dao.setItemRead('ws-1', 'user-1', 'unread', null);
      await dao.dismissItem('ws-1', 'user-1', 'hidden', DateTime(2026, 8, 15));

      await dao.markAllRead('ws-1', 'user-1', DateTime(2026, 8, 16));

      final states = await dao.watchItemStates('ws-1', 'user-1').first;
      // The unread override would otherwise outlive "mark all as read" and
      // keep the bell badged; the dismissal must survive or the row returns.
      expect(states.map((s) => s.itemId), ['hidden']);
    });

    test('clearAll drops every override', () async {
      await dao.setItemRead('ws-1', 'user-1', 'n1', null);
      await dao.dismissItem('ws-1', 'user-1', 'n2', DateTime(2026, 8, 15));

      await dao.clearAll('ws-1', 'user-1', DateTime(2026, 8, 16));

      // The cleared watermark hides every current row, so no override can
      // still change an answer.
      expect(await dao.watchItemStates('ws-1', 'user-1').first, isEmpty);
    });

    test('insertAndPrune drops states orphaned by pruning', () async {
      final base = DateTime(2026, 8, 16);
      await dao.insertAndPrune(entry('n0', base));
      await dao.setItemRead('ws-1', 'user-1', 'n0', base);

      // Push n0 past the retention window.
      for (var i = 1; i <= NotificationFeedDao.retainedRows; i++) {
        await dao.insertAndPrune(entry('n$i', base.add(Duration(seconds: i))));
      }

      // The state rows are per user and unbounded otherwise: without this the
      // table grows forever holding opinions about rows nobody can see.
      expect(await dao.watchItemStates('ws-1', 'user-1').first, isEmpty);
    });
  });
}
