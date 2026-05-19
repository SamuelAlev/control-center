import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Accent-colored divider marking the boundary between read and unread agent
/// turns — "New". Sits just above the first unread agent message so the reader
/// reads downward into fresh content.
///
/// Computed against a snapshot of the read cursor captured at space open
/// (not the live cursor), so it does not vanish the instant the cursor is
/// re-stamped on open/reach-bottom.
class UnreadDivider extends StatelessWidget {
  /// Creates an [UnreadDivider].
  const UnreadDivider({super.key, this.count});

  /// Optional unread count to surface inline ("New · 3"). When null the label
  /// is just "New".
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: CcDivider(color: tokens.accent.withValues(alpha: 0.4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              count == null ? l10n.newMessages : '${l10n.newMessages} · $count',
              style: CcTypography.caption.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: CcDivider(color: tokens.accent.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
