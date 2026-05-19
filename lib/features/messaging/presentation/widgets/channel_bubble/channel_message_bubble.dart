import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/plan_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/review_node_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/standalone_thinking_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/system_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/ticket_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/user_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChannelMessageBubble extends ConsumerWidget {
  const ChannelMessageBubble({
    super.key,
    required this.message,
    this.thinkingMessage,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
  });

  final ChannelMessage message;
  final ChannelMessage? thinkingMessage;

  /// Whether this bubble is rendered inside a thread panel.
  final bool isThreadReply;

  /// Thread reply metadata for preview bar under the bubble.
  final ThreadPreviewData? threadPreview;

  /// Callback when user clicks reply-in-thread on this message.
  final void Function(String messageId)? onReplyInThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    if (message.isSystem) {
      return SystemMessage(content: message.content);
    }
    if (message.isTicket) {
      return TicketCard(message: message);
    }
    if (message.isThinking) {
      return StandaloneThinkingBubble(message: message);
    }
    if (message.isPlan) {
      return PlanBubble(message: message);
    }
    if (message.isUserQuestion) {
      return QuestionBubble(message: message);
    }
    if (message.isReviewNode) {
      return ReviewNodeBubble(message: message);
    }
    if (message.isUser) {
      return UserBubble(
        message: message,
        codeFont: codeFont,
        isThreadReply: isThreadReply,
        threadPreview: threadPreview,
        onReplyInThread: onReplyInThread,
      );
    }
    return AgentBubble(
      message: message,
      thinkingMessage: thinkingMessage,
      codeFont: codeFont,
      isThreadReply: isThreadReply,
      threadPreview: threadPreview,
      onReplyInThread: onReplyInThread,
    );
  }
}
