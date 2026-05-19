import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

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
        ? (
            pipelineStepStatusLabel(stepStatus!, l10n),
            pipelineStepStatusColors(stepStatus!, tokens),
          )
        : (
            pipelineRunStatusLabel(status!, l10n),
            pipelineRunStatusColors(status!, tokens),
          );

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
          // Flexible so the pill degrades to an ellipsis in a width-capped
          // column (the runs table) instead of overflowing its cell.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.foreground,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
