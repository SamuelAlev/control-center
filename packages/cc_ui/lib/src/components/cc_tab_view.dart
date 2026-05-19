import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// One entry in a [CcTabView]: a strip [label] (any widget) and its [content].
@immutable
class CcTabViewEntry {
  /// Creates a [CcTabViewEntry].
  const CcTabViewEntry({required this.label, required this.content});

  /// The tab's strip label. Text/icons inside inherit the selected/unselected
  /// color via an ambient `DefaultTextStyle`/`IconTheme`.
  final Widget label;

  /// The panel shown below the strip when this tab is selected.
  final Widget content;
}

/// A tabbed container with content panels. Pairs the [CcTabs]-style underline
/// strip with the selected panel.
///
/// Controlled: the caller owns [selectedIndex] and updates it from [onChanged].
/// Set [scrollable] when the strip can
/// overflow horizontally, and [expand] to make the selected panel fill the
/// remaining height (the view must then sit in a bounded-height parent).
class CcTabView extends StatelessWidget {
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

  /// Called with a tab's index when tapped.
  final ValueChanged<int> onChanged;

  /// Whether the strip scrolls horizontally when it overflows.
  final bool scrollable;

  /// Whether the selected panel fills remaining height (wrapped in `Expanded`).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final strip = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _Tab(
              label: tabs[i].label,
              selected: i == selectedIndex,
              tokens: t,
              onPressed: () => onChanged(i),
            ),
        ],
      ),
    );

    final hasContent = selectedIndex >= 0 && selectedIndex < tabs.length;
    final content = hasContent ? tabs[selectedIndex].content : null;

    return Column(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scrollable
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: strip,
              )
            : strip,
        if (content != null)
          expand ? Expanded(child: content) : content,
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onPressed,
  });

  final Widget label;
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
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final Color background = pressed
            ? t.hoverStrong
            : (hovered && !selected ? t.hover : t.hover.withValues(alpha: 0));
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
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
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
                  child: DecoratedBox(decoration: BoxDecoration(color: t.accent)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
