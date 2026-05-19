import 'package:control_center/features/settings/data/services/acp_models_service.dart';
import 'package:control_center/features/settings/domain/entities/acp_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AcpModelsService service;

  setUp(() {
    service = AcpModelsService();
  });

  group('AcpModel', () {
    test('constructs with required fields', () {
      const model = AcpModel(id: 'model-1', name: 'Model 1');

      expect(model.id, 'model-1');
      expect(model.name, 'Model 1');
      expect(model.description, isNull);
    });

    test('constructs with optional description', () {
      const model = AcpModel(
        id: 'model-1',
        name: 'Model 1',
        description: 'A test model',
      );

      expect(model.description, 'A test model');
    });

    test('equality works by id', () {
      const a = AcpModel(id: 'model-1', name: 'Name A');
      const b = AcpModel(id: 'model-1', name: 'Name B');
      const c = AcpModel(id: 'model-2', name: 'Name A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is based on id', () {
      const a = AcpModel(id: 'model-1', name: 'A');
      const b = AcpModel(id: 'model-1', name: 'B');

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('listModels', () {
    test('returns models for claude-code adapter from static catalog', () async {
      final models = await service.listModels('claude-code');

      expect(models, isNotEmpty);
      expect(models.length, 3);
      expect(models.map((m) => m.id), contains('claude-opus-4-7'));
      expect(models.map((m) => m.id), contains('claude-sonnet-4-6'));
      expect(models.map((m) => m.id), contains('claude-haiku-4-5-20251001'));
    });

    test('returns models for opencode adapter', () async {
      final models = await service.listModels('opencode');

      expect(models, isNotEmpty);
      expect(models.every((m) => m.id.isNotEmpty), isTrue);
    });

    test('returns models for pi-dev adapter', () async {
      final models = await service.listModels('pi-dev');

      expect(models, isNotEmpty);
      expect(models.every((m) => m.id.isNotEmpty), isTrue);
    });

    test('returns empty list for unknown adapter id', () async {
      final models = await service.listModels('unknown-adapter');

      expect(models, isEmpty);
    });

    test('results are cached on second call', () async {
      final first = await service.listModels('claude-code');
      final second = await service.listModels('claude-code');

      expect(second, same(first));
    });

    test('returns AcpModel with correct fields', () async {
      final models = await service.listModels('claude-code');

      for (final model in models) {
        expect(model, isA<AcpModel>());
        expect(model.id, isNotEmpty);
        expect(model.name, isNotEmpty);
      }
    });
  });

  group('AcpModelsService constructor', () {
    test('creates without arguments', () {
      final svc = AcpModelsService();
      expect(svc, isA<AcpModelsService>());
    });
  });
}
