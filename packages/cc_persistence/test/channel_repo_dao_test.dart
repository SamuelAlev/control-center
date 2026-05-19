import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'r-1', name: 'o/r1', path: '/src/r1'),
        );
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'r-2', name: 'o/r2', path: '/src/r2'),
        );
    await db
        .into(db.channelsTable)
        .insert(ChannelsTableCompanion.insert(id: 'ch-1', name: 'PR #1'));
  });

  tearDown(() async {
    await db.close();
  });

  group('ChannelRepoDao', () {
    test(
      'records and returns a channel repo selection in link order',
      () async {
        await db.channelRepoDao.setReposForChannel(
          workspaceId: 'w-1',
          channelId: 'ch-1',
          repoIds: ['r-1', 'r-2'],
        );
        expect(
          await db.channelRepoDao.repoIdsForChannel('w-1', 'ch-1'),
          equals(['r-1', 'r-2']),
        );
      },
    );

    test(
      'an empty selection is a no-op (channel stays on the all-repos default)',
      () async {
        await db.channelRepoDao.setReposForChannel(
          workspaceId: 'w-1',
          channelId: 'ch-1',
          repoIds: const [],
        );
        expect(
          await db.channelRepoDao.repoIdsForChannel('w-1', 'ch-1'),
          isEmpty,
        );
      },
    );

    test('setReposForChannel is idempotent per (channel, repo)', () async {
      await db.channelRepoDao.setReposForChannel(
        workspaceId: 'w-1',
        channelId: 'ch-1',
        repoIds: ['r-1'],
      );
      await db.channelRepoDao.setReposForChannel(
        workspaceId: 'w-1',
        channelId: 'ch-1',
        repoIds: ['r-1', 'r-2'],
      );
      expect(
        await db.channelRepoDao.repoIdsForChannel('w-1', 'ch-1'),
        equals(['r-1', 'r-2']),
      );
    });

    test('reads are scoped by workspaceId (no cross-workspace leak)', () async {
      await db.channelRepoDao.setReposForChannel(
        workspaceId: 'w-1',
        channelId: 'ch-1',
        repoIds: ['r-1'],
      );
      // Same channel id, foreign workspace → nothing surfaces.
      expect(await db.channelRepoDao.repoIdsForChannel('w-2', 'ch-1'), isEmpty);
    });
  });
}
