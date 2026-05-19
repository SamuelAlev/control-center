import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Verifies the read-cursor column added in the v12 → v13 migration
/// (`channel_participants.last_read_at`) and the [MessagingDao] methods that
/// drive the sidebar's unseen indicator.
void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedChannelWithUser(String channelId) async {
    await db
        .into(db.channelsTable)
        .insert(
          ChannelsTableCompanion.insert(id: channelId, name: 'Ch $channelId'),
        );
    await db
        .into(db.channelParticipantsTable)
        .insert(
          ChannelParticipantsTableCompanion.insert(
            id: 'p-$channelId',
            channelId: channelId,
            principalId: 'user-1',
            participantType: const Value('user'),
          ),
        );
  }

  group('MessagingDao read cursor', () {
    test(
      'last_read_at column exists and defaults to null (migration applied)',
      () async {
        await seedChannelWithUser('c1');
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNull,
        );
      },
    );

    test(
      'markChannelRead stamps the user participant cursor to ~now',
      () async {
        await seedChannelWithUser('c1');
        final before = DateTime.now();
        await db.messagingDao.markChannelRead('c1', 'user-1');

        final cursor = await db.messagingDao
            .watchUserLastReadAt('c1', 'user-1')
            .first;
        expect(cursor, isNotNull);
        expect(
          cursor!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
      },
    );
    test(
      'markChannelRead can be called repeatedly without error and keeps a cursor',
      () async {
        await seedChannelWithUser('c1');
        // Drift stores DateTime at second resolution, so we can't assert strict
        // monotonicity across sub-second writes — only that repeated stamps are
        // safe and the cursor remains valid (>= the first stamp).
        await db.messagingDao.markChannelRead('c1', 'user-1');
        final first = await db.messagingDao
            .watchUserLastReadAt('c1', 'user-1')
            .first;

        await db.messagingDao.markChannelRead('c1', 'user-1');
        final second = await db.messagingDao
            .watchUserLastReadAt('c1', 'user-1')
            .first;

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(second!.isAfter(first!) || second == first, isTrue);
      },
    );

    test(
      'markChannelRead targets only the user row, not agent participants',
      () async {
        await seedChannelWithUser('c1');
        await db
            .into(db.channelParticipantsTable)
            .insert(
              ChannelParticipantsTableCompanion.insert(
                id: 'p-agent',
                channelId: 'c1',
                principalId: 'agent-1',
              ),
            );

        await db.messagingDao.markChannelRead('c1', 'user-1');

        // User cursor is set.
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNotNull,
        );
        // Agent participant cursor stays null.
        final agentRow = await (db.select(
          db.channelParticipantsTable,
        )..where((t) => t.principalId.equals('agent-1'))).getSingle();
        expect(agentRow.lastReadAt, isNull);
      },
    );

    test(
      'markChannelRead lazily inserts the user participant row when missing',
      () async {
        await db
            .into(db.channelsTable)
            .insert(ChannelsTableCompanion.insert(id: 'c1', name: 'Ch c1'));

        await db.messagingDao.markChannelRead('c1', 'user-1');
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNotNull,
        );
      },
    );

    test(
      'read cursors are per-user: one user reading leaves another unread',
      () async {
        await seedChannelWithUser('c1');
        await db
            .into(db.channelParticipantsTable)
            .insert(
              ChannelParticipantsTableCompanion.insert(
                id: 'p-user-2',
                channelId: 'c1',
                principalId: 'user-2',
                participantType: const Value('user'),
              ),
            );

        await db.messagingDao.markChannelRead('c1', 'user-1');

        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNotNull,
        );
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-2').first,
          isNull,
        );
      },
    );
  });
}
