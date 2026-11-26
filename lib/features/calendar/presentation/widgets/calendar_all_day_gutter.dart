import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The timeline-gutter cell that sits beside the week view's all-day strip,
/// where the hour labels would be if the strip were part of the timed grid.
///
/// It holds the control that folds the strip away. Only built for a week that
/// has all-day events: an empty week has no strip, so no cell beside it.
///
/// Rendered by `CalendarKalenderHost` through kalender's `weekNumberBuilder`
/// (the week header's leading slot). kalender lays the leading out beside the
/// *whole* header — day labels included — so [topInset] pushes the cell down
/// past the day-labels block onto the strip's own rows.
class CalendarAllDayGutter extends StatelessWidget {
  /// Creates a [CalendarAllDayGutter].
  const CalendarAllDayGutter({
    super.key,
    required this.topInset,
    required this.laneHeight,
    required this.rowHeight,
    required this.collapsed,
    required this.onToggle,
  });

  /// Height of the day-labels block above the strip. The cell is offset by this
  /// so it lines up with the strip's first row rather than the header's top.
  final double topInset;

  /// The strip's height. The cell claims all of it so kalender measures the
  /// leading at exactly the header height and never stretches the header to
  /// fit a taller leading.
  final double laneHeight;

  /// Height of one strip row. The toggle occupies the first row and the rest of
  /// [laneHeight] stays empty, so the cell tracks the strip's top edge however
  /// tall the strip grows.
  final double rowHeight;

  /// Whether the strip is currently folded to its one-row summary.
  final bool collapsed;

  /// Toggles [collapsed].
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Positioned inside a box rather than stacked in a Column, because kalender
    // lays the leading out twice per frame — once unbounded to measure it, then
    // again against whichever of the leading and the content turned out taller.
    // While the header is animating between two strip heights those two passes
    // disagree, and a Column reports the shortfall as an overflow; a box simply
    // takes the height it is given and the cell rides along at [topInset].
    return SizedBox(
      height: topInset + laneHeight,
      child: Stack(
        children: [
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            height: rowHeight,
            child: Center(child: _toggle(context)),
          ),
        ],
      ),
    );
  }

  Widget _toggle(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = CcButtonTokens.ghost(t);
    final l10n = AppLocalizations.of(context);
    final label = collapsed
        ? l10n.calendarExpandAllDay
        : l10n.calendarCollapseAllDay;
    return CcTooltip(
      message: label,
      child: CcTappable(
        onPressed: onToggle,
        borderRadius: AppRadii.brSm,
        focusRingColor: t.focusRing,
        semanticLabel: label,
        builder: (context, states) {
          final pressed = states.contains(WidgetState.pressed);
          final hovered = states.contains(WidgetState.hovered);
          final bg = pressed
              ? tokens.bgPressed
              : hovered
              ? tokens.bgHover
              : tokens.bg;
          // The margin lies inside the tappable, so the 22×18 box takes
          // presses in a 24×24 target; the 24px row centres it unmoved.
          return Container(
            width: 22,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
            child: Icon(
              // Chevrons pointing at each other read as "fold this away";
              // pointing apart, as "unfold it".
              collapsed ? AppIcons.chevronsUpDown : AppIcons.chevronsDownUp,
              size: 12,
              color: hovered ? t.textSecondary : t.textTertiary,
            ),
          );
        },
      ),
    );
  }
}
