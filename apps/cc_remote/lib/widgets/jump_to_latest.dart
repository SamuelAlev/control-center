import 'package:cc_remote/app_icons.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Touch-ergonomic "jump to latest" pill for the mobile feed. Surfaces a live
/// agent turn streaming below the fold (accent spinner) and a count of
/// messages that arrived while the reader was away. Tapping re-engages
/// following and snaps to the live edge.
class JumpToLatest extends StatelessWidget {
  /// Creates a [JumpToLatest].
  const JumpToLatest({
    required this.onTap,
    this.isStreaming = false,
    this.newCount = 0,
    super.key,
  });

  /// Tap handler: snaps to the live edge and re-engages following.
  final VoidCallback onTap;

  /// Whether a live agent turn is streaming below the fold.
  final bool isStreaming;

  /// New messages arrived while away (below the fold).
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return IgnorePointer(
      ignoring: false,
      child: CcTappable(
        onPressed: onTap,
        semanticLabel: 'Jump to latest',
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        builder: (context, _) => Container(
          // ≥44px hit box (touch-ergonomic), pill shape, token-driven colors.
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
                isStreaming ? 'Streaming' : 'Jump to latest',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.accentOn,
                ),
              ),
              if (newCount > 0) ...[
                const SizedBox(width: 8),
                _CountPill(count: newCount),
              ] else if (isStreaming) ...[
                const SizedBox(width: 8),
                CcSpinner(size: 12, strokeWidth: 1.6, color: t.accentOn),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

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
          color: t.accent,
        ),
      ),
    );
  }
}
