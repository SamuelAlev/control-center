import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A single entry in a [CcTabs] strip.
@immutable
class CcTab {
  /// Creates a [CcTab].
  const CcTab(this.label, {this.icon});

  /// The tab's visible text.
  final String label;

  /// Optional leading icon (e.g. a `lucide_icons_flutter` glyph).
  final IconData? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcTab && other.label == label && other.icon == icon;

  @override
  int get hashCode => Object.hash(label, icon);
}

/// A horizontal tab strip.
///
/// Renders the navigation bar only — the caller renders the body for
/// [selectedIndex]. Each tab is a [CcTappable], so it carries hover, press, and
/// keyboard-only focus-ring treatment for free. The selected tab reads as
/// [DesignSystemTokens.fg] text under a 2px [DesignSystemTokens.accent]
/// underline; unselected tabs are [DesignSystemTokens.textTertiary] with a
/// [DesignSystemTokens.hover] wash on hover. Status is carried by both the
/// underline bar and the color, never color alone.
class CcTabs extends StatelessWidget {
  /// Creates a [CcTabs] strip.
  const CcTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// The tabs, in display order.
  final List<CcTab> tabs;

  /// The index of the currently-active tab.
  final int selectedIndex;

  /// Called with a tab's index when it is tapped.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _CcTab(
              tab: tabs[i],
              selected: i == selectedIndex,
              tokens: t,
              onPressed: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _CcTab extends StatelessWidget {
  const _CcTab({
    required this.tab,
    required this.selected,
    required this.tokens,
    required this.onPressed,
  });

  final CcTab tab;
  final bool selected;
  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final duration = CcMotion.resolve(context, CcMotion.fast);
    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: tab.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final Color background;
        if (pressed) {
          background = t.hoverStrong;
        } else if (hovered && !selected) {
          background = t.hover;
        } else {
          background = t.hover.withValues(alpha: 0);
        }
        final foreground =
            selected ? t.fg : (hovered ? t.fgSecondary : t.textTertiary);
        return AnimatedContainer(
          duration: duration,
          curve: CcMotion.standard,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.brSm,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon, size: 15, color: foreground),
                      AppSpacing.hGapSm,
                    ],
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: CcMotion.standard,
                  opacity: selected ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: t.accent),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
