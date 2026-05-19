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
  group('planDownstream — routing & skip propagation', () {
    test('router routes false → the "true" branch is skipped, "false" runs', () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
        ]),
        _step('b', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'false'),
        ]),
        _step('end', StepKind.terminal, triggers: const [
          StepTrigger(sourceStepIds: ['a']),
          StepTrigger(sourceStepIds: ['b']),
        ]),
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
      expect(plan.terminalReached, isFalse);
    });

    test('skip propagates to an unconditional descendant of a skipped node', () {
      final def = _def([
        _step('t', StepKind.trigger),
        _step('r', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['t'])]),
        _step('a', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'true'),
        ]),
        _step('b', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'false'),
        ]),
        // c depends only on the (skipped) b — it must also be skipped.
        _step('c', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['b'])]),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['a'])]),
      ]);

      final plan = planDownstream(
        definition: def,
        completed: {'t', 'r'},
        skipped: {},
        existing: {'t', 'r'},
        chosenRoutes: {'r': 'true'},
      );

      expect(plan.toSkip, containsAll(['b', 'c']));
      expect(plan.toRun, contains('a'));
    });

    test('a join fires once every wait-for source is completed OR skipped', () {
      final def = _def([
        _step('clone', StepKind.listen),
        _step('cx', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['clone'])]),
        _step('ax', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['cx'], routeKey: 'true'),
        ]),
        _step('cy', StepKind.router,
            triggers: const [StepTrigger(sourceStepIds: ['clone'])]),
        _step('ay', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['cy'], routeKey: 'true'),
        ]),
        _step('consolidate', StepKind.join,
            triggers: const [
              StepTrigger(sourceStepIds: ['ax', 'ay']),
            ],
            waitFor: const ['ax', 'ay']),
        _step('end', StepKind.terminal,
            triggers: const [StepTrigger(sourceStepIds: ['consolidate'])]),
      ]);

      // ax completed, ay was skipped (cy chose false): the join should be ready.
      final plan = planDownstream(
        definition: def,
        completed: {'clone', 'cx', 'cy', 'ax'},
        skipped: {'ay'},
        existing: {'clone', 'cx', 'cy', 'ax', 'ay'},
        chosenRoutes: {'cx': 'true', 'cy': 'false'},
      );

      expect(plan.toRun, contains('consolidate'));
      expect(plan.terminalReached, isFalse);
    });

    test('a join is never killed by skip propagation', () {
      final def = _def([
        _step('cx', StepKind.router),
        _step('ax', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['cx'], routeKey: 'true'),
        ]),
        _step('j', StepKind.join,
            triggers: const [StepTrigger(sourceStepIds: ['ax'])],
            waitFor: const ['ax']),
      ]);
      // Even though ax will be skipped, the join must not be skipped.
      final plan = planDownstream(
        definition: def,
        completed: {'cx'},
        skipped: {},
        existing: {'cx'},
        chosenRoutes: {'cx': 'false'},
      );
      expect(plan.toSkip, contains('ax'));
      expect(plan.toSkip, isNot(contains('j')));
      // With ax skipped, the join's wait-for is satisfied → it runs.
      expect(plan.toRun, contains('j'));
    });

    test('terminal is reached only via a branch that actually completed', () {
      // pr_triage shape: a router with three exclusive comment branches feeding
      // one convergent terminal. Selecting "docs" must NOT finish the run via
      // the skipped security/standard branches.
      final def = _def([
        _step('r', StepKind.router),
        _step('docs', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'docs'),
        ]),
        _step('sec', StepKind.listen, triggers: const [
          StepTrigger(sourceStepIds: ['r'], routeKey: 'security'),
        ]),
        _step('docs_c', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['docs'])]),
        _step('sec_c', StepKind.listen,
            triggers: const [StepTrigger(sourceStepIds: ['sec'])]),
        _step('end', StepKind.terminal, triggers: const [
          StepTrigger(sourceStepIds: ['docs_c']),
          StepTrigger(sourceStepIds: ['sec_c']),
        ]),
      ]);

      // Router chose docs; sec + sec_c become skipped, docs is ready.
      final afterRouter = planDownstream(
        definition: def,
        completed: {'r'},
        skipped: {},
        existing: {'r'},
        chosenRoutes: {'r': 'docs'},
      );
      expect(afterRouter.toSkip, containsAll(['sec', 'sec_c']));
      expect(afterRouter.toRun, contains('docs'));
      expect(afterRouter.terminalReached, isFalse,
          reason: 'the skipped security branch must not finish the run');

      // Once docs_c completes, the terminal is genuinely reached.
      final afterComment = planDownstream(
        definition: def,
        completed: {'r', 'docs', 'docs_c'},
        skipped: {'sec', 'sec_c'},
        existing: {'r', 'docs', 'docs_c', 'sec', 'sec_c'},
        chosenRoutes: {'r': 'docs'},
      );
      expect(afterComment.terminalReached, isTrue);
    });

    test('a step with all sources completed (no routes) runs', () {
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
      expect(plan.toRun, ['a']);
      expect(plan.toSkip, isEmpty);
      expect(plan.terminalReached, isFalse);
    });
  });
}
