import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/pipeline_template_mappers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

PipelineDefinition _makeSimpleDef({
  String id = 'tpl-1',
  String ws = 'ws-1',
}) {
  final steps = [
    PipelineStepDefinition(
      id: 'trigger',
      kind: StepKind.trigger,
      bodyKey: 'pipeline.trigger',
      x: 100,
      y: 200,
    ),
    PipelineStepDefinition(
      id: 'fetch',
      kind: StepKind.listen,
      bodyKey: 'pipeline.promptAgent',
      triggers: [const StepTrigger(sourceStepIds: ['trigger'])],
    ),
  ];
  return PipelineDefinition(
    templateId: id,
    workspaceId: ws,
    name: 'Test Pipeline',
    description: 'A test pipeline',
    steps: steps,
    isBuiltIn: false,
    isEnabled: true,
    version: 1,
  );
}

PipelineDefinition _makeComplexDef() {
  final steps = [
    PipelineStepDefinition(
      id: 'trigger',
      kind: StepKind.trigger,
      bodyKey: 'pipeline.trigger',
    ),
    PipelineStepDefinition(
      id: 'router',
      kind: StepKind.router,
      bodyKey: 'pipeline.router',
      triggers: [const StepTrigger(sourceStepIds: ['trigger'])],
    ),
    PipelineStepDefinition(
      id: 'path_a',
      kind: StepKind.listen,
      bodyKey: 'pipeline.promptAgent',
      triggers: [
        const StepTrigger(sourceStepIds: ['router'], routeKey: 'a'),
      ],
    ),
    PipelineStepDefinition(
      id: 'path_b',
      kind: StepKind.listen,
      bodyKey: 'pipeline.promptAgent',
      triggers: [
        const StepTrigger(sourceStepIds: ['router'], routeKey: 'b'),
      ],
    ),
    PipelineStepDefinition(
      id: 'join',
      kind: StepKind.join,
      bodyKey: 'pipeline.join',
      triggers: [
        const StepTrigger(sourceStepIds: ['path_a', 'path_b']),
      ],
      waitForStepIds: const ['path_a', 'path_b'],
    ),
  ];
  return PipelineDefinition(
    templateId: 'cmplx-1',
    workspaceId: 'ws-1',
    name: 'Complex Pipeline',
    description: 'Has routing and joins',
    steps: steps,
    inputs: [
      PipelineInput(key: 'title', label: 'Title', type: PipelineInputType.text),
      PipelineInput(key: 'count', label: 'Count', type: PipelineInputType.number),
    ],
    isBuiltIn: true,
    isEnabled: true,
    version: 1,
  );
}

void main() {
  group('_kindFromString (via pipelineDefinitionFromRow)', () {
    test('maps all valid kind strings correctly', () {
      final cases = {
        'trigger': StepKind.trigger,
        'start': StepKind.trigger, // legacy compatibility
        'listen': StepKind.listen,
        'join': StepKind.join,
        'router': StepKind.router,
        'forEach': StepKind.forEach,
        'terminal': StepKind.terminal,
      };
      for (final entry in cases.entries) {
        final nodesJson = jsonEncode([
          {'stepId': 'n', 'kind': entry.key, 'bodyKey': 'body', 'config': {}},
        ]);
        final row = PipelineTemplatesTableData(
          id: 'test',
          workspaceId: 'ws-1',
          name: 'Test',
          description: null,
          nodesJson: nodesJson,
          edgesJson: '[]',
          inputsJson: '[]',
          isBuiltIn: false,
          isEnabled: true,
          version: 1,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 6, 1),
        );
        final result = pipelineDefinitionFromRow(row);
        expect(result.steps.first.kind, entry.value,
            reason: 'kind string "${entry.key}" should map to ${entry.value}');
      }
    }, timeout: const Timeout.factor(2));

    test('unknown kind string throws ArgumentError', () {
      final nodesJson = jsonEncode([
        {'stepId': 'n', 'kind': 'bogus', 'bodyKey': 'body', 'config': {}},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'test',
        workspaceId: 'ws-1',
        name: 'Test',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
      expect(
        () => pipelineDefinitionFromRow(row),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Unknown step kind: bogus'),
        )),
      );
    }, timeout: const Timeout.factor(2));
  });

  group('_kindToString (via pipelineDefinitionToCompanion)', () {
    test('converts each StepKind to correct string', () {
      final cases = {
        StepKind.trigger: 'trigger',
        StepKind.listen: 'listen',
        StepKind.join: 'join',
        StepKind.router: 'router',
        StepKind.forEach: 'forEach',
        StepKind.terminal: 'terminal',
      };
      for (final entry in cases.entries) {
        final steps = [
          PipelineStepDefinition(
            id: 'n',
            kind: entry.key,
            bodyKey: 'body',
          ),
        ];
        final def = PipelineDefinition(
          templateId: 'test',
          workspaceId: 'ws-1',
          name: 'Test',
          steps: steps,
        );
        final companion = pipelineDefinitionToCompanion(def, updatedAt: DateTime(2025, 6, 11));
        final nodes = jsonDecode(companion.nodesJson.value) as List<dynamic>;
        final node = nodes.first as Map<String, dynamic>;
        expect(node['kind'], entry.value,
            reason: 'StepKind ${entry.key} should serialize to "${entry.value}"');
      }
    }, timeout: const Timeout.factor(2));

    test('round-trip: kindToString → kindFromString for all StepKind values', () {
      for (final kind in StepKind.values) {
        // kindToString: encode to companion, read kind string
        final steps = [
          PipelineStepDefinition(id: 'n', kind: kind, bodyKey: 'body'),
        ];
        final def = PipelineDefinition(
          templateId: 'test',
          workspaceId: 'ws-1',
          name: 'Test',
          steps: steps,
        );
        final companion = pipelineDefinitionToCompanion(def, updatedAt: DateTime(2025, 6, 11));
        final nodes = jsonDecode(companion.nodesJson.value) as List<dynamic>;
        final kindStr = (nodes.first as Map<String, dynamic>)['kind'] as String;

        // kindFromString: decode from a row using that kind string
        final nodesJson = jsonEncode([
          {'stepId': 'n', 'kind': kindStr, 'bodyKey': 'body', 'config': {}},
        ]);
        final row = PipelineTemplatesTableData(
          id: 'test',
          workspaceId: 'ws-1',
          name: 'Test',
          description: null,
          nodesJson: nodesJson,
          edgesJson: '[]',
          inputsJson: '[]',
          isBuiltIn: false,
          isEnabled: true,
          version: 1,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 6, 1),
        );
        final result = pipelineDefinitionFromRow(row);
        expect(result.steps.first.kind, kind,
            reason: 'Round-trip failed for $kind via "$kindStr"');
      }
    }, timeout: const Timeout.factor(2));
  });
  group('pipelineDefinitionFromRow', () {
    test('parses a simple two-step pipeline', () {
      final nodesJson = jsonEncode([
        {'stepId': 'trigger', 'kind': 'trigger', 'bodyKey': 'pipeline.trigger', 'config': {}, 'x': 100, 'y': 200},
        {'stepId': 'fetch', 'kind': 'listen', 'bodyKey': 'pipeline.promptAgent', 'config': {}},
      ]);
      final edgesJson = jsonEncode([
        {'from': 'trigger', 'to': 'fetch'},
      ]);
      final inputsJson = jsonEncode([]);

      final row = PipelineTemplatesTableData(
        id: 'tpl-1',
        workspaceId: 'ws-1',
        name: 'Test Pipeline',
        description: 'A test pipeline',
        nodesJson: nodesJson,
        edgesJson: edgesJson,
        inputsJson: inputsJson,
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);

      expect(result.templateId, 'tpl-1');
      expect(result.workspaceId, 'ws-1');
      expect(result.name, 'Test Pipeline');
      expect(result.steps.length, 2);

      final fetchStep = result.steps.firstWhere((s) => s.id == 'fetch');
      expect(fetchStep.triggers.length, 1);
      expect(fetchStep.triggers.first.sourceStepIds, ['trigger']);
    });

    test('parses steps with x/y coordinates', () {
      final nodesJson = jsonEncode([
        {'stepId': 's1', 'kind': 'trigger', 'bodyKey': 'pipeline.trigger', 'config': {}, 'x': 10.5, 'y': 20.0},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'pos-1',
        workspaceId: 'ws-1',
        name: 'Positioned',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      final step = result.steps.first;
      expect(step.x, 10.5);
      expect(step.y, 20.0);
    });

    test('parses conditional (routed) edges', () {
      final nodesJson = jsonEncode([
        {'stepId': 'rtr', 'kind': 'router', 'bodyKey': 'pipeline.router', 'config': {}},
        {'stepId': 'branch', 'kind': 'listen', 'bodyKey': 'pipeline.promptAgent', 'config': {}},
      ]);
      final edgesJson = jsonEncode([
        {'from': 'rtr', 'to': 'branch', 'routeKey': 'success'},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'cond-1',
        workspaceId: 'ws-1',
        name: 'Conditional',
        description: null,
        nodesJson: nodesJson,
        edgesJson: edgesJson,
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      final branch = result.steps.firstWhere((s) => s.id == 'branch');
      expect(branch.triggers.length, 1);
      expect(branch.triggers.first.sourceStepIds, ['rtr']);
      expect(branch.triggers.first.routeKey, 'success');
    });

    test('parses join step with waitForStepIds', () {
      final nodesJson = jsonEncode([
        {'stepId': 'j', 'kind': 'join', 'bodyKey': 'pipeline.join', 'config': {}, 'waitForStepIds': ['a', 'b']},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'join-1',
        workspaceId: 'ws-1',
        name: 'Join',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      final join = result.steps.first;
      expect(join.waitForStepIds, ['a', 'b']);
    });

    test('parses node with PipelineNodeConfig', () {
      final nodesJson = jsonEncode([
        {
          'stepId': 'cfg',
          'kind': 'listen',
          'bodyKey': 'pipeline.promptAgent',
          'config': {
            'prompt': 'Review {{file}}',
            'agentId': 'agent-abc',
            'inputKeys': ['file', 'context'],
            'outputKey': 'review',
            'label': 'Review Node',
            'outputSchema': {'type': 'object'},
            'reducer': 'override',
            'retryPolicy': {'maxAttempts': 3, 'backoff': 'exponential', 'initialDelayMs': 500},
            'continueOnFail': true,
            'timeoutMs': 30000,
            'teamId': 'team-1',
            'dispatchMode': 'allParallel',
            'extras': {'customKey': 'customValue'},
          },
        },
      ]);
      final row = PipelineTemplatesTableData(
        id: 'cfg-1',
        workspaceId: 'ws-1',
        name: 'Config Test',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      final step = result.steps.first;
      final config = step.config;
      expect(config.prompt, 'Review {{file}}');
      expect(config.agentId, 'agent-abc');
      expect(config.inputKeys, ['file', 'context']);
      expect(config.outputKey, 'review');
      expect(config.label, 'Review Node');
      expect(config.outputSchema, {'type': 'object'});
      expect(config.reducer, 'override');
      expect(config.retryPolicy, isNotNull);
      expect(config.retryPolicy!.maxAttempts, 3);
      expect(config.retryPolicy!.backoff, 'exponential');
      expect(config.retryPolicy!.initialDelayMs, 500);
      expect(config.continueOnFail, true);
      expect(config.timeoutMs, 30000);
      expect(config.teamId, 'team-1');
      expect(config.dispatchMode, 'allParallel');
      expect(config.extras, {'customKey': 'customValue'});
    });

    test('parses empty inputs list', () {
      final nodesJson = jsonEncode([
        {'stepId': 't', 'kind': 'trigger', 'bodyKey': 'pipeline.trigger', 'config': {}},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'empty-inp',
        workspaceId: 'ws-1',
        name: 'No Inputs',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      expect(result.inputs, isEmpty);
    });

    test('parses multiple inputs', () {
      final nodesJson = jsonEncode([
        {'stepId': 't', 'kind': 'trigger', 'bodyKey': 'pipeline.trigger', 'config': {}},
      ]);
      final inputsJson = jsonEncode([
        {'key': 'title', 'label': 'Title', 'type': 'text'},
        {'key': 'count', 'label': 'Count', 'type': 'number', 'required': true, 'defaultValue': 5},
        {'key': 'enable', 'label': 'Enable', 'type': 'boolean', 'defaultValue': true},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'multi-inp',
        workspaceId: 'ws-1',
        name: 'Multi Inputs',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: inputsJson,
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      expect(result.inputs.length, 3);
      expect(result.inputs[0].key, 'title');
      expect(result.inputs[0].type, PipelineInputType.text);
      expect(result.inputs[1].key, 'count');
      expect(result.inputs[1].type, PipelineInputType.number);
      expect(result.inputs[1].required, true);
      expect(result.inputs[1].defaultValue, 5);
      expect(result.inputs[2].key, 'enable');
      expect(result.inputs[2].type, PipelineInputType.boolean);
    });

    test('parses inputs', () {
      final nodesJson = jsonEncode([]);
      final inputsJson = jsonEncode([
        {'key': 'title', 'label': 'Title', 'type': 'text', 'required': false, 'defaultValue': null},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'inp-1',
        workspaceId: 'ws-1',
        name: 'With Inputs',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: inputsJson,
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      expect(result.inputs.length, 1);
      expect(result.inputs.first.key, 'title');
      expect(result.inputs.first.label, 'Title');
    });

    test('parses legacy "start" kind as trigger', () {
      final nodesJson = jsonEncode([
        {'stepId': 'entry', 'kind': 'start', 'bodyKey': 'pipeline.trigger', 'config': {}},
      ]);
      final row = PipelineTemplatesTableData(
        id: 'legacy-1',
        workspaceId: 'ws-1',
        name: 'Legacy',
        description: null,
        nodesJson: nodesJson,
        edgesJson: '[]',
        inputsJson: '[]',
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final result = pipelineDefinitionFromRow(row);
      expect(result.steps.first.kind, StepKind.trigger);
    });
  });

  group('pipelineDefinitionToCompanion', () {
    test('converts simple pipeline to companion', () {
      final def = _makeSimpleDef();
      final now = DateTime(2025, 6, 11);
      final companion = pipelineDefinitionToCompanion(def, updatedAt: now);

      expect(companion.id, const Value('tpl-1'));
      expect(companion.workspaceId, const Value('ws-1'));
      expect(companion.name, const Value('Test Pipeline'));
      expect(companion.description, const Value('A test pipeline'));
      expect(companion.isBuiltIn, const Value(false));
      expect(companion.isEnabled, const Value(true));
      expect(companion.version, const Value.absent());
      expect(companion.updatedAt, Value(now));
    });

    test('version defaults to absent when not provided', () {
      final def = _makeSimpleDef();
      final companion = pipelineDefinitionToCompanion(def, updatedAt: DateTime.now());
      expect(companion.version, const Value.absent());
    });

    test('createdAt defaults to absent when not provided', () {
      final def = _makeSimpleDef();
      final companion = pipelineDefinitionToCompanion(def, updatedAt: DateTime.now());
      expect(companion.createdAt, const Value.absent());
    });

    test('encodes single-node definition', () {
      final steps = [
        PipelineStepDefinition(
          id: 'entry',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
      ];
      final def = PipelineDefinition(
        templateId: 'single-1',
        workspaceId: 'ws-1',
        name: 'Single Node',
        steps: steps,
      );
      final now = DateTime(2025, 6, 11);
      final companion = pipelineDefinitionToCompanion(def, updatedAt: now);

      expect(companion.id, const Value('single-1'));
      expect(companion.workspaceId, const Value('ws-1'));
      expect(companion.name, const Value('Single Node'));
      expect(companion.isBuiltIn, const Value(false));
      expect(companion.isEnabled, const Value(true));

      // Decode the nodes JSON to check the node was encoded
      final nodes = jsonDecode(companion.nodesJson.value) as List<dynamic>;
      expect(nodes.length, 1);
      final node = nodes.first as Map<String, dynamic>;
      expect(node['stepId'], 'entry');
      expect(node['kind'], 'trigger');
      expect(node['bodyKey'], 'pipeline.trigger');

      // No edges for a single node with no triggers
      final edges = jsonDecode(companion.edgesJson.value) as List<dynamic>;
      expect(edges, isEmpty);
    });

    test('edge encoding with routeKey', () {
      final steps = [
        PipelineStepDefinition(
          id: 'rtr',
          kind: StepKind.router,
          bodyKey: 'pipeline.router',
        ),
        PipelineStepDefinition(
          id: 'branch',
          kind: StepKind.listen,
          bodyKey: 'pipeline.promptAgent',
          triggers: [
            const StepTrigger(sourceStepIds: ['rtr'], routeKey: 'success'),
          ],
        ),
      ];
      final def = PipelineDefinition(
        templateId: 'route-1',
        workspaceId: 'ws-1',
        name: 'Route Test',
        steps: steps,
      );
      final companion = pipelineDefinitionToCompanion(def, updatedAt: DateTime(2025, 6, 11));

      final edges = jsonDecode(companion.edgesJson.value) as List<dynamic>;
      expect(edges.length, 1);
      final edge = edges.first as Map<String, dynamic>;
      expect(edge['from'], 'rtr');
      expect(edge['to'], 'branch');
      expect(edge['routeKey'], 'success');
    });
  });

  group('round-trip', () {
    test('simple pipeline round-trips correctly', () {
      final original = _makeSimpleDef();
      final companion = pipelineDefinitionToCompanion(
        original,
        updatedAt: DateTime(2025, 6, 11),
        createdAt: DateTime(2025, 1, 1),
        version: 1,
      );

      final row = PipelineTemplatesTableData(
        id: companion.id.value,
        workspaceId: companion.workspaceId.value,
        name: companion.name.value,
        description: companion.description.value,
        nodesJson: companion.nodesJson.value,
        edgesJson: companion.edgesJson.value,
        inputsJson: companion.inputsJson.value,
        isBuiltIn: companion.isBuiltIn.value,
        isEnabled: companion.isEnabled.value,
        version: companion.version.value,
        createdAt: companion.createdAt.value,
        updatedAt: companion.updatedAt.value,
      );

      final roundtripped = pipelineDefinitionFromRow(row);
      expect(roundtripped.templateId, original.templateId);
      expect(roundtripped.workspaceId, original.workspaceId);
      expect(roundtripped.name, original.name);
      expect(roundtripped.steps.length, original.steps.length);
      expect(roundtripped.isBuiltIn, original.isBuiltIn);
      expect(roundtripped.isEnabled, original.isEnabled);
    });

    test('complex pipeline with routing and joins round-trips', () {
      final original = _makeComplexDef();
      final companion = pipelineDefinitionToCompanion(
        original,
        updatedAt: DateTime(2025, 6, 11),
        createdAt: DateTime(2025, 1, 1),
        version: 1,
      );

      final row = PipelineTemplatesTableData(
        id: companion.id.value,
        workspaceId: companion.workspaceId.value,
        name: companion.name.value,
        description: companion.description.value,
        nodesJson: companion.nodesJson.value,
        edgesJson: companion.edgesJson.value,
        inputsJson: companion.inputsJson.value,
        isBuiltIn: companion.isBuiltIn.value,
        isEnabled: companion.isEnabled.value,
        version: companion.version.value,
        createdAt: companion.createdAt.value,
        updatedAt: companion.updatedAt.value,
      );

      final roundtripped = pipelineDefinitionFromRow(row);
      expect(roundtripped.steps.length, original.steps.length);
      expect(roundtripped.inputs.length, original.inputs.length);

      // Check routing edges survived
      final pathA = roundtripped.steps.firstWhere((s) => s.id == 'path_a');
      expect(pathA.triggers.any((t) => t.routeKey == 'a'), isTrue);

      final join = roundtripped.steps.firstWhere((s) => s.id == 'join');
      expect(join.waitForStepIds, ['path_a', 'path_b']);
    });
  });
}
