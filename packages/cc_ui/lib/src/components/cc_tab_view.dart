import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
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
/// The strip uses WAI-ARIA-style roving-tabindex (Tab lands on the selected
/// tab; `←`/`→`/`↑`/`↓`/`Home`/`End` move between tabs). Set [scrollable] when
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
  void didUpdateWidget(covariant CcTabView oldWidget) {
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
    final strip = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: FocusScope(
          node: _scopeNode,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: _onKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  _Tab(
                    label: widget.tabs[i].label,
                    semanticLabel: widget.tabs[i].semanticLabel,
                    selected: i == widget.selectedIndex,
                    // Roving tabindex: only the selected tab is a Tab stop.
                    focusable: i == widget.selectedIndex,
                    focusNode: i < _tabNodes.length ? _tabNodes[i] : null,
                    tokens: t,
                    onPressed: () => _select(i),
                  ),
              ],
            ),
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
    required this.focusable,
    required this.focusNode,
    required this.tokens,
    required this.onPressed,
  });

  final Widget label;
  final String? semanticLabel;
  final bool selected;
  final bool focusable;
  final FocusNode? focusNode;
  final DesignSystemTokens tokens;
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
        semanticLabel: semanticLabel,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          final Color background = pressed
              ? t.hoverStrong
              : (hovered && !selected ? t.hover : t.hover.withValues(alpha: 0));
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
      ),
    );
  }
}
