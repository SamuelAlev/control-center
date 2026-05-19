import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoSpaceReadRepository], the thin pass-through over the
/// per-workspace [MessagingDao]s' read-cursor column on `space_participants`.
/// Covers both the lazy-row-create branch of `markSpaceRead` and the
/// read-cursor watch, with the workspace id routing to the workspace's own
/// database file.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoSpaceReadRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    repo = DaoSpaceReadRepository(dbs);
    final db = dbs.of('w-1');
    await db
        .into(db.spacesTable)
        .insert(SpacesTableCompanion.insert(id: 'c-1', name: 'c-1'));
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoSpaceReadRepository', () {
    test('watchUserLastReadAt emits null before the space is read', () async {
      final lastRead = await repo
          .watchUserLastReadAt('w-1', 'c-1', 'u-1')
          .first;
      expect(lastRead, isNull);
    });

    test(
      'markSpaceRead lazily creates a participant row and sets the cursor',
      () async {
        await repo.markSpaceRead('w-1', 'c-1', 'u-1');
        final lastRead = await repo
            .watchUserLastReadAt('w-1', 'c-1', 'u-1')
            .first;
        expect(lastRead, isNotNull);
      },
    );

    test(
      'markSpaceRead updates an existing participant row in place',
      () async {
        // Pre-seed a participant row, then mark read.
        final db = dbs.of('w-1');
        await db
            .into(db.spaceParticipantsTable)
            .insert(
              SpaceParticipantsTableCompanion.insert(
                id: 'c-1-user-u-1',
                spaceId: 'c-1',
                principalId: 'u-1',
                participantType: const Value('user'),
                lastReadAt: Value(DateTime(2020)),
              ),
            );
        final before = await repo
            .watchUserLastReadAt('w-1', 'c-1', 'u-1')
            .first;
        expect(before, DateTime(2020));

        await repo.markSpaceRead('w-1', 'c-1', 'u-1');
        final after = await repo.watchUserLastReadAt('w-1', 'c-1', 'u-1').first;
        expect(after!.isAfter(DateTime(2020)), isTrue);
      },
    );

    test('the cursor is per-user', () async {
      await repo.markSpaceRead('w-1', 'c-1', 'u-1');
      expect(
        await repo.watchUserLastReadAt('w-1', 'c-1', 'u-1').first,
        isNotNull,
      );
      expect(await repo.watchUserLastReadAt('w-1', 'c-1', 'u-2').first, isNull);
    });
  });
}
