import 'dart:io';

import 'package:control_center/features/pipelines/data/templates/condition_template.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._def);
  final PipelineDefinition _def;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async =>
      _def;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PipelineStepDefinition _step(String id, PipelineNodeConfig config) =>
    PipelineStepDefinition(
      id: id,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      config: config,
    );

PipelineDefinition _def(String stepId, PipelineNodeConfig config) =>
    PipelineDefinition(
      templateId: 'test-template',
      workspaceId: 'ws',
      name: 'Test Template',
      steps: [_step(stepId, config)],
    );

PipelineContext _ctx({
  required String stepId,
  required Map<String, dynamic> state,
  Map<String, dynamic>? triggerPayload,
}) =>
    PipelineContext(
      pipelineRunId: 'run-1',
      templateId: 'test-template',
      stepId: stepId,
      stepRunId: 'steprun-1',
      workspaceId: 'ws',
      state: state,
      triggerPayload: triggerPayload,
    );

Future<StepResult> Function(PipelineContext) _register({
  required PipelineNodeConfig config,
}) {
  final registry = PipelineBodyRegistry();
  final templateRepo = _FakeTemplateRepo(_def('step1', config));
  registerConditionBody(
    registry,
    templateRepository: templateRepo,
  );
  return registry.body(BuiltInBodyKeys.condition);
}

Future<StepResult> _invoke({
  required PipelineNodeConfig config,
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? trigger,
}) {
  final handler = _register(config: config);
  return handler(_ctx(stepId: 'step1', state: state, triggerPayload: trigger));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Predicate: comparison ────────────────────────────────────────────

  group('comparison predicate', () {
    test('equals — resolve left via template', () async {
      final result = await _invoke(
        state: {'value': 'hello'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'equals',
              'right': 'hello',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
      expect(result.isFailed, false);
    });

    test('equals false when values differ', () async {
      final result = await _invoke(
        state: {'value': 'hello'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'equals',
              'right': 'world',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('notEquals — resolve left via template', () async {
      final result = await _invoke(
        state: {'value': 'hello'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'notEquals',
              'right': 'world',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('contains substring', () async {
      final result = await _invoke(
        state: {'value': 'hello world'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'contains',
              'right': 'lo wo',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('contains false when substring absent', () async {
      final result = await _invoke(
        state: {'value': 'hello world'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'contains',
              'right': 'xyz',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('contains with null left is false', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'nonexistent',
              'op': 'contains',
              'right': 'x',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('exists — resolve left via bare key preserving type', () async {
      final result = await _invoke(
        state: {'value': 'something'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'value',
              'op': 'exists',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('exists — empty string resolves as false', () async {
      final result = await _invoke(
        state: {'value': ''},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'exists',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('notExists — null state key', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'nonexistent',
              'op': 'notExists',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('notExists — empty string in state', () async {
      final result = await _invoke(
        state: {'value': ''},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'notExists',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('gt — bare key lookup preserving int', () async {
      final result = await _invoke(
        state: {'score': 100},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'gt',
              'right': 50,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('gt false when not greater', () async {
      final result = await _invoke(
        state: {'score': 10},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'gt',
              'right': 50,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('lt — bare key lookup preserving int', () async {
      final result = await _invoke(
        state: {'score': 10},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'lt',
              'right': 50,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('lt false when not less', () async {
      final result = await _invoke(
        state: {'score': 100},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'lt',
              'right': 50,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('gt with string numeric right', () async {
      final result = await _invoke(
        state: {'score': 100},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'gt',
              'right': '50',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('gt with template-rendered left (stringifies)', () async {
      final result = await _invoke(
        state: {'score': 85},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{score}}',
              'op': 'gt',
              'right': 80,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('gt with non-numeric values is false', () async {
      final result = await _invoke(
        state: {'score': 'abc'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'gt',
              'right': 50,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('unknown operator returns false', () async {
      final result = await _invoke(
        state: {'x': 'val'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'x',
              'op': 'bogusOp',
              'right': 'y',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('resolves left from trigger payload via bare key', () async {
      final result = await _invoke(
        trigger: {'score': 90},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'score',
              'op': 'gt',
              'right': 80,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('resolves left from trigger payload via template', () async {
      final result = await _invoke(
        trigger: {'flag': 'on'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{flag}}',
              'op': 'equals',
              'right': 'on',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('null right in comparison stringified to "null"', () async {
      final result = await _invoke(
        state: {'value': 'null'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{value}}',
              'op': 'equals',
              'right': null,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });
  });

  // ── Predicate: boolean logic ─────────────────────────────────────────

  group('boolean logic predicates', () {
    test('and — all true → true', () async {
      final result = await _invoke(
        state: {'a': '1', 'b': '2'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'and',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'equals',
                  'right': '1',
                },
                {
                  'type': 'comparison',
                  'left': '{{b}}',
                  'op': 'equals',
                  'right': '2',
                },
              ],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('and — one false → false', () async {
      final result = await _invoke(
        state: {'a': '1', 'b': '2'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'and',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'equals',
                  'right': '1',
                },
                {
                  'type': 'comparison',
                  'left': '{{b}}',
                  'op': 'equals',
                  'right': 'X',
                },
              ],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('and with no children → vacuously true', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {'type': 'and'},
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('or — any true → true', () async {
      final result = await _invoke(
        state: {'a': '1', 'b': '2'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'or',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'equals',
                  'right': 'X',
                },
                {
                  'type': 'comparison',
                  'left': '{{b}}',
                  'op': 'equals',
                  'right': '2',
                },
              ],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('or — all false → false', () async {
      final result = await _invoke(
        state: {'a': '1', 'b': '2'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'or',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'equals',
                  'right': 'X',
                },
                {
                  'type': 'comparison',
                  'left': '{{b}}',
                  'op': 'equals',
                  'right': 'Y',
                },
              ],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('or with no children → false', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {'type': 'or'},
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('not — true becomes false', () async {
      final result = await _invoke(
        state: {'a': '1'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'not',
              'of': {
                'type': 'comparison',
                'left': '{{a}}',
                'op': 'equals',
                'right': '1',
              },
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('not — false becomes true', () async {
      final result = await _invoke(
        state: {'a': '1'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'not',
              'of': {
                'type': 'comparison',
                'left': '{{a}}',
                'op': 'equals',
                'right': 'X',
              },
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('not with no children → failed', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'not',
            },
          },
        ),
      );
      expect(result.isFailed, true);
      expect(result.errorMessage, contains('"not" predicate has no child'));
    });

    test('nested boolean logic', () async {
      // (score > 60) AND NOT(hasNotes is empty)
      // (75 > 60 → true) AND NOT('' exists → false) → true AND NOT(false) → true
      final result = await _invoke(
        state: {'score': 75, 'hasNotes': ''},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'and',
              'of': [
                {
                  'type': 'comparison',
                  'left': 'score',
                  'op': 'gt',
                  'right': 60,
                },
                {
                  'type': 'not',
                  'of': {
                    'type': 'comparison',
                    'left': '{{hasNotes}}',
                    'op': 'exists',
                  },
                },
              ],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('predicate of is absent → empty children for and (vacuously true)', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'and',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('not accepts list with one element', () async {
      final result = await _invoke(
        state: {'a': '1'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'not',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'notEquals',
                  'right': '1',
                },
              ],
            },
          },
        ),
      );
      // NOT(1 != 1) → NOT(false) → true
      expect(result.nextRouterKey, 'true');
    });
  });

  // ── Predicate: fileExists ────────────────────────────────────────────

  group('fileExists predicate', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('cond_test_');
    });

    tearDown(() {
      try {
        tmpDir.deleteSync(recursive: true);
      } on FileSystemException {
        // best-effort cleanup
      }
    });

    test('file exists → true', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('file missing → false', () async {
      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['nonexistent.txt'],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('any of multiple paths exist → true', () async {
      File('${tmpDir.path}/Cargo.lock').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml', 'Cargo.lock'],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('negate: no file → true (none exist)', () async {
      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['nonexistent.txt'],
              'negate': true,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('negate: file exists → false', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'negate': true,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('single path string (not list) works', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': 'Cargo.toml',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('single path convenience key', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'path': 'Cargo.toml',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('empty paths throws error', () async {
      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': [],
            },
          },
        ),
      );
      expect(result.isFailed, true);
      expect(result.errorMessage, contains('lists no paths'));
    });

    test('custom baseKey resolves', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'myCustomPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'baseKey': 'myCustomPath',
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('whitespace-only paths entry skipped gracefully', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['  ', 'Cargo.toml'],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('recursive finds file in subdirectory', () async {
      final sub = Directory('${tmpDir.path}/subdir');
      sub.createSync();
      File('${sub.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'recursive': true,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('recursive skips blacklisted dirs', () async {
      final skipped = Directory('${tmpDir.path}/node_modules');
      skipped.createSync();
      File('${skipped.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
              'recursive': true,
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('template rendering within path', () async {
      File('${tmpDir.path}/Cargo.toml').writeAsStringSync('');

      final result = await _invoke(
        state: {'repoLocalPath': tmpDir.path, 'manifest': 'Cargo.toml'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['{{manifest}}'],
            },
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });
  });

  // ── Switch mode ──────────────────────────────────────────────────────

  group('switch mode', () {
    test('matches case-insensitively (value contains case)', () async {
      final result = await _invoke(
        state: {'prClass': 'docs-update'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security', 'standard'],
            'default': 'standard',
          },
        ),
      );
      expect(result.nextRouterKey, 'docs');
    });

    test('matches when value contains case substring', () async {
      final result = await _invoke(
        state: {'prClass': 'this is a security-related PR'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security', 'standard'],
            'default': 'standard',
          },
        ),
      );
      expect(result.nextRouterKey, 'security');
    });

    test('returns default when no match', () async {
      final result = await _invoke(
        state: {'prClass': 'unknown-class'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security', 'standard'],
            'default': 'standard',
          },
        ),
      );
      expect(result.nextRouterKey, 'standard');
    });

    test('returns first case when no default and no match', () async {
      final result = await _invoke(
        state: {'prClass': 'unknown-class'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security'],
          },
        ),
      );
      expect(result.nextRouterKey, 'docs');
    });

    test('fallback from trigger payload', () async {
      final result = await _invoke(
        trigger: {'prClass': 'security review'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security', 'standard'],
            'default': 'standard',
          },
        ),
      );
      expect(result.nextRouterKey, 'security');
    });

    test('empty raw value with no cases → failed', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'missingKey',
            'cases': [],
          },
        ),
      );
      expect(result.isFailed, true);
      expect(result.errorMessage, contains('no matching case'));
    });

    test('mutatedState includes route key', () async {
      final result = await _invoke(
        state: {'prClass': 'standard pr'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['standard'],
          },
        ),
      );
      expect(result.nextRouterKey, 'standard');
      expect(result.mutatedState, containsPair('step1_route', 'standard'));
    });
  });

  // ── Legacy top-level comparison ──────────────────────────────────────

  group('legacy comparison mode', () {
    test('routes to true on equals match via state', () async {
      final result = await _invoke(
        state: {'val': 'hello'},
        config: const PipelineNodeConfig(
          extras: {
            'left': '{{val}}',
            'op': 'equals',
            'right': 'hello',
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('routes to false when not equal', () async {
      final result = await _invoke(
        state: {'val': 'hello'},
        config: const PipelineNodeConfig(
          extras: {
            'left': '{{val}}',
            'op': 'equals',
            'right': 'world',
          },
        ),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('defaults op to exists when missing', () async {
      final result = await _invoke(
        state: {'val': 'something'},
        config: const PipelineNodeConfig(
          extras: {
            'left': '{{val}}',
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('mutatedState includes route key', () async {
      final result = await _invoke(
        state: {'val': 'x'},
        config: const PipelineNodeConfig(
          extras: {
            'left': '{{val}}',
            'op': 'equals',
            'right': 'x',
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
      expect(result.mutatedState, containsPair('step1_route', 'true'));
    });

    test('uses trigger payload for left resolution', () async {
      final result = await _invoke(
        trigger: {'score': '90'},
        config: const PipelineNodeConfig(
          extras: {
            'left': '{{score}}',
            'op': 'equals',
            'right': '90',
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────

  group('edge cases', () {
    test('unknown predicate type → failed', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'bogusType',
            },
          },
        ),
      );
      expect(result.isFailed, true);
      expect(result.errorMessage, contains('unknown predicate type'));
    });

    test('empty predicate map (no type) → failed', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {},
          },
        ),
      );
      expect(result.isFailed, true);
      expect(result.errorMessage, contains('unknown predicate type'));
    });

    test('empty extras falls to legacy comparison', () async {
      final result = await _invoke(
        config: const PipelineNodeConfig(extras: {}),
      );
      expect(result.nextRouterKey, 'false');
    });

    test('predicate takes priority over legacy when both present', () async {
      final result = await _invoke(
        state: {'val': 'a'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{val}}',
              'op': 'equals',
              'right': 'a',
            },
            'left': 'X',
            'op': 'equals',
            'right': 'Y',
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });

    test('switch takes priority over legacy when both present', () async {
      final result = await _invoke(
        state: {'prClass': 'docs-update'},
        config: const PipelineNodeConfig(
          extras: {
            'switchKey': 'prClass',
            'cases': ['docs', 'security'],
            'left': 'X',
            'op': 'equals',
            'right': 'Y',
          },
        ),
      );
      expect(result.nextRouterKey, 'docs');
    });

    test('predicate takes priority over switch when both present', () async {
      final result = await _invoke(
        state: {'val': 'a', 'prClass': 'security'},
        config: const PipelineNodeConfig(
          extras: {
            'predicate': {
              'type': 'comparison',
              'left': '{{val}}',
              'op': 'equals',
              'right': 'a',
            },
            'switchKey': 'prClass',
            'cases': ['docs', 'security'],
          },
        ),
      );
      expect(result.nextRouterKey, 'true');
    });
  });
}
