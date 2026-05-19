import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Streak flame.
class StreakFlame extends StatelessWidget {
  /// Creates a new [StreakFlame].
  const StreakFlame({
    super.key,
    required this.count,
    required this.label,
    this.isActive = false,
  });

  /// Current streak count.
  final int count;
  /// Label describing the streak type.
  final String label;
  /// Whether the streak is currently active.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DesignSystemTokens.of(context);
    final color = isActive
        ? (tokens?.fgWarningPrimary ?? theme.colorScheme.tertiary)
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.flame, size: 20, color: color),
        const SizedBox(height: 2),
        Text('$count', style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
