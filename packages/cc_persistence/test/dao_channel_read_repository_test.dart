import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoChannelReadRepository], the thin pass-through over the
/// per-workspace [MessagingDao]s' read-cursor column on `channel_participants`.
/// Covers both the lazy-row-create branch of `markChannelRead` and the
/// read-cursor watch, with the workspace id routing to the workspace's own
/// database file.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoChannelReadRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    repo = DaoChannelReadRepository(dbs);
    final db = dbs.of('w-1');
    await db
        .into(db.channelsTable)
        .insert(ChannelsTableCompanion.insert(id: 'c-1', name: 'c-1'));
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoChannelReadRepository', () {
    test('watchUserLastReadAt emits null before the channel is read', () async {
      final lastRead = await repo
          .watchUserLastReadAt('w-1', 'c-1', 'u-1')
          .first;
      expect(lastRead, isNull);
    });

    test(
      'markChannelRead lazily creates a participant row and sets the cursor',
      () async {
        await repo.markChannelRead('w-1', 'c-1', 'u-1');
        final lastRead = await repo
            .watchUserLastReadAt('w-1', 'c-1', 'u-1')
            .first;
        expect(lastRead, isNotNull);
      },
    );

    test(
      'markChannelRead updates an existing participant row in place',
      () async {
        // Pre-seed a participant row, then mark read.
        final db = dbs.of('w-1');
        await db
            .into(db.channelParticipantsTable)
            .insert(
              ChannelParticipantsTableCompanion.insert(
                id: 'c-1-user-u-1',
                channelId: 'c-1',
                principalId: 'u-1',
                participantType: const Value('user'),
                lastReadAt: Value(DateTime(2020)),
              ),
            );
        final before = await repo
            .watchUserLastReadAt('w-1', 'c-1', 'u-1')
            .first;
        expect(before, DateTime(2020));

        await repo.markChannelRead('w-1', 'c-1', 'u-1');
        final after = await repo.watchUserLastReadAt('w-1', 'c-1', 'u-1').first;
        expect(after!.isAfter(DateTime(2020)), isTrue);
      },
    );

    test('the cursor is per-user', () async {
      await repo.markChannelRead('w-1', 'c-1', 'u-1');
      expect(
        await repo.watchUserLastReadAt('w-1', 'c-1', 'u-1').first,
        isNotNull,
      );
      expect(await repo.watchUserLastReadAt('w-1', 'c-1', 'u-2').first, isNull);
    });
  });
}
