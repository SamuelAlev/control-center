import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineDefinition _def(List<PipelineStepDefinition> steps) => PipelineDefinition(
      templateId: 't',
      workspaceId: 'w',
      name: 'T',
      steps: steps,
    );

void main() {
  group('PipelineIssue', () {
    test('isError returns true for error severity',
        timeout: const Timeout.factor(2), () {
      const issue = PipelineIssue(
        severity: PipelineIssueSeverity.error,
        message: 'test',
      );
      expect(issue.isError, isTrue);
    });

    test('isError returns false for warning severity',
        timeout: const Timeout.factor(2), () {
      const issue = PipelineIssue(
        severity: PipelineIssueSeverity.warning,
        message: 'test',
      );
      expect(issue.isError, isFalse);
    });

    test('stepId is optional', timeout: const Timeout.factor(2), () {
      const issue = PipelineIssue(
        severity: PipelineIssueSeverity.error,
        message: 'test',
        stepId: 's1',
      );
      expect(issue.stepId, 's1');
    });
  });

  group('PipelineValidationException', () {
    test('toString formats issues', timeout: const Timeout.factor(2), () {
      final ex = PipelineValidationException([
        const PipelineIssue(
          severity: PipelineIssueSeverity.error,
          message: 'err1',
        ),
        const PipelineIssue(
          severity: PipelineIssueSeverity.error,
          message: 'err2',
        ),
      ]);
      expect(ex.toString(), contains('err1'));
      expect(ex.toString(), contains('err2'));
    });
  });

  group('PipelineValidator', () {
    const validator = PipelineValidator();

    // ── Structural ──────────────────────────────────────────────────────

    test('valid minimal pipeline passes', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
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

    test('flags missing trigger step', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 'a', kind: StepKind.listen, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no trigger')),
        isTrue,
      );
    });

    test('flags multiple trigger steps', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's1', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(id: 's2', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('2 trigger')),
        isTrue,
      );
    });

    test('flags trigger step with upstream edges',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(
          id: 's',
          kind: StepKind.trigger,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['some_other_step'])],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('cannot have upstream')),
        isTrue,
      );
    });

    test('flags missing terminal step', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(id: 'a', kind: StepKind.listen, bodyKey: 'b'),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no terminal')),
        isTrue,
      );
    });

    test('flags empty pipeline', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([]));
      expect(issues.where((i) => i.isError), isNotEmpty);
      expect(issues.any((i) => i.message.contains('no trigger')), isTrue);
      expect(issues.any((i) => i.message.contains('no terminal')), isTrue);
    });

    // ── Duplicates ──────────────────────────────────────────────────────

    test('flags duplicate step ids', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(id: 'dup', kind: StepKind.listen, bodyKey: 'b',
            triggers: const [StepTrigger(sourceStepIds: ['s'])]),
        PipelineStepDefinition(id: 'dup', kind: StepKind.listen, bodyKey: 'b',
            triggers: const [StepTrigger(sourceStepIds: ['s'])]),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['dup'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('Duplicate step id')),
        isTrue,
      );
    });

    // ── Edge references ─────────────────────────────────────────────────

    test('flags edge referencing non-existent step',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['ghost'])],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('does not exist')),
        isTrue,
      );
    });

    test('flags routed edge from non-router step',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
        ),
        PipelineStepDefinition(
          id: 'b',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['a'], routeKey: 'x')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['b'])],
        ),
      ]));
      expect(
        issues.any((i) =>
            i.isError && i.message.contains('not a router')),
        isTrue,
      );
    });

    test('flags join waitForStepIds referencing non-existent step',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'j',
          kind: StepKind.join,
          bodyKey: 'b',
          waitForStepIds: const ['ghost'],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('does not exist')),
        isTrue,
      );
    });

    // ── Router validation ───────────────────────────────────────────────

    test('flags router with no routed outgoing edges',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
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
        issues.any((i) => i.isError && i.message.contains('no routed outgoing')),
        isTrue,
      );
    });

    test('router with valid routed edges passes router check',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'yes')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no routed outgoing')),
        isFalse,
      );
    });

    // ── Router predicate validation (exercises _predicateIssues) ────────

    test('router with fileExists predicate and valid paths passes',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['Cargo.toml'],
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('predicate')),
        isFalse,
      );
    });

    test('router with fileExists predicate and no paths warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'fileExists',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
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

    test('router with comparison predicate passes with valid fields',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'status',
              'op': 'equals',
              'right': 'done',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('comparison')),
        isFalse,
      );
    });

    test('router with comparison predicate missing left operand warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'op': 'equals',
              'right': 'done',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no "left"')),
        isTrue,
      );
    });

    test('router with comparison predicate missing operator warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'a',
              'right': 'b',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no operator')),
        isTrue,
      );
    });

    test('router with comparison predicate and unknown operator warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'a',
              'op': 'bogus',
              'right': 'b',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('unknown operator')),
        isTrue,
      );
    });

    test('router with comparison predicate exists without right passes',
        timeout: const Timeout.factor(2), () {
      // "exists" and "notExists" are unary — no right operand needed.
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'key',
              'op': 'exists',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any(
            (i) => i.isError && i.message.contains('no "right" operand')),
        isFalse,
      );
    });

    test('router with comparison predicate equals without right warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'comparison',
              'left': 'key',
              'op': 'equals',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any(
            (i) => i.isError && i.message.contains('no "right" operand')),
        isTrue,
      );
    });

    test('router with and predicate group validates children',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'and',
              'of': [
                {'type': 'fileExists', 'paths': ['Cargo.toml']},
                {'type': 'fileExists', 'paths': ['README.md']},
              ],
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('condition')),
        isFalse,
      );
    });

    test('router with empty and group warns', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'and',
              'of': [],
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('empty')),
        isTrue,
      );
    });

    test('router with or predicate group validates children',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'or',
              'of': [
                {'type': 'fileExists', 'paths': ['package.json']},
              ],
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('condition')),
        isFalse,
      );
    });

    test('router with not predicate validates',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'not',
              'of': {'type': 'fileExists', 'paths': ['Cargo.toml']},
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('not')),
        isFalse,
      );
    });

    test('router with not predicate and no child warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'not',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no child')),
        isTrue,
      );
    });

    test('router with unknown condition type warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'predicate': {
              'type': 'magic',
            },
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')],
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

    // ── Router switch mode validation ───────────────────────────────────

    test('router switch with no cases and no default warns',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'switchKey': 'category',
            'cases': <String>[],
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'a')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no cases')),
        isTrue,
      );
    });

    test('router switch with cases passes', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'switchKey': 'category',
            'cases': ['a', 'b'],
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'a')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('switch')),
        isFalse,
      );
    });

    test('router switch with default only passes',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'switchKey': 'category',
            'default': 'fallback',
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers:
              const [StepTrigger(sourceStepIds: ['r'], routeKey: 'fallback')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.isError && i.message.contains('no cases')),
        isFalse,
      );
    });

    test('router with empty string switchKey not treated as switch',
        timeout: const Timeout.factor(2), () {
      // empty switchKey should not trigger switch validation
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'r',
          kind: StepKind.router,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {
            'switchKey': '',
          }),
        ),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'x')],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      // Should not warn about switch — only about no predicate (which is absent
      // too, but that path is a no-op)
      expect(
        issues.any((i) => i.isError && i.message.contains('switch')),
        isFalse,
      );
    });

    // ── Reducer validation ──────────────────────────────────────────────

    test('flags unknown reducer name', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(reducer: 'bogus'),
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
            i.isError && i.message.contains('unknown reducer')),
        isTrue,
      );
    });

    test('known reducers pass validation', () {
      for (final r in ['append', 'mergeLists', 'mergeMaps', 'sum']) {
        final issues = validator.validate(_def([
          PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
          PipelineStepDefinition(
            id: 'a',
            kind: StepKind.listen,
            bodyKey: 'b',
            triggers: const [StepTrigger(sourceStepIds: ['s'])],
            config: PipelineNodeConfig(reducer: r),
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_t',
            triggers: const [StepTrigger(sourceStepIds: ['a'])],
          ),
        ]));
        expect(
          issues.any((i) => i.isError && i.message.contains('unknown reducer')),
          isFalse,
          reason: 'Reducer "$r" should be known',
        );
      }
    });

    // ── Duplicate output keys ───────────────────────────────────────────

    test('warns about duplicate output keys without reducer',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'out'),
        ),
        PipelineStepDefinition(
          id: 'b',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'out'),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a', 'b'])],
        ),
      ]));
      expect(
        issues.any((i) =>
            i.severity == PipelineIssueSeverity.warning &&
            i.message.contains('Output key "out"')),
        isTrue,
      );
    });

    test('no warning when duplicate output keys have a reducer',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'out', reducer: 'append'),
        ),
        PipelineStepDefinition(
          id: 'b',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'out', reducer: 'append'),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a', 'b'])],
        ),
      ]));
      expect(
        issues.any((i) => i.message.contains('Output key "out"')),
        isFalse,
      );
    });

    test('no warning for single producer of output key',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'out'),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.message.contains('Output key')),
        isFalse,
      );
    });

    // ── Consumed keys ───────────────────────────────────────────────────

    test('warns about consumed keys not produced upstream',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(inputKeys: ['ghost_key']),
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
            i.severity == PipelineIssueSeverity.warning &&
            i.message.contains('ghost_key')),
        isTrue,
      );
    });

    test('no warning for trigger-scoped placeholders',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(prompt: r'{{$trigger.author}}'),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      expect(
        issues.any((i) => i.message.contains(r'$trigger.author')),
        isFalse,
      );
    });

    test('warns about prompt placeholders for unproduced keys',
        timeout: const Timeout.factor(2), () {
      // Bare key in prompt that isn't produced upstream → warning
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(prompt: 'Hello {{missing_key}}'),
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
            i.severity == PipelineIssueSeverity.warning &&
            i.message.contains('missing_key')),
        isTrue,
      );
    });

    test('no warning when consumed key is produced upstream',
        timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'producer',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(outputKey: 'my_data'),
        ),
        PipelineStepDefinition(
          id: 'consumer',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['producer'])],
          config: const PipelineNodeConfig(inputKeys: ['my_data']),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['consumer'])],
        ),
      ]));
      expect(
        issues.any((i) => i.message.contains('my_data')),
        isFalse,
      );
    });

    test('no warning when consumed key is produced by the step itself',
        timeout: const Timeout.factor(2), () {
      // A step that both produces and consumes the same key shouldn't warn.
      // (Self-referencing: outputKey = 'x', inputKeys = ['x'])
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(
            inputKeys: ['self_key'],
            outputKey: 'self_key',
          ),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      // Check that 'self_key' is in producedBy AND consumed, so no warning.
      expect(
        issues.any((i) =>
            i.severity == PipelineIssueSeverity.warning &&
            i.message.contains('self_key')),
        isFalse,
      );
    });

    // ── forEach validation ──────────────────────────────────────────────

    test('flags forEach without iterableKey', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'fe',
          kind: StepKind.forEach,
          bodyKey: 'flow.forEach',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['fe'])],
        ),
      ]));
      expect(
        issues.any((i) =>
            i.isError && i.message.contains('iterableKey')),
        isTrue,
      );
    });

    test('forEach with iterableKey passes', timeout: const Timeout.factor(2), () {
      final issues = validator.validate(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'fe',
          kind: StepKind.forEach,
          bodyKey: 'flow.forEach',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(extras: {'iterableKey': 'items'}),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['fe'])],
        ),
      ]));
      expect(
        issues.where((i) => i.isError && i.message.contains('iterableKey')),
        isEmpty,
      );
    });

    // ── errors() ────────────────────────────────────────────────────────

    test('errors() returns only error-severity issues',
        timeout: const Timeout.factor(2), () {
      final errors = validator.errors(_def([
        PipelineStepDefinition(id: 's', kind: StepKind.trigger, bodyKey: 'b'),
        PipelineStepDefinition(
          id: 'a',
          kind: StepKind.listen,
          bodyKey: 'b',
          triggers: const [StepTrigger(sourceStepIds: ['s'])],
          config: const PipelineNodeConfig(inputKeys: ['ghost']),
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_t',
          triggers: const [StepTrigger(sourceStepIds: ['a'])],
        ),
      ]));
      // ghost is a warning, not an error
      expect(errors.every((i) => i.isError), isTrue);
      expect(errors, isEmpty);
    });

    test('errors() includes structural errors', () {
      final errors = validator.errors(_def([]));
      expect(errors.length, greaterThanOrEqualTo(2));
      expect(errors.every((i) => i.isError), isTrue);
    });
  });
}
