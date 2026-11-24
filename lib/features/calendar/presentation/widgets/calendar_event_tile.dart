import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart'
    show calendarKey;
import 'package:control_center/features/calendar/presentation/widgets/calendar_tile_body.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_tile_parts.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:kalender/kalender.dart' as k;

/// One event on the month / week / day grid, its treatment driven by its
/// state: a soft fill in the calendar's color when confirmed, a dashed outline
/// for an unanswered invitation, an outline when tentative, a neutral
/// strikethrough when cancelled. Past events are dimmed.
class CalendarEventTile extends StatelessWidget {
  /// Creates a [CalendarEventTile].
  const CalendarEventTile({
    super.key,
    required this.event,
    required this.now,
    required this.calendarColors,
    required this.dense,
    this.tileRange,
    this.lifted = false,
  });

  /// The event, or null for a bare span.
  final CalendarEvent? event;

  /// The reference "now": tiles that ended before it are dimmed.
  final DateTime now;

  /// Per-calendar accent colors, keyed by [calendarKey].
  final Map<String, Color> calendarColors;

  /// One line (month cells, the all-day strip) instead of title and times.
  final bool dense;

  /// The part of the event this bar covers on the page, for dense bars.
  final k.KalenderDateTimeRange? tileRange;

  /// Whether the tile is being dragged or drawn, so it floats over the grid.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final domain = event;
    final isPast = domain != null && domain.endTime.toLocal().isBefore(now);
    // Past tiles used to be wrapped in Opacity(0.5). That saveLayers every
    // event on every frame the calendar paints. The same 50% folded into the
    // tile's own colors keeps the dim and lets the grid scroll without an
    // offscreen buffer per event.
    Color dim(Color color) => isPast
        ? color.withValues(alpha: (color.a * 0.5).clamp(0.0, 1.0))
        : color;
    final status = domain?.status ?? CalendarEventStatus.confirmed;
    final cancelled = status == CalendarEventStatus.cancelled;
    // An invitation the user has not responded to yet ("needsAction"). Drawn as
    // a dashed outline with no fill so it reads as "pending — not yet on your
    // calendar", distinct from a confirmed (solid) or organiser-tentative block.
    final unanswered = !cancelled && (domain?.isUnansweredInvitation ?? false);
    final tentative =
        !cancelled && !unanswered && status == CalendarEventStatus.tentative;
    final calColor =
        (domain == null
            ? null
            : calendarColors[calendarKey(
                domain.accountId,
                domain.calendarId,
              )]) ??
        t.accent;

    // Status drives the tile's treatment so the calendar reports real state
    // rather than painting every block the same: a soft fill in the calendar's
    // color for confirmed, a dashed outline for an unanswered invitation, an
    // outline for tentative, a neutral strikethrough for cancelled.
    Color fill;
    // The fill shown while the pointer is over the tile — a touch stronger than
    // [fill] so hovering gives a clear, consistent "this is interactive" cue.
    Color hoverFill;
    Color accentBar;
    Color titleColor;
    BoxBorder? border;
    var dashed = false;
    if (cancelled) {
      fill = t.bgSecondary;
      hoverFill = t.bgSecondaryHover;
      accentBar = t.borderSecondary;
      titleColor = t.textTertiary;
    } else if (unanswered) {
      fill = const Color(0x00000000);
      // On hover a faint wash of the calendar color appears behind the dashed
      // outline, so a pending invitation still reacts to the pointer.
      hoverFill = calColor.withValues(alpha: 0.10);
      // The dashed outline (painted below) carries the calendar color, so the
      // solid accent bar is suppressed.
      accentBar = const Color(0x00000000);
      titleColor = t.textSecondary;
      dashed = true;
    } else if (tentative) {
      fill = const Color(0x00000000);
      hoverFill = calColor.withValues(alpha: 0.10);
      accentBar = calColor;
      titleColor = t.textSecondary;
      border = Border.all(color: calColor.withValues(alpha: 0.6), width: 1);
    } else {
      // A soft tint of the calendar color, kept fully opaque (alpha-blended over
      // the body background rather than laid on as a translucent wash) so the
      // tint reads consistently over the hour lines and now-indicator behind it.
      // Hover deepens the tint.
      fill = Color.alphaBlend(calColor.withValues(alpha: 0.16), t.bgPrimary);
      hoverFill = Color.alphaBlend(
        calColor.withValues(alpha: 0.30),
        t.bgPrimary,
      );
      accentBar = calColor;
      titleColor = t.textPrimary;
    }
    fill = dim(fill);
    hoverFill = dim(hoverFill);
    accentBar = dim(accentBar);
    titleColor = dim(titleColor);
    if (isPast && border != null) {
      border = Border.all(
        color: dim(calColor.withValues(alpha: 0.6)),
        width: 1,
      );
    }

    final title = Text(
      domain?.title ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: titleColor,
        decoration: cancelled ? TextDecoration.lineThrough : null,
      ),
    );

    // Dense (month / all-day header) tiles only have room for a compact start
    // time; the timed body tiles show the full start–end range (24h), matching
    // the timeline they sit on.
    final localStart = (domain == null || domain.isAllDay)
        ? null
        : domain.startTime.toLocal();
    // A dense tile is one bar across every day of the event that falls in view,
    // clipped at the edges of the page. When the event began before this page,
    // that bar starts on a day the event did not — so its start time would read
    // as "midnight on Monday" for something that started the previous Thursday.
    // The bar carries no time at all in that case; the page it starts on shows
    // it. (Nothing to suppress for the timed body: an event there is on its own
    // day by definition.)
    final range = tileRange;
    final continues =
        dense &&
        localStart != null &&
        range != null &&
        localStart.isBefore(range.start);
    final startLabel = (localStart == null || continues)
        ? null
        : DateFormat.Hm().format(localStart);
    final rangeLabel = localStart == null
        ? null
        : '$startLabel–${DateFormat.Hm().format(domain!.endTime.toLocal())}';

    final Widget content = dense
        // Short events give the tile less height than its content needs;
        // OverflowBox lets the content lay out at its natural size (no
        // RenderFlex overflow) while the parent Container clips the excess.
        ? ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                child: Row(
                  children: [
                    if (startLabel != null) ...[
                      Text(
                        startLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: dim(t.textTertiary),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(child: title),
                  ],
                ),
              ),
            ),
          )
        : CalendarTimedTileBody(
            title: domain?.title ?? '',
            timeLabel: rangeLabel,
            titleColor: titleColor,
            timeColor: dim(cancelled ? t.textTertiary : t.textSecondary),
            strikethrough: cancelled,
          );

    Widget box = CalendarHoverFillBox(
      fill: fill,
      hoverFill: hoverFill,
      border: border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2.5, color: accentBar),
          Expanded(child: content),
        ],
      ),
    );

    if (dashed) {
      // BoxDecoration has no dashed border, so paint one over the (transparent)
      // box. Drawn as a foreground painter so it sits above the clipped content.
      box = CustomPaint(
        foregroundPainter: CalendarDashedRRectPainter(
          color: dim(calColor),
          radius: AppRadii.sm,
        ),
        child: box,
      );
    }

    // Outer inset (was the Container's margin) so the dashed painter aligns with
    // the box's rounded rect. The horizontal half-gap also opens a visible seam
    // between adjacent side-by-side columns so overlapping events read as
    // distinct tiles rather than one block.
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 0.5),
      child: box,
    );

    if (!lifted) {
      return tile;
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadii.brSm,
        boxShadow: CcElevation.raised,
      ),
      child: tile,
    );
  }
}
