import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/material.dart';

/// Renders a centered system message with divider lines.
class SystemMessage extends StatelessWidget {
  /// Creates a [SystemMessage].
  const SystemMessage({super.key, required this.content});

  /// The system message content.
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        label: 'System: $content',
        child: Row(
          children: [
            Expanded(child: Divider(color: tokens.borderSecondary)),
            const SizedBox(width: 12),
            Text(
              content,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: tokens.borderSecondary)),
          ],
        ),
      ),
    );
  }
}
