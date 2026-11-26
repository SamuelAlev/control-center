import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The account on show and the arrows to the others, as the flyout's pager:
/// the position says where you are, which the arrows alone never do.
class TrayAccountPager extends StatelessWidget {
  /// Creates a [TrayAccountPager].
  const TrayAccountPager({
    required this.index,
    required this.count,
    required this.onPage,
    super.key,
  });

  /// The account on show (from zero), of [count].
  final int index, count;

  /// Called with the index to show, wrapping at either end.
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PagerArrow(
          icon: AppIcons.chevronLeft,
          tooltip: l10n.subscriptionUsagePreviousAccount,
          onPressed: () => onPage((index + count - 1) % count),
        ),
        Text(
          '${index + 1}/$count',
          style: CcFonts.numeric(
            textStyle: CcTypography.numeric,
          ).copyWith(color: t.textTertiary, fontSize: 11),
        ),
        _PagerArrow(
          icon: AppIcons.chevronRight,
          tooltip: l10n.subscriptionUsageNextAccount,
          onPressed: () => onPage((index + 1) % count),
        ),
      ],
    );
  }
}

/// One of the pager's arrows: small enough for a 22px line, with its own
/// wash over the block's.
class _PagerArrow extends StatelessWidget {
  const _PagerArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      message: tooltip,
      child: CcTappable(
        onPressed: onPressed,
        borderRadius: AppRadii.brSm,
        semanticLabel: tooltip,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: hovered
                  ? t.hoverStrong
                  : t.hoverStrong.withValues(alpha: 0),
              borderRadius: AppRadii.brSm,
            ),
            child: SizedBox.square(
              dimension: 20,
              child: Icon(
                icon,
                size: 12,
                color: hovered ? t.textPrimary : t.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}
