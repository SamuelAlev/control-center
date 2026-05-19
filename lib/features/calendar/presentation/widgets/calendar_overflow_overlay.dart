import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:kalender/kalender.dart' as k;

/// Design-system replacements for kalender's Material month-overflow pieces:
/// the "+N more" affordance in a full day cell and the day-events flyout it
/// opens. kalender's defaults render a Material `Card` + `IconButton.filledTonal`
/// (tinted by the Material theme, off-brand here); these rebuild both from
/// cc_ui tokens. Wired in via [k.OverlayBuilders] by `CalendarKalenderHost`.

/// The overflow affordance: a compact ghost button (transparent, hover wash
/// only) that hugs its "N more" label and opens the day's flyout.
class CalendarOverflowButton extends StatelessWidget {
  /// Creates a [CalendarOverflowButton].
  const CalendarOverflowButton({
    super.key,
    required this.portalController,
    required this.hiddenCount,
  });

  /// Shows the flyout on press.
  final OverlayPortalController portalController;

  /// How many events did not fit in the day cell.
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = CcButtonTokens.ghost(t);
    final label = AppLocalizations.of(context).calendarMoreEvents(hiddenCount);
    // The slot kalender gives this button is one tile-row high (~24px), too
    // short for a CcButton, so the ghost treatment is applied to a CcTappable
    // directly at the tile scale.
    return Align(
      alignment: Alignment.centerLeft,
      child: CcTappable(
        onPressed: portalController.show,
        borderRadius: AppRadii.brSm,
        focusRingColor: t.focusRing,
        semanticLabel: label,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          final bg = pressed
              ? tokens.bgPressed
              : hovered
              ? tokens.bgHover
              : tokens.bg;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tokens.fg,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The day-events flyout: a floating design-system panel over the day cell
/// listing every event of that day, with the weekday + date and a ghost close
/// button in its header. Event rows come from kalender's [overlayTileBuilder],
/// so they are the exact same tiles the calendar body renders (taps included).
class CalendarOverflowFlyout extends StatelessWidget {
  /// Creates a [CalendarOverflowFlyout].
  const CalendarOverflowFlyout({
    super.key,
    required this.date,
    required this.events,
    required this.tileHeight,
    required this.portalController,
    required this.getMultiDayEventLayoutRenderBox,
    required this.getOverlayPortalRenderBox,
    required this.overlayTileBuilder,
  });

  /// The day the flyout lists.
  final DateTime date;

  /// Every event of [date] (shown and hidden alike).
  final List<k.CalendarEvent> events;

  /// Row height for each event tile (matches the body's tile height).
  final double tileHeight;

  /// Hides the flyout.
  final OverlayPortalController portalController;

  /// The day cell's events-layout render box (drives vertical placement).
  final k.RenderBoxCallback getMultiDayEventLayoutRenderBox;

  /// The portal button's render box (drives horizontal placement).
  final k.RenderBoxCallback getOverlayPortalRenderBox;

  /// Builds one interactive event row.
  final k.MultiDayOverlayEventTileBuilder overlayTileBuilder;

  /// Panel width (kalender's default overlay width, kept for continuity).
  static const double _width = 300;

  /// Screen-edge inset the panel keeps clear.
  static const double _inset = 8;

  /// Same placement approach as kalender's default overlay: horizontally
  /// centred on the day cell, raised above it by the height of the cell's
  /// event stack, clamped to the screen with [_inset].
  (double top, double left, double width) _calculatePosition(
    BoxConstraints constraints,
  ) {
    final portalRenderBox = getOverlayPortalRenderBox();
    final layoutSize = getMultiDayEventLayoutRenderBox().size;
    final portalWidth = portalRenderBox.size.width;
    final portalPosition = portalRenderBox.localToGlobal(Offset.zero);

    var top = portalPosition.dy - layoutSize.height;
    if (top < _inset) {
      top = _inset;
    }

    final maxWidth = constraints.maxWidth < _width + 2 * _inset
        ? constraints.maxWidth - 2 * _inset
        : _width;
    var left = portalPosition.dx - (maxWidth / 2) + portalWidth / 2;
    var width = maxWidth;
    if (left < _inset) {
      left = _inset;
    }
    if (left + width > constraints.maxWidth - _inset) {
      if (left > constraints.maxWidth - _inset - maxWidth) {
        left = constraints.maxWidth - _inset - maxWidth;
      } else {
        width = constraints.maxWidth - _inset - left;
      }
    }
    return (top, left, width);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final range = k.InternalDateTime(date.year, date.month, date.day).dayRange;

    return LayoutBuilder(
      builder: (context, constraints) {
        final (top, left, width) = _calculatePosition(constraints);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Dismiss barrier.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: portalController.hide,
                onSecondaryTap: portalController.hide,
              ),
            ),
            Positioned(
              top: top,
              left: left,
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: card.bg,
                  borderRadius: AppRadii.brLg,
                  border: Border.all(color: card.border),
                  boxShadow: CcElevation.floating,
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.brLg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat.MMMMEEEEd(locale).format(date),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                            CcIconButton(
                              icon: AppIcons.x,
                              size: CcButtonSize.sm,
                              onPressed: portalController.hide,
                              tooltip: l10n.close,
                              semanticLabel: l10n.close,
                            ),
                          ],
                        ),
                      ),
                      const CcDivider(),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final event in events)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1.5,
                                ),
                                child: SizedBox(
                                  height: tileHeight,
                                  child: overlayTileBuilder(
                                    event,
                                    range,
                                    portalController.hide,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
