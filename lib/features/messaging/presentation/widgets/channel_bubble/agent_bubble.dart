import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/bubble_body.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/thinking_timeline.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_preview_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgentBubble extends ConsumerWidget {
  const AgentBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.thinkingMessage,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
  });

  final ChannelMessage message;
  final ChannelMessage? thinkingMessage;
  final String codeFont;

  /// Whether this bubble is rendered inside a thread panel.
  final bool isThreadReply;

  /// Thread reply metadata for preview bar.
  final ThreadPreviewData? threadPreview;

  /// Callback when user clicks reply-in-thread.
  final void Function(String messageId)? onReplyInThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final agentAsync = ref.watch(agentDetailProvider(message.senderId));
    final agentName =
        agentAsync.value?.name ?? message.senderId.substring(0, 4);
    final maxWidth = MediaQuery.sizeOf(context).width * maxBubbleFraction;
    final registry = ref.watch(activeStreamRegistryProvider);

    final eventStream = thinkingMessage != null
        ? registry.eventStreamFor(thinkingMessage!.id)
        : null;
    final textStream = registry.streamFor(message.id);
    final isThinkingLive =
        thinkingMessage != null && registry.isActive(thinkingMessage!.id);
    final isTextLive = registry.isActive(message.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$agentName: ${message.content}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GitHubUserAvatar(
              login: agentName,
              size: avatarSize,
              showHoverCard: false,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: IntrinsicWidth(
                  child: FocusableBubble(
                    isThreadReply: isThreadReply,
                    messageId: message.id,
                    onReplyInThread: onReplyInThread,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: bubblePadding,
                          decoration: BoxDecoration(
                            color: tokens.bgPrimary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(bubbleRadius),
                              topRight: Radius.circular(bubbleRadius),
                              bottomLeft: Radius.circular(tailRadius),
                              bottomRight: Radius.circular(bubbleRadius),
                            ),
                            border: Border.all(color: tokens.borderSecondary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                agentName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              if (thinkingMessage != null) ...[
                                const SizedBox(height: 8),
                                ThinkingTimeline(
                                  events: thinkingMessage!.thinkingEvents,
                                  eventStream: eventStream,
                                  isLive: isThinkingLive,
                                ),
                              ],
                              if (isTextLive || message.content.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                BubbleBody(
                                  content: message.content,
                                  createdAt: message.createdAt,
                                  codeFont: codeFont,
                                  tokens: tokens,
                                  theme: theme,
                                  textStream: textStream,
                                  isLive: isTextLive,
                                ),
                              ],
                            ],
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
        ),
      ),
    );
  }
}
