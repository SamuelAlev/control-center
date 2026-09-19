import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:collection/collection.dart';

/// `PipelineNodeConfig.extras` key holding the [PipelineTrigger.eventType]
/// a [StepKind.trigger] graph node belongs to.
///
/// The trigger *row* (enabled, cron, webhook token) stays in
/// `pipeline_triggers`. The graph node is what outgoing wires hang off, and
/// this extra is how [pipelineStartStep] picks the node a run should enter.
const String kPipelineStartEventTypeKey = 'eventType';

/// Pitch used when stacking newly created trigger nodes under a legacy
/// shared entry. Matches the editor's trigger-column pitch (tile + gap).
const double kPipelineTriggerStackPitch = 96;

/// Event type stamped on a trigger graph node, or null when the node is a
/// legacy shared entry (`id: 'trigger'` with no extra).
String? pipelineStepStartEventType(PipelineStepDefinition step) {
  if (step.kind != StepKind.trigger) {
    return null;
  }
  final value = step.config.extras[kPipelineStartEventTypeKey];
  return value is String && value.isNotEmpty ? value : null;
}

/// Trigger-kind steps in [def], in list order.
List<PipelineStepDefinition> pipelineTriggerSteps(PipelineDefinition def) => [
  for (final step in def.steps)
    if (step.kind == StepKind.trigger) step,
];

/// The graph node a run with [triggerEventType] should enter.
///
/// A template with one trigger step (built-ins, unexpanded drafts) always
/// returns that node, so a missing extra does not break existing graphs. With
/// several trigger nodes, the extra (or a leftover `id == 'trigger'`) selects
/// the start; a miss falls back to the first trigger so a run still launches
/// rather than throwing.
PipelineStepDefinition pipelineStartStep(
  PipelineDefinition def, {
  String? triggerEventType,
}) {
  final starts = pipelineTriggerSteps(def);
  if (starts.isEmpty) {
    throw StateError(
      'PipelineDefinition "${def.templateId}" has no trigger step',
    );
  }
  if (starts.length == 1) {
    return starts.single;
  }
  if (triggerEventType != null) {
    final match = [
      for (final step in starts)
        if (pipelineStepStartEventType(step) == triggerEventType) step,
    ];
    if (match.length == 1) {
      return match.single;
    }
  }
  return starts.firstWhere(
    (step) => step.id == 'trigger',
    orElse: () => starts.first,
  );
}

/// Manual first, then event type, then id — the canvas stack order.
List<PipelineTrigger> sortPipelineTriggers(Iterable<PipelineTrigger> triggers) {
  final list = [...triggers];
  int rank(PipelineTrigger t) =>
      t.eventType == PipelineTrigger.manualEventType ? 0 : 1;
  list.sort((a, b) {
    final byManual = rank(a).compareTo(rank(b));
    if (byManual != 0) {
      return byManual;
    }
    final byType = a.eventType.compareTo(b.eventType);
    if (byType != 0) {
      return byType;
    }
    return a.id.compareTo(b.id);
  });
  return list;
}

/// Makes trigger *rows* and trigger *graph nodes* 1:1.
///
/// Older templates keep one hidden `id: 'trigger'` entry that every
/// [PipelineTrigger] row painted as a proxy of. Expanding that node into one
/// step per row copies each outbound edge onto **every** row (separate
/// [StepTrigger]s, so they OR) — that is the seeded meaning: any of those
/// events runs the same graph. After expansion, pulling a new wire from
/// Schedule is Schedule-only.
///
/// Returns [def] unchanged when the graph already matches [rows].
PipelineDefinition syncPipelineTriggerSteps({
  required PipelineDefinition def,
  required List<PipelineTrigger> rows,
  double stackPitch = kPipelineTriggerStackPitch,
}) {
  final sortedRows = sortPipelineTriggers(rows);
  final rowById = {for (final row in sortedRows) row.id: row};
  final existingTriggerSteps = pipelineTriggerSteps(def);
  final legacy = [
    for (final step in existingTriggerSteps)
      if (!rowById.containsKey(step.id)) step,
  ];

  var steps = [...def.steps];
  var changed = false;

  // Only the leftover shared entry is rewritten onto a row. A deleted
  // 1:1 node must drop its outbound wires, not steal them onto another
  // start.
  final expandingShared = legacy.any((step) => step.id == 'trigger');
  final rewireFrom = expandingShared ? 'trigger' : null;

  if (sortedRows.isEmpty) {
    // Deleting the last trigger row is the editor's job
    // ([removePipelineTriggerStep]); an empty row list on load is "rows
    // have not arrived yet", not "strip the graph".
    return def;
  }

  final origin = existingTriggerSteps.isNotEmpty
      ? (
          x: existingTriggerSteps.first.x ?? 0,
          y: existingTriggerSteps.first.y ?? 0,
        )
      : (x: 0.0, y: 0.0);

  for (var i = 0; i < sortedRows.length; i++) {
    final row = sortedRows[i];
    final already = steps.where((s) => s.id == row.id).toList();
    if (already.isNotEmpty) {
      final step = already.single;
      final stamped = _stampEventType(step, row.eventType);
      if (stamped != step) {
        steps = [
          for (final s in steps)
            if (s.id == step.id) stamped else s,
        ];
        changed = true;
      }
      continue;
    }
    var y = origin.y + i * stackPitch;
    if (!expandingShared) {
      var maxY = origin.y;
      for (final step in steps) {
        if (step.kind == StepKind.trigger) {
          final top = step.y ?? origin.y;
          if (top > maxY) {
            maxY = top;
          }
        }
      }
      y = maxY + stackPitch;
    }
    steps.add(
      PipelineStepDefinition(
        id: row.id,
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
        config: PipelineNodeConfig(
          extras: {kPipelineStartEventTypeKey: row.eventType},
        ),
        x: origin.x,
        y: y,
      ),
    );
    changed = true;
  }

  if (rewireFrom != null) {
    final toIds = [for (final row in sortedRows) row.id];
    steps = [
      for (final step in steps)
        if (step.kind == StepKind.trigger)
          step
        else
          _fanOutSource(step, from: rewireFrom, toIds: toIds),
    ];
    changed = true;
  }

  if (legacy.isNotEmpty) {
    final legacyIds = {for (final step in legacy) step.id};
    steps = [
      for (final step in steps)
        if (!(step.kind == StepKind.trigger && legacyIds.contains(step.id)))
          step.kind == StepKind.trigger ? step : _stripSources(step, legacyIds),
    ];
    changed = true;
  }

  if (!changed) {
    return def;
  }
  return def.copyWith(steps: List.unmodifiable(steps));
}

/// Drops a trigger graph node and any edges that named it. Used when the
/// last [PipelineTrigger] row is deleted, because [syncPipelineTriggerSteps]
/// leaves an empty row list untouched.
PipelineDefinition removePipelineTriggerStep(
  PipelineDefinition def,
  String triggerId,
) {
  if (def.step(triggerId) == null) {
    return def;
  }
  final removed = {triggerId};
  return def.copyWith(
    steps: List.unmodifiable([
      for (final step in def.steps)
        if (step.id != triggerId) _stripSources(step, removed),
    ]),
  );
}

PipelineStepDefinition _stampEventType(
  PipelineStepDefinition step,
  String eventType,
) {
  if (pipelineStepStartEventType(step) == eventType) {
    return step;
  }
  return PipelineStepDefinition(
    id: step.id,
    kind: step.kind,
    bodyKey: step.bodyKey,
    triggers: step.triggers,
    waitForStepIds: step.waitForStepIds,
    config: step.config.copyWith(
      extras: {...step.config.extras, kPipelineStartEventTypeKey: eventType},
    ),
    x: step.x,
    y: step.y,
  );
}

/// Copies each edge that named [from] onto every id in [toIds] as its own
/// [StepTrigger] (OR across starts). AND-merging them into one source list
/// would wait for every start to fire.
PipelineStepDefinition _fanOutSource(
  PipelineStepDefinition step, {
  required String from,
  required List<String> toIds,
}) {
  if (toIds.isEmpty) {
    return step;
  }
  var touched = false;
  final triggers = <StepTrigger>[];
  for (final trigger in step.triggers) {
    if (!trigger.sourceStepIds.contains(from)) {
      triggers.add(trigger);
      continue;
    }
    touched = true;
    final others = [
      for (final id in trigger.sourceStepIds)
        if (id != from) id,
    ];
    for (final to in toIds) {
      triggers.add(
        StepTrigger(sourceStepIds: [to, ...others], routeKey: trigger.routeKey),
      );
    }
  }
  final waitFor = [
    for (final id in step.waitForStepIds)
      if (id != from) id,
  ];
  if (!touched &&
      const ListEquality<String>().equals(waitFor, step.waitForStepIds)) {
    return step;
  }
  return PipelineStepDefinition(
    id: step.id,
    kind: step.kind,
    bodyKey: step.bodyKey,
    triggers: triggers,
    waitForStepIds: waitFor,
    config: step.config,
    x: step.x,
    y: step.y,
  );
}

PipelineStepDefinition _stripSources(
  PipelineStepDefinition step,
  Set<String> removedIds,
) {
  final triggers = [
    for (final trigger in step.triggers)
      if (trigger.sourceStepIds.any(removedIds.contains)) ...[
        if ([
          for (final id in trigger.sourceStepIds)
            if (!removedIds.contains(id)) id,
        ].isNotEmpty)
          StepTrigger(
            sourceStepIds: [
              for (final id in trigger.sourceStepIds)
                if (!removedIds.contains(id)) id,
            ],
            routeKey: trigger.routeKey,
          ),
      ] else
        trigger,
  ];
  final waitFor = [
    for (final id in step.waitForStepIds)
      if (!removedIds.contains(id)) id,
  ];
  if (const DeepCollectionEquality().equals(triggers, step.triggers) &&
      const ListEquality<String>().equals(waitFor, step.waitForStepIds)) {
    return step;
  }
  return PipelineStepDefinition(
    id: step.id,
    kind: step.kind,
    bodyKey: step.bodyKey,
    triggers: triggers,
    waitForStepIds: waitFor,
    config: step.config,
    x: step.x,
    y: step.y,
  );
}
