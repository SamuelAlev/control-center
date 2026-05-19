import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A VS Code-style editor tab strip with bordered tabs.
///
/// Renders one bordered cell per tab: a vertical separator on the right of every
/// tab, a continuous bottom rule under the strip, and a 2px accent rule on top of
/// the active tab — whose background blends into the editor body below so the tab
/// visually "opens" onto its content. Replaces the borderless `panes`
/// `TabbedPane` header so the messaging IDE reads like an IDE.
///
/// Tab bodies are owned by the caller; this widget renders chrome + selection
/// only. Trailing [actions] (close / split / new-tab menu) are right-aligned.
class EditorTabBar extends StatefulWidget {
  /// Creates an [EditorTabBar].
  const EditorTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
    this.icons,
    this.actions = const [],
  }) : assert(icons == null || icons.length == labels.length);

  /// Tab labels, already localized.
  final List<String> labels;

  /// Optional per-tab leading icon. Must match [labels] length when provided.
  final List<IconData>? icons;

  /// Index of the selected tab.
  final int selectedIndex;

  /// Called with the tapped tab index.
  final ValueChanged<int> onTabSelected;

  /// Trailing header actions, right-aligned (close / split / new-tab menu).
  final List<Widget> actions;

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  /// Index of the tab under the pointer, or null. Drives the hover wash.
  int? _hovered;

  /// Strip height — matches VS Code's editor tab bar.
  static const double _height = 35;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: _height,
      child: ColoredBox(
        color: t.bgSecondary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.labels.length; i++) _buildTab(t, i),
            // The trailing area carries the bottom rule across the remaining
            // width so the strip reads as one continuous edge.
            Expanded(child: _buildTrailing(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(DesignSystemTokens t, int index) {
    final selected = index == widget.selectedIndex;
    final hovered = index == _hovered;
    final labelColor = selected ? t.fg : t.textTertiary;
    final background = selected
        ? t.bgPrimary
        : (hovered ? t.hover : const Color(0x00000000));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = index),
      onExit: (_) =>
          setState(() => _hovered = _hovered == index ? null : _hovered),
      child: GestureDetector(
        onTap: () => widget.onTabSelected(index),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: BorderSide(color: t.borderPrimary),
              // The active tab connects to the editor body below it: paint its
              // bottom rule in the body color so the strip line "opens" under it,
              // while inactive tabs keep the visible divider.
              bottom: BorderSide(
                color: selected ? t.bgPrimary : t.borderPrimary,
              ),
            ),
          ),
          // The accent rule is an overlay (not a top border) so selecting a tab
          // never insets — and thus never nudges — the label.
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icons case final icons?) ...[
                        Icon(icons[index], size: 14, color: labelColor),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        widget.labels[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w500 : FontWeight.w400,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 2,
                      child: ColoredBox(color: t.accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.actions,
        ),
      ),
    );
  }
}
