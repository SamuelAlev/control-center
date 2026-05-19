import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty state.
class EmptyState extends StatelessWidget {
  /// Creates a new [EmptyState].
  const EmptyState({
    super.key,
    required this.message,
    this.icon = LucideIcons.folderOpen,
    this.iconSize = 48,
    this.primaryAction,
    this.actionLabel,
    this.query,
    this.description,
  });

  /// Primary message displayed below the icon.
  final String message;

  /// Optional secondary line below the message that teaches what fills this
  /// surface (e.g. "Facts appear here as your agents learn.").
  final String? description;

  /// Icon displayed above the message.
  final IconData icon;

  /// Size of the icon.
  final double iconSize;

  /// Optional callback for the primary action button.
  final VoidCallback? primaryAction;

  /// Label for the primary action button.
  final String? actionLabel;

  /// Optional search query to display (e.g. when a filter yields no results).
  final String? query;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: theme.colors.mutedForeground),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          if (description != null && description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (query != null && query!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"$query"',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
          if (primaryAction != null && actionLabel != null) ...[
            const SizedBox(height: 8),
            FButton(
              onPress: primaryAction,
              mainAxisSize: MainAxisSize.min,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

