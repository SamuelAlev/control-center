import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Seed workspaces + spaces the goals FK-reference.
    for (final (id, ws) in [('c-1', 'w-1'), ('c-2', 'w-1'), ('c-3', 'w-2')]) {
      await db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              id: id,
              name: id,
              workspaceId: Value(ws),
            ),
          );
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setGoal(String ws, String space, String title) =>
      db.conversationGoalDao.upsert(
        ConversationGoalsTableCompanion.insert(
          spaceId: space,
          workspaceId: ws,
          title: title,
        ),
      );

  group('ConversationGoalDao workspace + space isolation', () {
    test('watchForSpace returns only the same (ws, space) goal', () async {
      await setGoal('w-1', 'c-1', 'ship it');
      final row = await db.conversationGoalDao
          .watchForSpace('w-1', 'c-1')
          .first;
      expect(row?.title, 'ship it');
    });

    test('one goal per space — upsert replaces', () async {
      await setGoal('w-1', 'c-1', 'first');
      await setGoal('w-1', 'c-1', 'second');
      final row = await db.conversationGoalDao
          .watchForSpace('w-1', 'c-1')
          .first;
      expect(row?.title, 'second');
    });

    test('a goal in another space does not surface', () async {
      await setGoal('w-1', 'c-1', 'ship it');
      final row = await db.conversationGoalDao
          .watchForSpace('w-1', 'c-2')
          .first;
      expect(row, isNull);
    });

    test('a goal in another workspace does not surface', () async {
      await setGoal('w-1', 'c-1', 'ship it');
      // c-3 lives in w-2; querying w-2/c-3 must not see w-1's goal.
      final row = await db.conversationGoalDao
          .watchForSpace('w-2', 'c-3')
          .first;
      expect(row, isNull);
    });

    test(
      'deleteForSpace is scoped — foreign workspace deletes nothing',
      () async {
        await setGoal('w-1', 'c-1', 'ship it');
        final deleted = await db.conversationGoalDao.deleteForSpace(
          'w-2',
          'c-1',
        );
        expect(deleted, 0);
        final row = await db.conversationGoalDao
            .watchForSpace('w-1', 'c-1')
            .first;
        expect(row, isNotNull);
      },
    );

    test('deleteForSpace clears the goal', () async {
      await setGoal('w-1', 'c-1', 'ship it');
      final deleted = await db.conversationGoalDao.deleteForSpace('w-1', 'c-1');
      expect(deleted, 1);
      final row = await db.conversationGoalDao
          .watchForSpace('w-1', 'c-1')
          .first;
      expect(row, isNull);
    });
  });
}
