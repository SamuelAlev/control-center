import 'package:control_center/features/settings/domain/entities/acp_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcpModel constructor', () {
    test('creates with required fields', () {
      const model = AcpModel(id: 'gpt-4', name: 'GPT-4');
      expect(model.id, 'gpt-4');
      expect(model.name, 'GPT-4');
      expect(model.description, isNull);
    });

    test('creates with optional description', () {
      const model = AcpModel(
        id: 'claude-3',
        name: 'Claude 3',
        description: 'Anthropic Claude 3 model',
      );
      expect(model.description, 'Anthropic Claude 3 model');
    });
  });

  group('AcpModel == and hashCode', () {
    test('identical models are equal (id-based)', () {
      const a = AcpModel(id: 'gpt-4', name: 'GPT-4', description: 'desc1');
      const b = AcpModel(id: 'gpt-4', name: 'GPT-4o', description: 'desc2');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      const a = AcpModel(id: 'gpt-4', name: 'GPT-4');
      const b = AcpModel(id: 'gpt-3', name: 'GPT-3');
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = AcpModel(id: 'claude-3', name: 'Claude 3');
      expect(a, equals(a));
    });

    test('different name but same id are equal', () {
      const a = AcpModel(id: 'model-1', name: 'Old Name');
      const b = AcpModel(id: 'model-1', name: 'New Name');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different description but same id are equal', () {
      const a = AcpModel(
        id: 'model-1',
        name: 'Model',
        description: 'Desc A',
      );
      const b = AcpModel(
        id: 'model-1',
        name: 'Model',
        description: 'Desc B',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode is the same as id hash', () {
      const model = AcpModel(id: 'gpt-4', name: 'GPT-4');
      expect(model.hashCode, 'gpt-4'.hashCode);
    });
  });

  group('AcpModel equality with null description', () {
    test('null description and non-null same id are equal', () {
      const a = AcpModel(id: 'gpt-4', name: 'GPT-4');
      const b = AcpModel(
        id: 'gpt-4',
        name: 'GPT-4',
        description: 'Some desc',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
