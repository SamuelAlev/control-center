import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/downstream_planner.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineStepDefinition _step(
  String id,
  StepKind kind, {
  List<StepTrigger> triggers = const [],
  List<String> waitFor = const [],
}) =>
    PipelineStepDefinition(
      id: id,
      kind: kind,
      bodyKey: 'b',
      triggers: triggers,
      waitForStepIds: waitFor,
    );

PipelineDefinition _def(List<PipelineStepDefinition> steps) => PipelineDefinition(
      templateId: 't',
      workspaceId: 'w',
      name: 'T',
      steps: steps,
    );

void main() {
  group('DownstreamPlan', () {
    test('stores toSkip, toRun, terminalReached', timeout: const Timeout.factor(2), () {
      const plan = DownstreamPlan(
        toSkip: ['a'],
        toRun: ['b'],
        terminalReached: true,
      );
      expect(plan.toSkip, ['a']);
      expect(plan.toRun, ['b']);
      expect(plan.terminalReached, isTrue);
    });
  });

  group('planDownstream', () {
    test('nothing completed, nothing skipped returns empty plan', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {},
        skipped: {},
        existing: {},
        chosenRoutes: {},
      );
      expect(plan.toSkip, isEmpty);
      expect(plan.toRun, isEmpty);
      expect(plan.terminalReached, isFalse);
    });

    test('trigger completed → listeners run', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t'},
        skipped: {},
        existing: {'t'},
        chosenRoutes: {},
      );
      expect(plan.toRun, contains('a'));
      expect(plan.toSkip, isEmpty);
      expect(plan.terminalReached, isFalse);
    });

    test('completed step + completed listener → terminal reached', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t', 'a'},
        skipped: {},
        existing: {'t', 'a'},
        chosenRoutes: {},
      );
      expect(plan.terminalReached, isTrue);
    });

    test('router routes false → true branch skipped, false branch runs', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')]),
        _step('b', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'false')]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['b'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t', 'r'},
        skipped: {},
        existing: {'t', 'r'},
        chosenRoutes: {'r': 'false'},
      );

      expect(plan.toSkip, contains('a'));
      expect(plan.toRun, contains('b'));
      expect(plan.toRun, isNot(contains('a')));
    });

    test('skip propagates to descendants', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')]),
        _step('a_child', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a_child'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t', 'r'},
        skipped: {},
        existing: {'t', 'r'},
        chosenRoutes: {'r': 'false'},
      );

      expect(plan.toSkip, containsAll(['a', 'a_child']));
    });

    test('join fires when all waitForStepIds are completed or skipped', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('b', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('j', StepKind.join,
            triggers: const [StepTrigger(sourceStepIds: ['a', 'b'])],
            waitFor: ['a', 'b']),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['j'])]),
      ]);

      // 'a' completed, 'b' skipped — join should still fire
      final plan = planDownstream(
        definition: def,
        completed: {'t', 'a'},
        skipped: {'b'},
        existing: {'t', 'a', 'b'},
        chosenRoutes: {},
      );
      expect(plan.toRun, contains('j'));
    });

    test('join is never killed by skip propagation', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')]),
        _step('j', StepKind.join,
            triggers: const [StepTrigger(sourceStepIds: ['a'])],
            waitFor: ['a']),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['j'])]),
      ]);

      // Router chose 'false', so 'a' is dead. But join with 'a' should not be killed.
      final plan = planDownstream(
        definition: def,
        completed: {'t', 'r'},
        skipped: {},
        existing: {'t', 'r'},
        chosenRoutes: {'r': 'false'},
      );

      expect(plan.toSkip, contains('a'));
      // Join is not skipped (it's never killed), but won't run yet because 'a' is not terminal
      expect(plan.toSkip, isNot(contains('j')));
    });

    test('terminal reached only via completed branch, not skipped', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['r'], routeKey: 'true')]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      // Router chose 'false', so 'a' is skipped. Terminal's source is all-skipped.
      final plan = planDownstream(
        definition: def,
        completed: {'t', 'r'},
        skipped: {},
        existing: {'t', 'r'},
        chosenRoutes: {'r': 'false'},
      );

      expect(plan.terminalReached, isFalse);
    });

    test('existing steps are neither skipped nor run', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t'},
        skipped: {},
        existing: {'t', 'a'}, // 'a' already exists
        chosenRoutes: {},
      );
      expect(plan.toRun, isNot(contains('a')));
      expect(plan.toSkip, isNot(contains('a')));
    });

    test('multi-source trigger requires all sources completed', timeout: const Timeout.factor(2), () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('a', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('b', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('c', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['a', 'b'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['c'])]),
      ]);

      // Only 'a' completed — 'c' needs both
      final plan1 = planDownstream(
        definition: def,
        completed: {'t', 'a'},
        skipped: {},
        existing: {'t', 'a'},
        chosenRoutes: {},
      );
      expect(plan1.toRun, isNot(contains('c')));

      // Both completed — 'c' fires
      final plan2 = planDownstream(
        definition: def,
        completed: {'t', 'a', 'b'},
        skipped: {},
        existing: {'t', 'a', 'b'},
        chosenRoutes: {},
      );
      expect(plan2.toRun, contains('c'));
    });
  });
}
