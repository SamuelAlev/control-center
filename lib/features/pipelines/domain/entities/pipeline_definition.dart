import 'package:collection/collection.dart';

import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';

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
    this.version = 1,
  }) : assert(templateId.isNotEmpty, 'templateId must not be empty'),
       assert(workspaceId.isNotEmpty, 'workspaceId must not be empty'),
       assert(name.isNotEmpty, 'name must not be empty');

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
  /// Every pipeline has exactly one, and it is always the first node.
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
        .where((s) =>
            s.triggers.any((t) => t.sourceStepIds.contains(sourceStepId)))
        .toList();
  }

  /// Returns a copy with the given fields overridden. Fields left null keep
  /// their current value (so callers can flip one flag without dropping
  /// [inputs], [steps], etc.).
  PipelineDefinition copyWith({
    String? name,
    String? description,
    List<PipelineStepDefinition>? steps,
    List<PipelineInput>? inputs,
    bool? isBuiltIn,
    bool? isEnabled,
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
          isEnabled == other.isEnabled;

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
      );
}
