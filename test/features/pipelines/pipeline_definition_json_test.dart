import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

/// Template export/import round-trip (FINDINGS §7.5): a full pipeline graph —
/// trigger → router → two conditional branches → join → terminal, plus a
/// forEach node, per-node config, inputs and canvas coordinates — must survive
/// `toJson` → `jsonEncode` → `jsonDecode` → `fromJson` byte-stably.
void main() {
  PipelineDefinition sample({String templateId = 'demo', String ws = 'ws1'}) {
    return PipelineDefinition(
      templateId: templateId,
      workspaceId: ws,
      name: 'Demo pipeline',
      description: 'A representative graph',
      version: 3,
      inputs: [
        PipelineInput(
          key: 'target',
          label: 'Target branch',
          type: PipelineInputType.text,
          required: true,
          defaultValue: 'main',
          helpText: 'Which branch',
        ),
      ],
      steps: [
        PipelineStepDefinition(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
          x: 0,
          y: 0,
        ),
        PipelineStepDefinition(
          id: 'route',
          kind: StepKind.router,
          bodyKey: 'route_body',
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger']),
          ],
          config: const PipelineNodeConfig(
            label: 'Router',
            inputKeys: ['target'],
            outputKey: 'decision',
          ),
          x: 100,
          y: 50,
        ),
        PipelineStepDefinition(
          id: 'branch_a',
          kind: StepKind.listen,
          bodyKey: 'agent_body',
          triggers: const [
            StepTrigger(sourceStepIds: ['route'], routeKey: 'a'),
          ],
          config: const PipelineNodeConfig(agentId: 'agent-1', prompt: 'do A'),
        ),
        PipelineStepDefinition(
          id: 'fanout',
          kind: StepKind.forEach,
          bodyKey: 'agent_body',
          triggers: const [
            StepTrigger(sourceStepIds: ['route'], routeKey: 'b'),
          ],
          config: const PipelineNodeConfig(
            outputKey: 'results',
            extras: {'iterableKey': 'items'},
          ),
        ),
        PipelineStepDefinition(
          id: 'gather',
          kind: StepKind.join,
          bodyKey: 'join_body',
          waitForStepIds: const ['branch_a', 'fanout'],
        ),
        PipelineStepDefinition(
          id: 'done',
          kind: StepKind.terminal,
          bodyKey: 'terminal_body',
          triggers: const [
            StepTrigger(sourceStepIds: ['gather']),
          ],
        ),
      ],
    );
  }

  test('a full definition round-trips through JSON unchanged', () {
    final original = sample();
    final wire =
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
    final restored = PipelineDefinition.fromJson(wire);

    // `==` deep-compares steps (kind, bodyKey, triggers incl. routeKey,
    // waitFor, config, x/y) and inputs.
    expect(restored, original);
    expect(restored.version, 3);
    expect(restored.entryStep.id, 'trigger');
    expect(restored.step('route')!.kind, StepKind.router);
    expect(restored.step('branch_a')!.triggers.single.routeKey, 'a');
    expect(restored.step('gather')!.waitForStepIds, ['branch_a', 'fanout']);
    expect(restored.step('route')!.x, 100);
  });

  test('carries the export schema version', () {
    expect(sample().toJson()['export_schema'], PipelineDefinition.exportSchema);
  });

  test('import can rehome a shared template to a new workspace/id', () {
    final exported = sample(templateId: 'shared', ws: 'origin').toJson();
    final imported = PipelineDefinition.fromJson(
      exported,
      templateId: 'copy',
      workspaceId: 'ws2',
    );
    expect(imported.templateId, 'copy');
    expect(imported.workspaceId, 'ws2');
    // The portable graph is unchanged by the rehoming.
    expect(imported.steps.length, sample().steps.length);
    expect(imported.name, 'Demo pipeline');
    // An imported template is never a re-seeded built-in.
    expect(imported.isBuiltIn, isFalse);
  });
}
