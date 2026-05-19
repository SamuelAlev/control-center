import 'dart:io';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/pipelines/condition_template.dart';
import 'package:test/test.dart';

/// Exercises the `pipeline.condition` router body: the predicate-tree mode
/// (fileExists / comparison / and / or / not), the switch mode and the legacy
/// top-level comparison mode. The body is registered against a fake template
/// repo that returns a step with the under-test `config.extras`, then invoked
/// through the registry like the real engine does.

PipelineContext _ctx({
  required String stepId,
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? trigger,
}) => PipelineContext(
  pipelineRunId: 'run-1',
  templateId: 'tpl-1',
  stepId: stepId,
  stepRunId: 'sr-1',
  workspaceId: 'ws-1',
  state: state,
  triggerPayload: trigger,
);

({PipelineBodyRegistry registry, _FakeTemplateRepo repo}) _build(
  Map<String, dynamic> extras,
) {
  final repo = _FakeTemplateRepo(extras);
  final registry = PipelineBodyRegistry();
  registerConditionBody(
    registry,
    templateRepository: repo,
    runDirPath: (_) async => '/tmp/cc-run',
  );
  return (registry: registry, repo: repo);
}

Future<StepResult> _run(
  Map<String, dynamic> extras, {
  Map<String, dynamic> state = const {},
  Map<String, dynamic>? trigger,
  String stepId = 'cond',
}) async {
  final b = _build(extras);
  return b.registry.body(BuiltInBodyKeys.condition)(
    _ctx(stepId: stepId, state: state, trigger: trigger),
  );
}

void main() {
  group('registerConditionBody — missing config', () {
    test('fails the step when the template has no such step config', () async {
      final registry = PipelineBodyRegistry();
      final repo = _NullTemplateRepo();
      registerConditionBody(
        registry,
        templateRepository: repo,
        runDirPath: (_) async => '/tmp',
      );
      final res = await registry.body(BuiltInBodyKeys.condition)(
        _ctx(stepId: 'nope'),
      );
      expect(res.errorMessage, contains('missing config'));
    });
  });

  group('registerConditionBody — predicate comparison mode', () {
    test('routes "true" when gt comparison holds', () async {
      final res = await _run(
        {
          'predicate': {
            'type': 'comparison',
            'left': '{{score}}',
            'op': 'gt',
            'right': 80,
          },
        },
        state: {'score': 95},
      );
      expect(res.nextRouterKey, 'true');
    });

    test('routes "false" when gt comparison fails', () async {
      final res = await _run(
        {
          'predicate': {
            'type': 'comparison',
            'left': '{{score}}',
            'op': 'gt',
            'right': 80,
          },
        },
        state: {'score': 40},
      );
      expect(res.nextRouterKey, 'false');
    });

    test('equals / notEquals / contains operators', () async {
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{x}}',
              'op': 'equals',
              'right': 'yes',
            },
          },
          state: {'x': 'yes'},
        )).nextRouterKey,
        'true',
      );
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{x}}',
              'op': 'notEquals',
              'right': 'yes',
            },
          },
          state: {'x': 'no'},
        )).nextRouterKey,
        'true',
      );
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{x}}',
              'op': 'contains',
              'right': 'foo',
            },
          },
          state: {'x': 'foobar'},
        )).nextRouterKey,
        'true',
      );
    });

    test('lt operator', () async {
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{n}}',
              'op': 'lt',
              'right': 5,
            },
          },
          state: {'n': 3},
        )).nextRouterKey,
        'true',
      );
    });

    test('exists / notExists operators', () async {
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{x}}',
              'op': 'exists',
            },
          },
          state: {'x': 'present'},
        )).nextRouterKey,
        'true',
      );
      expect(
        (await _run({
          'predicate': {
            'type': 'comparison',
            'left': '{{x}}',
            'op': 'notExists',
          },
        }, state: <String, dynamic>{})).nextRouterKey,
        'true',
      );
    });

    test('unknown operator evaluates to false', () async {
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'comparison',
              'left': '{{x}}',
              'op': 'bogus',
              'right': 1,
            },
          },
          state: {'x': 1},
        )).nextRouterKey,
        'false',
      );
    });

    test(
      'resolves a bare state key (no {{}}) preserving its runtime type',
      () async {
        // A bare key look-up returns the raw value, so numeric gt works.
        expect(
          (await _run(
            {
              'predicate': {
                'type': 'comparison',
                'left': 'count',
                'op': 'gt',
                'right': 5,
              },
            },
            state: {'count': 10},
          )).nextRouterKey,
          'true',
        );
      },
    );
  });

  group('registerConditionBody — boolean groups', () {
    test('and: all-true → true; one false → false', () async {
      final andTrue = await _run(
        {
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
        state: {'a': '1', 'b': '2'},
      );
      expect(andTrue.nextRouterKey, 'true');

      final andFalse = await _run(
        {
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
                'right': '9',
              },
            ],
          },
        },
        state: {'a': '1', 'b': '2'},
      );
      expect(andFalse.nextRouterKey, 'false');
    });

    test('or: any true → true; all false → false', () async {
      expect(
        (await _run(
          {
            'predicate': {
              'type': 'or',
              'of': [
                {
                  'type': 'comparison',
                  'left': '{{a}}',
                  'op': 'equals',
                  'right': 'no',
                },
                {
                  'type': 'comparison',
                  'left': '{{b}}',
                  'op': 'equals',
                  'right': 'yes',
                },
              ],
            },
          },
          state: {'a': 'no', 'b': 'x'},
        )).nextRouterKey,
        'true',
      );
    });

    test('not: negates a single child (map form)', () async {
      expect(
        (await _run(
          {
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
          state: {'a': '2'},
        )).nextRouterKey,
        'true',
      );
    });

    test('not with no child fails the step', () async {
      final res = await _run({
        'predicate': {'type': 'not', 'of': <Map<String, dynamic>>[]},
      });
      expect(res.errorMessage, contains('no child'));
    });

    test('unknown predicate type fails the step', () async {
      final res = await _run({
        'predicate': {'type': 'mystery'},
      });
      expect(res.errorMessage, contains('unknown predicate type'));
    });
  });

  group('registerConditionBody — switch mode', () {
    test(
      'routes to the first case the value (case-insensitively) contains',
      () async {
        final res = await _run(
          {
            'switchKey': 'pr_class',
            'cases': ['docs', 'security', 'standard'],
            'default': 'standard',
          },
          state: {'pr_class': 'SECURITY-fix'},
        );
        expect(res.nextRouterKey, 'security');
      },
    );

    test('falls back to default when no case matches', () async {
      final res = await _run(
        {
          'switchKey': 'pr_class',
          'cases': ['docs', 'security'],
          'default': 'standard',
        },
        state: {'pr_class': 'feature'},
      );
      expect(res.nextRouterKey, 'standard');
    });

    test(
      'uses the first case when no default is provided and none match',
      () async {
        final res = await _run(
          {
            'switchKey': 'pr_class',
            'cases': ['docs'],
          },
          state: {'pr_class': 'feature'},
        );
        expect(res.nextRouterKey, 'docs');
      },
    );

    test('falls back to trigger payload when state has no value', () async {
      final res = await _run(
        {
          'switchKey': 'kind',
          'cases': ['a'],
        },
        state: <String, dynamic>{},
        trigger: {'kind': 'aaa'},
      );
      expect(res.nextRouterKey, 'a');
    });

    test(
      'fails when value matches nothing and cases is empty with no default',
      () async {
        final res = await _run(
          {'switchKey': 'kind', 'cases': <String>[]},
          state: {'kind': 'x'},
        );
        expect(res.errorMessage, contains('no matching case'));
      },
    );
  });

  group('registerConditionBody — legacy top-level comparison', () {
    test('routes true/false from a bare left/op/right', () async {
      expect(
        (await _run(
          {'left': '{{score}}', 'op': 'gt', 'right': 10},
          state: {'score': 50},
        )).nextRouterKey,
        'true',
      );
    });

    test('defaults op to "exists" when omitted', () async {
      expect(
        (await _run({'left': '{{x}}'}, state: {'x': 'here'})).nextRouterKey,
        'true',
      );
    });
  });

  group('registerConditionBody — fileExists predicate', () {
    test('routes true when a listed path exists on disk', () async {
      // The test file itself always exists. The BASE is resolved rather than
      // assumed to be the CWD: `dart test packages/cc_infra` from the repo root
      // and `dart test` from the package root have different working
      // directories, and hardcoding `.` made this fail on the first — which
      // reads as a broken predicate rather than a broken path.
      final res = await _run(
        {
          'predicate': {
            'type': 'fileExists',
            'paths': ['test/pipelines/condition_template_test.dart'],
            'baseKey': 'repo_local_path',
          },
        },
        state: {'repo_local_path': _packageRoot()},
      );
      expect(res.nextRouterKey, 'true');
    });

    test('routes false when no listed path exists', () async {
      final res = await _run(
        {
          'predicate': {
            'type': 'fileExists',
            'paths': ['definitely_not_here.xyz'],
            'baseKey': 'repo_local_path',
          },
        },
        state: {'repo_local_path': '/tmp'},
      );
      expect(res.nextRouterKey, 'false');
    });

    test('negate flips the result', () async {
      final res = await _run(
        {
          'predicate': {
            'type': 'fileExists',
            'paths': ['definitely_not_here.xyz'],
            'baseKey': 'repo_local_path',
            'negate': true,
          },
        },
        state: {'repo_local_path': '/tmp'},
      );
      expect(res.nextRouterKey, 'true');
    });

    test('fails when no paths are listed', () async {
      final res = await _run(
        {
          'predicate': {'type': 'fileExists', 'paths': <String>[]},
        },
        state: {'repo_local_path': '/tmp'},
      );
      expect(res.errorMessage, contains('no paths'));
    });
  });
}

// --- Fakes ----------------------------------------------------------------

class _FakeTemplateRepository implements PipelineTemplateRepository {
  _FakeTemplateRepository(this._extras);
  final Map<String, dynamic> _extras;

  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) {
    return Future.value(
      PipelineDefinition(
        templateId: templateId,
        workspaceId: workspaceId,
        name: 'test',
        steps: [
          PipelineStepDefinition(
            id: 'cond',
            kind: StepKind.router,
            bodyKey: BuiltInBodyKeys.condition,
            config: PipelineNodeConfig(extras: _extras),
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Concrete subclass so `step('cond')` resolves to a config carrying `extras`.
class _FakeTemplateRepo extends _FakeTemplateRepository {
  _FakeTemplateRepo(super.extras);
}

class _NullTemplateRepo extends _FakeTemplateRepository {
  _NullTemplateRepo() : super(const {});
  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) =>
      Future.value(null);
}

/// The `cc_infra` package root, wherever the runner was started from.
String _packageRoot() {
  var dir = Directory.current;
  while (true) {
    for (final candidate in [
      dir.path,
      '${dir.path}/packages/cc_infra',
    ]) {
      if (File('$candidate/pubspec.yaml').existsSync() &&
          Directory('$candidate/test/pipelines').existsSync()) {
        return candidate;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the cc_infra root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
