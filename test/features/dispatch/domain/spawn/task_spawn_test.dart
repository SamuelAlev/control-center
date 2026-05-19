import 'package:cc_domain/features/dispatch/domain/spawn/task_spawn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskItem', () {
    test('asserts on empty id', () {
      expect(
        () => TaskItem(id: '', assignment: 'do the thing'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TaskItem(id: '   ', assignment: 'do the thing'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts on empty assignment', () {
      expect(
        () => TaskItem(id: 'a', assignment: ''),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TaskItem(id: 'a', assignment: '   '),
        throwsA(isA<AssertionError>()),
      );
    });

    test('defaults isolated to false', () {
      final item = TaskItem(id: 'a', assignment: 'work');
      expect(item.isolated, isFalse);
      expect(item.role, isNull);
    });

    test('equality and hashCode by value', () {
      final a = TaskItem(id: 'x', assignment: 'work', role: 'reviewer');
      final b = TaskItem(id: 'x', assignment: 'work', role: 'reviewer');
      final c = TaskItem(id: 'x', assignment: 'work', role: 'writer');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('validateSpawn — FlatSpawn', () {
    test('valid flat passes', () {
      final result = validateSpawn(
        const FlatSpawn(assignment: 'ship the feature'),
      );
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('flat with empty assignment fails', () {
      final result = validateSpawn(const FlatSpawn(assignment: ''));
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Flat spawn assignment must not be empty'));
    });

    test('flat with whitespace-only assignment fails', () {
      final result = validateSpawn(const FlatSpawn(assignment: '   '));
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Flat spawn assignment must not be empty'));
    });
  });

  group('validateSpawn — BatchSpawn', () {
    BatchSpawn batch(List<TaskItem> tasks, {String context = 'shared ctx'}) {
      return BatchSpawn(context: context, tasks: tasks);
    }

    test('valid batch passes', () {
      final result = validateSpawn(
        batch([
          TaskItem(id: 'one', assignment: 'task one'),
          TaskItem(id: 'two', assignment: 'task two', role: 'reviewer'),
        ]),
      );
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports duplicate ids', () {
      final result = validateSpawn(
        batch([
          TaskItem(id: 'dup', assignment: 'a'),
          TaskItem(id: 'dup', assignment: 'b'),
          TaskItem(id: 'unique', assignment: 'c'),
        ]),
      );
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Duplicate task id: dup'));
    });

    test('reports each duplicate id exactly once', () {
      final result = validateSpawn(
        batch([
          TaskItem(id: 'dup', assignment: 'a'),
          TaskItem(id: 'dup', assignment: 'b'),
          TaskItem(id: 'dup', assignment: 'c'),
        ]),
      );
      final duplicateErrors =
          result.errors.where((e) => e == 'Duplicate task id: dup').toList();
      expect(duplicateErrors, hasLength(1));
    });

    test('reports empty assignment per task', () {
      // In production, asserts are stripped, so a permissive wire shape can
      // produce a TaskItem whose assignment is blank after trimming. The
      // validator is the real defense for that case. We exercise its per-task
      // rule directly through a fake whose assignment is blank (it bypasses the
      // TaskItem assert), verifying the exact reported message format.
      final result = validateSpawn(
        BatchSpawn(
          context: 'shared ctx',
          tasks: [BlankAssignmentTaskItem('blank')],
        ),
      );
      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains('Task blank assignment must not be empty'),
      );
    });

    test('reports empty context', () {
      final result = validateSpawn(
        batch([TaskItem(id: 'one', assignment: 'work')], context: ''),
      );
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Batch context must not be empty'));
    });

    test('reports whitespace-only context', () {
      final result = validateSpawn(
        batch([TaskItem(id: 'one', assignment: 'work')], context: '   '),
      );
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Batch context must not be empty'));
    });

    test('reports empty tasks list', () {
      final result = validateSpawn(batch(const []));
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Batch must contain at least one task'));
    });

    test('empty tasks + empty context reports both', () {
      final result = validateSpawn(batch(const [], context: ''));
      expect(result.errors, contains('Batch context must not be empty'));
      expect(result.errors, contains('Batch must contain at least one task'));
    });
  });

  group('SpawnValidation', () {
    test('valid factory has no errors', () {
      const result = SpawnValidation.valid();
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('isValid is false when errors present', () {
      const result = SpawnValidation(['boom']);
      expect(result.isValid, isFalse);
    });
  });
}

/// A [TaskItem] whose [assignment] is blank, used to exercise the validator's
/// per-task empty-assignment rule.
///
/// The base constructor asserts a non-empty assignment, so we pass a valid
/// placeholder to `super` (satisfying the assert that fires in tests) and then
/// override the getter to return whitespace — simulating the asserts-disabled
/// production scenario the validator is the real defense against.
class BlankAssignmentTaskItem extends TaskItem {
  BlankAssignmentTaskItem(String id) : super(id: id, assignment: 'placeholder');

  @override
  String get assignment => '   ';
}
