import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/plan_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/review_node_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/system_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/ticket_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/user_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/orchestration/presentation/widgets/orchestration_proposal_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches a [ChannelMessage] to the correct bubble widget.
class ChannelMessageBubble extends ConsumerWidget {
  /// Creates a [ChannelMessageBubble].
  const ChannelMessageBubble({
    super.key,
    required this.message,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
  });

  /// The channel message.
  final ChannelMessage message;

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
    if (message.isPlan) {
      return PlanBubble(message: message);
    }
    if (message.isUserQuestion) {
      return QuestionBubble(message: message);
    }
    if (message.isReviewNode) {
      return ReviewNodeBubble(message: message);
    }
    if (message.isOrchestrationProposal) {
      return OrchestrationProposalBubble(message: message);
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
      codeFont: codeFont,
      isThreadReply: isThreadReply,
      threadPreview: threadPreview,
      onReplyInThread: onReplyInThread,
    );
  }
}
