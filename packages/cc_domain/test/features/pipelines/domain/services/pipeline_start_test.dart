import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:test/test.dart';

PipelineStepDefinition _step({
  required String id,
  required StepKind kind,
  List<StepTrigger> triggers = const [],
  Map<String, dynamic> extras = const {},
  double? x,
  double? y,
}) => PipelineStepDefinition(
  id: id,
  kind: kind,
  bodyKey: kind == StepKind.trigger ? 'pipeline.trigger' : 'b',
  triggers: triggers,
  config: PipelineNodeConfig(extras: extras),
  x: x,
  y: y,
);

PipelineDefinition _def(List<PipelineStepDefinition> steps) =>
    PipelineDefinition(
      templateId: 't',
      workspaceId: 'w',
      name: 'T',
      steps: steps,
    );

PipelineTrigger _row({required String id, required String eventType}) =>
    PipelineTrigger(
      id: id,
      eventType: eventType,
      templateId: 't',
      workspaceId: 'w',
      enabled: true,
    );

void main() {
  group('pipelineStartStep', () {
    test('returns the only trigger even without an event extra', () {
      final def = _def([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'end', kind: StepKind.terminal),
      ]);
      expect(
        pipelineStartStep(def, triggerEventType: 'schedule').id,
        'trigger',
      );
    });

    test('selects the matching extra when several starts exist', () {
      final def = _def([
        _step(
          id: 'manual',
          kind: StepKind.trigger,
          extras: const {kPipelineStartEventTypeKey: 'manual'},
        ),
        _step(
          id: 'sched',
          kind: StepKind.trigger,
          extras: const {kPipelineStartEventTypeKey: 'schedule'},
        ),
        _step(id: 'end', kind: StepKind.terminal),
      ]);
      expect(pipelineStartStep(def, triggerEventType: 'schedule').id, 'sched');
      expect(pipelineStartStep(def, triggerEventType: 'manual').id, 'manual');
    });
  });

  group('syncPipelineTriggerSteps', () {
    test('expands a shared trigger entry onto every start (OR)', () {
      final def = _def([
        _step(id: 'trigger', kind: StepKind.trigger, x: 0, y: 0),
        _step(
          id: 'work',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger']),
          ],
          x: 240,
          y: 0,
        ),
        _step(
          id: 'branch',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger'], routeKey: 'approved'),
          ],
        ),
        _step(
          id: 'end',
          kind: StepKind.terminal,
          triggers: const [
            StepTrigger(sourceStepIds: ['work']),
          ],
        ),
      ]);
      final next = syncPipelineTriggerSteps(
        def: def,
        rows: [
          _row(id: 't-sched', eventType: PipelineTrigger.scheduleEventType),
          _row(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
      );
      expect(pipelineTriggerSteps(next).map((s) => s.id).toSet(), {
        't-manual',
        't-sched',
      });
      expect(next.step('trigger'), isNull);
      expect(
        next.step('work')!.triggers.map((t) => t.sourceStepIds.single).toSet(),
        {'t-manual', 't-sched'},
      );
      expect(
        next
            .step('branch')!
            .triggers
            .map((t) => t.sourceStepIds.single)
            .toSet(),
        {'t-manual', 't-sched'},
      );
      expect(
        next.step('branch')!.triggers.every((t) => t.routeKey == 'approved'),
        isTrue,
      );
      expect(
        pipelineStepStartEventType(next.step('t-sched')!),
        PipelineTrigger.scheduleEventType,
      );
    });

    test('fans a mixed trigger+work AND onto each start separately', () {
      final def = _def([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'gate', kind: StepKind.listen),
        _step(
          id: 'work',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger', 'gate']),
          ],
        ),
        _step(
          id: 'end',
          kind: StepKind.terminal,
          triggers: const [
            StepTrigger(sourceStepIds: ['work']),
          ],
        ),
      ]);
      final next = syncPipelineTriggerSteps(
        def: def,
        rows: [
          _row(id: 't-manual', eventType: PipelineTrigger.manualEventType),
          _row(id: 't-sched', eventType: PipelineTrigger.scheduleEventType),
        ],
      );
      expect(
        next.step('work')!.triggers.map((t) => t.sourceStepIds.toSet()).toSet(),
        {
          {'t-manual', 'gate'},
          {'t-sched', 'gate'},
        },
      );
    });

    test('does not rewire a deleted 1:1 start onto another start', () {
      final def = _def([
        _step(
          id: 't-manual',
          kind: StepKind.trigger,
          extras: const {kPipelineStartEventTypeKey: 'manual'},
        ),
        _step(
          id: 't-sched',
          kind: StepKind.trigger,
          extras: const {kPipelineStartEventTypeKey: 'schedule'},
        ),
        _step(
          id: 'cond',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['t-manual']),
          ],
        ),
        _step(
          id: 'work',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['cond']),
            StepTrigger(sourceStepIds: ['t-sched']),
          ],
        ),
        _step(
          id: 'end',
          kind: StepKind.terminal,
          triggers: const [
            StepTrigger(sourceStepIds: ['work']),
          ],
        ),
      ]);
      final next = syncPipelineTriggerSteps(
        def: def,
        rows: [
          _row(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
      );
      expect(next.step('t-sched'), isNull);
      expect(next.step('work')!.triggers.map((t) => t.sourceStepIds).toList(), [
        ['cond'],
      ]);
      expect(next.step('cond')!.triggers.single.sourceStepIds, ['t-manual']);
    });

    test('empty rows leave the graph unchanged', () {
      final def = _def([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'end', kind: StepKind.terminal),
      ]);
      expect(syncPipelineTriggerSteps(def: def, rows: const []), def);
    });
  });

  group('removePipelineTriggerStep', () {
    test('drops the node and strips it as a source', () {
      final def = _def([
        _step(id: 't-manual', kind: StepKind.trigger),
        _step(
          id: 'work',
          kind: StepKind.listen,
          triggers: const [
            StepTrigger(sourceStepIds: ['t-manual']),
          ],
        ),
        _step(
          id: 'end',
          kind: StepKind.terminal,
          triggers: const [
            StepTrigger(sourceStepIds: ['work']),
          ],
        ),
      ]);
      final next = removePipelineTriggerStep(def, 't-manual');
      expect(next.step('t-manual'), isNull);
      expect(next.step('work')!.triggers, isEmpty);
    });
  });
}
