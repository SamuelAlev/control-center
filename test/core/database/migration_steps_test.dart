import 'package:control_center/core/database/migration_steps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MigrationStep', () {
    test('creates with from, to, and migrate callback', () {
      final step = MigrationStep(1, 2, (m) async {});
      expect(step.from, 1);
      expect(step.to, 2);
      expect(step.migrate, isA<Function>());
    });

    test('multiple steps with different versions', () {
      final step1 = MigrationStep(1, 2, (m) async {});
      final step2 = MigrationStep(2, 3, (m) async {});
      final step3 = MigrationStep(3, 4, (m) async {});

      expect(step1.from, 1);
      expect(step1.to, 2);
      expect(step2.from, 2);
      expect(step2.to, 3);
      expect(step3.from, 3);
      expect(step3.to, 4);
    });

    test('individual steps have different migrate callbacks', () {
      final step1 = MigrationStep(1, 2, (_) async {});
      final step2 = MigrationStep(2, 3, (_) async {});

      expect(step1.migrate, isNot(equals(step2.migrate)));
    });
  });
}
