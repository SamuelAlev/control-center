import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepKind', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(StepKind.values.length, 6);
      expect(StepKind.values, containsAll([
        StepKind.trigger,
        StepKind.listen,
        StepKind.join,
        StepKind.router,
        StepKind.forEach,
        StepKind.terminal,
      ]));
    });

    test('values are distinct', timeout: const Timeout.factor(2), () {
      final set = <StepKind>{};
      for (final kind in StepKind.values) {
        expect(set.add(kind), isTrue, reason: 'Duplicate: $kind');
      }
    });
  });
}
