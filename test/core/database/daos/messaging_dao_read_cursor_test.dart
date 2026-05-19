import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart' show MessagingDao;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

/// Verifies the read-cursor column added in the v12 → v13 migration
/// (`channel_participants.last_read_at`) and the [MessagingDao] methods that
/// drive the sidebar's unseen indicator.
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedChannelWithUser(String channelId) async {
    await db.into(db.channelsTable).insert(
      ChannelsTableCompanion.insert(id: channelId, name: 'Ch $channelId'),
    );
    await db.into(db.channelParticipantsTable).insert(
      ChannelParticipantsTableCompanion.insert(
        id: 'p-$channelId',
        channelId: channelId,
        agentId: 'user',
      ),
    );
  }

  group('MessagingDao read cursor', () {
    test('last_read_at column exists and defaults to null (migration applied)',
        () async {
      await seedChannelWithUser('c1');
      expect(await db.messagingDao.watchUserLastReadAt('c1').first, isNull);
    });

    test('markChannelRead stamps the user participant cursor to ~now',
        () async {
      await seedChannelWithUser('c1');
      final before = DateTime.now();
      await db.messagingDao.markChannelRead('c1');

      final cursor = await db.messagingDao.watchUserLastReadAt('c1').first;
      expect(cursor, isNotNull);
      expect(
        cursor!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
    test('markChannelRead can be called repeatedly without error and keeps a cursor',
        () async {
      await seedChannelWithUser('c1');
      // Drift stores DateTime at second resolution, so we can't assert strict
      // monotonicity across sub-second writes — only that repeated stamps are
      // safe and the cursor remains valid (>= the first stamp).
      await db.messagingDao.markChannelRead('c1');
      final first = await db.messagingDao.watchUserLastReadAt('c1').first;

      await db.messagingDao.markChannelRead('c1');
      final second = await db.messagingDao.watchUserLastReadAt('c1').first;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second!.isAfter(first!) || second == first, isTrue);
    });

    test('markChannelRead targets only the user row, not agent participants',
        () async {
      await seedChannelWithUser('c1');
      await db.into(db.channelParticipantsTable).insert(
        ChannelParticipantsTableCompanion.insert(
          id: 'p-agent',
          channelId: 'c1',
          agentId: 'agent-1',
        ),
      );

      await db.messagingDao.markChannelRead('c1');

      // User cursor is set.
      expect(
        await db.messagingDao.watchUserLastReadAt('c1').first,
        isNotNull,
      );
      // Agent participant cursor stays null.
      final agentRow = await (db.select(db.channelParticipantsTable)
            ..where((t) => t.agentId.equals('agent-1')))
          .getSingle();
      expect(agentRow.lastReadAt, isNull);
    });

    test('markChannelRead is a safe no-op when no user participant exists',
        () async {
      await db.into(db.channelsTable).insert(
        ChannelsTableCompanion.insert(id: 'c1', name: 'Ch c1'),
      );

      await db.messagingDao.markChannelRead('c1');
      expect(await db.messagingDao.watchUserLastReadAt('c1').first, isNull);
    });
  });
}
