import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await seedTodoConversations(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTodo(
    String id,
    String ws,
    String conversation, {
    int position = 0,
    String status = 'pending',
  }) => db.todoDao.upsert(
    TodosTableCompanion.insert(
      id: id,
      workspaceId: ws,
      conversationId: conversation,
      content: 'todo $id',
      position: Value(position),
      status: Value(status),
    ),
  );

  group('TodoDao workspace + conversation isolation', () {
    test('watchForConversation returns only same (ws, conversation) rows',
        () async {
      await insertTodo('t-1', 'w-1', 'c-1');
      await insertTodo('t-2', 'w-1', 'c-1', position: 1);
      await insertTodo('t-3', 'w-1', 'c-2');
      final rows = await db.todoDao.watchForConversation('w-1', 'c-1').first;
      expect(rows.map((r) => r.id), ['t-1', 't-2']);
    });

    test('a row in another conversation does not surface', () async {
      await insertTodo('t-1', 'w-1', 'c-1');
      final rows = await db.todoDao.watchForConversation('w-1', 'c-2').first;
      expect(rows, isEmpty);
    });

    test('a row in another workspace does not surface', () async {
      await insertTodo('t-1', 'w-1', 'c-1');
      // c-3 lives in w-2; querying w-2/c-3 must not see w-1's row.
      final rows = await db.todoDao.watchForConversation('w-2', 'c-3').first;
      expect(rows, isEmpty);
    });

    test('deleteById is scoped — foreign workspace deletes nothing', () async {
      await insertTodo('t-1', 'w-1', 'c-1');
      final deleted = await db.todoDao.deleteById('w-2', 'c-1', 't-1');
      expect(deleted, 0);
      final rows = await db.todoDao.watchForConversation('w-1', 'c-1').first;
      expect(rows, hasLength(1));
    });

    test('updatePosition rewrites order (reorder)', () async {
      await insertTodo('t-1', 'w-1', 'c-1', position: 0);
      await insertTodo('t-2', 'w-1', 'c-1', position: 1);
      await db.todoDao.updatePosition('w-1', 'c-1', 't-1', 5);
      final rows = await db.todoDao.watchForConversation('w-1', 'c-1').first;
      // t-2 (pos 1) now sorts before t-1 (pos 5).
      expect(rows.map((r) => r.id), ['t-2', 't-1']);
    });

    test(
      'replaceAll clears + reinserts scoped to (ws, conversation)',
      () async {
        await insertTodo('t-1', 'w-1', 'c-1');
        await insertTodo('keep', 'w-1', 'c-2');
        await db.todoDao.replaceAll('w-1', 'c-1', [
          TodosTableCompanion.insert(
            id: 'n-1',
            workspaceId: 'w-1',
            conversationId: 'c-1',
            content: 'new',
          ),
        ]);
        final c1 = await db.todoDao.watchForConversation('w-1', 'c-1').first;
        final c2 = await db.todoDao.watchForConversation('w-1', 'c-2').first;
        expect(c1.map((r) => r.id), ['n-1']);
        expect(c2.map((r) => r.id), ['keep']); // untouched
      },
    );
  });
}
