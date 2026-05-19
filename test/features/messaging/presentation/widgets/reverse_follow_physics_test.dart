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
  group('ReverseFollowPhysics.adjustPositionForNewDimensions', () {
    test('compensates bottom growth while unpinned (keeps reading position)', () {
      final physics = ReverseFollowPhysics(state: FollowState());
      // User scrolled up to offset 200; content grows by 120 at the bottom.
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 320); // 200 + 120 → same lines stay in view
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
      final state = FollowState()..loadingOlder = true;
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
      final physics = ReverseFollowPhysics(state: FollowState());
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1120),
        isScrolling: true,
        velocity: 600,
      );
      expect(result, 200);
    });

    test('no-op when content does not grow', () {
      final physics = ReverseFollowPhysics(state: FollowState());
      final result = physics.adjustPositionForNewDimensions(
        oldPosition: _metrics(pixels: 200, max: 1000),
        newPosition: _metrics(pixels: 200, max: 1000),
        isScrolling: false,
        velocity: 0,
      );
      expect(result, 200);
    });
  });
}
