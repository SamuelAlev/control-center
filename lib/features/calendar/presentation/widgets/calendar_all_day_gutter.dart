import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The timeline-gutter cell that sits beside the week view's all-day strip,
/// where the hour labels would be if the strip were part of the timed grid.
///
/// It answers the question the strip otherwise leaves open — "what is this band
/// above the grid?" — and, once the band has anything in it, doubles as the
/// control that folds it away. An empty band is labelled rather than blank; a
/// populated one is a toggle, because at that point the label is redundant and
/// the affordance is not.
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
    required this.collapsible,
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

  /// Height of one strip row. The label / toggle occupies the first row and the
  /// rest of [laneHeight] stays empty, so the cell tracks the strip's top edge
  /// however tall the strip grows.
  final double rowHeight;

  /// Whether the strip has anything to fold away. False renders the label.
  final bool collapsible;

  /// Whether the strip is currently folded to its one-row summary.
  final bool collapsed;

  /// Toggles [collapsed]. Only reachable when [collapsible].
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
            child: Center(
              child: collapsible ? _toggle(context) : _label(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    // The gutter is only as wide as an hour label, so it gets the short form of
    // the term and the tooltip (and the Semantics label) carries the full one.
    // Nothing is lost; the gutter just stays the width the grid needs it to be.
    return CcTooltip(
      message: l10n.calendarAllDay,
      child: Semantics(
        label: l10n.calendarAllDay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            l10n.calendarAllDayGutter,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: t.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = CcButtonTokens.ghost(t);
    final l10n = AppLocalizations.of(context);
    final label = collapsed ? l10n.calendarExpandAllDay : l10n.calendarCollapseAllDay;
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
          return Container(
            width: 22,
            height: 18,
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
