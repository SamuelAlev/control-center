import 'dart:convert';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:drift/drift.dart';

/// Decodes a Drift template row into a [PipelineDefinition].
///
/// `nodesJson` carries the node list including kind, body key, position,
/// per-node config, and (for join nodes) `waitForStepIds`. `edgesJson`
/// carries the `{from, to}` pairs; these are reattached as
/// [StepTrigger.sourceStepIds] on the target step.
PipelineDefinition pipelineDefinitionFromRow(
  PipelineTemplatesTableData row,
) {
  final nodesRaw = jsonDecode(row.nodesJson) as List<dynamic>;
  final edgesRaw = jsonDecode(row.edgesJson) as List<dynamic>;
  final inputsRaw = jsonDecode(row.inputsJson) as List<dynamic>;

  // Group edges by target so we can assemble StepTrigger lists. An edge may
  // carry an optional `routeKey` (router branch label); such edges become
  // their own conditional [StepTrigger] rather than being merged.
  final unconditionalSources = <String, List<String>>{};
  final conditionalEdges = <String, List<StepTrigger>>{};
  for (final edge in edgesRaw) {
    final from = (edge as Map<String, dynamic>)['from'] as String;
    final to = edge['to'] as String;
    final routeKey = edge['routeKey'] as String?;
    if (routeKey == null) {
      unconditionalSources.putIfAbsent(to, () => []).add(from);
    } else {
      conditionalEdges.putIfAbsent(to, () => []).add(
            StepTrigger(sourceStepIds: [from], routeKey: routeKey),
          );
    }
  }

  final steps = <PipelineStepDefinition>[];
  for (final raw in nodesRaw) {
    final node = raw as Map<String, dynamic>;
    final stepId = node['stepId'] as String;
    final kind = _kindFromString(node['kind'] as String);
    final waitForStepIds =
        (node['waitForStepIds'] as List?)?.cast<String>() ?? const <String>[];
    final sources = unconditionalSources[stepId] ?? const <String>[];
    final triggers = <StepTrigger>[
      if (sources.isNotEmpty) StepTrigger(sourceStepIds: sources),
      ...?conditionalEdges[stepId],
    ];

    steps.add(PipelineStepDefinition(
      id: stepId,
      kind: kind,
      bodyKey: node['bodyKey'] as String,
      triggers: triggers,
      waitForStepIds: kind == StepKind.join ? waitForStepIds : const [],
      config: node['config'] is Map<String, dynamic>
          ? PipelineNodeConfig.fromJson(node['config'] as Map<String, dynamic>)
          : PipelineNodeConfig.empty,
      x: (node['x'] as num?)?.toDouble(),
      y: (node['y'] as num?)?.toDouble(),
    ));
  }

  final inputs = inputsRaw
      .map((raw) =>
          PipelineInput.fromJson((raw as Map).cast<String, dynamic>()))
      .toList();

  return PipelineDefinition(
    templateId: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    description: row.description,
    steps: List.unmodifiable(steps),
    inputs: List.unmodifiable(inputs),
    isBuiltIn: row.isBuiltIn,
    isEnabled: row.isEnabled,
    version: row.version,
  );
}

/// Encodes a [PipelineDefinition] into a Drift companion ready for upsert.
PipelineTemplatesTableCompanion pipelineDefinitionToCompanion(
  PipelineDefinition def, {
  required DateTime updatedAt,
  DateTime? createdAt,
  int? version,
}) {
  final nodes = def.steps.map((s) {
    final node = <String, dynamic>{
      'stepId': s.id,
      'kind': _kindToString(s.kind),
      'bodyKey': s.bodyKey,
      'config': s.config.toJson(),
    };
    if (s.x != null) {
      node['x'] = s.x;
    }
    if (s.y != null) {
      node['y'] = s.y;
    }
    if (s.waitForStepIds.isNotEmpty) {
      node['waitForStepIds'] = s.waitForStepIds;
    }
    return node;
  }).toList();

  final edges = <Map<String, String>>[];
  for (final step in def.steps) {
    for (final trigger in step.triggers) {
      for (final src in trigger.sourceStepIds) {
        edges.add({
          'from': src,
          'to': step.id,
          if (trigger.routeKey != null) 'routeKey': trigger.routeKey!,
        });
      }
    }
  }

  final inputs = def.inputs.map((i) => i.toJson()).toList();

  return PipelineTemplatesTableCompanion(
    id: Value(def.templateId),
    workspaceId: Value(def.workspaceId),
    name: Value(def.name),
    description: Value(def.description),
    nodesJson: Value(jsonEncode(nodes)),
    edgesJson: Value(jsonEncode(edges)),
    inputsJson: Value(jsonEncode(inputs)),
    isBuiltIn: Value(def.isBuiltIn),
    isEnabled: Value(def.isEnabled),
    version: version != null ? Value(version) : const Value.absent(),
    createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
    updatedAt: Value(updatedAt),
  );
}

StepKind _kindFromString(String s) => switch (s) {
      'trigger' => StepKind.trigger,
      // Legacy templates persisted the entry node as 'start'; load it as the
      // trigger node so older rows keep deserializing.
      'start' => StepKind.trigger,
      'listen' => StepKind.listen,
      'join' => StepKind.join,
      'router' => StepKind.router,
      'forEach' => StepKind.forEach,
      'terminal' => StepKind.terminal,
      _ => throw ArgumentError('Unknown step kind: $s'),
    };

String _kindToString(StepKind k) => switch (k) {
      StepKind.trigger => 'trigger',
      StepKind.listen => 'listen',
      StepKind.join => 'join',
      StepKind.router => 'router',
      StepKind.forEach => 'forEach',
      StepKind.terminal => 'terminal',
    };
