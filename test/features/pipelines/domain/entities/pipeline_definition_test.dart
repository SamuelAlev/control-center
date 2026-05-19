import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineDefinition', () {
    PipelineStepDefinition step(
      String id,
      StepKind kind, {
      List<StepTrigger> triggers = const [],
    }) =>
        PipelineStepDefinition(
          id: id,
          kind: kind,
          bodyKey: 'body',
          triggers: triggers,
        );

    test('constructor requires non-empty templateId, workspaceId, name',
        timeout: const Timeout.factor(2), () {
      expect(
        () => PipelineDefinition(
          templateId: '',
          workspaceId: 'w',
          name: 'n',
          steps: [],
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PipelineDefinition(
          templateId: 't',
          workspaceId: '',
          name: 'n',
          steps: [],
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PipelineDefinition(
          templateId: 't',
          workspaceId: 'w',
          name: '',
          steps: [],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('step() returns matching step or null', timeout: const Timeout.factor(2), () {
      final s1 = step('a', StepKind.listen);
      final s2 = step('b', StepKind.listen);
      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [s1, s2],
      );
      expect(def.step('a'), s1);
      expect(def.step('b'), s2);
      expect(def.step('c'), isNull);
    });

    test('entryStep returns the trigger step', timeout: const Timeout.factor(2), () {
      final trigger = step('trigger', StepKind.trigger);
      final listen = step('listen', StepKind.listen);
      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [trigger, listen],
      );
      expect(def.entryStep, trigger);
    });

    test('entryStep throws when no trigger step exists', timeout: const Timeout.factor(2), () {
      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [step('a', StepKind.listen)],
      );
      expect(() => def.entryStep, throwsA(isA<StateError>()));
    });

    test('listenersOf returns steps whose triggers reference the source',
        timeout: const Timeout.factor(2), () {
      final trigger = step('s', StepKind.trigger);
      final l1 = step('a', StepKind.listen,
          triggers: const [StepTrigger(sourceStepIds: ['s'])]);
      final l2 = step('b', StepKind.listen,
          triggers: const [StepTrigger(sourceStepIds: ['s'])]);
      final l3 = step('c', StepKind.listen,
          triggers: const [StepTrigger(sourceStepIds: ['x'])]);

      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [trigger, l1, l2, l3],
      );
      expect(def.listenersOf('s'), [l1, l2]);
      expect(def.listenersOf('x'), [l3]);
      expect(def.listenersOf('none'), isEmpty);
    });

    test('copyWith overrides specified fields', timeout: const Timeout.factor(2), () {
      final def = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [],
      );
      final copy = def.copyWith(name: 'New', isEnabled: false, version: 5);
      expect(copy.templateId, 't');
      expect(copy.workspaceId, 'w');
      expect(copy.name, 'New');
      expect(copy.isEnabled, isFalse);
      expect(copy.version, 5);
      // Original unchanged
      expect(def.name, 'T');
      expect(def.isEnabled, isTrue);
    });

    test('equality compares templateId, workspaceId, name, steps, inputs, flags',
        timeout: const Timeout.factor(2), () {
      final a = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [],
      );
      final b = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = a.copyWith(name: 'Other');
      expect(a, isNot(equals(c)));
    });

    test('inequality with different inputs', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'k');
      final a = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [],
        inputs: [input],
      );
      final b = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [],
        inputs: [],
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality with different steps', timeout: const Timeout.factor(2), () {
      final a = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [step('x', StepKind.listen)],
      );
      final b = PipelineDefinition(
        templateId: 't',
        workspaceId: 'w',
        name: 'T',
        steps: [step('y', StepKind.listen)],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
