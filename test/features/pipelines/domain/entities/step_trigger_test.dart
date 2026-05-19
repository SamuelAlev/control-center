import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepTrigger', () {
    test('stores sourceStepIds and routeKey', timeout: const Timeout.factor(2), () {
      const trigger = StepTrigger(
        sourceStepIds: ['a', 'b'],
        routeKey: 'true',
      );
      expect(trigger.sourceStepIds, ['a', 'b']);
      expect(trigger.routeKey, 'true');
    });

    test('routeKey defaults to null', timeout: const Timeout.factor(2), () {
      const trigger = StepTrigger(sourceStepIds: ['x']);
      expect(trigger.routeKey, isNull);
    });

    test('sourceStepIds can be empty', timeout: const Timeout.factor(2), () {
      const trigger = StepTrigger(sourceStepIds: []);
      expect(trigger.sourceStepIds, isEmpty);
    });

    test('equality compares sourceStepIds (deep) and routeKey',
        timeout: const Timeout.factor(2), () {
      const a = StepTrigger(sourceStepIds: ['a', 'b'], routeKey: 'x');
      const b = StepTrigger(sourceStepIds: ['a', 'b'], routeKey: 'x');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different sourceStepIds', timeout: const Timeout.factor(2), () {
      const a = StepTrigger(sourceStepIds: ['a', 'b']);
      const b = StepTrigger(sourceStepIds: ['b', 'a']);
      expect(a, isNot(equals(b)));
    });

    test('inequality with different routeKey', timeout: const Timeout.factor(2), () {
      const a = StepTrigger(sourceStepIds: ['a'], routeKey: 'x');
      const b = StepTrigger(sourceStepIds: ['a'], routeKey: 'y');
      expect(a, isNot(equals(b)));
    });

    test('inequality with null vs non-null routeKey', timeout: const Timeout.factor(2), () {
      const a = StepTrigger(sourceStepIds: ['a']);
      const b = StepTrigger(sourceStepIds: ['a'], routeKey: 'x');
      expect(a, isNot(equals(b)));
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      const trigger = StepTrigger(sourceStepIds: ['a']);
      expect(trigger, equals(trigger));
    });
  });
}
