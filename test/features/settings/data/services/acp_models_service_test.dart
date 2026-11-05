import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AcpModelsService service;
  late _FakeProbe probe;

  setUp(() {
    probe = _FakeProbe();
    service = AcpModelsService(
      claudeCode: ClaudeCodeModelCatalog(
        probe: probe,
        resolveBinary: (_) async => '/nonexistent/claude',
      ),
    );
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
    test('claude-code models come from the installed CLI', () async {
      final models = await service.listModels('claude-code');

      expect([for (final m in models) m.id], ['opus', 'claude-opus-5-5']);
      expect(models.first.name, 'Opus (latest)');
      expect(models.first.contextWindow, 1000000);
      expect(models.first.thinkingLevels, isNotNull);
      expect(models.first.defaultThinkingLevel, isNotNull);
      expect(models.last.name, 'Claude Opus 5.5');
    });

    test('results are read from the CLI once', () async {
      await service.listModels('claude-code');
      await service.listModels('claude-code');

      expect(probe.calls, 1);
    });

    test('without a catalog claude-code lists nothing', () async {
      expect(await AcpModelsService().listModels('claude-code'), isEmpty);
    });

    test('returns empty list for unknown adapter id', () async {
      expect(await service.listModels('unknown-adapter'), isEmpty);
    });

    test('codex is not an adapter catalog', () async {
      expect(await service.listModels('codex'), isEmpty);
    });

    test('Cursor is not an adapter catalog', () async {
      expect(await service.listModels('cursor'), isEmpty);
      expect(await service.listModels('cursor-agent'), isEmpty);
    });
  });
}

/// Answers as the CLI would: one alias, resolving to Opus 5.5.
class _FakeProbe extends ClaudeCodeModelProbe {
  int calls = 0;

  @override
  Future<ClaudeCodeProbeResult> probe({
    required String binaryPath,
    String? configDir,
    bool listCatalog = true,
    List<String> extraIds = const [],
  }) async {
    calls++;
    return const ClaudeCodeProbeResult(
      models: [
        ClaudeCodeProbedModel(
          value: 'opus',
          resolvedModel: 'claude-opus-5-5',
          displayName: 'Opus 5.5',
          effortLevels: ['low', 'medium', 'high'],
          contextWindow: 1000000,
        ),
      ],
      defaultWindow: 1000000,
      extras: {},
    );
  }
}
