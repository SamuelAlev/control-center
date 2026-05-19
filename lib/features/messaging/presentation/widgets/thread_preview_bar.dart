import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/material.dart';

/// Bar shown under a message bubble when it has threaded replies.
/// Displays reply count + truncated snippet of the last reply.
class ThreadPreviewBar extends StatelessWidget {
  /// Creates a [ThreadPreviewBar].
  const ThreadPreviewBar({
    super.key,
    required this.preview,
    required this.onTap,
  });

  /// Thread metadata for display.
  final ThreadPreviewData preview;
  /// Called when the bar is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final count = preview.count;
    final lastContent = preview.lastReply.content;
    final snippet = lastContent.length > 60
        ? '${lastContent.substring(0, 60)}…'
        : lastContent;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count ${count == 1 ? 'reply' : 'replies'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                snippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
