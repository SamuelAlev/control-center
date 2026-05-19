import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
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
/// hidden frame: `animateTo` drives the position from there, and an unclamped
/// jump past the end of the day overscroll-springs back within it. The opacity
/// gate means neither is visible, so a check that started at the first visible
/// frame would pass either way; the host should not be overscrolling at all.
///
/// Unlike kalender's stock header, which tweens from a placeholder height and
/// walks `maxScrollExtent` over its first 100ms, the host's all-day lane is a
/// fixed height (see the "fixed all-day lane" group below), so a healthy host
/// holds `pixels` perfectly steady across every sample.
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

  group('CalendarKalenderHost fixed all-day lane', () {
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

    /// The height of the kalender header as laid out in the host.
    double headerHeight(WidgetTester tester) =>
        tester.getSize(find.byType(k.CalendarHeader)).height;

    testWidgets('week header height is identical empty and busy — no layout '
        'shift when events arrive', (tester) async {
      await tester.pumpWidget(testWrap(_host(CalendarViewMode.week)));
      await tester.pumpAndSettle();
      final empty = headerHeight(tester);

      // Five all-day events overlapping the same day: four more rows than the
      // lane shows (cap is 3, the rest collapse behind "+N more").
      final day = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [
              for (var i = 0; i < 5; i++) allDayEvent('e$i', day),
            ],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(headerHeight(tester), empty);
    });

    testWidgets('day header height is identical empty and busy', (tester) async {
      await tester.pumpWidget(testWrap(_host(CalendarViewMode.day)));
      await tester.pumpAndSettle();
      final empty = headerHeight(tester);

      final day = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.day,
            focusedDate: _midMorning,
            events: [for (var i = 0; i < 5; i++) allDayEvent('e$i', day)],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(headerHeight(tester), empty);
    });

    testWidgets('all-day rows beyond the cap collapse behind a "+N more" '
        'button instead of growing the header', (tester) async {
      final day = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [for (var i = 0; i < 5; i++) allDayEvent('e$i', day)],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarOverflowButton), findsWidgets);
    });

    testWidgets('within the cap no overflow button is shown', (tester) async {
      final day = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.week,
            focusedDate: _midMorning,
            events: [for (var i = 0; i < 2; i++) allDayEvent('e$i', day)],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarOverflowButton), findsNothing);
    });

    testWidgets('day-mode gutter label stays vertically centred regardless of '
        'all-day row count', (tester) async {
      // _midMorning is a Wednesday; the gutter shows its weekday name.
      double labelCenterY() => tester.getCenter(find.text('Wed')).dy;

      final day = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.day,
            focusedDate: _midMorning,
            events: [allDayEvent('one', day)],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final quiet = labelCenterY();

      await tester.pumpWidget(
        testWrap(
          CalendarKalenderHost(
            mode: CalendarViewMode.day,
            focusedDate: _midMorning,
            events: [for (var i = 0; i < 5; i++) allDayEvent('e$i', day)],
            now: _midMorning,
            onOpenEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(labelCenterY(), quiet);
    });
  });
}
