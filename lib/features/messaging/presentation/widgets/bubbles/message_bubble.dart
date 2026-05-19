import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/artifact_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/compaction_divider.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/entity_ref_chips.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/plan_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/review_node_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/steering_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/system_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/thread_indicator.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/ticket_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/user_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/orchestration/presentation/widgets/orchestration_proposal_bubble.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches a [Message] to the correct bubble widget.
class SpaceMessageBubble extends ConsumerWidget {
  /// Creates a [SpaceMessageBubble].
  const SpaceMessageBubble({
    super.key,
    required this.message,
    this.collapseHeader = false,
    this.onStartThread,
    this.onOpenThread,
  });

  /// The space message.
  final Message message;

  /// Whether to collapse the sender header (consecutive same-sender turn).
  final bool collapseHeader;

  /// Hover-rail "start thread" affordance, forwarded to text bubbles only —
  /// cards (ticket/plan/artifact/question/review/orchestration/system) never
  /// offer it.
  final VoidCallback? onStartThread;

  /// Opens the thread this message started, from the indicator row beneath it.
  /// Null hides the indicator — a thread with no way in is worse than none.
  final void Function(String threadId)? onOpenThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    if (message.isCompaction) {
      // A compaction is a boundary, not a message: what the reader needs at
      // this point is "the agent's memory of everything above is now a
      // summary", not the summary itself. Collapsed by default, expandable.
      return CompactionDivider(message: message);
    }
    if (message.isSystem) {
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
    if (message.isSteering) {
      // An injected steering message: it already rendered in the queue strip
      // while queued; here it reads as the user's words with a quiet marker
      // that they steered a running agent mid-turn rather than starting one.
      // (`isSteeringQueued` rows never reach the feed — see
      // `_buildFeedItems`.)
      return SteeringBubble(message: message, codeFont: codeFont);
    }
    final Widget bubble = message.isUser
        ? UserBubble(
            message: message,
            codeFont: codeFont,
            collapseHeader: collapseHeader,
            onStartThread: onStartThread,
          )
        : AgentTurn(
            message: message,
            codeFont: codeFont,
            collapseHeader: collapseHeader,
            onStartThread: onStartThread,
          );

    // `#`-tagged entity references (tickets/PRs/meetings) render as live chips
    // beneath the bubble, aligned with the bubble's side; a thread started
    // from this message gets its "N replies" row directly under them, because
    // the thread is otherwise invisible from the stream it branched off.
    final refs = message.entityRefs;
    final open = onOpenThread;
    final thread = open == null
        ? null
        : ref
              .watch(spaceThreadSummariesProvider(message.spaceId))
              .value?[message.id];
    if (refs.isEmpty && thread == null) {
      return bubble;
    }
    return Column(
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        bubble,
        if (refs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: EntityRefChips(refs: refs, alignEnd: message.isUser),
          ),
        if (thread != null && open != null)
          ThreadIndicator(
            summary: thread,
            onOpen: open,
            alignEnd: message.isUser,
          ),
      ],
    );
  }
}
