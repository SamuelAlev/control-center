import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:collection/collection.dart';

/// Sentinel distinguishing "argument omitted" from "explicitly null" in
/// [PipelineDefinition.copyWith] for the nullable
/// [PipelineDefinition.maxParallelRuns] — so a caller can clear the cap back to
/// unlimited without every other copy silently dropping it.
const Object _kUnset = Object();

/// A declarative graph of steps that defines how a pipeline executes.
///
/// Built directly via `PipelineStepDefinition` lists in the built-in
/// seeds or assembled in the editor. Immutable once constructed.
class PipelineDefinition {
  /// Creates a [PipelineDefinition].
  PipelineDefinition({
    required this.templateId,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.steps,
    this.inputs = const [],
    this.isBuiltIn = false,
    this.isEnabled = true,
    this.maxParallelRuns,
    this.version = 1,
  }) {
    if (templateId.isEmpty) {
      throw ArgumentError('templateId must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    if (maxParallelRuns != null && maxParallelRuns! < 1) {
      throw ArgumentError.value(
        maxParallelRuns,
        'maxParallelRuns',
        'must be null (unlimited) or at least 1',
      );
    }
  }

  /// Rebuilds a definition from its [toJson] envelope (template import,
  /// FINDINGS §7.5). [templateId] and [workspaceId] may be overridden so a
  /// shared template can be imported into a different workspace / under a new
  /// id (they are the only workspace-bound fields; the graph itself is
  /// portable). [isBuiltIn] is always cleared on import — an imported template
  /// is user-authored, never a re-seeded built-in.
  factory PipelineDefinition.fromJson(
    Map<String, dynamic> json, {
    String? templateId,
    String? workspaceId,
  }) {
    return PipelineDefinition(
      templateId: templateId ?? json['template_id'] as String,
      workspaceId: workspaceId ?? json['workspace_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: [
        for (final s in (json['steps'] as List? ?? const []))
          if (s is Map)
            PipelineStepDefinition.fromJson(Map<String, dynamic>.from(s)),
      ],
      inputs: [
        for (final i in (json['inputs'] as List? ?? const []))
          if (i is Map) PipelineInput.fromJson(Map<String, dynamic>.from(i)),
      ],
      isEnabled: json['is_enabled'] as bool? ?? true,
      maxParallelRuns: (json['max_parallel_runs'] as num?)?.toInt(),
      version: json['version'] as int? ?? 1,
    );
  }

  /// Schema version of the export envelope, so an importer can reject/upgrade
  /// an incompatible document.
  static const int exportSchema = 1;

  /// Serializes this definition to a portable export envelope (FINDINGS §7.5).
  /// Carries [exportSchema] and includes `template_id`/`workspace_id` for a
  /// same-workspace round-trip; a cross-workspace import overrides them via
  /// [PipelineDefinition.fromJson]. `isBuiltIn` is deliberately omitted — an
  /// exported template is shared as user content.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'export_schema': exportSchema,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
    'steps': [for (final s in steps) s.toJson()],
    'inputs': [for (final i in inputs) i.toJson()],
    'is_enabled': isEnabled,
    'max_parallel_runs': ?maxParallelRuns,
    'version': version,
  };

  /// Template identifier (e.g. 'pr_review', 'hello'). Unique per workspace.
  final String templateId;

  /// Workspace this template belongs to. Per-workspace because per-node
  /// config references workspace-scoped agent IDs.
  final String workspaceId;

  /// Human-readable template name.
  final String name;

  /// Optional description of what this pipeline does.
  final String? description;

  /// Ordered list of step definitions.
  final List<PipelineStepDefinition> steps;

  /// Declared inputs collected when the pipeline is started manually. Empty
  /// for pipelines that take no user-supplied input (event/scheduled runs read
  /// their payload from the triggering event instead). Rendered as a form on
  /// the manual run page; the submitted values become the run's trigger
  /// payload.
  final List<PipelineInput> inputs;

  /// Whether this template is a built-in (re-seeded on each app launch).
  /// User-authored templates have this false.
  final bool isBuiltIn;

  /// Whether this template is enabled. Disabled templates cannot be started
  /// and do not appear in trigger pickers. Defaults to true.
  final bool isEnabled;

  /// How many runs of this template may execute at once, or null for
  /// unlimited (the default).
  ///
  /// A start requested while the cap is full is **queued**, not dropped:
  /// the run is persisted `PipelineRunStatus.queued` and the engine admits it
  /// when a slot frees. Dropping would be wrong for the templates that need a
  /// cap in the first place — `index_code` is capped at 1 so N repos don't
  /// index concurrently, and a dropped index leaves that repo unindexed until
  /// something happens to trigger it again.
  final int? maxParallelRuns;

  /// Monotonic version, bumped on each edit. Runs pin to the version they
  /// started against.
  final int version;

  /// Finds a step by [stepId], or null if not found.
  PipelineStepDefinition? step(String stepId) {
    for (final s in steps) {
      if (s.id == stepId) {
        return s;
      }
    }
    return null;
  }

  /// Returns the entry (trigger) step — the one with [StepKind.trigger].
  /// Every pipeline has exactly one and it is always the first node.
  PipelineStepDefinition get entryStep {
    for (final s in steps) {
      if (s.kind == StepKind.trigger) {
        return s;
      }
    }
    throw StateError('PipelineDefinition "$templateId" has no trigger step');
  }

  /// Returns steps that listen to [sourceStepId].
  List<PipelineStepDefinition> listenersOf(String sourceStepId) {
    return steps
        .where(
          (s) => s.triggers.any((t) => t.sourceStepIds.contains(sourceStepId)),
        )
        .toList();
  }

  /// Returns a copy with the given fields overridden. Fields left null keep
  /// their current value (so callers can flip one flag without dropping
  /// [inputs], [steps], etc.).
  ///
  /// [maxParallelRuns] is nullable-aware: omit it to keep the current cap, or
  /// pass `null` explicitly to clear it back to unlimited.
  PipelineDefinition copyWith({
    String? name,
    String? description,
    List<PipelineStepDefinition>? steps,
    List<PipelineInput>? inputs,
    bool? isBuiltIn,
    bool? isEnabled,
    Object? maxParallelRuns = _kUnset,
    int? version,
  }) {
    return PipelineDefinition(
      templateId: templateId,
      workspaceId: workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      inputs: inputs ?? this.inputs,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      maxParallelRuns: identical(maxParallelRuns, _kUnset)
          ? this.maxParallelRuns
          : maxParallelRuns as int?,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineDefinition &&
          templateId == other.templateId &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          description == other.description &&
          const DeepCollectionEquality().equals(steps, other.steps) &&
          const DeepCollectionEquality().equals(inputs, other.inputs) &&
          isBuiltIn == other.isBuiltIn &&
          isEnabled == other.isEnabled &&
          maxParallelRuns == other.maxParallelRuns;

  @override
  int get hashCode => Object.hash(
    templateId,
    workspaceId,
    name,
    description,
    const DeepCollectionEquality().hash(steps),
    const DeepCollectionEquality().hash(inputs),
    isBuiltIn,
    isEnabled,
    maxParallelRuns,
  );
}
