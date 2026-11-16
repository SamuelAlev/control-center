import 'package:flutter/widgets.dart';

/// The three modes the message-scroller follow state machine can be in.
///
/// * [following] — pinned to the live edge. New content pushes the viewport
///   forward (the reader is watching the stream arrive).
/// * [anchored] — a specific message was parked near the top of the viewport
///   (a permalink target, a freshly sent turn). The reader's place is held
///   while the answer streams in below it.
/// * [free] — the reader scrolled away from the live edge (history browsing).
///   The reader's place is held exactly like [anchored]; re-engaging
///   [following] only happens when they scroll back to the live edge.
enum FeedFollowMode {
  /// Pinned to the live edge: new content pushes the viewport forward.
  following,

  /// A specific message is parked near the top; the reader's place is held.
  anchored,

  /// The reader scrolled away from the live edge; their place is held.
  free,
}

/// Answers where the row identified by a row key currently ends, as a scroll
/// offset inside the list sliver (for the reverse feed: the row's top edge),
/// or null when that row is not laid out.
typedef FeedAnchorProbe = double? Function(String rowKey);

/// Where the reader is, as Delta stores it: a row identity plus that row's
/// position, captured at the end of a frame.
///
/// `trailingEdge` is the row's far edge in list coordinates and `pixels` the
/// scroll offset in the same frame, so `trailingEdge - pixels` is how far the
/// row's top sits from the viewport's bottom. Holding that difference is
/// holding the reader's place.
typedef FeedScrollAnchor = ({
  String rowKey,
  double trailingEdge,
  double pixels,
});

/// State shared between the feed and [AnchorFollowPhysics].
///
/// The feed records a [FeedScrollAnchor] after each frame and supplies a
/// [probe] that resolves a row key to its current geometry; the physics uses
/// both to keep that row where it was whenever the content around it changes.
class FollowState {
  /// Creates a [FollowState]. [now] is injectable for tests.
  FollowState({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Current follow mode. Only [FeedFollowMode.following] tracks the live
  /// edge; the other two hold the reader's place.
  FeedFollowMode mode = FeedFollowMode.following;

  /// The reader's place at the end of the last recorded frame.
  FeedScrollAnchor? anchor;

  /// Resolves a row key to its current trailing edge. Installed by the feed.
  FeedAnchorProbe? probe;

  DateTime? _lastUserScrollAt;

  /// Whether the viewport follows the live edge rather than holding a place.
  bool get isPinnedFollow => mode == FeedFollowMode.following;

  /// Records a user-driven scroll movement (drag, fling, wheel, trackpad,
  /// scrollbar). While the user drives the position the anchor is theirs to
  /// move, so the physics stands down (see [userScrollActive]).
  void noteUserScroll() => _lastUserScrollAt = _now();

  /// Whether a user scroll movement happened within
  /// [kUserScrollCompensationHold]. Wheel and trackpad scrolls never present
  /// as a scrolling activity (`isScrolling` stays false, `velocity` stays 0),
  /// so this notification-driven signal is the only reliable way to know the
  /// user is driving the position on desktop.
  bool get userScrollActive {
    final t = _lastUserScrollAt;
    return t != null && _now().difference(t) < kUserScrollCompensationHold;
  }

  /// The scroll offset that puts the anchored row back where it was, or null
  /// when there is no anchor or its row is not laid out.
  ///
  /// The correction is residual, not cumulative: it is computed from where the
  /// row is now, so a correction the list already applied itself (the lazy
  /// list fixes up the offset when it measures rows before the viewport) is
  /// not applied twice, and calling this again after the viewport re-runs
  /// layout yields the same answer.
  double? heldPixels() {
    final anchor = this.anchor;
    final probe = this.probe;
    if (anchor == null || probe == null) {
      return null;
    }
    final edge = probe(anchor.rowKey);
    if (edge == null) {
      return null;
    }
    return anchor.pixels + (edge - anchor.trailingEdge);
  }
}

/// How long after the last user-driven scroll movement the anchor stays
/// released. Long enough to cover the gap between wheel ticks and trackpad
/// momentum events, short enough that a streaming turn is held in place almost
/// immediately after the reader stops scrolling.
const Duration kUserScrollCompensationHold = Duration(milliseconds: 200);

/// Offset below which the reverse list is considered "pinned" to the newest
/// message; at or below it the reader is on the live edge and growth is
/// followed, above it the reader is reading history and their place is held.
const double kFollowPinThreshold = 50;

/// Scroll physics for the `reverse: true` feed that holds the reader's place
/// by row identity instead of by pixel arithmetic.
///
/// A reverse list measures its offset from the bottom, and Flutter keeps that
/// number fixed when rows change size, so the lines above a change slide. The
/// old physics answered by adding the change in `maxScrollExtent` to the
/// offset. That number mixes real growth below the viewport with re-estimated
/// extents of rows nobody is looking at (older rows the idle measurement just
/// built), so it needed a stack of guards and still nudged the reader.
///
/// This physics asks where the anchored row is now and moves the offset by
/// exactly how far that row moved. Rows that change size above the anchor (in
/// a reverse list: older rows) do not move it, so they cause no correction at
/// all; rows that change size below it (newer rows, a streaming answer, a tool
/// body opening) move it, and the offset follows. On the live edge
/// ([FeedFollowMode.following]) nothing is held, so the view keeps following
/// new content.
class AnchorFollowPhysics extends ScrollPhysics {
  /// Creates an [AnchorFollowPhysics].
  const AnchorFollowPhysics({required this.state, super.parent});

  /// Shared follow/anchor state.
  final FollowState state;

  @override
  AnchorFollowPhysics applyTo(ScrollPhysics? ancestor) =>
      AnchorFollowPhysics(state: state, parent: buildParent(ancestor));

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
    // While the user drives the position (drag, fling, wheel, trackpad — the
    // latter two never set `isScrolling`/`velocity`), the place is theirs.
    if (state.isPinnedFollow ||
        isScrolling ||
        velocity != 0 ||
        state.userScrollActive) {
      return base;
    }
    final held = state.heldPixels();
    if (held == null) {
      return base;
    }
    return held.clamp(newPosition.minScrollExtent, newPosition.maxScrollExtent);
  }
}
