import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The three modes the message-scroller follow state machine can be in.
///
/// * [following] — pinned to the live edge. New content pushes the viewport
///   forward (the reader is watching the stream arrive).
/// * [anchored] — a specific message has been parked near the top of the
///   viewport (a freshly sent user turn, a permalink target, the first unread
///   message). Growth anywhere is compensated so the reader's view stays fixed;
///   the answer streams into the space below the anchor.
/// * [free] — the reader scrolled away from both the anchor and the live edge
///   (history browsing). Like [anchored], growth is compensated so nothing
///   moves against their intent; re-engaging [following] only happens when they
///   scroll back to the live edge.
enum FeedFollowMode {
  /// Pinned to the live edge: new content pushes the viewport forward.
  following,

  /// A specific message is parked near the top; growth is compensated so the
  /// view stays fixed while the answer streams in below it.
  anchored,

  /// The reader scrolled away from both the anchor and the live edge
  /// (history browsing); growth is compensated so nothing moves against intent.
  free,
}

/// Mutable state shared with [ReverseFollowPhysics] so it can tell bottom-end
/// growth (streaming — compensate) from top-end growth (loading older history
/// — leave alone) and so the feed's state machine can flip between follow,
/// anchor and free without rebuilding the physics.
class FollowState {
  /// Creates a [FollowState]. [now] is injectable for tests.
  FollowState({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Current follow mode. Drives whether growth is compensated (anchored/free)
  /// or followed (following).
  FeedFollowMode mode = FeedFollowMode.following;

  /// The message id the viewport is anchored to (only meaningful in
  /// [FeedFollowMode.anchored]).
  String? anchorMessageId;

  /// Whether older history is currently being loaded (top-end growth).
  bool loadingOlder = false;

  DateTime? _lastUserScrollAt;
  Duration? _lastCompensatedFrame;

  /// Whether growth should be compensated (the reader's position held) rather
  /// than followed. Only [FeedFollowMode.following] tracks the live edge.
  bool get isPinnedFollow => mode == FeedFollowMode.following;

  /// Records a user-driven scroll movement (drag, fling, wheel, trackpad,
  /// scrollbar). While the user is moving the position, `maxScrollExtent`
  /// deltas are dominated by the lazy list re-estimating its extent as rows
  /// with very different heights build and unbuild — not by real content
  /// growth — so compensation must stand down (see [userScrollActive]).
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

  /// Claims the single growth compensation allowed in the current frame.
  ///
  /// A compensation makes the viewport re-run layout, which re-estimates the
  /// list extent, which can change `maxScrollExtent` again — if physics then
  /// compensates again, viewport and physics never reach consensus and the
  /// RenderViewport aborts with "exceeded its maximum number of layout
  /// cycles". Capping at one compensation per frame makes that loop
  /// structurally impossible. Outside a frame (unit tests) the cap is off.
  bool claimCompensationForFrame() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      return true;
    }
    final frame = binding.currentFrameTimeStamp;
    if (_lastCompensatedFrame == frame) {
      return false;
    }
    _lastCompensatedFrame = frame;
    return true;
  }
}

/// How long after the last user-driven scroll movement growth compensation
/// stays suppressed. Long enough to cover the gap between wheel ticks and
/// trackpad momentum events, short enough that a streaming turn is held in
/// place almost immediately after the reader stops scrolling.
const Duration kUserScrollCompensationHold = Duration(milliseconds: 200);

/// Offset below which the reverse list is considered "pinned" to the newest
/// message; at or below it the reader is on the live edge and growth is
/// followed, above it the reader is reading history and growth is compensated.
const double kFollowPinThreshold = 50;

/// Scroll physics for a `reverse: true` message list that keeps the user's
/// reading position fixed when content grows while they're not on the live
/// edge.
///
/// In a reverse list the scroll offset is measured from the bottom, so when the
/// bottom item streams in more content Flutter keeps the numeric offset
/// constant — which visually drags the viewport toward the newest content. When
/// the reader is not in [FeedFollowMode.following] and content grows at the
/// bottom end, we add the growth delta to the offset so the same lines stay
/// put. When on the live edge ([FeedFollowMode.following], offset ~0) we do
/// nothing, so the
/// view keeps following new content. Growth from loading older history (top
/// end) is excluded via [FollowState.loadingOlder].
class ReverseFollowPhysics extends ScrollPhysics {
  /// Creates a [ReverseFollowPhysics].
  const ReverseFollowPhysics({required this.state, super.parent});

  /// Shared follow/loading state.
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
    // Hold the reader's position whenever we are not pinned-following: anchored
    // (a turn parked near the top with the answer streaming in below) and free
    // (browsing history) both keep the viewport fixed so nothing moves against
    // intent.
    //
    // `maxScrollExtent` growth is only trusted as "content grew at the bottom"
    // while the reader is idle: during any user scroll (drag, fling, wheel,
    // trackpad — the latter two never set `isScrolling`/`velocity`) the delta
    // is estimation noise from rows building/unbuilding and compensating
    // against it fights the viewport's own offset corrections.
    if (grew <= 0 ||
        state.isPinnedFollow ||
        state.loadingOlder ||
        isScrolling ||
        velocity != 0 ||
        state.userScrollActive) {
      return base;
    }
    // Loop breaker: at most one compensation per frame, so viewport layout
    // retries always converge (see [FollowState.claimCompensationForFrame]).
    if (!state.claimCompensationForFrame()) {
      return base;
    }
    // Estimation-spike guard. `maxScrollExtent` for a lazily-built list is an
    // ESTIMATE: the extent of off-screen rows is extrapolated from the average
    // height of the built ones. When a very tall row (a long agent transcript)
    // enters or leaves the built set, that estimate can lurch by thousands of
    // pixels of pure noise. Compensating by the raw delta would then shove the
    // offset toward `maxScrollExtent` — which in a reverse list is the OLDEST
    // end — snapping the reader "all the way up".
    //
    // Real content growth at the newest edge within a single frame is bounded
    // by roughly one viewport (a streaming flush appends a little text; even a
    // whole code block is one relayout the reader is looking at). So clamp the
    // compensation to one viewport: legitimate streaming holds exactly, while a
    // noise spike becomes at most a bounded, self-correcting nudge instead of a
    // jump to the top. With an exact-extent list this clamp never binds.
    final compensation = grew.clamp(0.0, newPosition.viewportDimension);
    return (oldPosition.pixels + compensation).clamp(
      newPosition.minScrollExtent,
      newPosition.maxScrollExtent,
    );
  }
}
