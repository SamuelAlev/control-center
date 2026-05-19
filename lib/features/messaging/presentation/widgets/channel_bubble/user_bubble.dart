import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/bubble_body.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_preview_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/material.dart';

/// Renders a user message as a right-aligned bubble, capped at ~75% of the
/// centered content column. The user avatar is intentionally dropped (the
/// "You" attribution is implicit on the right edge); the column width — not
/// the viewport — bounds the cap, so the bubble shrinks on narrow panes and
/// stays composed on wide ones.
class UserBubble extends StatelessWidget {
  /// Creates a [UserBubble].
  const UserBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
    this.collapseHeader = false,
  });

  /// The user message.
  final ChannelMessage message;

  /// Font family for code blocks.
  final String codeFont;

  /// Whether this bubble is rendered inside a thread panel.
  final bool isThreadReply;

  /// Thread reply metadata for preview bar.
  final ThreadPreviewData? threadPreview;

  /// Callback when user clicks reply-in-thread.
  final void Function(String messageId)? onReplyInThread;

  /// When true (consecutive same-sender turn), top padding tightens so grouped
  /// user messages read as one run.
  final bool collapseHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final topPad = isThreadReply || collapseHeader
        ? AppSpacing.xxs
        : AppSpacing.xl;

    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Semantics(
        label: 'You: ${message.content}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Cap the bubble at ~75% of the (already-centered, ≤760px) column
            // it sits in, not the viewport.
            final maxWidth = constraints.maxWidth * maxBubbleFraction;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: IntrinsicWidth(
                      child: FocusableBubble(
                        isThreadReply: isThreadReply,
                        messageId: message.id,
                        onReplyInThread: onReplyInThread,
                        alignRight: true,
                        copyText: message.content,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: bubblePadding,
                              decoration: BoxDecoration(
                                color: tokens.bgSecondary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(bubbleRadius),
                                  topRight: Radius.circular(bubbleRadius),
                                  bottomLeft: Radius.circular(bubbleRadius),
                                  bottomRight: Radius.circular(tailRadius),
                                ),
                                border:
                                    Border.all(color: tokens.borderSecondary),
                              ),
                              child: BubbleBody(
                                content: message.content,
                                createdAt: message.createdAt,
                                codeFont: codeFont,
                                tokens: tokens,
                                theme: theme,
                              ),
                            ),
                            if (!isThreadReply && threadPreview != null)
                              ThreadPreviewBar(
                                preview: threadPreview!,
                                onTap: () =>
                                    onReplyInThread?.call(message.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
