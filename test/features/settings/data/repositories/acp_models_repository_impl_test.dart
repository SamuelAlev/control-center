import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [AcpModelsService] that returns canned model lists.
class _FakeAcpModelsService implements AcpModelsService {

  _FakeAcpModelsService(this._models);
  final Map<String, List<AcpModel>> _models;

  int listModelsCallCount = 0;

  @override
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath}) async {
    listModelsCallCount++;
    return _models[adapterId] ?? [];
  }
}

void main() {
  group('AcpModelRepositoryImpl', () {
    test('delegates listModels to service', () async {
      final service = _FakeAcpModelsService({
        'opencode': [
          const AcpModel(id: 'm1', name: 'Claude Opus'),
          const AcpModel(id: 'm2', name: 'Claude Sonnet'),
        ],
      });
      final repo = AcpModelRepositoryImpl(service);

      final models = await repo.listModels('opencode');

      expect(models.length, 2);
      expect(models[0].id, 'm1');
      expect(models[1].id, 'm2');
      expect(service.listModelsCallCount, 1);
    });

    test('returns empty list for unknown adapter', () async {
      final service = _FakeAcpModelsService({});
      final repo = AcpModelRepositoryImpl(service);

      final models = await repo.listModels('unknown');

      expect(models, isEmpty);
    });

    test('passes cliPath through to service', () async {
      final service = _FakeAcpModelsService({
        'pi': [const AcpModel(id: 'p1', name: 'Pi Model')],
      });
      final repo = AcpModelRepositoryImpl(service);

      final models = await repo.listModels('pi', cliPath: '/usr/local/bin/pi');

      expect(models.length, 1);
      expect(models[0].id, 'p1');
    });

    test('returns empty list when service returns empty', () async {
      final service = _FakeAcpModelsService({'opencode': []});
      final repo = AcpModelRepositoryImpl(service);

      final models = await repo.listModels('opencode');

      expect(models, isEmpty);
    });

    test('preserves model fields', () async {
      final service = _FakeAcpModelsService({
        'claude': [
          const AcpModel(
            id: 'anthropic/claude-opus-4-7',
            name: 'Claude Opus 4.7',
            description: 'Most capable model',
          ),
        ],
      });
      final repo = AcpModelRepositoryImpl(service);

      final models = await repo.listModels('claude');

      expect(models.single.id, 'anthropic/claude-opus-4-7');
      expect(models.single.name, 'Claude Opus 4.7');
      expect(models.single.description, 'Most capable model');
    });
  });
}
