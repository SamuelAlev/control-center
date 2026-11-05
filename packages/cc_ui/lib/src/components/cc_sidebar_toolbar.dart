import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/components/cc_sidebar_item.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:flutter/widgets.dart';

/// Edge of a [CcSidebarToolbar] item. A step below the rail's square, so seven
/// items fit the narrowest sidebar.
const double _kItemExtent = 30;

/// Puts the first icon on the line of the [CcSidebarItem] rows above, and
/// mirrors that inset at the strip's end.
const double _kInset = kCcSidebarItemIconCenter - _kItemExtent / 2;

/// One strip of icon-only [CcSidebarItem]s for an expanded [CcSidebar], such
/// as its footer: [leading] at the start, [trailing] at the end.
///
/// Items sit flush so a gap never drops the click cursor, and show their labels
/// in tooltips above the strip. While the sidebar's width animates the strip
/// holds its smallest size and clips, so the narrowing sidebar never overflows
/// it. The strip does not fit the collapsed rail; stack the same items in a
/// [CcSidebarGroup] there.
class CcSidebarToolbar extends StatelessWidget {
  /// Creates a [CcSidebarToolbar].
  const CcSidebarToolbar({
    super.key,
    required this.leading,
    this.trailing = const [],
  });

  /// The items at the strip's start, typically [CcSidebarItem]s.
  final List<Widget> leading;

  /// The items at the strip's end.
  final List<Widget> trailing;

  /// A group of its own per side, so the empty middle highlights nothing.
  Widget _group(List<Widget> items) => CcFluidHover(
    axis: CcFluidHoverAxis.x,
    mouseCursor: SystemMouseCursors.click,
    itemCount: items.length,
    isItemBoundary: (index) => items[index] is! CcFluidHoverTarget,
    isItemDisabled: (index) {
      final child = items[index];
      if (child case final CcFluidHoverTarget target) {
        return !target.fluidHoverEnabled;
      }
      return true;
    },
    itemBuilder: (context, index) =>
        SizedBox.square(dimension: _kItemExtent, child: items[index]),
    layoutBuilder: (context, registered) =>
        Row(mainAxisSize: MainAxisSize.min, children: registered),
  );

  @override
  Widget build(BuildContext context) {
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;
    final minWidth =
        (leading.length + trailing.length) * _kItemExtent + 2 * _kInset;
    return LayoutBuilder(
      builder: (context, constraints) => UnconstrainedBox(
        constrainedAxis: Axis.vertical,
        alignment: AlignmentDirectional.centerStart,
        clipBehavior: transitioning ? Clip.hardEdge : Clip.none,
        child: SizedBox(
          width: math.max(constraints.maxWidth, minWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kInset),
            child: CcSidebarScope(
              collapsed: true,
              transitioning: transitioning,
              tooltipPlacement: CcTooltipPlacement.top,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _group(leading),
                  if (trailing.isNotEmpty) _group(trailing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
