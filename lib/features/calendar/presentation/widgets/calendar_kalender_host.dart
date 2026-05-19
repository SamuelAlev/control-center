import 'dart:math' as math;

import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart'
    show calendarKey;
import 'package:control_center/features/calendar/presentation/utils/calendar_event_layout.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_all_day_gutter.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_overflow_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// intl declares its own `TextDirection` (a bidi enum, unrelated to the layout
// one), which would shadow Flutter's in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:kalender/kalender.dart' as k;

/// Pixels per minute in the timed (week / day) body. Sets the minimum height
/// of an hour interval: 60 × this. kalender's default is 0.7 (≈42px/hour),
/// which is too cramped to read; 1.2 gives each hour a comfortable 72px.
const double _heightPerMinute = 1.2;

/// Legibility floor for a timed tile: the height a short event may *grow into*
/// so its title stays readable, used by [calendarEventLayoutStrategy]. A
/// 1-minute event would otherwise collapse to ~1px. Kept at 18px (= 15 min at
/// [_heightPerMinute]) so a real 15-minute event renders at its exact height and
/// never appears to overrun its end time; only shorter events are grown and
/// only into empty space — never past the start of the following event. 18px
/// fits one title line.
const double _minimumTileHeight = 18;

/// Rows of all-day events the week/day header shows before collapsing the rest
/// behind a "+N more" button (which opens the day flyout). kalender's default
/// is an uncapped strip: one genuinely busy week would push the timed grid
/// most of the way off screen.
const int _allDayLaneRows = 3;

/// Height of one all-day tile row (kalender's `defaultTileHeight`). Repeated
/// here so the lane height computed below stays in lockstep with what kalender
/// actually lays out.
const double _allDayTileHeight = 24;

/// The day-labels block (badge + weekday name) above the all-day strip in week
/// view, pinned rather than measured. The strip's gutter cell has to line up
/// with the strip's first row, and it can only do that by offsetting itself by
/// a height it knows. The block's natural, font-metric height is ~47px, so the
/// content centres inside this with room for a fallback font.
const double _dayLabelsHeight = 56;

/// The most compact day view can be. Two floors meet here and the taller wins:
/// kalender's single-day header pins its strip at two tile rows
/// (`_SingleDayHeader` passes `minHeight: tileHeight * 2` = 48), and day view
/// spends its gutter on the day label — the same badge-and-weekday block week
/// view stacks above the strip — which needs [_dayLabelsHeight] beside it.
const double _dayLaneMinHeight = _dayLabelsHeight;

/// Explicit timeline gutter width, in place of kalender's measure-the-widest-
/// hour-label default. Two reasons: the all-day gutter cell needs a width it
/// can lay a word out in (the measured width is the widest *time*, which is
/// narrower), and the default lays out all 24 labels with a `TextPainter` on
/// every header build to arrive at a number that never changes.
const double _timelineWidth = 56;

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
  /// centred on it), which day header is marked as today and which tiles are
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

  /// Whether the user has folded the all-day strip down to its one-row
  /// summary. Week view only — day view's gutter is taken by the day label, so
  /// it has nowhere to put the toggle (and one column of all-day events is
  /// rarely worth folding).
  bool _allDayCollapsed = false;

  /// The page kalender is showing, once it has told us (see [_effectiveRange]).
  /// Null until the first `onPageChanged`, and reset whenever the view is
  /// re-framed, so the derived fallback takes over rather than a stale week
  /// sizing the strip.
  DateTimeRange<DateTime>? _visibleRange;

  /// The tiles handed to kalender, kept so the strip's height can be computed
  /// from the same events kalender is about to lay out.
  List<_DomainTile> _tiles = const [];

  /// [_allDayRows] per visible range. The strip's height is read on every
  /// build; the packing behind it only changes when the events do.
  final _allDayRowCache = <String, int>{};

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
      _visibleRange = null;
      // The recreated timed body carries the outgoing view's time-of-day over
      // (kalender's ScrollTransition.preserve), so re-centre the now-indicator
      // for the freshly-entered view.
      _schedulePositionOnNow();
    } else if (!_isSameDay(oldWidget.focusedDate, widget.focusedDate)) {
      // The animation below lands an `onPageChanged`, but not until it does;
      // dropping the tracked range means the strip sizes itself from the newly
      // focused date this frame instead of from the week being left.
      _visibleRange = null;
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
    _tiles = [for (final event in widget.events) _toTile(event)];
    _allDayRowCache.clear();
    _eventsController.clearEvents();
    _eventsController.addEvents(_tiles);
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

  /// The page kalender is showing: what it last reported, or — before it has
  /// reported anything, and for the frames between a date change and the page
  /// animation landing — the page [CalendarKalenderHost.focusedDate] falls in.
  ///
  /// Day arithmetic goes through the [DateTime] constructor rather than
  /// `add(Duration(days: n))`, which is elapsed time: across a daylight saving
  /// change it lands at 23:00 or 01:00 and the range covers the wrong set of
  /// days.
  DateTimeRange<DateTime> get _effectiveRange {
    final tracked = _visibleRange;
    if (tracked != null) {
      return tracked;
    }
    final focused = widget.focusedDate;
    final day = DateTime(focused.year, focused.month, focused.day);
    if (widget.mode == CalendarViewMode.day) {
      return DateTimeRange(
        start: day,
        end: DateTime(day.year, day.month, day.day + 1),
      );
    }
    final start = DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - DateTime.monday),
    );
    return DateTimeRange(
      start: start,
      end: DateTime(start.year, start.month, start.day + 7),
    );
  }

  /// How many rows of all-day tiles [range] needs.
  ///
  /// Computed with kalender's own frame generator over the events kalender
  /// itself would put in the strip, so the height reserved for the strip and
  /// the height the strip lays out at cannot drift apart. Deriving it here
  /// rather than measuring the laid-out header is the point: a measured strip
  /// only reports its height *after* a frame at the wrong one, which is how
  /// every late-arriving event used to shove the timed grid down.
  int _allDayRows(DateTimeRange<DateTime> range) {
    final key = '${range.start.toIso8601String()}|${range.end.toIso8601String()}';
    final cached = _allDayRowCache[key];
    if (cached != null) {
      return cached;
    }
    // What kalender's header asks its event store for: multi-day events (by the
    // view's rule — 24 hours or longer, which is every all-day event) that
    // overlap the page.
    final visible = <k.CalendarEvent>[
      for (final tile in _tiles)
        if (tile.spansMultipleDays(
              location: null,
              defaultRule: k.defaultMultiDayRule,
            ) &&
            tile.dateTimeRange.start.isBefore(range.end) &&
            tile.dateTimeRange.end.isAfter(range.start))
          tile,
    ];
    // The generator reports one row for a non-empty event list even when none
    // of it lands on a visible column, so the emptiness test happens here.
    final rows = visible.isEmpty
        ? 0
        : k
              .defaultMultiDayFrameGenerator(
                visibleDateTimeRange: k.InternalDateTimeRange(
                  start: k.InternalDateTime.fromDateTime(range.start),
                  end: k.InternalDateTime.fromDateTime(range.end),
                ),
                events: visible,
                // The packing mirrors under RTL — same intervals, same clashes —
                // so the row count is direction-independent.
                textDirection: TextDirection.ltr,
                location: null,
              )
              .totalNumberOfRows;
    _allDayRowCache[key] = rows;
    return rows;
  }

  /// The height of the all-day strip for [rows] of events.
  ///
  /// Empty and collapsed both come out at a single row: an empty strip is a
  /// labelled band rather than a gap, and a collapsed one holds the per-day
  /// "N events" summaries. Beyond [_allDayLaneRows] the strip stops growing and
  /// the remainder moves into the overflow row.
  double _laneHeight(int rows, {required bool collapsed}) {
    if (collapsed || rows == 0) {
      return _allDayTileHeight;
    }
    final shown = math.min(rows, _allDayLaneRows);
    final overflow = rows > _allDayLaneRows
        ? CalendarOverflowButton.rowHeight
        : 0.0;
    return shown * _allDayTileHeight + overflow;
  }

  /// The header height for a strip of [laneHeight] — the strip alone in day
  /// view (where the day label sits beside it in the gutter), the day labels
  /// stacked above it in week view.
  double _headerHeight(double laneHeight) {
    return widget.mode == CalendarViewMode.day
        ? laneHeight
        : _dayLabelsHeight + laneHeight;
  }

  /// What the header takes from the timed grid, whatever the strip needs.
  ///
  /// A constant: the strip at its resting size, one row. Everything past that
  /// hangs over the grid instead of pushing it (see [_FloatingBand]), so the
  /// hour the grid opens on is decided by the time of day and nothing else —
  /// not by how many people put an all-day event in this particular week.
  double get _reservedHeaderHeight => _headerHeight(
    widget.mode == CalendarViewMode.day ? _dayLaneMinHeight : _allDayTileHeight,
  );

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
  /// jumps rather than animates and the body stays transparent until it lands,
  /// so the first frame the user sees is already the resting position: no
  /// visible attempt at centring and nothing to suppress for reduced motion.
  void _positionOnNow() {
    if (!mounted) {
      return;
    }
    final viewController = _isTimed ? _timedViewController : null;
    final scrollController = viewController?.scrollController;
    // A position that was attached but never laid out (the host built inside an
    // offstage branch, say) has no extents yet and reading them would throw.
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

  /// The kalender header, with the all-day rows capped at [maxRows] — beyond
  /// that the remainder collapses behind the "+N more" portal, so the strip's
  /// height stays the one [_laneHeight] computed.
  Widget _calendarHeader(DesignSystemTokens t, {required int? maxRows}) {
    return k.CalendarHeader(
      multiDayHeaderConfiguration: k.MultiDayHeaderConfiguration(
        maximumNumberOfVerticalEvents: maxRows,
      ),
      // Without explicit tile components the all-day header falls back to
      // kalender's default builder, which renders the literal text "Tile".
      multiDayTileComponents: k.TileComponents(
        tileBuilder: (event, tileRange) =>
            _tile(t, event, dense: true, tileRange: tileRange),
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
    final rows = hasAllDayStrip ? _allDayRows(_effectiveRange) : 0;
    // Only week view can fold: its gutter holds the toggle. And there is
    // nothing to fold when the strip is already at its one-row resting size.
    final collapsed =
        _allDayCollapsed && rows > 0 && widget.mode == CalendarViewMode.week;
    final laneHeight = widget.mode == CalendarViewMode.day
        ? math.max(_laneHeight(rows, collapsed: false), _dayLaneMinHeight)
        : _laneHeight(rows, collapsed: collapsed);
    return k.KalenderTheme(
      data: _theme(t),
      child: k.CalendarView(
        eventsController: _eventsController,
        calendarController: _calendarController,
        viewConfiguration: _viewConfiguration,
        components: _components(
          t,
          laneHeight: laneHeight,
          rows: rows,
          collapsed: collapsed,
        ),
        callbacks: k.CalendarCallbacks(
          onEventTapped: (event, renderBox) {
            if (event is _DomainTile) {
              widget.onOpenEvent(event.event);
            }
          },
          // kalender pages independently of the screen's focused date, so the
          // strip would otherwise size itself from a week the user has swiped
          // away from.
          onPageChanged: (range) {
            if (mounted && range != _visibleRange) {
              setState(() => _visibleRange = range);
            }
          },
        ),
        header: hasAllDayStrip
            ? _allDayHeader(t, laneHeight: laneHeight, collapsed: collapsed)
            : DecoratedBox(
                // Month's header is just the weekday labels — no strip, so no
                // rule under it and nothing to float.
                decoration: BoxDecoration(color: t.bgPrimary),
                child: _calendarHeader(t, maxRows: null),
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
            // turn unreadable) and every tile gets a minimum height so short
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
              tileBuilder: (event, tileRange) =>
                  _tile(t, event, dense: true, tileRange: tileRange),
            ),
          ),
        ),
      ),
    );
  }

  /// The week/day header: a band that grows with the all-day strip it actually
  /// has, hanging over the timed grid rather than pushing it down.
  ///
  /// It reserves [_reservedHeaderHeight] — one strip row — from the layout and
  /// paints the rest over the grid, so the hour the grid opens on never depends
  /// on how busy the week's all-day strip is. Nothing is permanently hidden
  /// under it: the cap keeps the overhang under an hour, and the gutter's fold
  /// control returns the band to one row.
  ///
  /// The height is derived (see [_allDayRows]), never measured, so it is
  /// settled on the frame the events arrive — no reflow behind the user. It
  /// animates because the band genuinely changes size as you page through weeks
  /// or fold it away, and a band that jumps between sizes reads as a glitch
  /// where one that slides reads as the same band, resized.
  ///
  /// Top-aligned in a [_ClippedBand] rather than squeezed into one, so the
  /// frames where kalender's own measurement disagrees with this height trim
  /// empty space instead of overflowing.
  Widget _allDayHeader(
    DesignSystemTokens t, {
    required double laneHeight,
    required bool collapsed,
  }) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reserved = _reservedHeaderHeight;
    final target = _headerHeight(laneHeight);
    final header = _calendarHeader(
      t,
      // A collapsed strip shows no tiles at all: every day's events move into
      // the summary row, which is the same "+N more" portal the overflow uses.
      maxRows: collapsed ? 0 : _allDayLaneRows,
    );
    return _FloatingBand(
      reservedHeight: reserved,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: target, end: target),
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, height, child) => DecoratedBox(
          decoration: BoxDecoration(
            // Opaque, because the grid runs underneath it: a translucent band
            // would put hour lines through the event titles.
            color: t.bgPrimary,
            border: Border(bottom: BorderSide(color: t.borderSecondary)),
            // Lifted only while it is actually hanging over the grid. At its
            // resting height the band sits flush in the layout and a shadow
            // would be a shadow on nothing.
            boxShadow: height > reserved + 0.5 ? CcElevation.raised : null,
          ),
          child: _ClippedBand(
            height: height,
            alignment: Alignment.topCenter,
            child: child!,
          ),
        ),
        child: header,
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
    final timelineText = TextStyle(fontSize: 11, color: t.textTertiary);
    final weekNumber = TextStyle(fontSize: 10, color: t.textTertiary);
    return k.KalenderThemeData(
      hourLinesStyle: k.HourLinesStyle(color: t.borderSecondary),
      daySeparatorStyle: k.DaySeparatorStyle(color: t.borderSecondary),
      timelineStyle: k.TimelineStyle(
        textStyle: timelineText,
        width: _timelineWidth,
      ),
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
  /// black in this design system), plus the all-day strip's gutter cell.
  k.CalendarComponents _components(
    DesignSystemTokens t, {
    required double laneHeight,
    required int rows,
    required bool collapsed,
  }) {
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
      // strip. It gets the strip's RESTING height — the part of the band that
      // is in the layout — so the date sits at the top of the band and stays
      // there, the way week view's day labels do. Centring it on the whole band
      // would walk the date down the screen as all-day rows arrived.
      if (widget.mode == CalendarViewMode.day) {
        return _ClippedBand(
          height: _dayLaneMinHeight,
          alignment: Alignment.center,
          child: header,
        );
      }
      // Week view stacks the day-name row above the all-day events strip, so a
      // rule under each day header reads as the strip's upper edge (its lower
      // edge is the header's bottom border). Month's grid needs no rule.
      //
      // Pinned to [_dayLabelsHeight] rather than left to its font metrics: the
      // strip's gutter cell offsets itself by that constant to line up with the
      // strip's first row, and a measured block would only line up by accident.
      if (widget.mode == CalendarViewMode.week) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSecondary)),
          ),
          child: SizedBox(height: _dayLabelsHeight, child: header),
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
            // In a collapsed strip nothing is shown above this row, so the
            // count is the day's whole tally rather than what is left over.
            summarise: collapsed,
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
          // kalender's week-number badge is dropped — the focused week is
          // already named in the screen header — and the slot it leaves, the
          // gutter beside the all-day strip, is where the strip names itself
          // and offers its fold. Week view only: day view spends this slot on
          // the day label above.
          weekNumberBuilder: (_, _) => widget.mode == CalendarViewMode.week
              ? CalendarAllDayGutter(
                  topInset: _dayLabelsHeight,
                  laneHeight: laneHeight,
                  rowHeight: _allDayTileHeight,
                  collapsible: rows > 0,
                  collapsed: collapsed,
                  onToggle: () =>
                      setState(() => _allDayCollapsed = !_allDayCollapsed),
                )
              : const SizedBox.shrink(),
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
    DateTimeRange<DateTime>? tileRange,
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
    // A dense tile is one bar across every day of the event that falls in view,
    // clipped at the edges of the page. When the event began before this page,
    // that bar starts on a day the event did not — so its start time would read
    // as "midnight on Monday" for something that started the previous Thursday.
    // The bar carries no time at all in that case; the page it starts on shows
    // it. (Nothing to suppress for the timed body: an event there is on its own
    // day by definition.)
    final continues =
        dense &&
        localStart != null &&
        tileRange != null &&
        localStart.isBefore(tileRange.start);
    final startLabel = (localStart == null || continues)
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
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
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

/// A band that takes [reservedHeight] from the layout and paints — and stays
/// tappable — at whatever height its child turns out to be.
///
/// This is what makes the all-day strip hover over the timed grid instead of
/// pushing it down. kalender lays its header and body out with a
/// `CustomMultiChildLayout` that positions the body directly below the header's
/// reported height and paints the header second, precisely so a header can cast
/// a shadow on the body. Reporting the resting height while painting the full
/// one turns "the grid starts under the strip" into "the strip hangs over the
/// grid", and the grid's position stops depending on the week's all-day events.
///
/// [RenderBox.hitTest] refuses any position outside `size`, so the overhang
/// would be invisible to the pointer — its tiles unclickable and, worse, the
/// grid underneath clickable straight through an opaque band. The override
/// below tests against the child's real bounds instead, and claims whatever the
/// child does not, so nothing reaches the grid through the band.
class _FloatingBand extends SingleChildRenderObjectWidget {
  const _FloatingBand({required this.reservedHeight, required super.child});

  final double reservedHeight;

  @override
  _RenderFloatingBand createRenderObject(BuildContext context) {
    return _RenderFloatingBand(reservedHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFloatingBand renderObject,
  ) {
    renderObject.reservedHeight = reservedHeight;
  }
}

class _RenderFloatingBand extends RenderProxyBox {
  _RenderFloatingBand(this._reservedHeight);

  double _reservedHeight;
  double get reservedHeight => _reservedHeight;
  set reservedHeight(double value) {
    if (value == _reservedHeight) {
      return;
    }
    _reservedHeight = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _reservedHeight));
      return;
    }
    // Height-unbounded, so the child settles at its own height rather than
    // being squeezed into the band's.
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    size = Size(child.size.width, _reservedHeight);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !(Offset.zero & child.size).contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  /// Claims every point the band paints on, so a press on an empty part of it
  /// stops there instead of falling through to the grid behind.
  @override
  bool hitTestSelf(Offset position) => true;
}

/// A [height]-tall band whose child is laid out at its natural height and
/// clipped, rather than squeezed into the band.
///
/// The all-day strip is measured by kalender in two passes per frame — once
/// unbounded, once against the height it settled on — and its page view reports
/// a placeholder height before it has measured a page, then tweens between
/// heights afterwards. So for a handful of frames the content is taller than
/// the band it is going into. Clamped, that is a RenderFlex overflow (and a
/// visibly squashed row); clipped, it is empty space below a top-aligned strip
/// that nobody can see missing.
class _ClippedBand extends StatelessWidget {
  const _ClippedBand({
    required this.height,
    required this.alignment,
    required this.child,
  });

  final double height;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
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
