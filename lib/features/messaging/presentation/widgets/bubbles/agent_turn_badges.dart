part of 'agent_turn.dart';

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

/// A quiet failed-run badge with a scoped Retry action.
class _FailedBadge extends StatelessWidget {
  const _FailedBadge({required this.errorFamily, required this.onRetry});

  final String? errorFamily;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final label = errorFamily == null
        ? l10n.messageFailed
        : '${l10n.messageFailed} · $errorFamily';
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
        const SizedBox(width: 8),
        CcButton(
          onPressed: onRetry,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
