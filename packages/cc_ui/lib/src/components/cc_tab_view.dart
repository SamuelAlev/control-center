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

/// One entry in a [CcTabView]: a strip [label] (any widget) and its [content].
@immutable
class CcTabViewEntry {
  /// Creates a [CcTabViewEntry].
  const CcTabViewEntry({
    required this.label,
    required this.content,
    this.semanticLabel,
  });

  /// The tab's strip label. Text/icons inside inherit the selected/unselected
  /// color via an ambient `DefaultTextStyle`/`IconTheme`.
  final Widget label;

  /// The panel shown below the strip when this tab is selected.
  final Widget content;

  /// Accessibility name for the tab — required when [label] is icon-only so the
  /// tab is not nameless to assistive tech.
  final String? semanticLabel;
}

/// A tabbed container with content panels. Pairs the [CcTabs]-style underline
/// strip with the selected panel.
///
/// Controlled: the caller owns [selectedIndex] and updates it from [onChanged].
/// The strip uses WAI-ARIA-style roving-tabindex: it is one Tab stop (the
/// selected tab), `←`/`→` (mirrored under RTL) and `Home`/`End` move between
/// tabs and select them, and `↑`/`↓` are left to directional focus. Set [scrollable] when
/// the strip can overflow horizontally and [expand] to make the selected panel
/// fill the remaining height (the view must then sit in a bounded-height
/// parent).
class CcTabView extends StatefulWidget {
  /// Creates a [CcTabView].
  const CcTabView({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.scrollable = false,
    this.expand = false,
  });

  /// The tabs, in display order.
  final List<CcTabViewEntry> tabs;

  /// Index of the active tab.
  final int selectedIndex;

  /// Called with a tab's index when selected (tap or keyboard).
  final ValueChanged<int> onChanged;

  /// Whether the strip scrolls horizontally when it overflows.
  final bool scrollable;

  /// Whether the selected panel fills remaining height (wrapped in `Expanded`).
  final bool expand;

  @override
  State<CcTabView> createState() => _CcTabViewState();
}

class _CcTabViewState extends State<CcTabView> {
  late final CcRovingFocusNodes _tabNodes = CcRovingFocusNodes(
    'CcTabView tab',
    widget.tabs.length,
  );

  @override
  void didUpdateWidget(covariant CcTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabNodes.sync(widget.tabs.length);
  }

  @override
  void dispose() {
    _tabNodes.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final target = ccRovingTarget(
      event: event,
      current: _tabNodes.focusedIndex ?? widget.selectedIndex,
      count: widget.tabs.length,
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
    final strip = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: CcFluidHover(
            axis: CcFluidHoverAxis.x,
            itemCount: count,
            itemBuilder: (context, i) => _Tab(
              label: widget.tabs[i].label,
              semanticLabel: widget.tabs[i].semanticLabel,
              selected: i == selected,
              focusNode: _tabNodes[i],
              tokens: t,
              onPressed: () => widget.onChanged(i),
            ),
            layoutBuilder: (context, items) =>
                Row(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
      ),
    );

    final hasContent =
        widget.selectedIndex >= 0 && widget.selectedIndex < widget.tabs.length;
    final content = hasContent
        ? widget.tabs[widget.selectedIndex].content
        : null;

    return Column(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [widget.scrollable] is now always honored (the strip scrolls) so a
        // long tab list never overflows the viewport.
        strip,
        if (content != null)
          widget.expand
              ? Expanded(child: Semantics(container: true, child: content))
              : Semantics(container: true, child: content),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.focusNode,
    required this.tokens,
    required this.onPressed,
  });

  final Widget label;
  final String? semanticLabel;
  final bool selected;
  final FocusNode focusNode;
  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final duration = CcMotion.resolveFade(context, CcMotion.moderate);
    return CcTappable(
      onPressed: onPressed,
      focusNode: focusNode,
      borderRadius: AppRadii.brSm,
      semanticLabel: semanticLabel,
      semanticSelected: selected,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        final Color background = pressed
            ? t.hoverStrong
            : (hovered && !selected && !fluidActive
                  ? t.hover
                  : t.hover.withValues(alpha: 0));
        final foreground = selected
            ? t.fg
            : (hovered ? t.fgSecondary : t.textTertiary);
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
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: CcTypography.regularWeight,
                    color: foreground,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 15),
                    child: label,
                  ),
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
