import 'package:control_center/features/messaging/presentation/widgets/feed/reverse_follow_physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

ScrollMetrics _metrics({required double pixels, required double max}) =>
    FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: max,
      pixels: pixels,
      viewportDimension: 500,
      axisDirection: AxisDirection.up,
      devicePixelRatio: 2,
    );

void main() {
  // The physics consults SchedulerBinding for its once-per-frame cap.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReverseFollowPhysics.adjustPositionForNewDimensions', () {
    test('compensates bottom growth in free mode (keeps reading position)', () {
      final state = FollowState()..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      // User scrolled up to offset 200; content grows by 120 at the bottom.
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 320); // 200 + 120 → same lines stay in view
    });

    test(
      'compensates bottom growth in anchored mode (answer streams below)',
      () {
        final state = FollowState()..mode = FeedFollowMode.anchored;
        final physics = ReverseFollowPhysics(state: state);
        final result = physics.adjustPositionForNewDimensions(
          oldPosition: _metrics(pixels: 200, max: 1000),
          newPosition: _metrics(pixels: 200, max: 1120),
          isScrolling: false,
          velocity: 0,
        );
        expect(result, 320);
      },
    );

    test('follows bottom growth in following mode (stays on the live edge)', () {
      // Even when scrolled up (offset 200), following stays pinned: the base
      // value keeps the offset, letting new content push the viewport forward.
      final physics = ReverseFollowPhysics(state: FollowState());
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 200); // base: not compensated
    });

    test('does not compensate when pinned to bottom (keeps following)', () {
      final physics = ReverseFollowPhysics(state: FollowState());
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 0, max: 1000),
        newPosition: _metrics(pixels: 0, max: 1120),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 0); // stays pinned at the newest message
    });

    test('does not compensate while loading older history (top growth)', () {
      final state = FollowState()
        ..mode = FeedFollowMode.free
        ..loadingOlder = true;
      final physics = ReverseFollowPhysics(state: state);
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 800, max: 1000),
        newPosition: _metrics(pixels: 800, max: 1400),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 800); // top-end growth: leave the offset alone
    });

    test('does not compensate during an active fling', () {
      final state = FollowState()..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: true,
        velocity: 600,
      );
      expect(result, 200);
    });

    test('does not compensate during an active drag (velocity 0)', () {
      final state = FollowState()..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      // A drag activity reports isScrolling=true with velocity 0; extent
      // deltas during a drag are lazy-list re-estimation, not content growth.
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: true,
        velocity: 0,
      );
      expect(result, 200);
    });

    test('suppresses compensation while a user scroll is active, resumes '
        'after the hold expires', () {
      var now = DateTime(2026);
      final state = FollowState(now: () => now)..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      double adjust() => physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: false,
        velocity: 0,
      );

      // Wheel/trackpad scrolls never present as a scrolling activity — the
      // feed reports them via noteUserScroll instead.
      state.noteUserScroll();
      expect(adjust(), 200, reason: 'suppressed right after a user scroll');

      now = now.add(kUserScrollCompensationHold ~/ 2);
      expect(adjust(), 200, reason: 'still inside the hold window');

      now = now.add(kUserScrollCompensationHold);
      expect(adjust(), 320, reason: 'hold expired: growth is compensated');
    });

    test('clamps a huge estimation spike to one viewport (no jump to top)', () {
      // A tall row entering the built set inflates the ESTIMATED maxScrollExtent
      // by thousands of px of noise. Compensating by the raw delta would shove
      // the offset toward maxScrollExtent (the oldest end in a reverse list) —
      // the "all the way up" jump. The clamp caps it at one viewport.
      final state = FollowState()..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 9000), // +8000 estimation spike
        isScrolling: false,
        velocity: 0,
      );
      // 200 + min(8000, viewport 500) = 700, NOT 8200/clamped-to-9000.
      expect(result, 700);
    });

    test('no-op when content does not grow', () {
      final state = FollowState()..mode = FeedFollowMode.free;
      final physics = ReverseFollowPhysics(state: state);
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1000),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 200);
    });
  });

  group('FollowState', () {
    test('defaults to following', () {
      expect(FollowState().mode, FeedFollowMode.following);
      expect(FollowState().isPinnedFollow, isTrue);
    });

    test('anchored and free are not pinned-follow', () {
      expect(
        (FollowState()..mode = FeedFollowMode.anchored).isPinnedFollow,
        isFalse,
      );
      expect(
        (FollowState()..mode = FeedFollowMode.free).isPinnedFollow,
        isFalse,
      );
    });
  });
}
