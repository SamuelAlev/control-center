import 'package:control_center/core/infrastructure/validation/json_schema_validator.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:control_center/features/pipelines/domain/services/state_reducer.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemplateRenderer', () {
    const r = TemplateRenderer();

    test('substitutes bare, state, and trigger-scoped refs', () {
      final out = r.render(
        'PR #{{prNumber}} by {{\$trigger.author}} at {{\$state.path}}',
        state: {'prNumber': 42, 'path': '/repo'},
        trigger: {'author': 'octocat'},
      );
      expect(out.text, 'PR #42 by octocat at /repo');
      expect(out.unresolved, isEmpty);
      expect(out.isComplete, isTrue);
    });

    test('reports unresolved placeholders and renders them empty', () {
      final out = r.render('a={{a}} b={{b}}', state: {'a': 1});
      expect(out.text, 'a=1 b=');
      expect(out.unresolved, {'b'});
    });

    test('state takes precedence over trigger for bare keys', () {
      final out =
          r.render('{{k}}', state: {'k': 'state'}, trigger: {'k': 'trigger'});
      expect(out.text, 'state');
    });

    test('placeholders() and stateKeyOf() classify refs', () {
      expect(r.placeholders('{{a}} {{\$trigger.b}}'), {'a', r'$trigger.b'});
      expect(r.isTriggerScoped(r'$trigger.b'), isTrue);
      expect(r.stateKeyOf(r'$state.x'), 'x');
      expect(r.stateKeyOf(r'$trigger.x'), isNull);
    });
  });

  group('StateReducer', () {
    const s = StateReducer();

    test('first write returns incoming (append wraps scalars)', () {
      expect(s.apply('override', null, 5), 5);
      expect(s.apply('append', null, 'x'), ['x']);
    });

    test('append accumulates', () {
      expect(s.apply('append', ['a'], 'b'), ['a', 'b']);
      expect(s.apply('append', ['a'], ['b', 'c']), ['a', 'b', 'c']);
    });

    test('mergeLists and mergeMaps and sum', () {
      expect(s.apply('mergeLists', [1], [2, 3]), [1, 2, 3]);
      expect(s.apply('mergeMaps', {'a': 1}, {'b': 2}), {'a': 1, 'b': 2});
      expect(s.apply('sum', 2, 3), 5);
    });

    test('override and unknown fall back to incoming', () {
      expect(s.apply('override', 'old', 'new'), 'new');
      expect(s.apply(null, 'old', 'new'), 'new');
    });
  });

  group('JsonSchemaValidator', () {
    const v = JsonSchemaValidator();

    test('valid object passes', () {
      final errs = v.validate(
        {'name': 'x', 'count': 3},
        {
          'type': 'object',
          'required': ['name'],
          'properties': {
            'name': {'type': 'string'},
            'count': {'type': 'integer'},
          },
        },
      );
      expect(errs, isEmpty);
    });

    test('missing required + wrong type are reported', () {
      final errs = v.validate(
        {'count': 'nope'},
        {
          'type': 'object',
          'required': ['name'],
          'properties': {
            'name': {'type': 'string'},
            'count': {'type': 'integer'},
          },
        },
      );
      expect(errs.length, 2);
    });

    test('enum and array item validation', () {
      expect(
        v.validate('c', {
          'type': 'string',
          'enum': ['a', 'b'],
        }),
        isNotEmpty,
      );
      expect(
        v.validate([1, 'x'], {
          'type': 'array',
          'items': {'type': 'integer'},
        }),
        isNotEmpty,
      );
    });
  });

  group('PipelineValidator', () {
    const validator = PipelineValidator();

    PipelineDefinition def(List<PipelineStepDefinition> steps) =>
        PipelineDefinition(
          templateId: 't',
          workspaceId: 'w',
          name: 'T',
          steps: steps,
        );

    test('flags missing trigger and terminal', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
        ),
      ]));
      expect(
          issues.any((i) => i.isError && i.message.contains('trigger')), isTrue);
      expect(
        issues.any((i) => i.isError && i.message.contains('terminal')),
        isTrue,
      );
    });

    test('router without a routed edge is an error', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'pipeline.condition',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['r'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('Router')),
        isTrue,
      );
    });

    test('router with an empty file-exists predicate is an error', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'pipeline.condition',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {'type': 'fileExists', 'paths': <String>[]},
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [
            StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
          ],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no paths')),
        isTrue,
      );
    });

    test('router with an unknown predicate type is an error', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'pipeline.condition',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {'type': 'bogus'},
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [
            StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
          ],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('unknown condition type')),
        isTrue,
      );
    });

    test('switch router with no cases and no default is an error', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'pipeline.condition',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'switchKey': 'x',
            'cases': <String>[],
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [
            StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
          ],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) =>
            i.isError && i.message.contains('switch with no cases')),
        isTrue,
      );
    });

    test('and predicate with a single-map child is valid (matches runtime)', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'pipeline.condition',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'and',
              'of': {'type': 'fileExists', 'paths': ['Cargo.toml']},
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [
            StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
          ],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(issues.where((i) => i.isError), isEmpty);
    });

    test('undeclared input is a warning, not an error', () {
      final issues = validator.validate(def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'use',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(inputKeys: ['ghost']),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['use'])],
        ),
      ]));
      expect(issues.where((i) => i.isError), isEmpty);
      expect(
        issues.any((i) =>
            i.severity == PipelineIssueSeverity.warning &&
            i.message.contains('ghost')),
        isTrue,
      );
    });

    test('all built-in templates are structurally valid (no errors)', () {
      const ids = BuiltInAgentIds(
        qa: 'qa',
        architect: 'arch',
        engineer: 'eng',
        librarian: 'lib',
        ceo: 'ceo',
      );
      final seeds = builtInTemplateSeeds(workspaceId: 'w', agentIds: ids);
      for (final seed in seeds) {
        final errors = validator.errors(seed);
        expect(
          errors,
          isEmpty,
          reason: 'Template "${seed.templateId}" has errors: '
              '${errors.map((e) => e.message).join('; ')}',
        );
      }
    });
  });
}
