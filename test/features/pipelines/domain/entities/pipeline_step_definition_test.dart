import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineStepDefinition', () {
    test('constructor asserts non-empty id and bodyKey', timeout: const Timeout.factor(2), () {
      expect(
        () => PipelineStepDefinition(id: '', kind: StepKind.listen, bodyKey: 'b'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PipelineStepDefinition(id: 's', kind: StepKind.listen, bodyKey: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default values', timeout: const Timeout.factor(2), () {
      final step = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'body',
      );
      expect(step.triggers, isEmpty);
      expect(step.waitForStepIds, isEmpty);
      expect(step.config, PipelineNodeConfig.empty);
      expect(step.x, isNull);
      expect(step.y, isNull);
    });

    test('stores all fields', timeout: const Timeout.factor(2), () {
      final step = PipelineStepDefinition(
        id: 'review',
        kind: StepKind.listen,
        bodyKey: 'pipeline.promptAgent',
        triggers: const [StepTrigger(sourceStepIds: ['trigger'])],
        waitForStepIds: const ['a', 'b'],
        config: const PipelineNodeConfig(prompt: 'p', outputKey: 'out'),
        x: 10.0,
        y: 20.0,
      );
      expect(step.id, 'review');
      expect(step.kind, StepKind.listen);
      expect(step.bodyKey, 'pipeline.promptAgent');
      expect(step.triggers.length, 1);
      expect(step.waitForStepIds, ['a', 'b']);
      expect(step.config.outputKey, 'out');
      expect(step.x, 10.0);
      expect(step.y, 20.0);
    });

    test('equality compares id, kind, bodyKey, triggers, waitForStepIds, config, x, y',
        timeout: const Timeout.factor(2), () {
      final a = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        triggers: const [StepTrigger(sourceStepIds: ['x'])],
        config: const PipelineNodeConfig(prompt: 'p'),
      );
      final b = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        triggers: const [StepTrigger(sourceStepIds: ['x'])],
        config: const PipelineNodeConfig(prompt: 'p'),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different triggers', timeout: const Timeout.factor(2), () {
      final a = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        triggers: const [StepTrigger(sourceStepIds: ['x'])],
      );
      final b = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        triggers: const [StepTrigger(sourceStepIds: ['y'])],
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality with different config', timeout: const Timeout.factor(2), () {
      final a = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        config: const PipelineNodeConfig(prompt: 'a'),
      );
      final b = PipelineStepDefinition(
        id: 's',
        kind: StepKind.listen,
        bodyKey: 'b',
        config: const PipelineNodeConfig(prompt: 'b'),
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality with different kind', timeout: const Timeout.factor(2), () {
      final a = PipelineStepDefinition(id: 's', kind: StepKind.listen, bodyKey: 'b');
      final b = PipelineStepDefinition(id: 's', kind: StepKind.router, bodyKey: 'b');
      expect(a, isNot(equals(b)));
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      final step = PipelineStepDefinition(id: 's', kind: StepKind.listen, bodyKey: 'b');
      expect(step, equals(step));
    });
  });
}
