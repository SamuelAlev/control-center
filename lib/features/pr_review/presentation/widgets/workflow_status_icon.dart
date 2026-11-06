import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Reusable status glyph used by both the sidebar and the Actions tab.
class WorkflowStatusIcon extends StatelessWidget {
  /// Creates a [WorkflowStatusIcon].
  const WorkflowStatusIcon({super.key, required this.status, this.size = 16});

  /// Aggregated workflow status to render.
  final WorkflowStatus status;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = workflowStatusStyle(status, context);
    if (status == WorkflowStatus.running) {
      return CcSpinner(size: size, color: style.color);
    }
    return Icon(style.icon, size: size, color: style.color);
  }
}

/// Visual style descriptor for a [WorkflowStatus].
({IconData icon, Color color, String label}) workflowStatusStyle(
  WorkflowStatus status,
  BuildContext context,
) {
  switch (status) {
    case WorkflowStatus.running:
      return (
        icon: AppIcons.loader,
        color: ReviewStatusColors.running,
        label: AppLocalizations.of(context).running,
      );
    case WorkflowStatus.success:
      return (
        icon: AppIcons.checkCircle2,
        color: ReviewStatusColors.success,
        label: AppLocalizations.of(context).passed,
      );
    case WorkflowStatus.failure:
      return (
        icon: AppIcons.xCircle,
        color: ReviewStatusColors.failure,
        label: AppLocalizations.of(context).failed,
      );
    case WorkflowStatus.neutral:
      return (
        icon: AppIcons.minusCircle,
        color: ReviewStatusColors.neutral,
        label: AppLocalizations.of(context).neutral,
      );
  }
}
