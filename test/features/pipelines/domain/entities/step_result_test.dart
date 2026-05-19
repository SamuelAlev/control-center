import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepResult', () {
    test('ok creates a normal completion', timeout: const Timeout.factor(2), () {
      final result = StepResult.ok(mutatedState: {'a': 1});
      expect(result.mutatedState, {'a': 1});
      expect(result.nextRouterKey, isNull);
      expect(result.isTerminal, isFalse);
      expect(result.isFailed, isFalse);
      expect(result.isSuspended, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('ok with no state', timeout: const Timeout.factor(2), () {
      final result = StepResult.ok();
      expect(result.mutatedState, isNull);
    });

    test('route creates a router completion', timeout: const Timeout.factor(2), () {
      final result = StepResult.route('branch-a', mutatedState: {'r': 1});
      expect(result.nextRouterKey, 'branch-a');
      expect(result.mutatedState, {'r': 1});
      expect(result.isTerminal, isFalse);
    });

    test('suspendUntilEvent creates a suspension', timeout: const Timeout.factor(2), () {
      final result = StepResult.suspendUntilEvent('TicketCompleted');
      expect(result.suspendUntilEvent, 'TicketCompleted');
      expect(result.isSuspended, isTrue);
      expect(result.isFailed, isFalse);
    });

    test('suspendUntilTasksComplete creates a suspension', timeout: const Timeout.factor(2), () {
      final result = StepResult.suspendUntilTasksComplete(['t1', 't2']);
      expect(result.suspendUntilTaskIds, ['t1', 't2']);
      expect(result.isSuspended, isTrue);
    });

    test('terminal creates a pipeline-ending result', timeout: const Timeout.factor(2), () {
      final result = StepResult.terminal(mutatedState: {'done': true});
      expect(result.isTerminal, isTrue);
      expect(result.mutatedState, {'done': true});
    });

    test('failed creates an error result', timeout: const Timeout.factor(2), () {
      final result = StepResult.failed('something broke');
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, 'something broke');
      expect(result.isTerminal, isFalse);
      expect(result.isSuspended, isFalse);
    });

    test('isFailed is false when no errorMessage', timeout: const Timeout.factor(2), () {
      expect(StepResult.ok().isFailed, isFalse);
    });

    test('isSuspended is false when neither suspend fields set',
        timeout: const Timeout.factor(2), () {
      expect(StepResult.ok().isSuspended, isFalse);
    });

    test('equality compares all fields with deep collection equality',
        timeout: const Timeout.factor(2), () {
      final a = StepResult.ok(mutatedState: {'a': 1});
      final b = StepResult.ok(mutatedState: {'a': 1});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different mutatedState', timeout: const Timeout.factor(2), () {
      final a = StepResult.ok(mutatedState: {'a': 1});
      final b = StepResult.ok(mutatedState: {'a': 2});
      expect(a, isNot(equals(b)));
    });

    test('inequality with different router keys', timeout: const Timeout.factor(2), () {
      final a = StepResult.route('x');
      final b = StepResult.route('y');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different error messages', timeout: const Timeout.factor(2), () {
      final a = StepResult.failed('err1');
      final b = StepResult.failed('err2');
      expect(a, isNot(equals(b)));
    });

    test('different result types are not equal', timeout: const Timeout.factor(2), () {
      expect(StepResult.ok(), isNot(equals(StepResult.terminal())));
      expect(StepResult.route('x'), isNot(equals(StepResult.ok())));
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      final result = StepResult.ok();
      expect(result, equals(result));
    });
  });
}
