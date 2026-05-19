import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/sync_dao.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The deterministic-sync change feed (PRD 16 §6): SQLite triggers on the
/// adopted stores allocate the per-workspace monotonic seq and append to
/// `sync_changes` inside the writing transaction.
void main() {
  late WorkspaceDatabase db;
  late SyncDao sync;

  setUp(() async {
    db = createTestDatabase();
    sync = SyncDao(db);
  });

  tearDown(() => db.close());

  Future<void> insertChannel(String id, String? ws) async {
    await db
        .into(db.channelsTable)
        .insert(
          ChannelsTableCompanion(
            id: Value(id),
            name: const Value('chan'),
            workspaceId: Value(ws),
          ),
        );
    // Every channel owns a `main` conversation whose id equals the channel id;
    // channel_messages.conversation_id references it.
    await db
        .into(db.conversationsTable)
        .insert(
          ConversationsTableCompanion(
            id: Value(id),
            channelId: Value(id),
            workspaceId: Value(ws),
          ),
        );
  }

  Future<void> insertMessage(String id, String channelId) => db
      .into(db.channelMessagesTable)
      .insert(
        ChannelMessagesTableCompanion(
          id: Value(id),
          channelId: Value(channelId),
          conversationId: Value(channelId),
          senderId: const Value('user:u1'),
          senderType: const Value('user'),
          content: const Value('hello'),
          messageType: const Value('text'),
        ),
      );

  test(
    'a channel + message write appends ordered feed rows atomically',
    () async {
      await insertChannel('c1', 'ws1');
      await insertMessage('m1', 'c1');

      final changes = await sync.changesSince('ws1', 0);
      expect(changes, hasLength(3));
      expect(changes[0].seq, 1);
      expect(changes[0].tbl, 'channels');
      expect(changes[0].pk, 'c1');
      expect(changes[0].op, 'upsert');
      expect(changes[0].store, 'messaging');
      expect(changes[1].seq, 2);
      expect(changes[1].tbl, 'conversations');
      expect(changes[1].pk, 'c1');
      expect(changes[2].seq, 3);
      expect(changes[2].tbl, 'channel_messages');
      expect(changes[2].pk, 'm1');
      expect(await sync.currentSeq('ws1'), 3);
    },
  );

  test(
    'updates and deletes are recorded with server-receipt ordering',
    () async {
      await insertChannel('c1', 'ws1');
      await insertMessage('m1', 'c1');
      await (db.update(db.channelMessagesTable)
            ..where((t) => t.id.equals('m1')))
          .write(const ChannelMessagesTableCompanion(content: Value('edited')));
      await (db.delete(
        db.channelMessagesTable,
      )..where((t) => t.id.equals('m1'))).go();

      final changes = await sync.changesSince('ws1', 0);
      expect(changes.map((c) => c.op).toList(), [
        'upsert',
        'upsert',
        'upsert',
        'upsert',
        'delete',
      ]);
      // Strictly monotonic, no gaps, no clocks involved.
      expect(changes.map((c) => c.seq).toList(), [1, 2, 3, 4, 5]);
    },
  );

  test(
    'sequences are PER WORKSPACE and never leak across (isolation)',
    () async {
      await insertChannel('c1', 'ws1');
      await insertChannel('c2', 'ws2');
      await insertMessage('m1', 'c1');

      expect(await sync.currentSeq('ws1'), 3);
      expect(await sync.currentSeq('ws2'), 2);
      final ws2 = await sync.changesSince('ws2', 0);
      expect(ws2, hasLength(2));
      expect(ws2.every((c) => c.pk == 'c2'), isTrue);
      // ws2's feed never contains ws1 rows.
      expect(ws2.any((c) => c.pk == 'c1' || c.pk == 'm1'), isFalse);
    },
  );

  test('a workspace-less channel records nothing (guarded trigger)', () async {
    await insertChannel('orphan', null);
    expect(await sync.currentSeq('ws1'), 0);
    final all = await db.select(db.syncChangesTable).get();
    expect(all, isEmpty);
  });

  test('ticket writes land in the tickets store', () async {
    await db
        .into(db.ticketsTable)
        .insert(
          TicketsTableCompanion.insert(
            id: 't1',
            workspaceId: 'ws1',
            title: 'A ticket',
          ),
        );
    final changes = await sync.changesSince('ws1', 0);
    expect(changes.single.store, 'tickets');
    expect(changes.single.tbl, 'tickets');
    expect(changes.single.pk, 't1');
  });

  test('gap-fill reads: changesSince honors fromSeq and limit; pruning moves '
      'the oldest horizon', () async {
    await insertChannel('c1', 'ws1');
    for (var i = 0; i < 5; i++) {
      await insertMessage('m$i', 'c1');
    }
    final tail = await sync.changesSince('ws1', 3);
    expect(tail.map((c) => c.seq).toList(), [4, 5, 6, 7]);
    final capped = await sync.changesSince('ws1', 0, limit: 2);
    expect(capped, hasLength(2));

    expect(await sync.oldestSeq('ws1'), 1);
    final pruned = await sync.pruneBefore(
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(pruned, 7);
    expect(await sync.oldestSeq('ws1'), isNull);
    // The counter survives pruning: new writes keep the monotonic order.
    await insertMessage('m9', 'c1');
    expect(await sync.currentSeq('ws1'), 8);
  });
}
