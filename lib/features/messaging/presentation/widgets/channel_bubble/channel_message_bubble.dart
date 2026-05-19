import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/artifact_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/entity_ref_chips.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/plan_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/review_node_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/system_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/ticket_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/user_bubble.dart';
import 'package:control_center/features/orchestration/presentation/widgets/orchestration_proposal_bubble.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches a [ChannelMessage] to the correct bubble widget.
class ChannelMessageBubble extends ConsumerWidget {
  /// Creates a [ChannelMessageBubble].
  const ChannelMessageBubble({
    super.key,
    required this.message,
    this.collapseHeader = false,
  });

  /// The channel message.
  final ChannelMessage message;

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
    if (message.isArtifact) {
      return ArtifactBubble(message: message);
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
            collapseHeader: collapseHeader,
          )
        : AgentTurn(
            message: message,
            codeFont: codeFont,
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
