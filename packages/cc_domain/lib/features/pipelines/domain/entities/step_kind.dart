import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart'
    show PipelineNodeConfig;
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart'
    show StepTrigger;

/// The kind of a pipeline step definition.
///
/// Determines how the engine schedules the step relative to its triggers.
enum StepKind {
  /// A start node. A template has one per [PipelineTrigger] row; each owns
  /// its own outgoing wires. A trigger node does no work itself — it
  /// completes immediately so the engine fans out to *this start's*
  /// listeners. Which start a run enters is selected by the run's
  /// `triggerEventType`. Its body is the no-op `pipeline.trigger`.
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
  terminal,
}
