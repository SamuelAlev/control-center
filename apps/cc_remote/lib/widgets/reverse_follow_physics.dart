import 'package:flutter/widgets.dart';

/// The three modes the message-scroller follow state machine can be in.
enum FollowMode { following, anchored, free }

/// Mutable state shared with [ReverseFollowPhysics]. On mobile (cc_remote) the
/// client only ever sees whole-message snapshots over RPC — there is no token
/// stream — so growth is at the message (not token) granularity.
class FollowState {
  /// Current follow mode.
  FollowMode mode = FollowMode.following;

  /// The message id the viewport is anchored to (only meaningful in
  /// [FollowMode.anchored]).
  String? anchorMessageId;

  /// Whether growth should be compensated (anchored/free) rather than followed
  /// (following, on the live edge).
  bool get isPinnedFollow => mode == FollowMode.following;
}

/// Offset below which the reverse list is considered pinned to the newest
/// message (the live edge).
const double kFollowPinThreshold = 50;

/// Scroll physics for a `reverse: true` message list that keeps the reader's
/// position fixed when content grows while they're not on the live edge. See
/// the desktop `ReverseFollowPhysics` for the full rationale; this is a slim
/// duplicate for cc_remote's separate dependency graph.
class ReverseFollowPhysics extends ScrollPhysics {
  /// Creates a [ReverseFollowPhysics].
  const ReverseFollowPhysics({required this.state, super.parent});

  /// Shared follow state.
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
    if (grew > 0 && !state.isPinnedFollow && velocity == 0) {
      return (oldPosition.pixels + grew).clamp(
        newPosition.minScrollExtent,
        newPosition.maxScrollExtent,
      );
    }
    return base;
  }
}
