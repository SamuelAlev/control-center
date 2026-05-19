import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcpModel', () {
    test('construction with all fields', timeout: const Timeout.factor(2), () {
      const model = AcpModel(
        id: 'anthropic/claude-opus-4-7',
        name: 'Claude Opus 4.7',
        description: 'Latest Opus model',
      );

      expect(model.id, 'anthropic/claude-opus-4-7');
      expect(model.name, 'Claude Opus 4.7');
      expect(model.description, 'Latest Opus model');
    });

    test('construction with optional description null', timeout: const Timeout.factor(2), () {
      const model = AcpModel(id: 'gpt-5', name: 'GPT-5');

      expect(model.id, 'gpt-5');
      expect(model.name, 'GPT-5');
      expect(model.description, isNull);
    });

    test('equality is based on id only', timeout: const Timeout.factor(2), () {
      const a = AcpModel(id: 'x', name: 'Alpha', description: 'desc');
      const b = AcpModel(id: 'x', name: 'Beta', description: null);

      expect(a, equals(b));
    });

    test('hashCode consistency', timeout: const Timeout.factor(2), () {
      const a = AcpModel(id: 'x', name: 'Alpha');
      const b = AcpModel(id: 'x', name: 'Beta');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id means not equal', timeout: const Timeout.factor(2), () {
      const a = AcpModel(id: 'a', name: 'Same');
      const b = AcpModel(id: 'b', name: 'Same');

      expect(a, isNot(equals(b)));
    });

    test('not equal to unrelated types', timeout: const Timeout.factor(2), () {
      const model = AcpModel(id: 'x', name: 'X');

      expect(model, isNot(equals('x')));
      expect(model, isNot(equals(42)));
    });
  });
}
