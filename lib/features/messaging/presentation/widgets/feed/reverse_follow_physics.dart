import 'package:flutter/widgets.dart';

/// Mutable flag shared with [ReverseFollowPhysics] so it can tell bottom-end
/// growth (streaming — compensate) from top-end growth (loading older history —
/// leave alone).
class FollowState {
  /// Whether older history is currently being loaded (top-end growth).
  bool loadingOlder = false;
}

/// Offset below which the reverse list is considered "pinned" to the newest
/// message; above it the user is reading history and growth is compensated.
const double kFollowPinThreshold = 50;

/// Scroll physics for a `reverse: true` message list that keeps the user's
/// reading position fixed when the newest (bottom) message grows while they're
/// scrolled up.
///
/// In a reverse list the scroll offset is measured from the bottom, so when the
/// bottom item streams in more content Flutter keeps the numeric offset
/// constant — which visually drags the viewport toward the newest content. When
/// the user is scrolled up (unpinned) and content grows at the bottom end, we
/// add the growth delta to the offset so the same lines stay put. When pinned
/// to the bottom (offset ~0) we do nothing, so the view keeps following new
/// content. Growth from loading older history (top end) is excluded via
/// [FollowState.loadingOlder].
class ReverseFollowPhysics extends ScrollPhysics {
  /// Creates a [ReverseFollowPhysics].
  const ReverseFollowPhysics({required this.state, super.parent});

  /// Shared streaming/loading flag.
  final FollowState state;

  @override
  ReverseFollowPhysics applyTo(ScrollPhysics? ancestor) =>
      ReverseFollowPhysics(state: state, parent: buildParent(ancestor));

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
    final unpinned = oldPosition.pixels > kFollowPinThreshold;
    if (grew > 0 && unpinned && velocity == 0 && !state.loadingOlder) {
      return (oldPosition.pixels + grew).clamp(
        newPosition.minScrollExtent,
        newPosition.maxScrollExtent,
      );
    }
    return base;
  }
}
