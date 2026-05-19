import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';

/// Workspace health gauge.
class WorkspaceHealthGauge extends StatelessWidget {
  /// Creates a new [WorkspaceHealthGauge].
  const WorkspaceHealthGauge({
    super.key,
    required this.score,
    required this.label,
  });

  /// Health score (0–100).
  final double score;
  /// Workspace name label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final color = score >= 70
        ? (tokens?.fgSuccessPrimary ?? theme.colorScheme.primary)
        : score >= 40
            ? (tokens?.fgWarningPrimary ?? theme.colorScheme.tertiary)
            : (tokens?.fgErrorPrimary ?? theme.colorScheme.error);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('${score.round()}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
