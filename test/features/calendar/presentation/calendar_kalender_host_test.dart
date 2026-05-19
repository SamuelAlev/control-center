import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_all_day_gutter.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_kalender_host.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_overflow_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender/kalender.dart' as k;

import '../../../helpers/test_wrap.dart';

/// Mid-morning, so centring "now" is a real jump well inside the scroll extents.
/// Pinned rather than taken from the clock: late in the day the centred target
/// clamps to the bottom — as does the offset kalender itself opens on — and the
/// positioning under test collapses into a no-op that asserts nothing.
final _midMorning = DateTime(2026, 3, 4, 9, 30);

/// Late evening, where centring "now" would run past the end of the day, so the
/// target is clamped to [ScrollPosition.maxScrollExtent].
final _lateEvening = DateTime(2026, 3, 4, 23, 40);

Widget _host(CalendarViewMode mode, {DateTime? now}) {
  final reference = now ?? _midMorning;
  return CalendarKalenderHost(
    mode: mode,
    focusedDate: reference,
    events: const [],
    now: reference,
    onOpenEvent: (_) {},
  );
}

/// The vertical scroll position of the timed (week / day) body.
ScrollPosition _bodyPosition(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(k.MultiDayBody.singleChildScrollViewKey),
  );
  return scrollView.controller!.position;
}

/// The opacity of the wrapper the host puts around the timed body.
double _bodyOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byType(k.CalendarBody),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;
}

/// Pumps frames until the host reveals the timed body, returning the scroll
/// offset of that first visible frame. The exact frame count is pinned by its
/// own test below; the tests that care about the resting offset shouldn't also
/// restate it.
Future<double> _pumpUntilBodyVisible(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    if (_bodyOpacity(tester) == 1) {
      return _bodyPosition(tester).pixels;
    }
    await tester.pump();
  }
  fail('the timed body was never revealed');
}

/// Asserts the timed body places itself with one settled jump and then leaves the
/// scroll position alone: never under a scroll activity, never out of range.
///
/// Sampling starts at the frame `pumpWidget` painted — before the body is
/// revealed — on purpose. Both failure modes this guards against happen on that
/// hidden frame: `animateTo` drives the position from there and an unclamped
/// jump past the end of the day overscroll-springs back within it. The opacity
/// gate means neither is visible, so a check that started at the first visible
/// frame would pass either way; the host should not be overscrolling at all.
///
/// Unlike kalender's stock header, which tweens from a placeholder height and
/// walks `maxScrollExtent` over its first 100ms, the host derives the all-day
/// strip's height from the events themselves (see the "all-day strip" group
/// below), so on a settled week a healthy host holds `pixels` perfectly steady
/// across every sample.
Future<void> _expectNeverScrolls(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    final position = _bodyPosition(tester);
    expect(
      position.activity!.isScrolling,
      isFalse,
      reason: 'the body was scrolling on frame $frame',
    );
    expect(
      position.pixels,
      lessThanOrEqualTo(position.maxScrollExtent),
      reason: 'the body overscrolled past the end of the day on frame $frame',
    );
    expect(
      position.pixels,
      greaterThanOrEqualTo(position.minScrollExtent),
      reason: 'the body overscrolled past the start of the day on frame $frame',
    );
    // Stepped rather than settled in one go: pumpAndSettle would run the header
    // tween to completion between samples and miss an activity that only exists
    // mid-flight.
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
}

void main() {
  group('CalendarKalenderHost initial scroll', () {
    testWidgets('week view rests at the now-centred offset on its first '
        'visible frame', (tester) async {
      await tester.pumpWidget(testWrap(_host(CalendarViewMode.week)));
      final revealedAt = await _pumpUntilBodyVisible(tester);
      final position = _bodyPosition(tester);

      // Derive the zoom from the laid-out extents rather than restating the
      // host's private constant: the body is exactly one day tall.
      final contentHeight =
          position.maxScrollExtent + position.viewportDimension;
      final heightPerMinute = contentHeight / Duration.minutesPerDay;
      final nowOffset =
          (_midMorning.hour * 60 + _midMorning.minute) * heightPerMinute;
      final expected = nowOffset - position.viewportDimension / 2;

      expect(revealedAt, moreOrLessEquals(expected, epsilon: 0.5));
      // Mid-morning the centred target is genuinely interior, so this test would
      // still fail if the positioning stopped happening at all — unlike late in
      // the day, where it and kalender's own opening offset both clamp to the
      // bottom and any jump becomes unobservable.
      expect(revealedAt, greaterThan(position.minScrollExtent));
      expect(revealedAt, lessThan(position.maxScrollExtent));
    });

    testWidgets('week view rests at the bottom rather than overscrolling late '
        'in the day', (tester) async {
      await tester.pumpWidget(
        testWrap(_host(CalendarViewMode.week, now: _lateEvening)),
      );
      final revealedAt = await _pumpUntilBodyVisible(tester);
      final position = _bodyPosition(tester);

      // Centring 23:40 would need to scroll past midnight, so the clamp takes
      // over: the day's end sits at the bottom of the viewport and the
      // now-indicator rides above centre.
      expect(revealedAt, position.maxScrollExtent);
    });

    testWidgets('week view never scrolls itself, mid-morning', (tester) async {
      await tester.pumpWidget(testWrap(_host(CalendarViewMode.week)));
      await _expectNeverScrolls(tester);
    });

    testWidgets('week view never scrolls itself late in the day, where the '
        'uncentrable target is clamped away', (tester) async {
      await tester.pumpWidget(
        testWrap(_host(CalendarViewMode.week, now: _lateEvening)),
      );
      await _expectNeverScrolls(tester);
    });

    testWidgets('timed body is revealed only once it has been positioned', (
      tester,
    ) async {
      await tester.pumpWidget(testWrap(_host(CalendarViewMode.week)));
      // The frame pumpWidget painted is the one kalender's initial (uncentred)
      // offset is visible in, so the body is transparent for it.
      expect(_bodyOpacity(tester), 0);

      await tester.pump();
      expect(_bodyOpacity(tester), 1);
    });

    testWidgets(
      'month view has no timed body to position and is never hidden',
      (tester) async {
        await tester.pumpWidget(testWrap(_host(CalendarViewMode.month)));
        expect(_bodyOpacity(tester), 1);
      },
    );
  });

  group('CalendarKalenderHost all-day strip', () {
    CalendarEvent allDayEvent(String id, DateTime day, {int days = 1}) {
      return CalendarEvent(
        id: id,
        workspaceId: 'ws',
        accountId: 'acc',
        externalEventId: 'ext-$id',
        calendarId: 'primary',
        title: 'Event $id',
        startTime: day,
        endTime: day.add(Duration(days: days)),
        updatedAt: day,
        isAllDay: true,
      );
    }

    Widget hostWith(CalendarViewMode mode, List<CalendarEvent> events) {
      return testWrap(
        CalendarKalenderHost(
          mode: mode,
          focusedDate: _midMorning,
          events: events,
          now: _midMorning,
          onOpenEvent: (_) {},
        ),
      );
    }

    /// Where the timed grid starts — how much the header takes from it.
    ///
    /// The whole point of the band is that this number is a constant, so it is
    /// the one every height test is written against.
    double gridTop(WidgetTester tester) =>
        tester.getTopLeft(find.byType(k.CalendarBody)).dy -
        tester.getTopLeft(find.byType(CalendarKalenderHost)).dy;

    /// The height the all-day band actually paints at, overhang included.
    ///
    /// Read off the gutter cell, which spans the day labels plus the strip —
    /// `CalendarHeader`'s own size is kalender's opinion of the header, not the
    /// host's, and the band the host paints is clipped to the latter.
    double bandHeight(WidgetTester tester) =>
        tester.getSize(find.byType(CalendarAllDayGutter)).height;

    /// A Wednesday, inside the week [_midMorning] falls in.
    final day = DateTime(2026, 3, 4);

    testWidgets('the week band is one row tall with nothing in it', (
      tester,
    ) async {
      await tester.pumpWidget(hostWith(CalendarViewMode.week, const []));
      await tester.pumpAndSettle();

      // Day labels (56) + a single 24px row. The strip is a labelled band, not
      // a block of reserved space the events may or may not grow into.
      expect(bandHeight(tester), 80);
      expect(gridTop(tester), 80);
    });

    testWidgets('the week band grows one row per stacked event and stops at '
        'the cap', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [allDayEvent('one', day)]),
      );
      await tester.pumpAndSettle();
      expect(bandHeight(tester), 80, reason: 'one row');

      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 2; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();
      expect(bandHeight(tester), 104, reason: 'two rows');

      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 3; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();
      expect(bandHeight(tester), 128, reason: 'three rows, the cap');

      // Past the cap the band stops growing: the remainder moves into the 20px
      // overflow row.
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 6; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();
      expect(bandHeight(tester), 148, reason: 'capped, plus the "+N more" row');
    });

    testWidgets('the timed grid stays put however tall the band grows — it '
        'hangs over the grid rather than pushing it down', (tester) async {
      await tester.pumpWidget(hostWith(CalendarViewMode.week, const []));
      await tester.pumpAndSettle();
      final resting = gridTop(tester);

      for (final count in [1, 2, 3, 6]) {
        await tester.pumpWidget(
          hostWith(CalendarViewMode.week, [
            for (var i = 0; i < count; i++) allDayEvent('e$i', day),
          ]),
        );
        await tester.pumpAndSettle();
        expect(
          gridTop(tester),
          resting,
          reason: 'the grid moved with $count all-day events',
        );
        // ...and the band really is overhanging, not silently capped to the
        // reserved height — otherwise this test would pass on a band that
        // simply stopped growing.
        expect(bandHeight(tester), greaterThanOrEqualTo(resting));
      }
    });

    testWidgets('a tile in the overhang is still tappable — the press does not '
        'fall through the band into the grid', (tester) async {
      CalendarEvent? opened;
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [for (var i = 0; i < 3; i++) allDayEvent('e$i', day)],
            now: _midMorning,
            onOpenEvent: (event) => opened = event,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The band paints below the height it reports, and `RenderBox.hitTest`
      // rejects anything outside a box's reported size — so without the
      // override in the host, this row would be visible and dead.
      final lowest = [for (var i = 0; i < 3; i++) find.text('Event e$i')]
          .map((finder) => (finder, tester.getRect(finder)))
          .reduce((a, b) => a.$2.bottom > b.$2.bottom ? a : b);
      expect(
        lowest.$2.top,
        greaterThan(gridTop(tester)),
        reason: 'that row is not actually in the overhang',
      );

      await tester.tap(lowest.$1);
      await tester.pumpAndSettle();

      expect(opened, isNotNull);
    });

    testWidgets('the overhang leaves 01:00 clear, so the band never buries a '
        'whole hour of the grid', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 6; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();

      // At the tallest the band can get, the grid it covers has to stop short
      // of an hour (72px at this zoom) — the first hour line stays visible
      // without folding the band away.
      expect(bandHeight(tester) - gridTop(tester), lessThan(72));
    });

    testWidgets('events on different days share a row rather than stacking', (
      tester,
    ) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          allDayEvent('mon', DateTime(2026, 3, 2)),
          allDayEvent('wed', day),
          allDayEvent('fri', DateTime(2026, 3, 6)),
        ]),
      );
      await tester.pumpAndSettle();

      // Three events, but none of them overlap, so the strip needs one row —
      // the height has to come from the packing, not from a count.
      expect(bandHeight(tester), 80);
    });

    testWidgets('all-day rows beyond the cap collapse behind a "+N more" '
        'button instead of growing the header', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 5; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarOverflowButton), findsWidgets);
    });

    testWidgets('within the cap no overflow button is shown', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 2; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarOverflowButton), findsNothing);
    });

    testWidgets('the gutter cell sits on the strip\'s first row, not on the '
        'day labels above it', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [allDayEvent('one', day)]),
      );
      await tester.pumpAndSettle();

      // kalender lays the gutter out beside the WHOLE header, day labels
      // included, so the cell has to offset itself past them by a height it was
      // told rather than one it can see. If that constant and the day-labels
      // block ever drift apart, the label floats off its row — which is
      // invisible in a screenshot of an empty week and obvious next to a tile.
      final toggle = tester.getRect(
        find.bySemanticsLabel('Collapse all-day events').first,
      );
      final tile = tester.getRect(find.text('Event one'));
      expect(toggle.center.dy, greaterThan(tile.top - 12));
      expect(toggle.center.dy, lessThan(tile.bottom + 12));
    });

    testWidgets('the gutter labels an empty strip and offers no fold', (
      tester,
    ) async {
      await tester.pumpWidget(hostWith(CalendarViewMode.week, const []));
      await tester.pumpAndSettle();

      expect(find.text('All-day'), findsOneWidget);
      expect(find.bySemanticsLabel('Collapse all-day events'), findsNothing);
    });

    testWidgets('the gutter folds a populated strip down to a per-day summary '
        'and back', (tester) async {
      await tester.pumpWidget(
        hostWith(CalendarViewMode.week, [
          for (var i = 0; i < 2; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();
      expect(bandHeight(tester), 104);
      // The label gives way to the fold control once there is something to fold.
      expect(find.text('All-day'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Collapse all-day events'));
      await tester.pumpAndSettle();

      // Folded: back to one row, with every event of the day behind a summary
      // that counts them all rather than counting what is left over.
      expect(bandHeight(tester), 80);
      expect(find.text('2 events'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Expand all-day events'));
      await tester.pumpAndSettle();

      expect(bandHeight(tester), 104);
      expect(find.text('2 events'), findsNothing);
    });

    testWidgets('day view hangs its extra rows over the grid too', (
      tester,
    ) async {
      await tester.pumpWidget(hostWith(CalendarViewMode.day, const []));
      await tester.pumpAndSettle();
      // Day view spends its gutter on the date instead of the fold control, so
      // its resting band is the height that block needs beside the strip.
      expect(gridTop(tester), 56);

      await tester.pumpWidget(
        hostWith(CalendarViewMode.day, [
          for (var i = 0; i < 3; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();

      expect(gridTop(tester), 56, reason: 'the grid moved');
      // Three rows do not fit in 56px, so the lowest one is painted over the
      // grid rather than having pushed it down.
      final lowestRow = [
        for (var i = 0; i < 3; i++)
          tester.getRect(find.text('Event e$i')).bottom,
      ].reduce((a, b) => a > b ? a : b);
      expect(lowestRow, greaterThan(gridTop(tester)));
    });

    testWidgets('day-mode gutter date stays put as rows arrive', (
      tester,
    ) async {
      // _midMorning is a Wednesday; the gutter shows its weekday name. The date
      // rides the band's resting height, not its painted one, so rows arriving
      // never walk it down the screen.
      double labelCenterY() => tester.getCenter(find.text('Wed')).dy;

      await tester.pumpWidget(
        hostWith(CalendarViewMode.day, [allDayEvent('one', day)]),
      );
      await tester.pumpAndSettle();
      final quiet = labelCenterY();

      await tester.pumpWidget(
        hostWith(CalendarViewMode.day, [
          for (var i = 0; i < 5; i++) allDayEvent('e$i', day),
        ]),
      );
      await tester.pumpAndSettle();

      expect(labelCenterY(), quiet);
    });
  });

  group('CalendarKalenderHost all-day tiles', () {
    /// A timed event long enough to land in the all-day strip (kalender's rule
    /// is 24 hours or longer), running from the Monday *before* the week under
    /// test through to its Thursday.
    CalendarEvent spanning({required DateTime start, required DateTime end}) {
      return CalendarEvent(
        id: 'span',
        workspaceId: 'ws',
        accountId: 'acc',
        externalEventId: 'ext-span',
        calendarId: 'primary',
        title: 'Out of office',
        startTime: start,
        endTime: end,
        updatedAt: start,
      );
    }

    testWidgets('a bar that starts inside the week carries its start time', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [
              spanning(
                start: DateTime(2026, 3, 3, 9),
                end: DateTime(2026, 3, 5, 17),
              ),
            ],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
    });

    testWidgets('a bar continuing from an earlier week carries no time — the '
        'week it is clipped to is not the day it started', (tester) async {
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [
              // Starts the previous Thursday, so the bar drawn on this week
              // begins on Monday at 00:00 — a time the event never had.
              spanning(
                start: DateTime(2026, 2, 26, 9),
                end: DateTime(2026, 3, 5, 17),
              ),
            ],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Out of office'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
      expect(find.text('09:00'), findsNothing);
    });
  });
}
