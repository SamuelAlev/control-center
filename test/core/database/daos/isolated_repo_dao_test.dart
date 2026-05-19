import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Parents for the FK constraints.
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'w-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'w-2', name: 'WS 2'),
        );
    await db.into(db.reposTable).insert(
          ReposTableCompanion.insert(id: 'r-1', name: 'o/r', path: '/src/r'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    required String workspaceId,
    required String channelId,
    String? ticketId,
  }) =>
      db.isolatedRepoDao.upsert(
        IsolatedReposTableCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          channelId: channelId,
          repoId: 'r-1',
          path: '/iso/$id',
          branch: 'feature/$id',
          sourcePath: '/src/r',
          ticketId: Value(ticketId),
        ),
      );

  group('IsolatedRepoDao — workspace isolation', () {
    test('findForUnit + forChannel are scoped by workspaceId', () async {
      await seed(id: 'a', workspaceId: 'w-1', channelId: 'ch', ticketId: 't-1');
      await seed(id: 'b', workspaceId: 'w-2', channelId: 'ch', ticketId: 't-2');

      final a = await db.isolatedRepoDao.findForUnit('w-1', 'ch', 'r-1');
      expect(a?.id, 'a');

      // A foreign workspace must not surface w-1's row even with same channel.
      final foreign = await db.isolatedRepoDao.findForUnit('w-2', 'ch', 'r-1');
      expect(foreign?.id, 'b');

      final w1 = await db.isolatedRepoDao.forChannel('w-1', 'ch');
      expect(w1.map((r) => r.id), ['a']);
      final w2 = await db.isolatedRepoDao.forChannel('w-2', 'ch');
      expect(w2.map((r) => r.id), ['b']);
    });

    test('forTicket is scoped by workspaceId', () async {
      await seed(id: 'a', workspaceId: 'w-1', channelId: 'ch', ticketId: 't-1');
      final rows = await db.isolatedRepoDao.forTicket('w-1', 't-1');
      expect(rows.map((r) => r.id), ['a']);
      expect(await db.isolatedRepoDao.forTicket('w-2', 't-1'), isEmpty);
    });

    test('cross-workspace teardown lookups span all workspaces', () async {
      await seed(id: 'a', workspaceId: 'w-1', channelId: 'ch', ticketId: 't-1');
      await seed(id: 'b', workspaceId: 'w-2', channelId: 'ch', ticketId: 't-1');

      final byChannel =
          await db.isolatedRepoDao.findByChannelAcrossWorkspaces('ch');
      expect(byChannel.map((r) => r.id).toSet(), {'a', 'b'});

      final byTicket =
          await db.isolatedRepoDao.findByTicketAcrossWorkspaces('t-1');
      expect(byTicket.map((r) => r.id).toSet(), {'a', 'b'});
    });

    test('unique (workspaceId, channelId, repoId) — upsert replaces', () async {
      await seed(id: 'a', workspaceId: 'w-1', channelId: 'ch');
      // Same unit, different row id → conflict on the unique index updates.
      await db.isolatedRepoDao.upsert(
        IsolatedReposTableCompanion.insert(
          id: 'a',
          workspaceId: 'w-1',
          channelId: 'ch',
          repoId: 'r-1',
          path: '/iso/updated',
          branch: 'feature/updated',
          sourcePath: '/src/r',
        ),
      );
      final row = await db.isolatedRepoDao.findForUnit('w-1', 'ch', 'r-1');
      expect(row?.path, '/iso/updated');
    });

    test('deleteById removes the row', () async {
      await seed(id: 'a', workspaceId: 'w-1', channelId: 'ch');
      await db.isolatedRepoDao.deleteById('a');
      expect(await db.isolatedRepoDao.findForUnit('w-1', 'ch', 'r-1'), isNull);
    });
  });
}
