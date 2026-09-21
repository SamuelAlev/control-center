import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_infra/cc_infra.dart';
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
    test(
      'returns models for claude-code adapter from static catalog',
      () async {
        final models = await service.listModels('claude-code');

        final ids = models.map((m) => m.id).toList();
        // `claude` has no listing command, so the catalog is curated — but it
        // is the CLI's whole vocabulary, aliases included, not three ids.
        expect(ids, contains('claude-opus-4-7'));
        expect(ids, contains('claude-sonnet-4-6'));
        expect(ids, contains('claude-haiku-4-5-20251001'));
        expect(ids, containsAll(['opus', 'sonnet', 'haiku', 'fable']));
        expect(ids, contains('opusplan'));
        expect(ids.length, greaterThan(20));
        expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
      },
    );

    test('claude-code long-context aliases carry a 1M window', () async {
      final models = await service.listModels('claude-code');

      for (final id in ['opus[1m]', 'sonnet[1m]', 'fable[1m]']) {
        final model = models.firstWhere((m) => m.id == id);
        expect(model.contextWindow, 1000000, reason: id);
      }
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

    test('codex is not an adapter catalog', () async {
      expect(await service.listModels('codex'), isEmpty);
    });

    test('curated claude-code model carries its context window', () async {
      final models = await service.listModels('claude-code');
      final opus = models.firstWhere((m) => m.id.contains('opus'));
      expect(opus.contextWindow, 200000);
      expect(opus.thinkingLevels, isNotNull);
      expect(opus.defaultThinkingLevel, isNotNull);
    });

    test('Cursor is not an adapter catalog', () async {
      expect(await service.listModels('cursor'), isEmpty);
      expect(await service.listModels('cursor-agent'), isEmpty);
    });
  });
}
