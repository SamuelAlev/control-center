import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:collection/collection.dart';

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
  }) {
    if (id.isEmpty) {
      throw ArgumentError('Step id must not be empty');
    }
    if (bodyKey.isEmpty) {
      throw ArgumentError('bodyKey must not be empty');
    }
  }

  /// Rebuilds a [PipelineStepDefinition] from its [toJson] map (template
  /// import). Unknown [StepKind] names fall back to [StepKind.listen].
  factory PipelineStepDefinition.fromJson(Map<String, dynamic> json) {
    return PipelineStepDefinition(
      id: json['id'] as String,
      kind: StepKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => StepKind.listen,
      ),
      bodyKey: json['body_key'] as String,
      triggers: [
        for (final t in (json['triggers'] as List? ?? const []))
          if (t is Map) StepTrigger.fromJson(Map<String, dynamic>.from(t)),
      ],
      waitForStepIds: [
        for (final s in (json['wait_for_step_ids'] as List? ?? const []))
          if (s is String) s,
      ],
      config: json['config'] is Map
          ? PipelineNodeConfig.fromJson(
              Map<String, dynamic>.from(json['config'] as Map),
            )
          : PipelineNodeConfig.empty,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
    );
  }

  /// Serializes this step for template export.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'body_key': bodyKey,
    'triggers': [for (final t in triggers) t.toJson()],
    if (waitForStepIds.isNotEmpty) 'wait_for_step_ids': waitForStepIds,
    'config': config.toJson(),
    if (x != null) 'x': x,
    if (y != null) 'y': y,
  };

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
          const DeepCollectionEquality().equals(triggers, other.triggers) &&
          const DeepCollectionEquality().equals(
            waitForStepIds,
            other.waitForStepIds,
          ) &&
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
