import 'dart:io';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/pipelines/condition_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake exposing a single template via [getById].
class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) async =>
      _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cond_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  /// Builds the registered condition body bound to a one-step template whose
  /// router config carries [extras], then runs it with `repoLocalPath` pointing
  /// at the temp dir, and returns the route key it chose.
  Future<String?> route(Map<String, dynamic> extras) async {
    final def = PipelineDefinition(
      templateId: 't',
      workspaceId: 'w',
      name: 'T',
      steps: [
        PipelineStepDefinition(
          id: 'cond',
          kind: StepKind.router,
          bodyKey: BuiltInBodyKeys.condition,
          config: PipelineNodeConfig(label: 'Cond', extras: extras),
        ),
      ],
    );
    final registry = PipelineBodyRegistry();
    registerConditionBody(registry, templateRepository: _FakeTemplateRepo(def), runDirPath: (_) async => Directory.systemTemp.path);
    final result = await registry.body(BuiltInBodyKeys.condition)(
      PipelineContext(
        pipelineRunId: 'run1',
        templateId: 't',
        stepId: 'cond',
        stepRunId: 'sr1',
        workspaceId: 'w',
        state: {'repoLocalPath': tmp.path},
      ),
    );
    return result.nextRouterKey;
  }

  void touch(String relative) {
    final f = File('${tmp.path}/$relative')..parent.createSync(recursive: true);
    f.writeAsStringSync('x');
  }

  group('fileExists predicate', () {
    test('routes true when the file exists, false when absent', () async {
      touch('Cargo.toml');
      expect(
        await route({
          'predicate': {'type': 'fileExists', 'paths': ['Cargo.toml']},
        }),
        'true',
      );
      expect(
        await route({
          'predicate': {'type': 'fileExists', 'paths': ['pubspec.yaml']},
        }),
        'false',
      );
    });

    test('any-of: routes true when any listed path exists', () async {
      touch('yarn.lock');
      expect(
        await route({
          'predicate': {
            'type': 'fileExists',
            'paths': ['package-lock.json', 'yarn.lock', 'pnpm-lock.yaml'],
          },
        }),
        'true',
      );
    });

    test('negate routes true only when none exist', () async {
      expect(
        await route({
          'predicate': {
            'type': 'fileExists',
            'paths': ['Cargo.toml'],
            'negate': true,
          },
        }),
        'true',
      );
      touch('Cargo.toml');
      expect(
        await route({
          'predicate': {
            'type': 'fileExists',
            'paths': ['Cargo.toml'],
            'negate': true,
          },
        }),
        'false',
      );
    });

    test('recursive finds a manifest in a subdirectory', () async {
      touch('packages/app/pubspec.yaml');
      // Non-recursive: not at the root → false.
      expect(
        await route({
          'predicate': {'type': 'fileExists', 'paths': ['pubspec.yaml']},
        }),
        'false',
      );
      // Recursive: found under packages/app → true.
      expect(
        await route({
          'predicate': {
            'type': 'fileExists',
            'paths': ['pubspec.yaml'],
            'recursive': true,
          },
        }),
        'true',
      );
    });
  });

  group('boolean groups', () {
    test('and requires every leaf', () async {
      touch('package.json');
      Map<String, dynamic> andOf(List<String> files) => {
            'predicate': {
              'type': 'and',
              'of': [
                for (final f in files)
                  {'type': 'fileExists', 'paths': [f]},
              ],
            },
          };
      expect(await route(andOf(['package.json', 'tsconfig.json'])), 'false');
      touch('tsconfig.json');
      expect(await route(andOf(['package.json', 'tsconfig.json'])), 'true');
    });

    test('or matches any leaf', () async {
      touch('pnpm-lock.yaml');
      expect(
        await route({
          'predicate': {
            'type': 'or',
            'of': [
              {'type': 'fileExists', 'paths': ['yarn.lock']},
              {'type': 'fileExists', 'paths': ['pnpm-lock.yaml']},
            ],
          },
        }),
        'true',
      );
    });
  });

  group('comparison predicate', () {
    test('gt routes on numeric state', () async {
      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [
          PipelineStepDefinition(
            id: 'cond',
            kind: StepKind.router,
            bodyKey: BuiltInBodyKeys.condition,
            config: const PipelineNodeConfig(extras: {
              'predicate': {
                'type': 'comparison',
                'left': '{{score}}',
                'op': 'gt',
                'right': 80,
              },
            }),
          ),
        ],
      );
      final registry = PipelineBodyRegistry();
      registerConditionBody(registry,
          templateRepository: _FakeTemplateRepo(def), runDirPath: (_) async => Directory.systemTemp.path);
      Future<String?> withScore(int score) async {
        final r = await registry.body(BuiltInBodyKeys.condition)(
          PipelineContext(
            pipelineRunId: 'run1',
            templateId: 't',
            stepId: 'cond',
            stepRunId: 'sr1',
            workspaceId: 'w',
            state: {'score': score},
          ),
        );
        return r.nextRouterKey;
      }

      expect(await withScore(90), 'true');
      expect(await withScore(50), 'false');
    });
  });

  test('malformed predicate fails the step', () async {
    final def = PipelineDefinition(
      templateId: 't',
      workspaceId: 'w',
      name: 'T',
      steps: [
        PipelineStepDefinition(
          id: 'cond',
          kind: StepKind.router,
          bodyKey: BuiltInBodyKeys.condition,
          config: const PipelineNodeConfig(extras: {
            'predicate': {'type': 'fileExists', 'paths': <String>[]},
          }),
        ),
      ],
    );
    final registry = PipelineBodyRegistry();
    registerConditionBody(registry, templateRepository: _FakeTemplateRepo(def), runDirPath: (_) async => Directory.systemTemp.path);
    final r = await registry.body(BuiltInBodyKeys.condition)(
      const PipelineContext(
        pipelineRunId: 'run1',
        templateId: 't',
        stepId: 'cond',
        stepRunId: 'sr1',
        workspaceId: 'w',
        state: {'repoLocalPath': '/tmp/does-not-matter'},
      ),
    );
    expect(r.isFailed, isTrue);
  });
}
