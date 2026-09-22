import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionScope;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/day_separator.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_helpers.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/jump_to_latest.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/reverse_follow_physics.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/row_extent_estimate.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/unread_divider.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

part 'message_feed_build.dart';
part 'message_feed_navigation.dart';
part 'message_feed_scrolling.dart';

/// How far below the viewport top a freshly anchored turn lands, leaving the
/// previous turn peeking into view so the reader keeps the prior context.
const double kPreviousTurnPeek = 64;
const double _bottomThreshold = kFollowPinThreshold;
const double _loadMoreThreshold = 400;

/// How long the feed must be still — no window emission, no scroll — before it
/// starts measuring row extents.
const Duration _precalcIdleDelay = Duration(milliseconds: 700);

/// Scrollable feed of space messages — windowed (newest-N + load-older),
/// rendered bottom-up via a reverse list so follow-bottom and streaming growth
/// stay anchored without scroll jumps.
///
/// Follow behavior implements the message-scroller model: new turns settle
/// near the top of the viewport (anchored mode), the live edge is only
/// followed while the reader is on it and any interaction releases following.
///
/// Opening the chat — and returning to it after the pane was hidden — lands on
/// the live edge instantly: no scroll animation, no anchor hunt, the newest
/// message on screen. The unread divider still marks where the reader left off,
/// up in the scrollback, but it is never scrolled to.
class SpaceMessageFeed extends ConsumerStatefulWidget {
  /// Creates a new [SpaceMessageFeed].
  const SpaceMessageFeed({
    super.key,
    required this.spaceId,
    required this.conversationId,
    this.onStartThread,
    this.onOpenThread,
  });

  /// Space to display messages for.
  final String spaceId;

  /// The conversation (stream) inside the space to display.
  final String conversationId;

  /// "Start thread" affordance on text messages: opens a conversation
  /// anchored to the hovered message. Null hides the affordance.
  final void Function(Message message)? onStartThread;

  /// Opens an existing thread from the "N replies" row under its anchor
  /// message. Null hides that row.
  final void Function(String threadId)? onOpenThread;

  @override
  ConsumerState<SpaceMessageFeed> createState() => _SpaceMessageFeedState();
}

class _SpaceMessageFeedState extends ConsumerState<SpaceMessageFeed> {
  void _set(VoidCallback fn) => setState(fn);

  final _scrollController = ScrollController();
  final _follow = FollowState();
  final _rowKeys = <String, GlobalKey>{};

  /// Bubble widgets reused when a window emission changes some other row.
  ///
  /// The list builder runs again for every visible index. Returning the same
  /// widget instance is what lets the element skip the update, so a streaming
  /// turn does not re-parse every other bubble in the window.
  final _keptRows = <String, _KeptFeedRow>{};

  /// List extent queries and offscreen-row reveals for deep anchors.
  final _listController = ListController();

  /// Refines row extents once the feed is idle, bounded to
  /// [kFeedPrecalcRowBudget] rows. Armed by [_deferPrecalculation].
  final _precalcPolicy = IdlePrecalculationPolicy();

  /// Re-arms [_precalcPolicy] once nothing has moved for
  /// [_precalcIdleDelay].
  Timer? _precalcTimer;

  /// The current display rows (ascending, oldest→newest), mirrored from the
  /// last build so the anchor path can map a message id to its reverse
  /// [SuperListView] index without the build closure in scope.
  List<FeedItem> _items = const [];

  bool _didInitialLanding = false;
  bool _cursorSnapshotTaken = false;
  String? _lastNewestId;

  /// Creation time of [_lastNewestId], so reaching the live edge can advance the
  /// divider cutoff to "everything currently here" without re-deriving it from
  /// the window.
  DateTime? _lastNewestAt;
  int _lastItemCount = 0;

  /// Snapshot of the last window emission, rendered while the pane is hidden
  /// (all live watches dropped) and, on reveal, until the first fresh
  /// emission — so the tree never collapses to a spinner across a hide/show.
  ({List<Message> messages, bool hasMore})? _frozenWindow;

  /// Whether the pane was visible on the previous build (IndexedStack tab).
  bool _wasVisible = true;

  /// Set on hidden→visible; consumed by [_onWindowChanged] so the first fresh
  /// window after a hidden spell is not mistaken for content the reader
  /// witnessed arriving.
  bool _pendingRevealReconcile = false;
  int _newWhileAway = 0;
  String? _highlightedMessageId;

  /// Permalink target this feed has already claimed, so the one-shot is acted
  /// on exactly once even though the provider write that clears it is deferred
  /// out of [build].
  String? _consumedFocusMessageId;

  /// Cutoff the unread divider is drawn against: agent messages created after
  /// it are "new". Seeded from the open-time read cursor when the cursor
  /// snapshot is taken, then advanced past every arrival the reader witnessed —
  /// so a reply they watched land is never "new", while a turn that arrived
  /// during a hidden spell (or below the fold) still is.
  DateTime? _readFrontier;

  /// True from the moment the reader sends a turn until their next deliberate
  /// scroll or a hide. [_anchorTo] parks their own message near the top, which
  /// leaves [FollowState.mode] `anchored` even though they are sitting there
  /// watching the answer stream into the space below it.
  bool _watchingOwnTurn = false;
  String? _lastStampedNewestId;

  Timer? _cursorDebounce;

  /// Newest agent-turn id we last announced as "started", so we announce at
  /// most once per turn.
  String? _announcedStartFor;

  /// Newest agent-turn id we last announced as "finished", so the completion
  /// cue fires once when streaming ends (not on every token flush).
  String? _announcedDoneFor;

  /// Whether the newest agent turn was still streaming on the previous
  /// emission, used to detect the stream→complete transition.
  bool _newestWasStreaming = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _deferPrecalculation();
  }

  @override
  void dispose() {
    _cursorDebounce?.cancel();
    _highlightTimer?.cancel();
    _precalcTimer?.cancel();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Holds extent precalculation off until the feed has been still for
  /// [_precalcIdleDelay], then re-arms it.
  ///
  /// Called on open, on every window emission and on every scroll, so
  /// precalculation only ever runs in the gaps: opening a chat, growing the
  /// window and reading through it all push it back out.
  void _deferPrecalculation() {
    _precalcPolicy.disarm();
    _precalcTimer?.cancel();
    _precalcTimer = Timer(_precalcIdleDelay, () {
      _precalcTimer = null;
      if (mounted) {
        _precalcPolicy.arm();
      }
    });
  }

  /// The in-flight highlight-pulse timer, so a dispose (or a second jump
  /// before the first pulse ends) cancels it rather than leaving it to fire
  /// into a disposed State. The `mounted` guard below made it benign, not
  /// absent — an unreferenced pending timer keeps this State reachable.
  bool _programmatic = false;

  Timer? _highlightTimer;

  /// Whether the viewport is sitting on the live edge right now, independent of
  /// [FollowState.mode]. A permalink open parks the reader in `anchored` mode,
  /// and a space whose content fits the viewport never fires [_onScroll] to
  /// re-engage following — so mode alone reports a reader who is plainly looking
  /// at the newest turn as "away".
  bool get _isAtLiveEdge =>
      _scrollController.hasClients &&
      _scrollController.position.pixels <= _bottomThreshold;

  /// Whether older history exists beyond the current window — mirrored from
  /// the latest window emission so [_onScroll] can consult it.
  bool _hasMore = false;

  bool _showJumpControl = false;

  /// Whether a live agent turn is streaming below the fold — drives the
  /// jump-to-latest "streaming" indicator.
  bool get _isLiveBelow {
    final newestId = _lastNewestId;
    if (newestId == null) {
      return false;
    }
    final registry = ref.read(activeStreamRegistryProvider);
    return registry.isActive(newestId) &&
        _scrollController.hasClients &&
        _scrollController.position.pixels > kFollowPinThreshold;
  }

  @override
  Widget build(BuildContext context) {
    // Hidden-pane freeze. When this feed sits in a hidden IndexedStack tab,
    // Visibility.of reports false (and registers a dependency, so build
    // re-runs when the tab flips). While hidden we drop every live
    // watch/listen — Riverpod recomputes the dependency set per build, the
    // autoDispose providers lose their last listener, the RPC subscriptions
    // unsubscribe and server work for this space stops — and render the
    // frozen snapshots instead. The tree stays mounted with identical
    // content, so the ScrollController offset, FollowState, _didInitialLanding,
    // and _rowKeys all survive the nap.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      // Reveal: navigating back to this chat lands on the live edge, so the
      // surviving offset from before the nap is reset — instantly, next frame,
      // no animation. Done here rather than off a window emission because a
      // short nap may not produce one (the provider is still warm) and the
      // reader must land at the bottom either way.
      _pendingRevealReconcile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _landOnLiveEdge();
        }
      });
    }
    if (!isVisible) {
      // Away: nothing arriving now is witnessed, so the next arrival must not
      // inherit the send-and-watch grace. The frontier itself simply stops
      // advancing (the window listener only runs while visible), which is what
      // makes turns that land during the nap genuinely unread.
      _watchingOwnTurn = false;
    }
    _wasVisible = isVisible;

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final ({List<Message> messages, bool hasMore}) window;
    final feedRef = (
      spaceId: widget.spaceId,
      conversationId: widget.conversationId,
    );
    if (isVisible) {
      // Live turn relay: folds `messaging.watchSpaceTurns` into the
      // active-stream registry the agent bubbles render from. Watched here so
      // the subscription lives exactly as long as the feed is on screen.
      ref.watch(spaceTurnRelayProvider(widget.spaceId));
      final windowAsync = ref.watch(spaceFeedWindowedProvider(feedRef));
      ref.listen(spaceFeedWindowedProvider(feedRef), (_, next) {
        _onWindowChanged(next.value);
      });

      // Read the last value rather than `.when` so a reload (window growth
      // from loadMore, a streaming DB flush, or the re-subscribe after a
      // hidden spell) never replaces the list with a spinner — which would
      // destroy the ScrollController and snap the reverse list back to the
      // bottom. Until the first fresh emission after a reveal, the frozen
      // snapshot keeps rendering.
      final fresh = windowAsync.value ?? _frozenWindow;
      if (fresh == null) {
        if (windowAsync.hasError) {
          return Center(
            child: Text(l10n.failedWithError('${windowAsync.error}')),
          );
        }
        return const Center(child: CcSpinner());
      }
      window = fresh;
      _frozenWindow = fresh;
    } else {
      final frozen = _frozenWindow;
      if (frozen == null) {
        // Hidden before anything ever emitted: nothing to freeze. The live
        // watches (and the spinner-to-content transition) resume on reveal.
        return const Center(child: CcSpinner());
      }
      window = frozen;
    }
    _hasMore = window.hasMore;

    return _buildFeedBody(
      context,
      window: window,
      isVisible: isVisible,
      theme: theme,
      l10n: l10n,
    );
  }
}

/// One feed row's bubble, kept while that message is still in the window.
///
/// [child] is the widget handed back to the list. Flutter skips the element
/// update when the instance is the same, which is the point: only the row
/// whose message actually changed should build again.
class _KeptFeedRow {
  const _KeptFeedRow({
    required this.message,
    required this.collapseHeader,
    required this.highlighted,
    required this.onOpenThread,
    required this.onStartThread,
    required this.child,
  });

  final Message message;
  final bool collapseHeader;
  final bool highlighted;
  final void Function(String threadId)? onOpenThread;
  final void Function(Message message)? onStartThread;
  final Widget child;
}
