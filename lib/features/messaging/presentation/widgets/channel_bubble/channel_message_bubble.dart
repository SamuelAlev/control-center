import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/entity_ref_chips.dart';
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
    this.collapseHeader = false,
  });

  /// The channel message.
  final ChannelMessage message;

  /// Whether this bubble is rendered inside a thread panel.
  final bool isThreadReply;

  /// Thread reply metadata for preview bar under the bubble.
  final ThreadPreviewData? threadPreview;

  /// Callback when user clicks reply-in-thread on this message.
  final void Function(String messageId)? onReplyInThread;

  /// Whether to collapse the sender header (consecutive same-sender turn).
  final bool collapseHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    if (message.isSystem || message.isCompaction) {
      // A compaction summary stands in for older history; render it as a
      // subtle system divider rather than an agent turn.
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
    final Widget bubble = message.isUser
        ? UserBubble(
            message: message,
            codeFont: codeFont,
            isThreadReply: isThreadReply,
            threadPreview: threadPreview,
            onReplyInThread: onReplyInThread,
            collapseHeader: collapseHeader,
          )
        : AgentTurn(
            message: message,
            codeFont: codeFont,
            isThreadReply: isThreadReply,
            threadPreview: threadPreview,
            onReplyInThread: onReplyInThread,
            collapseHeader: collapseHeader,
          );

    // `#`-tagged entity references (tickets/PRs/meetings) render as live chips
    // beneath the bubble, aligned with the bubble's side.
    final refs = message.entityRefs;
    if (refs.isEmpty) {
      return bubble;
    }
    return Column(
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        bubble,
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
          child: EntityRefChips(refs: refs, alignEnd: message.isUser),
        ),
      ],
    );
  }
}
