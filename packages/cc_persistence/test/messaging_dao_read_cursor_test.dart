import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Verifies the read cursor (`space_participants.last_read_at` +
/// `last_read_seq`) and the [MessagingDao] methods that drive the sidebar's
/// unseen indicator.
void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSpaceWithUser(String spaceId) async {
    await db
        .into(db.spacesTable)
        .insert(
          SpacesTableCompanion.insert(
            workspaceId: 'test-workspace',
            id: spaceId,
            name: 'Ch $spaceId',
          ),
        );
    await db
        .into(db.spaceParticipantsTable)
        .insert(
          SpaceParticipantsTableCompanion.insert(
            id: 'p-$spaceId',
            spaceId: spaceId,
            principalId: 'user-1',
            participantType: const Value('user'),
          ),
        );
  }

  group('MessagingDao read cursor', () {
    test(
      'last_read_at column exists and defaults to null (migration applied)',
      () async {
        await seedSpaceWithUser('c1');
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNull,
        );
      },
    );

    test('markSpaceRead stamps the user participant cursor to ~now', () async {
      await seedSpaceWithUser('c1');
      final before = DateTime.now();
      await db.messagingDao.markSpaceRead('c1', 'user-1');

      final cursor = await db.messagingDao
          .watchUserLastReadAt('c1', 'user-1')
          .first;
      expect(cursor, isNotNull);
      expect(
        cursor!.at.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
    test(
      'markSpaceRead can be called repeatedly without error and keeps a cursor',
      () async {
        await seedSpaceWithUser('c1');
        // Drift stores DateTime at second resolution, so we can't assert strict
        // monotonicity across sub-second writes — only that repeated stamps are
        // safe and the cursor remains valid (>= the first stamp).
        await db.messagingDao.markSpaceRead('c1', 'user-1');
        final first = await db.messagingDao
            .watchUserLastReadAt('c1', 'user-1')
            .first;

        await db.messagingDao.markSpaceRead('c1', 'user-1');
        final second = await db.messagingDao
            .watchUserLastReadAt('c1', 'user-1')
            .first;

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(second!.isAfter(first!) || second == first, isTrue);
      },
    );

    test('the cursor is the newest message position, ties included', () async {
      await seedSpaceWithUser('c1');
      await (db.update(db.spacesTable)..where((t) => t.id.equals('c1'))).write(
        const SpacesTableCompanion(workspaceId: Value('w-1')),
      );
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion.insert(
              workspaceId: 'test-workspace',
              id: 'conv-1',
              spaceId: 'c1',
            ),
          );
      final second = DateTime.utc(2025, 3, 1, 12);
      Future<void> message(String id) => db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: id,
          spaceId: 'c1',
          conversationId: 'conv-1',
          senderId: 'agent-1',
          senderType: 'agent',
          content: id,
          createdAt: Value(second),
        ),
      );
      await message('m-1');
      await message('m-2');

      await db.messagingDao.markSpaceRead('c1', 'user-1');
      final cursor = await db.messagingDao
          .watchUserLastReadAt('c1', 'user-1')
          .first;
      expect(cursor!.at.isAtSameMomentAs(second), isTrue);

      // A message stamped with the very same second, written after the read,
      // is still after the cursor: the time alone could not tell them apart.
      await message('m-3');
      final activity = await db.messagingDao.watchSpaceActivity('w-1').first;
      expect(activity.single.lastAgentMessage!.isAfter(cursor), isTrue);

      await db.messagingDao.markSpaceRead('c1', 'user-1');
      final caughtUp = await db.messagingDao
          .watchUserLastReadAt('c1', 'user-1')
          .first;
      expect(activity.single.lastAgentMessage, caughtUp);
    });

    test(
      'markSpaceRead targets only the user row, not agent participants',
      () async {
        await seedSpaceWithUser('c1');
        await db
            .into(db.spaceParticipantsTable)
            .insert(
              SpaceParticipantsTableCompanion.insert(
                id: 'p-agent',
                spaceId: 'c1',
                principalId: 'agent-1',
              ),
            );

        await db.messagingDao.markSpaceRead('c1', 'user-1');

        // User cursor is set.
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNotNull,
        );
        // Agent participant cursor stays null.
        final agentRow = await (db.select(
          db.spaceParticipantsTable,
        )..where((t) => t.principalId.equals('agent-1'))).getSingle();
        expect(agentRow.lastReadAt, isNull);
      },
    );

    test(
      'markSpaceRead lazily inserts the user participant row when missing',
      () async {
        await db
            .into(db.spacesTable)
            .insert(
              SpacesTableCompanion.insert(
                workspaceId: 'test-workspace',
                id: 'c1',
                name: 'Ch c1',
              ),
            );

        await db.messagingDao.markSpaceRead('c1', 'user-1');
        expect(
          await db.messagingDao.watchUserLastReadAt('c1', 'user-1').first,
          isNotNull,
        );
      },
    );

    test(
      'read cursors are per-user: one user reading leaves another unread',
      () async {
        await seedSpaceWithUser('c1');
        await db
            .into(db.spaceParticipantsTable)
            .insert(
              SpaceParticipantsTableCompanion.insert(
                id: 'p-user-2',
                spaceId: 'c1',
                principalId: 'user-2',
                participantType: const Value('user'),
              ),
            );

        await db.messagingDao.markSpaceRead('c1', 'user-1');

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
