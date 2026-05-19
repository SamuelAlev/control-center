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
}
