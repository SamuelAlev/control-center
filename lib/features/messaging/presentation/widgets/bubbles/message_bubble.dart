import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
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
    this.inlineMessages = const [],
    this.canRetry = false,
    this.onStartThread,
    this.onOpenThread,
  });

  /// The space message.
  final Message message;

  /// Whether to collapse the sender header (consecutive same-sender turn).
  final bool collapseHeader;

  /// Steering and resolved questions placed inside this agent turn's transcript.
  final List<Message> inlineMessages;

  /// Whether a failed agent turn offers Retry (see `MessageItem.canRetry`).
  final bool canRetry;

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
            inlineMessages: inlineMessages,
            canRetry: canRetry,
            onStartThread: onStartThread,
          );

    final open = onOpenThread;
    final footnotes = messageFootnotes(
      message: message,
      thread: watchThreadSummary(ref, message, open),
      onOpenThread: open,
    );
    if (footnotes.isEmpty) {
      return bubble;
    }
    return Column(
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [bubble, ...footnotes],
    );
  }
}

/// The thread [message] started, when [onOpenThread] can open one.
///
/// The space publishes one map of every thread. Selecting this message's
/// rollup means a reply in some other thread does not rebuild this row (and
/// the transcript under it).
ThreadSummary? watchThreadSummary(
  WidgetRef ref,
  Message message,
  void Function(String threadId)? onOpenThread,
) => onOpenThread == null
    ? null
    : ref.watch(
        spaceThreadSummariesProvider(
          message.spaceId,
        ).select((async) => async.asData?.value[message.id]),
      );

/// What renders beneath a message: `#`-tagged entity references
/// (tickets/PRs/meetings) as live chips aligned with the bubble's side, and
/// the "N replies" row of a thread started from it, because the thread is
/// otherwise invisible from the stream it branched off.
List<Widget> messageFootnotes({
  required Message message,
  required ThreadSummary? thread,
  required void Function(String threadId)? onOpenThread,
}) {
  final refs = message.entityRefs;
  return [
    if (refs.isNotEmpty)
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 4),
        child: EntityRefChips(refs: refs, alignEnd: message.isUser),
      ),
    if (thread != null && onOpenThread != null)
      ThreadIndicator(
        summary: thread,
        onOpen: onOpenThread,
        alignEnd: message.isUser,
      ),
  ];
}

/// [messageFootnotes] for a message whose bubble is laid out elsewhere (the
/// footer row of an agent turn the feed lays out row by row).
class MessageFootnotes extends ConsumerWidget {
  /// Creates the footnotes of [message].
  const MessageFootnotes({super.key, required this.message, this.onOpenThread});

  /// The message.
  final Message message;

  /// Opens the thread this message started; null hides the replies row.
  final void Function(String threadId)? onOpenThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final footnotes = messageFootnotes(
      message: message,
      thread: watchThreadSummary(ref, message, onOpenThread),
      onOpenThread: onOpenThread,
    );
    if (footnotes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: footnotes,
    );
  }
}
