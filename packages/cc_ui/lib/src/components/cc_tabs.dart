import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
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
/// [selectedIndex]. The strip owns a focus scope: Tab enters the strip and
/// lands on the *selected* tab (the only tab stop — roving tabindex), then
/// `←`/`→` (and `↑`/`↓`, `Home`/`End`) move between tabs, selecting each as it
/// is focused (automatic activation). The selected tab reads as
/// [DesignSystemTokens.fg] text under a 2px [DesignSystemTokens.accent]
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
  final FocusScopeNode _scopeNode = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  List<FocusNode> _tabNodes = const [];

  @override
  void initState() {
    super.initState();
    _tabNodes = [for (var i = 0; i < widget.tabs.length; i++) FocusNode()];
  }

  @override
  void didUpdateWidget(covariant CcTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      for (final n in _tabNodes) {
        n.dispose();
      }
      _tabNodes = [for (var i = 0; i < widget.tabs.length; i++) FocusNode()];
    }
  }

  @override
  void dispose() {
    for (final n in _tabNodes) {
      n.dispose();
    }
    _scopeNode.dispose();
    super.dispose();
  }

  void _select(int index) {
    widget.onChanged(index);
    // Move focus to the newly-selected tab after the rebuild (roving tabindex).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _tabNodes.length) {
        _tabNodes[index].requestFocus();
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final count = widget.tabs.length;
    if (count == 0) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _select((widget.selectedIndex + 1) % count);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _select((widget.selectedIndex - 1) % count);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.home) {
      _select(0);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.end) {
      _select(count - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Semantics(
      container: true,
      child: FocusScope(
        node: _scopeNode,
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: _onKey,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderPrimary)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // A fixed-height strip hands the tabs a tight height to fill,
                // so their underline lands on the strip's rule. Without one the
                // cross-axis constraint is unbounded and stretch is illegal.
                crossAxisAlignment: widget.height == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.tabs.length; i++)
                    _CcTab(
                      tab: widget.tabs[i],
                      selected: i == widget.selectedIndex,
                      // Roving tabindex: only the selected tab is a Tab stop.
                      focusable: i == widget.selectedIndex,
                      focusNode: i < _tabNodes.length ? _tabNodes[i] : null,
                      tokens: t,
                      fillHeight: widget.height != null,
                      onPressed: () => _select(i),
                    ),
                ],
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
    required this.focusable,
    required this.focusNode,
    required this.tokens,
    required this.fillHeight,
    required this.onPressed,
  });

  final CcTab tab;
  final bool selected;
  final bool focusable;
  final FocusNode? focusNode;
  final DesignSystemTokens tokens;

  /// True on a fixed-height strip: the cell fills the height it was handed and
  /// centers its label instead of deriving its height from vertical padding.
  final bool fillHeight;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final duration = CcMotion.resolve(context, CcMotion.fast);
    return Semantics(
      selected: selected,
      child: CcTappable(
        onPressed: onPressed,
        focusNode: focusNode,
        canRequestFocus: focusable,
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
      ),
    );
  }
}
