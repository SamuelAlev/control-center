part of 'agent_turn.dart';

/// The agent's display name for [message]. Only the name is watched: watching
/// the whole agent future rebuilt the transcript whenever any other field on
/// the agent settled.
String agentTurnName(WidgetRef ref, Message message) =>
    ref.watch(
      agentDetailProvider(
        message.senderId,
      ).select((async) => async.asData?.value?.name),
    ) ??
    message.metadata?['agentName'] as String? ??
    message.senderId.substring(0, 4);

/// The top of an agent turn: the small name-only header (unless
/// [collapseHeader]) and the in-reply-to caption.
///
/// Shared by [AgentTurn] and the feed's row-per-part layout of a long turn.
class AgentTurnHeader extends ConsumerWidget {
  /// Creates the header of [message].
  const AgentTurnHeader({
    super.key,
    required this.message,
    required this.collapseHeader,
  });

  /// The agent turn.
  final Message message;

  /// Whether a consecutive same-sender turn hides the name.
  final bool collapseHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = resolveTokens(context);
    // The in-reply-to caption attributes a wake/consult/delegation turn to the
    // agent that triggered it, so multi-agent rooms read as a conversation.
    final inReplyTo = message.metadata?['inReplyToAgentName'] as String?;
    final caption = inReplyTo == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Text(
              '↳ ${AppLocalizations.of(context).replyingTo(inReplyTo)}',
              style: CcTypography.caption.copyWith(
                color: tokens.textQuaternary,
              ),
            ),
          );
    if (collapseHeader) {
      return caption ?? const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          agentTurnName(ref, message),
          style: CcTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: agentNameColor(message.senderId, tokens),
          ),
        ),
        ?caption,
      ],
    );
  }
}

/// The bottom of an agent turn: the quiet trailer line, then the feedback bar
/// or the turn-limit / failed / retried badge.
///
/// Shared by [AgentTurn] and the feed's row-per-part layout of a long turn.
class AgentTurnFooter extends StatelessWidget {
  /// Creates the footer of a turn.
  const AgentTurnFooter({
    super.key,
    required this.listed,
    required this.shown,
    required this.canRetry,
  });

  /// The live list row of the turn.
  final Message listed;

  /// The row as rendered: the detail read when one replaced the list row.
  final Message shown;

  /// Whether a failed turn offers Retry.
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final failure = _TurnFailure(listed, shown);
    // The turn ended cleanly but unfinished: the loop hit its turn ceiling.
    // Not an error (no retry affordance), but not a completion either — the
    // feedback bar makes no sense on a cut-short turn, so it is hidden too.
    final limited = shown.turnOutcome == TurnOutcome.maxTurns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AgentTrailer(message: shown, tokens: tokens),
        if (!failure.failed && !limited && shown.turnOutcome != null)
          AgentFeedbackBar(message: shown),
        if (limited) ...[
          const SizedBox(height: AppSpacing.sm),
          const _TurnLimitBadge(),
        ],
        if (failure.failed) ...[
          const SizedBox(height: AppSpacing.sm),
          _FailedBadge(
            turn: listed,
            errorFamily: failure.errorFamily,
            canRetry: canRetry,
          ),
        ] else if (failure.retried) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).retried,
            style: CcTypography.caption.copyWith(
              color: tokens.textQuaternary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
