import 'package:cc_ui/src/components/cc_roving_focus.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
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

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcTab && other.label == label && other.icon == icon;

  @override
  int get hashCode => Object.hash(label, icon);
}

/// A horizontal tab strip with WAI-ARIA-style roving-tabindex keyboard nav.
///
/// Renders the navigation bar only — the caller renders the body for
/// [selectedIndex]. The strip is one Tab stop: Tab lands on the *selected*
/// tab and the next Tab leaves the strip. `←`/`→` (mirrored under RTL) and
/// `Home`/`End` move between tabs, selecting each as it is focused (automatic
/// activation); `↑`/`↓` are left to directional focus. The selected tab reads
/// as [DesignSystemTokens.fg] text under a 2px [DesignSystemTokens.accent]
/// underline; unselected tabs are [DesignSystemTokens.textTertiary] with a
/// [DesignSystemTokens.hover] wash on hover. Status is carried by the underline
/// bar, color and the selected semantic — never color alone.
class CcTabs extends StatefulWidget {
  /// Creates a [CcTabs] strip.
  const CcTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.height,
  });

  /// The tabs, in display order.
  final List<CcTab> tabs;

  /// The index of the currently-active tab.
  final int selectedIndex;

  /// Called with a tab's index when it is selected (tap or keyboard).
  final ValueChanged<int> onChanged;

  /// Exact strip height, bottom rule included. Null sizes the strip to its
  /// content (the label plus [AppSpacing.sm] above and below), which lands on a
  /// fractional height.
  ///
  /// Set it when the strip sits beside another strip whose height is fixed —
  /// the IDE sidebar next to the editor tab bar — because a sub-pixel
  /// difference leaves a visible jog in the rule where the two meet. The tabs
  /// then stretch to fill the height, so the active tab's underline stays on
  /// the rule and the label stays vertically centered.
  final double? height;

  @override
  State<CcTabs> createState() => _CcTabsState();
}

class _CcTabsState extends State<CcTabs> {
  late final CcRovingFocusNodes _tabNodes = CcRovingFocusNodes(
    'CcTab',
    widget.tabs.length,
  );

  @override
  void didUpdateWidget(covariant CcTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabNodes.sync(widget.tabs.length);
  }

  @override
  void dispose() {
    _tabNodes.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final count = widget.tabs.length;
    final target = ccRovingTarget(
      event: event,
      current: _tabNodes.focusedIndex ?? widget.selectedIndex,
      count: count,
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    if (target == null) {
      return KeyEventResult.ignored;
    }
    _tabNodes[target].requestFocus();
    if (target != widget.selectedIndex) {
      widget.onChanged(target);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final count = widget.tabs.length;
    final selected = widget.selectedIndex;
    _tabNodes.setStop(selected >= 0 && selected < count ? selected : 0);
    return Semantics(
      container: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderPrimary)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CcFluidHover(
              axis: CcFluidHoverAxis.x,
              itemCount: count,
              itemBuilder: (context, i) => _CcTab(
                tab: widget.tabs[i],
                selected: i == selected,
                focusNode: _tabNodes[i],
                tokens: t,
                fillHeight: widget.height != null,
                onPressed: () => widget.onChanged(i),
              ),
              layoutBuilder: (context, items) => Row(
                mainAxisSize: MainAxisSize.min,
                // A fixed-height strip hands the tabs a tight height to fill,
                // so their underline lands on the strip's rule. Without one
                // the cross-axis constraint is unbounded and stretch is
                // illegal.
                crossAxisAlignment: widget.height == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CcTab extends StatelessWidget {
  const _CcTab({
    required this.tab,
    required this.selected,
    required this.focusNode,
    required this.tokens,
    required this.fillHeight,
    required this.onPressed,
  });

  final CcTab tab;
  final bool selected;
  final FocusNode focusNode;
  final DesignSystemTokens tokens;

  /// True on a fixed-height strip: the cell fills the height it was handed and
  /// centers its label instead of deriving its height from vertical padding.
  final bool fillHeight;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final duration = CcMotion.resolveFade(context, CcMotion.moderate);
    return CcTappable(
      onPressed: onPressed,
      focusNode: focusNode,
      borderRadius: AppRadii.brSm,
      // The visible label names the tab; passing it here too reads it twice.
      semanticSelected: selected,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        final Color background;
        if (pressed) {
          background = t.hoverStrong;
        } else if (hovered && !selected && !fluidActive) {
          background = t.hover;
        } else {
          background = t.hover.withValues(alpha: 0);
        }
        final foreground = selected
            ? t.fg
            : (hovered ? t.fgSecondary : t.textTertiary);
        final label = Row(
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
                fontWeight: CcTypography.regularWeight,
                color: foreground,
              ),
            ),
          ],
        );
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
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  // On a fixed-height strip the height comes from the strip,
                  // so the label centers in it rather than padding its way to
                  // a size of its own.
                  vertical: fillHeight ? 0 : AppSpacing.sm,
                ),
                // widthFactor: 1 shrink-wraps the width (the cell still hugs
                // its label); heightFactor stays null so it fills the strip.
                child: fillHeight
                    ? Center(widthFactor: 1, child: label)
                    : label,
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
