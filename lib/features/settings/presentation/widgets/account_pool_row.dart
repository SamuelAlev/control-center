import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart'
    show AccountPoolCandidate;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One attachable credential in an account pool: a checkbox, its identity
/// and its position in the order.
class AccountPoolRow extends StatelessWidget {
  /// Creates an [AccountPoolRow].
  const AccountPoolRow({
    required this.candidate,
    required this.attached,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.position,
    required this.onToggle,
    required this.onMove,
    super.key,
  });

  /// The credential this row shows.
  final AccountPoolCandidate candidate;

  /// Whether it is in the pool.
  final bool attached;

  /// Whether it can move earlier in the order.
  final bool canMoveUp;

  /// Whether it can move later in the order.
  final bool canMoveDown;

  /// Its 1-based position, or null when detached.
  final int? position;

  /// Attaches or detaches it.
  final VoidCallback onToggle;

  /// Moves it by the given number of places (negative moves it earlier).
  final Future<void> Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final detail = [
      if (candidate.detail != null && candidate.detail!.isNotEmpty)
        candidate.detail!,
      if (candidate.unavailable && candidate.unavailableReason != null)
        candidate.unavailableReason!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CcCheckbox(
            value: attached,
            semanticLabel: candidate.label,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 8),
          if (position != null) ...[
            // The position is the whole point of an ordered pool, so it is
            // stated rather than left to be inferred from vertical order.
            SizedBox(
              width: 18,
              child: Text(
                '$position',
                style: TextStyle(fontSize: 11, color: t.fgSecondary),
              ),
            ),
          ] else
            const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: attached ? t.fgPrimary : t.fgSecondary,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: t.fgSecondary),
                  ),
              ],
            ),
          ),
          if (attached) ...[
            CcIconButton(
              icon: AppIcons.arrowUp,
              size: CcButtonSize.sm,
              tooltip: l10n.accountPoolMoveUp,
              onPressed: canMoveUp ? () => onMove(-1) : null,
            ),
            CcIconButton(
              icon: AppIcons.arrowDown,
              size: CcButtonSize.sm,
              tooltip: l10n.accountPoolMoveDown,
              onPressed: canMoveDown ? () => onMove(1) : null,
            ),
          ],
        ],
      ),
    );
  }
}
