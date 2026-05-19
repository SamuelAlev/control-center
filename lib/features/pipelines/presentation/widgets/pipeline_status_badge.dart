import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Small pill badge showing a pipeline run or step status, colored from the
/// design system semantic tokens with a leading status dot.
class PipelineStatusBadge extends StatelessWidget {
  /// Creates a [PipelineStatusBadge] for a pipeline run status.
  const PipelineStatusBadge.forRun({
    super.key,
    required this.status,
    this.stepStatus,
  }) : isStep = false;

  /// Creates a [PipelineStatusBadge] for a step run status.
  const PipelineStatusBadge.forStep({
    super.key,
    required this.stepStatus,
    this.status,
  }) : isStep = true;

  /// Pipeline run status.
  final PipelineRunStatus? status;

  /// Step run status.
  final PipelineStepStatus? stepStatus;

  /// Whether this badge represents a step (vs a pipeline run).
  final bool isStep;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final (label, c) = isStep
        ? (_stepLabel(stepStatus!, l10n), pipelineStepStatusColors(stepStatus!, tokens))
        : (_runLabel(status!, l10n), pipelineRunStatusColors(status!, tokens));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c.foreground,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _runLabel(PipelineRunStatus s, AppLocalizations l10n) {
    return switch (s) {
      PipelineRunStatus.pending => l10n.pipelineStatusPending,
      PipelineRunStatus.running => l10n.pipelineStatusRunning,
      PipelineRunStatus.suspended => l10n.pipelineStatusSuspended,
      PipelineRunStatus.completed => l10n.pipelineStatusCompleted,
      PipelineRunStatus.failed => l10n.pipelineStatusFailed,
      PipelineRunStatus.cancelled => l10n.pipelineStatusCancelled,
    };
  }

  String _stepLabel(PipelineStepStatus s, AppLocalizations l10n) {
    return switch (s) {
      PipelineStepStatus.pending => l10n.pipelineStatusPending,
      PipelineStepStatus.running => l10n.pipelineStatusRunning,
      PipelineStepStatus.suspended => l10n.pipelineStatusSuspended,
      PipelineStepStatus.completed => l10n.pipelineStatusCompleted,
      PipelineStepStatus.failed => l10n.pipelineStatusFailed,
      PipelineStepStatus.skipped => l10n.pipelineStatusSkipped,
      PipelineStepStatus.cancelled => l10n.pipelineStatusCancelled,
    };
  }
}
