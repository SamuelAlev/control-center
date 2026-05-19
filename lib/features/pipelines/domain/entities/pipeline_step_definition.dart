import 'package:collection/collection.dart';

import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';

/// A single step in a PipelineDefinition.
///
/// Steps are the nodes of the pipeline graph. Edges are defined by
/// [triggers] — when all source steps complete, this step fires.
class PipelineStepDefinition {
  /// Creates a [PipelineStepDefinition].
  PipelineStepDefinition({
    required this.id,
    required this.kind,
    required this.bodyKey,
    this.triggers = const [],
    this.waitForStepIds = const [],
    this.config = PipelineNodeConfig.empty,
    this.x,
    this.y,
  }) : assert(id.isNotEmpty, 'Step id must not be empty'),
       assert(bodyKey.isNotEmpty, 'bodyKey must not be empty');

  /// Unique identifier within the template (e.g. 'setup', 'fetch_context').
  final String id;

  /// What kind of step this is.
  final StepKind kind;

  /// Key used to look up the step body closure from PipelineBodyRegistry.
  final String bodyKey;

  /// Trigger conditions — when satisfied, this step fires.
  final List<StepTrigger> triggers;

  /// For [StepKind.join] steps: the step IDs that must all complete
  /// before this join fires.
  final List<String> waitForStepIds;

  /// Per-node configuration: prompt template, agent role, I/O keys, etc.
  final PipelineNodeConfig config;

  /// Canvas X coordinate (editor only; engine ignores).
  final double? x;

  /// Canvas Y coordinate (editor only; engine ignores).
  final double? y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineStepDefinition &&
          id == other.id &&
          kind == other.kind &&
          bodyKey == other.bodyKey &&
          const DeepCollectionEquality()
              .equals(triggers, other.triggers) &&
          const DeepCollectionEquality()
              .equals(waitForStepIds, other.waitForStepIds) &&
          config == other.config &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        bodyKey,
        const DeepCollectionEquality().hash(triggers),
        const DeepCollectionEquality().hash(waitForStepIds),
        config,
        x,
        y,
      );
}
