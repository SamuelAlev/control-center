import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart'
    show calendarKey;
import 'package:control_center/features/calendar/presentation/utils/calendar_event_layout.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_overflow_overlay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender/kalender.dart' as k;

/// Pixels per minute in the timed (week / day) body. Sets the minimum height
/// of an hour interval: 60 × this. kalender's default is 0.7 (≈42px/hour),
/// which is too cramped to read; 1.2 gives each hour a comfortable 72px.
const double _heightPerMinute = 1.2;

/// Legibility floor for a timed tile: the height a short event may *grow into*
/// so its title stays readable, used by [calendarEventLayoutStrategy]. A
/// 1-minute event would otherwise collapse to ~1px. Kept at 18px (= 15 min at
/// [_heightPerMinute]) so a real 15-minute event renders at its exact height and
/// never appears to overrun its end time; only shorter events are grown, and
/// only into empty space — never past the start of the following event. 18px
/// fits one title line.
const double _minimumTileHeight = 18;

/// Rows of all-day events the week/day header shows before collapsing the rest
/// behind a "+N more" button (which opens the day flyout). kalender's default
/// is an uncapped, content-measured strip: every late-arriving event re-measured
/// the header and shoved the timed body down — a layout shift on every load.
/// Two rows (not three) keeps the fixed lane compact on ordinary days; the
/// flyout covers genuinely busy ones.
const int _allDayLaneRows = 2;

/// Height of one all-day tile row (kalender's `defaultTileHeight`). Repeated
/// here so the fixed lane height below stays in lockstep with the cap.
const double _allDayTileHeight = 24;

/// Layout budget for the day-labels block (badge + weekday name) above the
/// all-day strip in week view. The block keeps its natural, font-metric height
/// (~54px); this budget is what [_weekHeaderHeight] reserves for it. If a
/// fallback font ever outgrows it, kalender's top-aligned page OverflowBox
/// clips the slack instead of overflowing — never a hard layout error.
const double _dayLabelsHeight = 56;

/// Fixed week-view header height: day labels + [_allDayLaneRows] event rows +
/// one row of slack that the "+N more" overflow row occupies on busy weeks.
/// The header NEVER resizes: content is top-aligned inside and the overflow
/// row takes the slack slot, so loading events (cached, streamed, or freshly
/// synced) can't move the timed body.
const double _weekHeaderHeight =
    _dayLabelsHeight + (_allDayLaneRows + 1) * _allDayTileHeight;

/// Fixed day-view header height: the day labels sit in the gutter beside the
/// strip (not stacked above it), so the lane is just the event rows + overflow
/// slack. This must be ≥ 80 — kalender's ExpandablePageView measures pages at a
/// placeholder height of 80 for the first frame(s) before the real height is
/// reported, and a smaller lane overflows the header's Column for those frames
/// (a transient clip of the bottom row in release builds). Real content tops
/// out at 2 rows + the "+N more" row (~67px), so 80 also covers it exactly.
const double _dayHeaderHeight = 80;

/// A kalender tile that carries the originating domain [CalendarEvent].
class _DomainTile extends k.CalendarEvent {
  _DomainTile({required super.dateTimeRange, required this.event});

  final CalendarEvent event;
}

/// Hosts the `kalender` month / week views, fed from our domain events and
/// styled to the design system. Read-only: dragging, resizing and creation are
/// all disabled. Tapping a tile calls [onOpenEvent].
class CalendarKalenderHost extends StatefulWidget {
  /// Creates a [CalendarKalenderHost].
  const CalendarKalenderHost({
    super.key,
    required this.mode,
    required this.focusedDate,
    required this.events,
    required this.now,
    required this.onOpenEvent,
    this.calendarColors = const {},
  });

  /// Month, week or day (agenda is handled by a separate widget).
  final CalendarViewMode mode;

  /// The date the view is framed around.
  final DateTime focusedDate;

  /// The events to render.
  final List<CalendarEvent> events;

  /// The reference "now": drives where a timed view opens (the now-indicator is
  /// centred on it), which day header is marked as today, and which tiles are
  /// dimmed as elapsed. Supplied by the caller — as `AgendaPanel` does — rather
  /// than read from the clock here, so all three agree within one build and a
  /// test can pin a time of day.
  final DateTime now;

  /// Called when a tile is tapped.
  final ValueChanged<CalendarEvent> onOpenEvent;

  /// Per-calendar accent colors, keyed by `calendarId`. Tiles fall back to the
  /// brand accent for calendars not present here.
  final Map<String, Color> calendarColors;

  @override
  State<CalendarKalenderHost> createState() => _CalendarKalenderHostState();
}

class _CalendarKalenderHostState extends State<CalendarKalenderHost> {
  final _eventsController = k.DefaultEventsController();
  final _calendarController = k.CalendarController();

  /// False for the one frame a timed view needs to lay its body out before
  /// [_positionOnNow] can place it; the body paints fully transparent until then.
  /// Without this the user sees kalender's initial offset (now pinned to the top)
  /// for a frame before the correction lands — and late in the day, where
  /// centring "now" would run past midnight, the correction used to overscroll
  /// and spring back down. Month and agenda have no timed body to position, so
  /// they are never hidden.
  bool _bodyPositioned = false;

  /// Cached so an events refresh (or any unrelated rebuild) doesn't recreate
  /// the kalender view controller and lose the scroll position. Rebuilt only
  /// when the view *mode* changes; same-mode date changes animate via the
  /// controller instead (see [didUpdateWidget]).
  late k.ViewConfiguration _viewConfiguration = _buildConfiguration();

  /// Week and day are the timed, vertically-scrolling views — the only ones
  /// with a now-indicator to centre. Month and agenda have no timed body.
  bool get _isTimed =>
      widget.mode == CalendarViewMode.week ||
      widget.mode == CalendarViewMode.day;

  @override
  void initState() {
    super.initState();
    _syncEvents();
    // Open timed views scrolled so the current time sits mid-viewport rather
    // than pinned to midnight at the top (kalender's default), which forced a
    // manual scroll to reach "now" on every visit.
    _schedulePositionOnNow();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarKalenderHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      // A new configuration recreates the view, opening it on the focused date.
      _viewConfiguration = _buildConfiguration();
      // The recreated timed body carries the outgoing view's time-of-day over
      // (kalender's ScrollTransition.preserve), so re-centre the now-indicator
      // for the freshly-entered view.
      _schedulePositionOnNow();
    } else if (!_isSameDay(oldWidget.focusedDate, widget.focusedDate)) {
      // Same view, different date: animate without rebuilding the controller.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calendarController.animateToDate(widget.focusedDate);
        }
      });
    }
    if (!identical(oldWidget.events, widget.events)) {
      _syncEvents();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _syncEvents() {
    _eventsController.clearEvents();
    _eventsController.addEvents([
      for (final event in widget.events) _toTile(event),
    ]);
  }

  _DomainTile _toTile(CalendarEvent event) {
    final start = event.startTime.toLocal();
    var end = event.endTime.toLocal();
    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }
    return _DomainTile(
      dateTimeRange: DateTimeRange(start: start, end: end),
      event: event,
    );
  }

  k.ViewConfiguration _buildConfiguration() {
    // Open timed views with "now" pinned to the top of the body. This offset is
    // only ever painted behind the transparent first frame (see
    // [_bodyPositioned]); [_positionOnNow] replaces it with the centred,
    // extent-clamped one before the body is revealed. It stays the resting
    // position if that can't run at all (e.g. the body never gets a size).
    final nowTimeOfDay = TimeOfDay.fromDateTime(widget.now);
    return switch (widget.mode) {
      CalendarViewMode.week => k.MultiDayViewConfiguration.week(
        firstDayOfWeek: DateTime.monday,
        initialDateTime: widget.focusedDate,
        initialHeightPerMinute: _heightPerMinute,
        initialTimeOfDay: nowTimeOfDay,
      ),
      CalendarViewMode.day => k.MultiDayViewConfiguration.singleDay(
        initialDateTime: widget.focusedDate,
        initialHeightPerMinute: _heightPerMinute,
        initialTimeOfDay: nowTimeOfDay,
      ),
      CalendarViewMode.month ||
      CalendarViewMode.agenda => k.MonthViewConfiguration.singleMonth(
        firstDayOfWeek: DateTime.monday,
        initialDateTime: widget.focusedDate,
      ),
    };
  }

  /// Queues a [_positionOnNow] for after the next frame — the first point at
  /// which the timed body has been laid out, so its viewport height and scroll
  /// extents are known.
  void _schedulePositionOnNow() {
    if (!_isTimed) {
      _bodyPositioned = true;
      return;
    }
    _bodyPositioned = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _positionOnNow());
  }

  /// kalender's controller for the vertically-scrolling timed body, or `null`
  /// when the attached view has none (month) or nothing is attached yet.
  k.MultiDayViewController? get _timedViewController {
    final viewController = _calendarController.viewController;
    return viewController is k.MultiDayViewController ? viewController : null;
  }

  /// Positions the timed body so the current time sits at the vertical centre of
  /// the viewport (where the orange now-indicator is drawn), then reveals it.
  ///
  /// The target is clamped to the scroll extents, so late in the day — when
  /// centring "now" would mean scrolling past the end of the day — the view
  /// simply rests at the bottom instead of overscrolling and springing back. It
  /// jumps rather than animates, and the body stays transparent until it lands,
  /// so the first frame the user sees is already the resting position: no
  /// visible attempt at centring, and nothing to suppress for reduced motion.
  void _positionOnNow() {
    if (!mounted) {
      return;
    }
    final viewController = _isTimed ? _timedViewController : null;
    final scrollController = viewController?.scrollController;
    // A position that was attached but never laid out (the host built inside an
    // offstage branch, say) has no extents yet, and reading them would throw.
    if (viewController != null &&
        scrollController != null &&
        scrollController.hasClients &&
        scrollController.position.hasViewportDimension &&
        scrollController.position.hasContentDimensions) {
      final position = scrollController.position;
      final heightPerMinute = viewController.heightPerMinute.value;
      // The vertical axis is a single day's timeline (the date lives on the
      // horizontal page axis), so the offset is a pure time-of-day measure and
      // holds whichever date is in view.
      final dayStart = viewController.viewConfiguration.timeOfDayRange.start;
      final now = TimeOfDay.fromDateTime(widget.now);
      final minutesIntoDay =
          (now.hour * 60 + now.minute) - (dayStart.hour * 60 + dayStart.minute);
      final target =
          minutesIntoDay * heightPerMinute - position.viewportDimension / 2;
      scrollController.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
    if (!_bodyPositioned) {
      setState(() => _bodyPositioned = true);
    }
  }

  /// The kalender header, with the all-day rows capped (see [_allDayLaneRows])
  /// so the fixed-height lane in [build] can never be outgrown.
  Widget _calendarHeader() {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return k.CalendarHeader(
      multiDayHeaderConfiguration: const k.MultiDayHeaderConfiguration(
        maximumNumberOfVerticalEvents: _allDayLaneRows,
      ),
      // Without explicit tile components the all-day header falls back to
      // kalender's default builder, which renders the literal text "Tile".
      multiDayTileComponents: k.TileComponents(
        tileBuilder: (event, _) => _tile(t, event, dense: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Week and day views carry an all-day events strip in the header; framing it
    // with a rule below (and, in week view, above — see [weekDayHeader]) sets it
    // apart from the timed grid. Month view's header is just the weekday labels,
    // so it stays borderless.
    final hasAllDayStrip =
        widget.mode == CalendarViewMode.week ||
        widget.mode == CalendarViewMode.day;
    return k.KalenderTheme(
      data: _theme(t),
      child: k.CalendarView(
        eventsController: _eventsController,
        calendarController: _calendarController,
        viewConfiguration: _viewConfiguration,
        components: _components(t),
        callbacks: k.CalendarCallbacks(
          onEventTapped: (event, renderBox) {
            if (event is _DomainTile) {
              widget.onOpenEvent(event.event);
            }
          },
        ),
        header: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgPrimary,
            border: hasAllDayStrip
                ? Border(bottom: BorderSide(color: t.borderSecondary))
                : null,
          ),
          // The all-day lane is a FIXED height (see [_weekHeaderHeight]) with the
          // rows capped at [_allDayLaneRows] — busier days collapse behind kalender's
          // "+N more" portal (wired to [CalendarOverflowButton] / flyout below).
          // kalender pages are top-aligned OverflowBoxes, so short weeks simply
          // leave calm slack; the strip — and therefore the timed body — never
          // moves, no matter when the events arrive. Month has no all-day strip;
          // its header is just the weekday labels and stays content-sized.
          child: hasAllDayStrip
              ? SizedBox(
                  height: widget.mode == CalendarViewMode.day
                      ? _dayHeaderHeight
                      : _weekHeaderHeight,
                  child: _calendarHeader(),
                )
              : _calendarHeader(),
        ),
        // Transparent until the timed body has been scrolled to "now" (one frame,
        // see [_bodyPositioned]); the header stays visible throughout. Opacity, not
        // Offstage: the body has to be laid out for its scroll extents to exist.
        body: Opacity(
          opacity: _bodyPositioned ? 1 : 0,
          child: k.CalendarBody(
            interaction: k.CalendarInteraction(
              allowResizing: false,
              allowRescheduling: false,
              allowEventCreation: false,
            ),
            // Overlapping events lay out side by side in equal-width columns (so
            // two conflicting tiles never paint their titles in the same band and
            // turn unreadable), and every tile gets a minimum height so short
            // events stay legible. See [calendarEventLayoutStrategy].
            multiDayBodyConfiguration: const k.MultiDayBodyConfiguration(
              eventLayoutStrategy: calendarEventLayoutStrategy,
              minimumTileHeight: _minimumTileHeight,
            ),
            multiDayTileComponents: k.TileComponents(
              tileBuilder: (event, _) => _tile(t, event, dense: false),
            ),
            // Order each month day-cell's events by start time. kalender's default
            // frame generator sorts by duration (longest first), which reads as a
            // random order for a stack of same-length meetings. The closure's
            // parameter types are inferred from GenerateMultiDayLayoutFrame.
            monthBodyConfiguration: k.MonthBodyConfiguration(
              generateMultiDayLayoutFrame:
                  ({
                    required visibleDateTimeRange,
                    required events,
                    required textDirection,
                    required location,
                    cache,
                  }) => k.defaultMultiDayFrameGenerator(
                    visibleDateTimeRange: visibleDateTimeRange,
                    events: events,
                    textDirection: textDirection,
                    location: location,
                    cache: cache,
                    eventComparator: (a, b) => a.start.compareTo(b.start),
                  ),
            ),
            monthTileComponents: k.TileComponents(
              tileBuilder: (event, _) => _tile(t, event, dense: true),
            ),
          ),
        ),
      ),
    );
  }

  /// Maps the design-system tokens onto kalender's theme so the hour lines,
  /// separators, timeline, headers, grid and now-indicator all read from one
  /// source of truth instead of kalender's Material defaults.
  k.KalenderThemeData _theme(DesignSystemTokens t) {
    final dayName = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: t.textTertiary,
    );
    final timelineText = TextStyle(
      fontSize: 11,
      color: t.textTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final weekNumber = TextStyle(fontSize: 10, color: t.textTertiary);
    return k.KalenderThemeData(
      hourLinesStyle: k.HourLinesStyle(color: t.borderSecondary),
      daySeparatorStyle: k.DaySeparatorStyle(color: t.borderSecondary),
      timelineStyle: k.TimelineStyle(textStyle: timelineText),
      timeIndicatorStyle: k.TimeIndicatorStyle(
        lineColor: t.accent,
        thickness: 1.5,
        circleColor: t.accent,
        circleSize: const Size(8, 8),
      ),
      weekDayHeaderStyle: k.WeekDayHeaderStyle(
        textStyle: dayName.copyWith(color: t.textSecondary),
      ),
      monthGridStyle: k.MonthGridStyle(color: t.borderSecondary),
      weekNumberStyle: k.WeekNumberStyle(
        alignment: Alignment.topCenter,
        textStyle: weekNumber,
      ),
    );
  }

  /// Custom day-header builders so "today" is marked with the brand accent
  /// (kalender's default fills it with the Material `primary`, which is ink
  /// black in this design system).
  k.CalendarComponents _components(DesignSystemTokens t) {
    final dayName = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: t.textTertiary,
    );

    bool isToday(DateTime date) {
      final now = widget.now;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    Widget dayBadge(int day, {required bool today, double fontSize = 14}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: today ? t.accent : Colors.transparent,
          borderRadius: AppRadii.brMd,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: today ? t.accentOn : t.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    Widget weekDayHeader(DateTime date, k.DayHeaderStyle? style) {
      final today = isToday(date);
      final header = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            dayBadge(date.day, today: today),
            const SizedBox(height: 2),
            Text(
              DateFormat.E().format(date),
              style: dayName.copyWith(color: today ? t.accent : t.textTertiary),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
      // Day view puts this same builder in the timeline gutter beside the
      // strip. Give it the full lane height so kalender's header layout
      // (height = max(content, leading)) always measures the leading at lane
      // height and the Center above centres the label against the LANE — not
      // against the strip's content, whose height varies with the number of
      // all-day rows (that's what made the date drift up and down).
      if (widget.mode == CalendarViewMode.day) {
        return SizedBox(height: _dayHeaderHeight, child: header);
      }
      // Week view stacks the day-name row above the all-day events strip, so a
      // rule under each day header reads as the strip's upper edge (its lower
      // edge is the header's bottom border). Month's grid needs no rule.
      if (widget.mode == CalendarViewMode.week) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSecondary)),
          ),
          child: header,
        );
      }
      return header;
    }

    Widget monthDayHeader(DateTime date, k.MonthDayHeaderStyle? style) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: dayBadge(date.day, today: isToday(date), fontSize: 12),
        ),
      );
    }

    // Replaces kalender's Material overflow pieces (a theme-tinted Card with
    // filled-tonal buttons) with the design-system ghost button + flyout —
    // shared by the month body and the week/day all-day strip.
    final overlayBuilders = k.OverlayBuilders(
      multiDayPortalOverlayButtonBuilder: (portalController, hidden, _) =>
          CalendarOverflowButton(
            portalController: portalController,
            hiddenCount: hidden,
          ),
      multiDayOverlayBuilder:
          ({
            required date,
            required events,
            required tileHeight,
            required portalController,
            required getMultiDayEventLayoutRenderBox,
            required getOverlayPortalRenderBox,
            required overlayTileBuilder,
            required style,
          }) => CalendarOverflowFlyout(
            date: date,
            events: events,
            tileHeight: tileHeight,
            portalController: portalController,
            getMultiDayEventLayoutRenderBox: getMultiDayEventLayoutRenderBox,
            getOverlayPortalRenderBox: getOverlayPortalRenderBox,
            overlayTileBuilder: overlayTileBuilder,
          ),
    );

    return k.CalendarComponents(
      multiDayComponents: k.MultiDayComponents(
        headerComponents: k.MultiDayHeaderComponents(
          dayHeaderBuilder: weekDayHeader,
          // The week/day timeline gutter has no week-number badge: the focused
          // week is already named in the screen header, so repeating it atop the
          // hour column is redundant. An empty builder removes it (the gutter
          // still sizes to the timeline, keeping header and body aligned).
          weekNumberBuilder: (_, _) => const SizedBox.shrink(),
          overlayBuilders: overlayBuilders,
        ),
      ),
      monthComponents: k.MonthComponents(
        bodyComponents: k.MonthBodyComponents(
          monthDayHeaderBuilder: monthDayHeader,
          overlayBuilders: overlayBuilders,
        ),
      ),
    );
  }

  Widget _tile(
    DesignSystemTokens t,
    k.CalendarEvent event, {
    required bool dense,
  }) {
    final domain = event is _DomainTile ? event.event : null;
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
            : widget.calendarColors[calendarKey(
                domain.accountId,
                domain.calendarId,
              )]) ??
        t.accent;

    // Status drives the tile's treatment so the calendar reports real state
    // rather than painting every block the same: a soft fill in the calendar's
    // color for confirmed, a dashed outline for an unanswered invitation, an
    // outline for tentative, a neutral strikethrough for cancelled.
    final Color fill;
    // The fill shown while the pointer is over the tile — a touch stronger than
    // [fill] so hovering gives a clear, consistent "this is interactive" cue.
    final Color hoverFill;
    final Color accentBar;
    final Color titleColor;
    BoxBorder? border;
    var dashed = false;
    if (cancelled) {
      fill = t.bgSecondary;
      hoverFill = t.bgSecondaryHover;
      accentBar = t.borderSecondary;
      titleColor = t.textTertiary;
    } else if (unanswered) {
      fill = Colors.transparent;
      // On hover a faint wash of the calendar color appears behind the dashed
      // outline, so a pending invitation still reacts to the pointer.
      hoverFill = calColor.withValues(alpha: 0.10);
      // The dashed outline (painted below) carries the calendar color, so the
      // solid accent bar is suppressed.
      accentBar = Colors.transparent;
      titleColor = t.textSecondary;
      dashed = true;
    } else if (tentative) {
      fill = Colors.transparent;
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

    final title = Text(
      domain?.title ?? '',
      maxLines: dense ? 1 : 3,
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
    final startLabel = localStart == null
        ? null
        : DateFormat.Hm().format(localStart);
    final rangeLabel = localStart == null
        ? null
        : '$startLabel–${DateFormat.Hm().format(domain!.endTime.toLocal())}';

    final Widget content = dense
        ? Row(
            children: [
              if (startLabel != null) ...[
                Text(
                  startLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(child: title),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (rangeLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    rangeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: cancelled ? t.textTertiary : t.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          );

    Widget box = _HoverFillBox(
      fill: fill,
      hoverFill: hoverFill,
      border: border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2.5, color: accentBar),
          Expanded(
            // Short events give the tile less height than its content needs;
            // OverflowBox lets the content lay out at its natural size (no
            // RenderFlex overflow) while the parent Container clips the excess.
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: dense ? 1 : 3,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (dashed) {
      // BoxDecoration has no dashed border, so paint one over the (transparent)
      // box. Drawn as a foreground painter so it sits above the clipped content.
      box = CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: calColor,
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

    // A finished event is dimmed so attention falls on what is still ahead. Only
    // fully-elapsed events fade — one in progress (end still in the future) stays
    // at full strength. Re-evaluated on each rebuild rather than on a timer, so a
    // tile that elapses mid-session fades on the next refresh.
    final isPast =
        domain != null && domain.endTime.toLocal().isBefore(widget.now);
    return isPast ? Opacity(opacity: 0.5, child: tile) : tile;
  }
}

/// The tile body, with a pointer-driven background. Stateful so each tile tracks
/// its own hover without rebuilding the whole calendar. The fill cross-fades
/// between [fill] and [hoverFill] (instantly when the platform requests reduced
/// motion).
class _HoverFillBox extends StatefulWidget {
  const _HoverFillBox({
    required this.fill,
    required this.hoverFill,
    required this.border,
    required this.child,
  });

  final Color fill;
  final Color hoverFill;
  final BoxBorder? border;
  final Widget child;

  @override
  State<_HoverFillBox> createState() => _HoverFillBoxState();
}

class _HoverFillBoxState extends State<_HoverFillBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? widget.hoverFill : widget.fill,
          borderRadius: AppRadii.brSm,
          border: widget.border,
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle outline, inset by half the stroke so it is
/// not clipped at the edges. Used for unanswered invitations, which have no
/// fill of their own.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _strokeWidth = 1;
  static const double _dashLength = 4;
  static const double _gapLength = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    const inset = _strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - _strokeWidth,
            size.height - _strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
