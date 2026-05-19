import 'dart:async';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/sync_dao.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/sync/sync_feed_service.dart';
import 'package:test/test.dart';
import 'helpers/test_database.dart';

/// The deterministic-sync backbone (PRD 16 §6): ordered delta frames with
/// contiguity, ranged pulls with the snapshot-required kill-switch path, and
/// per-column LWW resolved by server receipt order — never client clocks.
void main() {
  const workspaceId = 'ws1';
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late TicketDao ticketDao;
  late SyncFeedService feed;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, workspaceId);
    db = dbs.of(workspaceId);
    ticketDao = db.ticketDao;
    final tickets = DaoTicketRepository(dbs, global.workspaceRouteDao);
    feed = SyncFeedService(
      workspaces: dbs,
      pollInterval: const Duration(milliseconds: 50),
      loaders: {
        'tickets': (ws, pk, ctx) async {
          final t = await tickets.getById(ws, pk);
          return t == null ? null : ticketToWire(t);
        },
      },
    );
  });

  tearDown(() async {
    feed.dispose();
    await dbs.closeAll();
    await global.close();
  });

  Future<void> insertTicket(String id, {String title = 'T'}) => db
      .into(db.ticketsTable)
      .insert(
        TicketsTableCompanion.insert(id: id, workspaceId: 'ws1', title: title),
      );

  test('watch emits a seed, then ordered contiguous delta frames with the '
      'loaded row', () async {
    final frames = <Map<String, dynamic>>[];
    final sub = feed.watch('ws1', 'tickets').listen(frames.add);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(frames.first['kind'], 'seed');
    expect(frames.first['v'], SyncFeedService.wireVersion);
    final seedSeq = frames.first['seq'] as int;

    await insertTicket('t1', title: 'Hello');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final delta = frames.firstWhere((f) => f['kind'] == 'delta');
    expect(delta['from'], seedSeq);
    expect(delta['seq'], greaterThan(seedSeq));
    final change = (delta['changes'] as List).single as Map;
    expect(change['tbl'], 'tickets');
    expect(change['pk'], 't1');
    expect(change['op'], 'upsert');
    expect((change['row'] as Map)['title'], 'Hello');
    await sub.cancel();
  });

  test('a delete is streamed as a delete change', () async {
    await insertTicket('t1');
    final frames = <Map<String, dynamic>>[];
    final sub = feed.watch('ws1', 'tickets').listen(frames.add);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await ticketDao.deleteTicket('t1', 'ws1');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final delta = frames.lastWhere((f) => f['kind'] == 'delta');
    final change = (delta['changes'] as List).single as Map;
    expect(change['op'], 'delete');
    expect(change['pk'], 't1');
    expect(change.containsKey('row'), isFalse);
    await sub.cancel();
  });

  test('pull returns the requested range; a pruned range answers '
      'snapshot_required (the automatic kill-switch path)', () async {
    await insertTicket('t1');
    await insertTicket('t2');
    final pulled = await feed.pull('ws1', 'tickets', 0);
    expect(pulled['snapshot_required'], isFalse);
    expect(pulled['changes'] as List, hasLength(2));

    // Prune the whole feed, then ask for the old range again.
    await SyncDao(db).pruneBefore(DateTime.now().add(const Duration(days: 1)));
    await insertTicket('t3');
    final stale = await feed.pull('ws1', 'tickets', 1);
    expect(stale['snapshot_required'], isTrue);
    expect(stale['changes'], isEmpty);
  });

  test(
    'per-column LWW: two concurrent field edits both land in server '
    'receipt order — deliberately skewed client clocks change nothing',
    () async {
      await insertTicket('t1', title: 'Original');
      final initial = await (db.select(
        db.ticketsTable,
      )..where((t) => t.id.equals('t1'))).getSingle();
      // Client A (clock far in the past) edits the title; client B (clock far
      // in the future) edits the priority. Neither patch carries its clock —
      // the server's receipt order is the only order.
      await ticketDao.patchFields(
        'ws1',
        't1',
        const TicketsTableCompanion(title: Value('From A')),
      );
      await ticketDao.patchFields(
        'ws1',
        't1',
        const TicketsTableCompanion(priority: Value(3)),
      );
      final row = await (db.select(
        db.ticketsTable,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(
        row.title,
        'From A',
        reason: 'B did not clobber A (no lost update)',
      );
      expect(row.priority, 3);
      expect(row.version, initial.version + 2, reason: 'both patches bumped');

      // Same-column race: the LAST server receipt wins.
      await ticketDao.patchFields(
        'ws1',
        't1',
        const TicketsTableCompanion(title: Value('First')),
      );
      await ticketDao.patchFields(
        'ws1',
        't1',
        const TicketsTableCompanion(title: Value('Second')),
      );
      final again = await (db.select(
        db.ticketsTable,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(again.title, 'Second');
    },
  );

  test('patchFields cannot reach a ticket in another workspace', () async {
    // `ws2` is a different database entirely, so the patch below is not merely
    // filtered out — the row it names is not in the file being written to.
    await seedTestWorkspace(global, dbs, 'ws2');
    await insertTicket('t1');
    final matched = await ticketDao.patchFields(
      'ws2',
      't1',
      const TicketsTableCompanion(title: Value('stolen')),
    );
    expect(matched, 0);
    final row = await (db.select(
      db.ticketsTable,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(row.title, isNot('stolen'));
  });

  test('frames advance seq even when only OTHER stores changed (contiguity '
      'across store-filtered streams)', () async {
    final frames = <Map<String, dynamic>>[];
    final sub = feed.watch('ws1', 'tickets').listen(frames.add);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // A messaging-store change consumes a seq without touching tickets.
    await db
        .into(db.channelsTable)
        .insert(
          const ChannelsTableCompanion(
            id: Value('c1'),
            name: Value('chan'),
            workspaceId: Value('ws1'),
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final delta = frames.lastWhere((f) => f['kind'] == 'delta');
    expect(delta['changes'], isEmpty);
    expect(delta['seq'], greaterThan(delta['from'] as int));
    await sub.cancel();
  });
}
