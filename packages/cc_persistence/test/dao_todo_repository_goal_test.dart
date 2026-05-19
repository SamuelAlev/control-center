import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises the goal surface of [DaoTodoRepository] (setGoal / clearGoal /
/// watchGoal) against the real Drift database. The todo-list methods are
/// covered by `todo_dao_test.dart`; this file targets the new
/// `ConversationGoal` plumbing, including the blank-title-clears and
/// createdAt-preservation branches.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoTodoRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoTodoRepository(dbs);
    // Seed the spaces the goals FK-reference, each into its own workspace's
    // database file.
    for (final (id, ws) in [('c-1', 'w-1'), ('c-2', 'w-1'), ('c-3', 'w-2')]) {
      final db = dbs.of(ws);
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
    await dbs.closeAll();
    await global.close();
  });

  group('DaoTodoRepository goals — setGoal', () {
    test('persists a goal that watchGoal emits', () async {
      await repo.setGoal('w-1', 'c-1', 'Ship it');
      final g = await repo.watchGoal('w-1', 'c-1').first;
      expect(g, isNotNull);
      expect(g!.title, 'Ship it');
      expect(g.spaceId, 'c-1');
      expect(g.workspaceId, 'w-1');
      expect(
        g.createdAt,
        g.updatedAt,
        reason: 'first set stamps both to the same instant',
      );
    });

    test('replacing a goal preserves the original createdAt', () async {
      await repo.setGoal('w-1', 'c-1', 'first');
      final first = await repo.watchGoal('w-1', 'c-1').first;
      // A measurable gap so updatedAt strictly advances.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.setGoal('w-1', 'c-1', 'second');
      final second = await repo.watchGoal('w-1', 'c-1').first;

      expect(second!.title, 'second');
      expect(
        second.createdAt,
        first!.createdAt,
        reason: 'createdAt is preserved across an update',
      );
      expect(
        second.updatedAt.isAfter(first.updatedAt) ||
            !second.updatedAt.isBefore(first.updatedAt),
        isTrue,
        reason: 'updatedAt is refreshed',
      );
    });

    test('a blank title clears the goal instead of persisting', () async {
      await repo.setGoal('w-1', 'c-1', 'ship it');
      expect(await repo.watchGoal('w-1', 'c-1').first, isNotNull);

      await repo.setGoal('w-1', 'c-1', '   ');
      expect(await repo.watchGoal('w-1', 'c-1').first, isNull);
    });

    test('trims the title before persisting', () async {
      await repo.setGoal('w-1', 'c-1', '  trimmed  ');
      final g = await repo.watchGoal('w-1', 'c-1').first;
      expect(g!.title, 'trimmed');
    });

    test('a goal in another space is invisible', () async {
      await repo.setGoal('w-1', 'c-1', 'mine');
      expect(await repo.watchGoal('w-1', 'c-2').first, isNull);
    });

    test('a goal in another workspace is invisible', () async {
      await repo.setGoal('w-1', 'c-1', 'ws-1 goal');
      expect(await repo.watchGoal('w-2', 'c-3').first, isNull);
    });
  });

  group('DaoTodoRepository goals — clearGoal', () {
    test('removes an existing goal', () async {
      await repo.setGoal('w-1', 'c-1', 'ship it');
      await repo.clearGoal('w-1', 'c-1');
      expect(await repo.watchGoal('w-1', 'c-1').first, isNull);
    });

    test('is a no-op when no goal exists', () async {
      // Clearing a never-set goal must not throw.
      await repo.clearGoal('w-1', 'c-1');
      expect(await repo.watchGoal('w-1', 'c-1').first, isNull);
    });

    test('clearing one space leaves another intact', () async {
      await repo.setGoal('w-1', 'c-1', 'one');
      await repo.setGoal('w-1', 'c-2', 'two');
      await repo.clearGoal('w-1', 'c-1');
      expect(await repo.watchGoal('w-1', 'c-1').first, isNull);
      expect((await repo.watchGoal('w-1', 'c-2').first)!.title, 'two');
    });
  });

  group('DaoTodoRepository goals — watchGoal reactivity', () {
    test('emits null, then the goal, then null again as it changes', () async {
      final emissions = <ConversationGoal?>[];
      final sub = repo.watchGoal('w-1', 'c-1').listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.setGoal('w-1', 'c-1', 'first');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.clearGoal('w-1', 'c-1');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      expect(emissions, isNotEmpty);
      expect(emissions.first, isNull);
      expect(emissions.any((g) => g?.title == 'first'), isTrue);
      expect(emissions.last, isNull);
    });
  });

  group('DaoTodoRepository goals — todos remain independent', () {
    test('setting a goal does not clobber the todo list', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'do thing',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.setGoal('w-1', 'c-1', 'goal');
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.length, 1);
      expect(todos.first.content, 'do thing');
      expect((await repo.watchGoal('w-1', 'c-1').first)!.title, 'goal');
    });

    test('clearing a goal does not clear the todos', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'persisted',
          status: TodoStatus.inProgress,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.setGoal('w-1', 'c-1', 'goal');
      await repo.clearGoal('w-1', 'c-1');
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.length, 1);
      expect(todos.first.status, TodoStatus.inProgress);
    });
  });

  group('DaoTodoRepository todo-list methods', () {
    test(
      'replaceAll assigns positions by list order and list returns them',
      () async {
        await repo.replaceAll('w-1', 'c-1', [
          TodoItem(
            id: 't-1',
            workspaceId: 'w-1',
            spaceId: 'c-1',
            content: 'first',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          TodoItem(
            id: 't-2',
            workspaceId: 'w-1',
            spaceId: 'c-1',
            content: 'second',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ]);
        final todos = await repo.list('w-1', 'c-1');
        expect(todos.map((t) => t.id), ['t-1', 't-2']);
        expect(todos.first.position, 0);
        expect(todos.last.position, 1);
      },
    );

    test('replaceAll replaces the whole list (clobbers prior items)', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-old',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'old',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-new',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'new',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.length, 1);
      expect(todos.first.id, 't-new');
    });

    test('append assigns the next position after the existing max', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'first',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      final appended = await repo.append('w-1', 'c-1', 'second');
      expect(appended.content, 'second');
      expect(appended.status, TodoStatus.pending);
      expect(appended.position, 1);
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.length, 2);
    });

    test('append to an empty list starts at position 0', () async {
      final appended = await repo.append('w-1', 'c-1', 'first');
      expect(appended.position, 0);
    });

    test('updateStatus changes a single item status', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'do thing',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.updateStatus('w-1', 'c-1', 't-1', TodoStatus.completed);
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.first.status, TodoStatus.completed);
    });

    test('remove deletes a single item', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'keep',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        TodoItem(
          id: 't-2',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'drop',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.remove('w-1', 'c-1', 't-2');
      final todos = await repo.list('w-1', 'c-1');
      expect(todos.length, 1);
      expect(todos.first.id, 't-1');
    });

    test(
      'reorder re-sequences the items to match the given id order',
      () async {
        await repo.replaceAll('w-1', 'c-1', [
          TodoItem(
            id: 't-1',
            workspaceId: 'w-1',
            spaceId: 'c-1',
            content: 'one',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          TodoItem(
            id: 't-2',
            workspaceId: 'w-1',
            spaceId: 'c-1',
            content: 'two',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          TodoItem(
            id: 't-3',
            workspaceId: 'w-1',
            spaceId: 'c-1',
            content: 'three',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ]);
        await repo.reorder('w-1', 'c-1', ['t-3', 't-1', 't-2']);
        final todos = await repo.list('w-1', 'c-1');
        expect(todos.map((t) => t.id), ['t-3', 't-1', 't-2']);
        expect(todos.first.position, 0);
        expect(todos.last.position, 2);
      },
    );

    test('clear removes every item in the space', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'one',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await repo.clear('w-1', 'c-1');
      expect(await repo.list('w-1', 'c-1'), isEmpty);
    });

    test('watch emits the live list as it changes', () async {
      final emissions = <List<TodoItem>>[];
      final sub = repo.watch('w-1', 'c-1').listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.append('w-1', 'c-1', 'first');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      expect(emissions, isNotEmpty);
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
    });

    test('a todo in another workspace is invisible', () async {
      await repo.replaceAll('w-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'w-1',
          spaceId: 'c-1',
          content: 'ws-1 todo',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      // w-2/c-3 must not see w-1/c-1's todo.
      expect(await repo.list('w-2', 'c-3'), isEmpty);
    });
  });
}
