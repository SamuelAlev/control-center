import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The live execution state of a plan node, derived from its pipeline step run
/// plus the plan's approval/drift state. Rendered with an ICON + LABEL, never
/// colour alone (WCAG AAA "never status-by-colour-alone").
enum PlanNodeRunState {
  /// Not yet approved — materialized behind a suspended approval gate.
  deferred,

  /// Approved, not started.
  pending,

  /// Executing.
  running,

  /// Held by stop-and-ask drift policy.
  diverged,

  /// Finished successfully.
  done,

  /// Finished with a failure.
  failed,

  /// A structural node (research/discussion/synthesis frame) or no run yet.
  none,
}

/// Icon + short label + token colour for a node run state.
class PlanNodeStateVisual {
  /// Creates a visual bundle of [icon], [label], and [color] for one run state.
  const PlanNodeStateVisual(this.icon, this.label, this.color);

  /// The state icon (paired with [label] so colour is never the sole signal).
  final IconData icon;

  /// A short human label.
  final String label;

  /// The accent colour token for this state.
  final Color color;
}

/// Resolves a node's run state from the pipeline step runs of its
/// orchestration (step ids `sub_<key>`, gate ids `gate_<key>`), the approved
/// node set, and the drift markers.
PlanNodeRunState resolvePlanNodeRunState(
  String nodeKey, {
  required List<PipelineStepRun> stepRuns,
  required List<String>? approvedNodeKeys,
  required Map<String, dynamic> divergence,
}) {
  final marker = divergence[nodeKey];
  if (marker is Map && marker['held'] == true) {
    return PlanNodeRunState.diverged;
  }
  // Latest run for this node's work step.
  PipelineStepRun? latest;
  for (final sr in stepRuns) {
    if (sr.stepId == 'sub_$nodeKey') {
      if (latest == null || sr.startedAt.isAfter(latest.startedAt)) {
        latest = sr;
      }
    }
  }
  if (latest != null) {
    switch (latest.status) {
      case PipelineStepStatus.completed:
        return PlanNodeRunState.done;
      case PipelineStepStatus.failed:
      case PipelineStepStatus.cancelled:
        return PlanNodeRunState.failed;
      case PipelineStepStatus.skipped:
        return PlanNodeRunState.none;
      case PipelineStepStatus.running:
      case PipelineStepStatus.suspended:
        return PlanNodeRunState.running;
      case PipelineStepStatus.pending:
        break;
    }
  }
  // No work-step run yet: deferred if the plan is partially approved and this
  // node is not in the set; else pending once execution has begun.
  if (approvedNodeKeys != null && !approvedNodeKeys.contains(nodeKey)) {
    return PlanNodeRunState.deferred;
  }
  final started = stepRuns.isNotEmpty;
  return started ? PlanNodeRunState.pending : PlanNodeRunState.none;
}

/// The icon/label/colour for a run state, from the design-system tokens.
PlanNodeStateVisual planNodeStateVisual(
  PlanNodeRunState state,
  DesignSystemTokens ds,
) {
  switch (state) {
    case PlanNodeRunState.deferred:
      return PlanNodeStateVisual(AppIcons.clock, 'Deferred', ds.textTertiary);
    case PlanNodeRunState.pending:
      return PlanNodeStateVisual(
        AppIcons.circleDashed,
        'Pending',
        ds.textSecondary,
      );
    case PlanNodeRunState.running:
      return PlanNodeStateVisual(AppIcons.loaderCircle, 'Running', ds.accent);
    case PlanNodeRunState.diverged:
      return PlanNodeStateVisual(
        AppIcons.triangleAlert,
        'Diverged',
        ds.textWarningPrimary,
      );
    case PlanNodeRunState.done:
      return PlanNodeStateVisual(AppIcons.circleCheck, 'Done', ds.success);
    case PlanNodeRunState.failed:
      return PlanNodeStateVisual(AppIcons.circleX, 'Failed', ds.danger);
    case PlanNodeRunState.none:
      return PlanNodeStateVisual(AppIcons.circle, '', ds.textTertiary);
  }
}

/// The type icon + label for a plan node (research / work / discussion /
/// synthesis), so node kind is legible independent of run state.
({IconData icon, String label}) planNodeTypeVisual(PlanNodeType type) {
  switch (type) {
    case PlanNodeType.research:
      return (icon: AppIcons.search, label: 'Research');
    case PlanNodeType.work:
      return (icon: AppIcons.squareCheckBig, label: 'Work');
    case PlanNodeType.discussion:
      return (icon: AppIcons.messagesSquare, label: 'Discussion');
    case PlanNodeType.synthesis:
      return (icon: AppIcons.sparkles, label: 'Synthesis');
  }
}
