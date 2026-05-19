import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart' show PipelineNodeConfig;
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart' show StepTrigger;

/// The kind of a pipeline step definition.
///
/// Determines how the engine schedules the step relative to its triggers.
enum StepKind {
  /// The mandatory entry point of a pipeline — exactly one per template, and
  /// always the first node. A trigger node does no work itself; it declares
  /// *what starts the pipeline* (a manual run, a domain event, or a schedule,
  /// tracked as `PipelineTrigger` rows) and fans out to its downstream
  /// listeners. Its body is the no-op `pipeline.trigger`.
  trigger,

  /// Fires when all source steps (in [StepTrigger.sourceStepIds]) complete.
  listen,

  /// Fires when all steps in `waitForStepIds` reach terminal state.
  join,

  /// Conditional branching — body returns a router key (via
  /// `StepResult.route(key)`) that selects which downstream edge fires.
  /// Non-selected branches are marked skipped.
  router,

  /// Map / fan-out: runs its body once per item in a state collection
  /// ([PipelineNodeConfig.extras] `iterableKey`), keyed by branch index, then
  /// aggregates the per-item outputs into a list under `outputKey`.
  forEach,

  /// A terminal node. Pipeline completes when a terminal step finishes.
  terminal;
}
