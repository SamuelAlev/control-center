import 'dart:math' as math;

import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart'
    show CalendarSlot;
import 'package:control_center/features/calendar/presentation/utils/calendar_event_layout.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart'
    show dayKey;
import 'package:control_center/features/calendar/presentation/widgets/calendar_all_day_gutter.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_tile.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_overflow_overlay.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_tile_parts.dart';
import 'package:flutter/widgets.dart';
// intl declares its own `TextDirection` (a bidi enum, unrelated to the layout
// one), which would shadow Flutter's in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:kalender/kalender.dart' as k;

/// Pixels per minute in the timed (week / day) body. Sets the minimum height
/// of an hour interval: 60 × this. kalender's default is 0.7 (≈42px/hour),
/// which is too cramped to read; 1.2 gives each hour a comfortable 72px.
const double _heightPerMinute = 1.2;

/// Legibility floor for a timed tile: the height a short event may *grow into*
/// so its title stays readable, used by [CalendarEventLayoutStrategy]. A
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

/// The day-labels block above the all-day strip in week view. Pinned rather
/// than measured so the strip's gutter can offset by a height it already knows.
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
class _DomainTile extends k.KalenderEvent {
  _DomainTile({
    required super.start,
    required super.end,
    required this.event,
    super.interaction,
  }) : super(isAllDay: event.isAllDay);

  final CalendarEvent event;

  @override
  _DomainTile copyWithData({required DateTime start, required DateTime end}) =>
      _DomainTile(
        start: start,
        end: end,
        event: event,
        interaction: interaction,
      );
}

/// Hosts the `kalender` month / week views, fed from our domain events and
/// styled to the design system. With [onCreate] set, dragging across empty
/// time draws a new event's span; with [onMove] set, the tiles [canMove]
/// allows drag to another time or stretch at an edge. Tapping a tile calls
/// [onOpenEvent].
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
    this.onCreate,
    this.composing,
    this.canMove,
    this.onMove,
    this.draft,
  });

  /// The placeholder event for a span being drawn, so it looks like the tile
  /// it becomes. Null draws nothing until the drag ends.
  final CalendarEvent? Function(CalendarSlot slot)? draft;

  /// Whether a tile may be dragged or resized. Null: none may.
  final bool Function(CalendarEvent event)? canMove;

  /// Called with an event and the span it was dropped on or stretched to.
  /// Resolves false when the change was refused, and the tile goes back.
  final Future<bool> Function(CalendarEvent event, CalendarSlot to)? onMove;

  /// Called with the span drawn across empty time (and the point it was drawn
  /// from), or null when the person has no calendar to add events to.
  final ValueChanged<CalendarSlot>? onCreate;

  /// The span the open composer is for, drawn as its [draft] until it is
  /// saved or dropped.
  final CalendarSlot? composing;

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

  /// Holds the view configuration. An events refresh (or any unrelated
  /// rebuild) leaves it alone, so the view controller and its scroll position
  /// survive; only a change of view *mode* switches it, and same-mode date
  /// changes animate via the controller instead (see [didUpdateWidget]).
  late final _calendarController = k.KalenderController(
    viewConfiguration: _buildConfiguration(),
  );

  /// Creation follows [CalendarKalenderHost.onCreate], moving and resizing
  /// [CalendarKalenderHost.onMove] (each tile still says whether it may).
  /// Held so a rebuild hands kalender the same instance.
  final _interactions = <(bool, bool), k.KalenderInteraction>{};

  k.KalenderInteraction get _interaction {
    final create = widget.onCreate != null;
    final move = widget.onMove != null;
    return _interactions[(create, move)] ??= k.KalenderInteraction(
      allowResizing: move,
      allowRescheduling: move,
      allowEventCreation: create,
    );
  }

  /// Where the current drag started, in global coordinates: the composer
  /// opens beside it.
  Offset _createAnchor = Offset.zero;

  /// False for the one frame a timed view needs to lay its body out before
  /// [_positionOnNow] can place it; the body paints fully transparent until then.
  /// Without this the user sees kalender's initial offset (now pinned to the top)
  /// for a frame before the correction lands — and late in the day, where
  /// centring "now" would run past midnight, the correction used to overscroll
  /// and spring back down. Month and agenda have no timed body to position, so
  /// they are never hidden.
  bool _bodyPositioned = false;

  /// Whether the user has folded the all-day strip down to its one-row
  /// summary. Week view only — day view's gutter is taken by the day label, so
  /// it has nowhere to put the toggle (and one column of all-day events is
  /// rarely worth folding).
  bool _allDayCollapsed = false;

  /// The page kalender is showing, once it has told us (see [_effectiveRange]).
  /// Null until the first `onPageChanged`, and reset whenever the view is
  /// re-framed, so the derived fallback takes over rather than a stale week
  /// sizing the strip.
  k.KalenderDateTimeRange? _visibleRange;

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
      // A new configuration switches the view, opening it on the focused date
      // (through its date resolver — see [_buildConfiguration]).
      _calendarController.viewConfiguration = _buildConfiguration();
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
    if (!identical(oldWidget.events, widget.events) ||
        oldWidget.composing != widget.composing ||
        (oldWidget.canMove == null) != (widget.canMove == null)) {
      _syncEvents();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// The composer's placeholder tile, rebuilt with the tiles.
  CalendarEvent? _preview;

  void _syncEvents() {
    final composing = widget.composing;
    _preview = composing == null ? null : widget.draft?.call(composing);
    _tiles = [
      for (final event in widget.events) _toTile(event),
      if (_preview case final preview?) _toTile(preview),
    ];
    _allDayRowCache.clear();
    _eventsController.clearEvents();
    _eventsController.addEvents(_tiles);
  }

  /// The local span of kalender's [event] (it holds UTC instants). A drawn
  /// span reads as whole days when it runs midnight to midnight (the month
  /// grid and the all-day strip draw days); a moved one keeps [allDay].
  CalendarSlot _slotFor(k.KalenderEvent event, {bool? allDay}) {
    final start = event.start.toLocal();
    final end = event.end.toLocal();
    bool midnight(DateTime d) => d.hour == 0 && d.minute == 0 && d.second == 0;
    final days =
        allDay ??
        (widget.mode == CalendarViewMode.month ||
            (midnight(start) &&
                midnight(end) &&
                end.difference(start).inHours >= 23));
    return CalendarSlot(
      start: days ? dayKey(start) : start,
      // kalender ends a day span on the last day's midnight or on the next;
      // either way Google wants the day after the last one.
      end: days
          ? dayKey(
              end.subtract(const Duration(seconds: 1)),
            ).add(const Duration(days: 1))
          : end,
      allDay: days,
      anchor: _createAnchor,
    );
  }

  /// The event behind kalender's [event], at the times kalender holds (a
  /// dragged or just-dropped tile has moved before the host confirms it), or
  /// the [CalendarKalenderHost.draft] for a span being drawn.
  CalendarEvent? _domainOf(k.KalenderEvent event) {
    if (event is! _DomainTile) {
      return widget.draft?.call(_slotFor(event));
    }
    final domain = event.event;
    return event.start == domain.startTime.toUtc() &&
            event.end == domain.endTime.toUtc()
        ? domain
        : domain.copyWith(startTime: event.start, endTime: event.end);
  }

  /// Tiles for one surface. While a tile is dragged its old place keeps a
  /// ghost, and where it would land (or the span being drawn) floats above.
  k.TileComponents _tileParts({required bool dense}) {
    Widget tile(
      k.KalenderEvent event, {
      bool lifted = false,
      k.KalenderDateTimeRange? range,
    }) => CalendarEventTile(
      event: _domainOf(event),
      now: widget.now,
      calendarColors: widget.calendarColors,
      dense: dense,
      tileRange: dense ? range : null,
      lifted: lifted,
    );
    return k.TileComponents(
      tileBuilder: (_, event, range) => tile(event, range: range),
      tileWhenDraggingBuilder: (_, event) =>
          Opacity(opacity: 0.35, child: tile(event)),
      dropTargetTile: (_, event) =>
          IgnorePointer(child: tile(event, lifted: true)),
    );
  }

  /// Hands a dropped or stretched tile to [CalendarKalenderHost.onMove], and
  /// puts it back when the change is refused.
  Future<void> _moved(k.KalenderEvent from, k.KalenderEvent to) async {
    final onMove = widget.onMove;
    if (from is! _DomainTile || onMove == null) {
      return;
    }
    final slot = _slotFor(to, allDay: from.event.isAllDay);
    if (await onMove(from.event, slot) || !mounted) {
      return;
    }
    setState(_syncEvents);
  }

  _DomainTile _toTile(CalendarEvent event) {
    final start = event.startTime.toLocal();
    var end = event.endTime.toLocal();
    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }
    final movable = event != _preview && (widget.canMove?.call(event) ?? false);
    return _DomainTile(
      start: start,
      end: end,
      event: event,
      interaction: k.EventInteraction.fromCanModify(movable),
    );
  }

  k.ViewConfiguration _buildConfiguration() {
    // Open timed views with "now" pinned to the top of the body. This offset is
    // only ever painted behind the transparent first frame (see
    // [_bodyPositioned]); [_positionOnNow] replaces it with the centred,
    // extent-clamped one before the body is revealed. It stays the resting
    // position if that can't run at all (e.g. the body never gets a size).
    final nowTimeOfDay = k.KalenderTime.fromDateTime(widget.now);
    // kalender reads `initialDateTime` only when the controller is constructed.
    // A configuration set on it later (every mode switch) opens on the outgoing
    // view's own date instead — a week's Monday, a month's 1st — so switching
    // month → day on the 19th used to land on the 1st, with the events loaded
    // for the 19th nowhere on screen. The resolver pins every switch to the
    // screen's focused date. It reads `widget` when kalender calls it, inside
    // the switch, so it always sees the date being switched to.
    k.FloatingDateTime focused(k.ViewTransitionContext transition) =>
        k.FloatingDateTime.fromExternal(
          widget.focusedDate,
          location: transition.location,
        );
    return switch (widget.mode) {
      CalendarViewMode.week => k.MultiDayViewConfiguration.week(
        firstDayOfWeek: DateTime.monday,
        initialDateTime: widget.focusedDate,
        dateResolver: focused,
        initialHeightPerMinute: _heightPerMinute,
        initialTimeOfDay: nowTimeOfDay,
      ),
      CalendarViewMode.day => k.MultiDayViewConfiguration.singleDay(
        initialDateTime: widget.focusedDate,
        dateResolver: focused,
        initialHeightPerMinute: _heightPerMinute,
        initialTimeOfDay: nowTimeOfDay,
      ),
      CalendarViewMode.month ||
      CalendarViewMode.agenda => k.MonthViewConfiguration.singleMonth(
        firstDayOfWeek: DateTime.monday,
        initialDateTime: widget.focusedDate,
        dateResolver: focused,
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
  k.KalenderDateTimeRange get _effectiveRange {
    final tracked = _visibleRange;
    if (tracked != null) {
      return tracked;
    }
    final focused = widget.focusedDate;
    final day = DateTime(focused.year, focused.month, focused.day);
    if (widget.mode == CalendarViewMode.day) {
      return k.KalenderDateTimeRange(
        start: day,
        end: DateTime(day.year, day.month, day.day + 1),
      );
    }
    final start = DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - DateTime.monday),
    );
    return k.KalenderDateTimeRange(
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
  int _allDayRows(k.KalenderDateTimeRange range) {
    final key =
        '${range.start.toIso8601String()}|${range.end.toIso8601String()}';
    final cached = _allDayRowCache[key];
    if (cached != null) {
      return cached;
    }
    // What kalender's header asks its event store for: multi-day events (by the
    // view's rule — 24 hours or longer, which is every all-day event) that
    // overlap the page.
    final visible = <k.KalenderEvent>[
      for (final tile in _tiles)
        if (tile.spansMultipleDays(
              location: null,
              defaultRule: k.kDefaultMultiDayRule,
            ) &&
            tile.start.isBefore(range.end) &&
            tile.end.isAfter(range.start))
          tile,
    ];
    // The generator reports one row for a non-empty event list even when none
    // of it lands on a visible column, so the emptiness test happens here.
    final rows = visible.isEmpty
        ? 0
        : k
              .defaultMultiDayFrameGenerator(
                visibleRange: k.FloatingDateTimeRange(
                  start: k.FloatingDateTime.fromDateTime(range.start),
                  end: k.FloatingDateTime.fromDateTime(range.end),
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
  /// An empty range has no strip at all — the day labels sit straight on the
  /// timed grid. A collapsed strip is a single row holding the per-day
  /// "N events" summaries. Beyond [_allDayLaneRows] the strip stops growing and
  /// the remainder moves into the overflow row.
  double _laneHeight(int rows, {required bool collapsed}) {
    if (rows == 0) {
      return 0;
    }
    if (collapsed) {
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

  /// What the header takes from the timed grid for a range with [rows] of
  /// all-day events.
  ///
  /// The strip at its resting size: one row when the range has any all-day
  /// events, none when it has nothing to show (week view drops the strip). Everything
  /// past that hangs over the grid instead of pushing it (see [CalendarFloatingBand]),
  /// so how busy a week's strip is never moves the grid — only whether it has one.
  /// Day view always reserves its floor, which its gutter's day label needs anyway.
  double _reservedHeaderHeight(int rows) => _headerHeight(
    widget.mode == CalendarViewMode.day
        ? _dayLaneMinHeight
        : (rows > 0 ? _allDayTileHeight : 0),
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
  /// when the current view has none (month).
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
      final now = k.KalenderTime.fromDateTime(widget.now);
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
  Widget _calendarHeader(DesignSystemTokens t, {required int maxRows}) {
    return k.MultiDayHeader(
      configuration: k.MultiDayHeaderConfiguration(
        maximumNumberOfVerticalEvents: maxRows,
      ),
      // Without explicit tile components the all-day header falls back to
      // kalender's default builder, which renders the literal text "Tile".
      tileComponents: _tileParts(dense: true),
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
    // Only week view can fold: its gutter holds the toggle. And a week with
    // no all-day events has no strip to fold.
    final collapsed =
        _allDayCollapsed && rows > 0 && widget.mode == CalendarViewMode.week;
    final laneHeight = widget.mode == CalendarViewMode.day
        ? math.max(_laneHeight(rows, collapsed: false), _dayLaneMinHeight)
        : _laneHeight(rows, collapsed: collapsed);
    return k.KalenderTheme(
      data: _theme(t),
      child: k.KalenderView(
        eventsController: _eventsController,
        kalenderController: _calendarController,
        interaction: _interaction,
        components: _components(
          t,
          laneHeight: laneHeight,
          rows: rows,
          collapsed: collapsed,
        ),
        callbacks: k.KalenderCallbacks(
          onEventTapped: (event) {
            if (event is _DomainTile && event.event != _preview) {
              widget.onOpenEvent(event.event);
            }
          },
          onEventCreateWithDetail: (event, detail) {
            _createAnchor = detail.renderBox.localToGlobal(detail.localOffset);
            return event;
          },
          onEventCreated: (event) => widget.onCreate?.call(_slotFor(event)),
          onEventChanged: _moved,
          // kalender pages independently of the screen's focused date, so the
          // strip would otherwise size itself from a week the user has swiped
          // away from.
          onPageChanged: (range) {
            if (mounted && range != _visibleRange) {
              setState(() => _visibleRange = range);
            }
          },
        ),
        // Transparent until the timed body has been scrolled to "now" (one
        // frame, see [_bodyPositioned]); the header stays visible throughout.
        // Opacity, not Offstage: the body has to be laid out for its scroll
        // extents to exist. Month is never hidden.
        views: [
          k.MultiDayViewParts(
            header: _allDayHeader(
              t,
              laneHeight: laneHeight,
              rows: rows,
              collapsed: collapsed,
            ),
            body: Opacity(
              opacity: _bodyPositioned ? 1 : 0,
              child: k.MultiDayBody(
                // Overlapping events lay out side by side in equal-width
                // columns (so two conflicting tiles never paint their titles in
                // the same band and turn unreadable) and every tile gets a
                // minimum height so short events stay legible. See
                // [CalendarEventLayoutStrategy].
                configuration: const k.MultiDayBodyConfiguration(
                  eventLayoutStrategy: CalendarEventLayoutStrategy(),
                  minimumTileHeight: _minimumTileHeight,
                ),
                tileComponents: _tileParts(dense: false),
                // Quarter hours: a drawn or moved event lands on times people
                // book, not on the now line or a ten-minute grid.
                snapping: const k.KalenderSnapping(
                  snapIntervalMinutes: 15,
                  snapToTimeIndicator: false,
                ),
              ),
            ),
          ),
          k.MonthViewParts(
            // Month's header is just the weekday labels — no strip, so no rule
            // under it and nothing to float.
            header: DecoratedBox(
              decoration: BoxDecoration(color: t.bgPrimary),
              child: const k.MonthHeader(),
            ),
            body: k.MonthBody(
              // Order each month day-cell's events by start time. kalender's
              // default frame generator sorts by duration (longest first),
              // which reads as a random order for a stack of same-length
              // meetings.
              configuration: const k.MonthBodyConfiguration(
                multiDayLayoutStrategy: StartSortedMultiDayLayoutStrategy(),
              ),
              tileComponents: _tileParts(dense: true),
            ),
          ),
        ],
      ),
    );
  }

  /// The week/day header: a band that grows with the all-day strip it actually has, hanging
  /// over the timed grid rather than pushing it down.
  /// It reserves [_reservedHeaderHeight] — one strip row, or none for a week without
  /// all-day events — from the layout and paints the rest over the grid, so the hour the
  /// grid opens on never depends on how busy the week's all-day strip is.
  /// The height is derived (see [_allDayRows]), never measured, so it is settled on the frame
  /// the events arrive — no reflow behind the user.
  Widget _allDayHeader(
    DesignSystemTokens t, {
    required double laneHeight,
    required int rows,
    required bool collapsed,
  }) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reserved = _reservedHeaderHeight(rows);
    final target = _headerHeight(laneHeight);
    final header = _calendarHeader(
      t,
      // A collapsed strip shows no tiles at all: every day's events move into
      // the summary row, which is the same "+N more" portal the overflow uses.
      maxRows: collapsed ? 0 : _allDayLaneRows,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: target, end: target),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      // The reservation rides the animation while the band is still shorter
      // than it — a strip appearing in a week that had none slides the grid
      // down with it instead of opening a blank gap under the band first.
      builder: (context, height, child) => CalendarFloatingBand(
        reservedHeight: math.min(height, reserved),
        child: DecoratedBox(
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
          child: CalendarClippedBand(
            height: height,
            alignment: Alignment.topCenter,
            child: child!,
          ),
        ),
      ),
      child: header,
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
  k.KalenderComponents _components(
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
          color: today ? t.bgBrandSolid : const Color(0x00000000),
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

    Widget weekDayHeader(BuildContext _, DateTime date) {
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
        return CalendarClippedBand(
          height: _dayLaneMinHeight,
          alignment: Alignment.center,
          child: header,
        );
      }
      // Week view stacks the day-name row above the all-day events strip, so a
      // rule under each day header reads as the strip's upper edge (its lower
      // edge is the header's bottom border). A week with no strip has only the
      // header's border, and month's grid needs no rule.
      //
      // Pinned to [_dayLabelsHeight] rather than left to its font metrics: the
      // strip's gutter cell offsets itself by that constant to line up with the
      // strip's first row, and a measured block would only line up by accident.
      if (widget.mode == CalendarViewMode.week) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: rows > 0
                ? Border(bottom: BorderSide(color: t.borderSecondary))
                : null,
          ),
          child: SizedBox(height: _dayLabelsHeight, child: header),
        );
      }
      return header;
    }

    Widget monthDayHeader(BuildContext _, DateTime date) {
      return Align(
        alignment: Alignment.topCenter,
        // Only as tall as the badge. kalender caps the header at the row's
        // height and gives the events what is left, so an Align that expanded
        // to that cap took the whole cell: no room for a single tile, or even
        // the "+N more" button, and every month rendered empty.
        heightFactor: 1,
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
      multiDayPortalOverlayButtonBuilder: (_, portalController, hidden) =>
          CalendarOverflowButton(
            portalController: portalController,
            hiddenCount: hidden,
            // In a collapsed strip nothing is shown above this row, so the
            // count is the day's whole tally rather than what is left over.
            summarise: collapsed,
          ),
      multiDayOverlayBuilder:
          (
            _, {
            required date,
            required events,
            required tileHeight,
            required portalController,
            required getMultiDayEventLayoutRenderBox,
            required getOverlayPortalRenderBox,
            required overlayTileBuilder,
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

    return k.KalenderComponents(
      multiDayComponents: k.MultiDayComponents(
        headerComponents: k.MultiDayHeaderComponents(
          dayHeaderBuilder: weekDayHeader,
          // kalender's week-number badge is dropped — the focused week is
          // already named in the screen header — and the slot it leaves, the
          // gutter beside the all-day strip, is where the strip offers its
          // fold. Week view only (day view spends this slot on the day label
          // above), and only while the week has a strip to fold.
          weekNumberBuilder: (_, _) =>
              widget.mode == CalendarViewMode.week && rows > 0
              ? CalendarAllDayGutter(
                  topInset: _dayLabelsHeight,
                  laneHeight: laneHeight,
                  rowHeight: _allDayTileHeight,
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
}
