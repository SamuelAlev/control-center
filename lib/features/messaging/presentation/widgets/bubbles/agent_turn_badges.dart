part of 'agent_turn.dart';

/// How a turn failed, read from both copies of its row.
///
/// The listed row is live. [_AgentTurnState._shown] can be the detail read,
/// which is one snapshot: taken before a retry, it never learns the turn was
/// retried, and a Retry action keyed on it alone stays up for good. Both flags
/// only ever turn on, so whichever copy has seen one is right.
extension _TurnFailure on _AgentTurnState {
  bool _flag(String key) =>
      widget.message.metadata?[key] == true || _shown.metadata?[key] == true;
  bool get _failed => _flag('error') && !_retried;
  bool get _retried => _flag('retried');
  String? get _errorFamily =>
      (_shown.metadata?['errorFamily'] ??
              widget.message.metadata?['errorFamily'])
          as String?;
}

/// A quiet badge for a turn that stopped at the loop's turn ceiling: warns
/// that the run is unfinished and that a plain reply keeps it going. Distinct
/// from [_FailedBadge] — nothing errored, so no retry affordance and the
/// warning (not error) color keeps it informational rather than alarming.
class _TurnLimitBadge extends StatelessWidget {
  const _TurnLimitBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.octagonAlert, size: 14, color: tokens.fgWarningPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context).turnLimitReached,
            style: CcTypography.caption.copyWith(
              color: tokens.textWarningPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A quiet failed-run badge. [canRetry] adds the Retry action.
///
/// One press is one request: the action is busy until the server answers, and
/// a failure to ask is said out loud. What happens next is the feed's to show:
/// the retry is a newer turn, so this row loses the action on its own. A press
/// that slips in before that is one the server ignores.
class _FailedBadge extends ConsumerStatefulWidget {
  const _FailedBadge({
    required this.turn,
    required this.errorFamily,
    required this.canRetry,
  });

  final Message turn;
  final String? errorFamily;
  final bool canRetry;

  @override
  ConsumerState<_FailedBadge> createState() => _FailedBadgeState();
}

class _FailedBadgeState extends ConsumerState<_FailedBadge> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await ref
          .read(messagingServiceProvider)
          .retryAgentTurn(
            workspaceId: ref.requireWorkspaceId(),
            spaceId: widget.turn.spaceId,
            failedMessageId: widget.turn.id,
          );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          AppLocalizations.of(context).failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final label = widget.errorFamily == null
        ? l10n.messageFailed
        : '${l10n.messageFailed} · ${widget.errorFamily}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.circleAlert, size: 14, color: tokens.textErrorPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: CcTypography.caption.copyWith(
              color: tokens.textErrorPrimary,
            ),
          ),
        ),
        if (widget.canRetry) ...[
          const SizedBox(width: 8),
          CcButton(
            onPressed: _retry,
            loading: _retrying,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            child: Text(l10n.retry),
          ),
        ],
      ],
    );
  }
}
