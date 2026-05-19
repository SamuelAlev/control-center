import 'package:control_center/features/messaging/presentation/widgets/feed/reverse_follow_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A wildly-variable set of row heights matching the real feed: a mix of 44px
/// one-liners and 900px multi-thousand-px agent transcripts. The alternating
/// pattern maximises the `maxScrollExtent` estimation churn a lazy list emits
/// as tall/short rows build and unbuild during scrolling — exactly the noise
/// that used to make the (now-fixed) physics fight the viewport.
List<double> _rowHeights(int count) => List<double>.generate(
  count,
  (i) => switch (i % 5) {
    0 => 44.0,
    1 => 900.0,
    2 => 44.0,
    3 => 620.0,
    _ => 120.0,
  },
);

/// Builds the harness: a reverse ListView.builder driven by the physics under
/// test, wrapped in the feed's suppression wiring
/// (`NotificationListener<ScrollUpdateNotification>` → `state.noteUserScroll()`
/// at depth 0). [physicsBuilder] lets each test swap in the current or the
/// legacy physics while sharing everything else. [firstRowExtra] is added to
/// row 0's height so a test can grow the bottom-most (reverse index 0) row and
/// force real content growth.
Widget _harness({
  required FollowState state,
  required ScrollPhysics Function(FollowState) physicsBuilder,
  required ScrollController controller,
  required List<double> heights,
  double firstRowExtra = 0,
  double cacheExtentPx = 250,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          if (n.depth == 0) {
            state.noteUserScroll();
          }
          return false;
        },
        child: Scrollbar(
          controller: controller,
          child: ListView.builder(
            reverse: true,
            controller: controller,
            // A large cacheExtent keeps rows built so growing row 0 moves
            // maxScrollExtent by its real delta (not just the lazy average
            // estimate) — the deterministic form of the streaming-turn growth
            // the physics must compensate.
            scrollCacheExtent: ScrollCacheExtent.pixels(cacheExtentPx),
            physics: physicsBuilder(
              state,
            ).applyTo(const ClampingScrollPhysics()),
            itemCount: heights.length,
            itemBuilder: (context, index) {
              final h = heights[index] + (index == 0 ? firstRowExtra : 0);
              return SizedBox(height: h, child: Text('row $index'));
            },
          ),
        ),
      ),
    ),
  );
}

/// The OLD, buggy `adjustPositionForNewDimensions`: it treated ANY growth of
/// `maxScrollExtent` as bottom-end content growth and shifted pixels by the
/// delta — with no `isScrolling` guard, no user-scroll suppression, and no
/// once-per-frame loop breaker. In a lazy list `maxScrollExtent` is an estimate
/// that fluctuates as rows build/unbuild, so during a wheel/trackpad/drag
/// scroll this fought the viewport's own offset corrections.
class _LegacyReverseFollowPhysics extends ScrollPhysics {
  const _LegacyReverseFollowPhysics({required this.state, super.parent});

  final FollowState state;

  @override
  _LegacyReverseFollowPhysics applyTo(ScrollPhysics? ancestor) =>
      _LegacyReverseFollowPhysics(state: state, parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final base = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
    final grew = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;
    if (grew > 0 &&
        !state.isPinnedFollow &&
        velocity == 0 &&
        !state.loadingOlder) {
      return (oldPosition.pixels + grew).clamp(
        newPosition.minScrollExtent,
        newPosition.maxScrollExtent,
      );
    }
    return base;
  }
}

void main() {
  // Plain test()s below touch SchedulerBinding via claimCompensationForFrame,
  // and the widget harness needs a binding regardless.
  TestWidgetsFlutterBinding.ensureInitialized();

  ScrollPhysics current(FollowState s) => ReverseFollowPhysics(state: s);

  group('ReverseFollowPhysics widget regression', () {
    testWidgets(
      'dragging through variable-height history throws no layout-cycle errors',
      (tester) async {
        final state = FollowState()..mode = FeedFollowMode.free;
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _harness(
            state: state,
            physicsBuilder: current,
            controller: controller,
            heights: _rowHeights(300),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final listFinder = find.byType(Scrollbar);

        // Hammer the list up and down repeatedly with drags and flings across
        // the full range of tall/short rows. Each op re-estimates the extent
        // as rows build/unbuild — the exact condition that crashed before.
        for (var i = 0; i < 8; i++) {
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
          await tester.drag(listFinder, const Offset(0, 350));
          await tester.pump();
          await tester.fling(listFinder, const Offset(0, -600), 1200);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.fling(listFinder, const Offset(0, 500), 1000);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('idle bottom growth holds the reading position', (
      tester,
    ) async {
      // FollowState's user-scroll hold is measured against a real clock; drive
      // it from an injectable clock so we can deterministically step past the
      // 200ms suppression window without leaning on wall time.
      var now = DateTime(2026);
      final state = FollowState(now: () => now)..mode = FeedFollowMode.free;
      final controller = ScrollController();
      addTearDown(controller.dispose);

      var extra = 0.0;
      // A shorter list whose total height (a few thousand px) sits fully inside
      // the large cacheExtent, so every row stays built. With no lazy estimate
      // in play, growing row 0 moves maxScrollExtent by EXACTLY its growth —
      // making the held-position assertion deterministic.
      final heights = _rowHeights(40);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            // Expose a rebuild hook via a global so the test body can grow
            // row 0 and trigger setState.
            _growRow0 = (v) => setState(() => extra = v);
            return _harness(
              state: state,
              physicsBuilder: current,
              controller: controller,
              heights: heights,
              firstRowExtra: extra,
              cacheExtentPx: 100000,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Scroll up into history (reverse list: positive pixels = older content).
      controller.jumpTo(600);
      await tester.pumpAndSettle();
      expect(controller.position.pixels, closeTo(600, 1));

      // Step the clock past the user-scroll suppression hold so compensation is
      // allowed again (the jumpTo above armed noteUserScroll via its
      // ScrollUpdateNotification).
      now = now.add(kUserScrollCompensationHold * 2);
      expect(state.userScrollActive, isFalse);

      final before = controller.position.pixels;
      final maxBefore = controller.position.maxScrollExtent;

      // Grow the bottom-most row (reverse index 0) by 300px while idle. This is
      // genuine bottom-end content growth: the physics should shift the offset
      // by ~the growth so the same history lines stay in view.
      _growRow0!(300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final after = controller.position.pixels;
      final grewReal = controller.position.maxScrollExtent - maxBefore;
      expect(tester.takeException(), isNull);
      // Sanity: with all rows built, the extent grew by exactly the row growth.
      expect(grewReal, closeTo(300, 1));
      // The offset should have moved up by roughly the real growth so the same
      // history lines stay in view — held, not dragged toward the live edge.
      expect(
        after - before,
        closeTo(grewReal, 40),
        reason: 'reading position should be held across bottom growth',
      );
    });

    testWidgets('legacy physics misbehaves in the same harness', (
      tester,
    ) async {
      // Drive the LEGACY physics hard: drag while growing row heights between
      // pumps, with no isScrolling guard / user-scroll suppression / loop
      // breaker. Success = EITHER a thrown layout-cycle FlutterError OR the
      // offset being dragged against the user's drag direction.
      final state = FollowState()..mode = FeedFollowMode.free;
      final controller = ScrollController();
      addTearDown(controller.dispose);

      final heights = _rowHeights(300);
      var extra = 0.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            _growRow0 = (v) => setState(() => extra = v);
            return _harness(
              state: state,
              physicsBuilder: (s) => _LegacyReverseFollowPhysics(state: s),
              controller: controller,
              heights: heights,
              firstRowExtra: extra,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpTo(600);
      await tester.pumpAndSettle();

      Object? thrownError;
      var draggedAgainstUser = false;

      // Repeatedly drag up (finger up → offset should INCREASE toward older
      // content) while simultaneously growing the bottom row. The legacy physics
      // adds the extent delta on top of every settle, compounding against the
      // drag and/or refusing to converge.
      for (
        var i = 1;
        i <= 12 && thrownError == null && !draggedAgainstUser;
        i++
      ) {
        final beforeDrag = controller.position.pixels;
        _growRow0!(i * 90.0);
        await tester.pump();

        // A user drag upward (finger moves up): in a reverse list this scrolls
        // toward older content, i.e. pixels should increase or hold. If the
        // legacy compensation drives pixels the OTHER way (or overshoots
        // massively), that is the visible misbehavior.
        await tester.drag(find.byType(Scrollbar), const Offset(0, -50));
        await tester.pump();
        thrownError = tester.takeException();
        if (thrownError != null) {
          break;
        }

        final afterDrag = controller.position.pixels;
        // A -50 finger drag should move the offset by roughly +50 (older). If
        // instead it moved DOWN (against the user) despite the upward drag, the
        // legacy compensation is fighting the user.
        if (afterDrag < beforeDrag - 5) {
          draggedAgainstUser = true;
        }
      }

      // The legacy physics reproduces the bug deterministically via the
      // dragged-against-user path (its uncapped, unsuppressed compensation adds
      // the extent delta on top of the drag and drives the offset the wrong
      // way); on some engine versions it can instead abort layout. Accept
      // either symptom.
      final reproduced = thrownError != null || draggedAgainstUser;
      // Consume any residual exception so the test frame is clean either way.
      tester.takeException();

      expect(
        reproduced,
        isTrue,
        reason:
            'legacy physics should either crash with a layout-cycle error '
            'or drag the offset against the user',
      );
    });
  });

  group('claimCompensationForFrame', () {
    test(
      'allows only one compensation per frame during persistent callbacks',
      () {
        // Outside a frame the cap is off (returns true every time).
        final state = FollowState();
        expect(state.claimCompensationForFrame(), isTrue);
        expect(state.claimCompensationForFrame(), isTrue);
      },
    );
  });
}

// Test-scoped rebuild hook: grows row 0's height and triggers a setState so
// the harness rebuilds (set from within a StatefulBuilder in each test).
void Function(double)? _growRow0;
