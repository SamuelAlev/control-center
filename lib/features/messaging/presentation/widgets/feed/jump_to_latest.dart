import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A solid accent pill that surfaces what is happening below the fold: a live
/// agent turn streaming below the fold (accent spinner) and a count of messages
/// that arrived while the reader was away (numeric badge). Tapping re-engages
/// following and snaps to the live edge.
class JumpToLatest extends StatelessWidget {
  /// Creates a [JumpToLatest].
  const JumpToLatest({
    required this.onTap,
    this.isStreaming = false,
    this.newCount = 0,
    super.key,
  });

  /// Snaps the viewport to the live edge and re-engages following.
  final VoidCallback onTap;

  /// Whether a live agent turn is currently streaming below the fold.
  final bool isStreaming;

  /// New messages arrived while the reader was away (below the fold).
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: IgnorePointer(
          ignoring: false,
          child: CcTappable(
            onPressed: onTap,
            semanticLabel: l10n.jumpToLatest,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            builder: (context, _) => Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.chevronsDown, size: 16, color: t.accentOn),
                  const SizedBox(width: 8),
                  Text(
                    isStreaming ? l10n.streaming : l10n.jumpToLatest,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.accentOn,
                    ),
                  ),
                  if (newCount > 0) ...[
                    const SizedBox(width: 8),
                    _CountPill(count: newCount, accent: t.accent),
                  ] else if (isStreaming) ...[
                    const SizedBox(width: 8),
                    CcSpinner(size: 12, strokeWidth: 1.6, color: t.accentOn),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.accentOn,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}
