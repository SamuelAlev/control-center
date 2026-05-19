import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionScope;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/day_separator.dart';
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

/// How far below the viewport top a freshly anchored turn lands, leaving the
/// previous turn peeking into view so the reader keeps the prior context.
const double kPreviousTurnPeek = 64;

/// One rendered row in the feed: a message (with optional paired thinking),
/// a day separator, or the unread divider.
sealed class _FeedItem {
  const _FeedItem();
}

class _MessageItem extends _FeedItem {
  const _MessageItem(this.message, {this.collapseHeader = false});
  final Message message;
  final bool collapseHeader;
}

class _DayItem extends _FeedItem {
  const _DayItem(this.day);
  final DateTime day;
}

class _UnreadItem extends _FeedItem {
  const _UnreadItem({this.count});
  final int? count;
}

/// Builds feed items from an ascending message list: inserts day separators on
/// local-date changes, marks consecutive same-sender messages (<5 min apart)
/// to collapse their header and inserts a single unread divider before the
/// first agent message past [readFrontier]. The user's own messages are never
/// unread to themselves.
///
/// [readFrontier] is a *witnessed* cutoff, not the raw open-time read cursor:
/// it starts at the cursor and then advances past every arrival the reader
/// demonstrably saw (see [_SpaceMessageFeedState._advanceReadFrontier]).
/// Testing against the frozen cursor instead is what drew "New · 1" above a
/// reply the reader was actively watching — every live arrival is trivially
/// after the moment they arrived. Turns that land while the pane is hidden, or
/// while the reader is reading history below the fold, never advance the
/// frontier and so still get their divider.
List<_FeedItem> _buildFeedItems(
  List<Message> messages, {
  required bool suppressOldestSeparator,
  DateTime? readFrontier,
}) {
  final out = <_FeedItem>[];
  DateTime? lastDay;
  Message? prevSender;
  bool dividerInserted = false;
  bool isUnread(Message m) =>
      readFrontier != null &&
      m.senderType == SenderType.agent &&
      m.createdAt.isAfter(readFrontier);
  // Count unread agent messages past the frontier, for the divider label.
  final unreadCount = messages.where(isUnread).length;

  for (final display in messages) {
    // A queued steering card renders in the strip below the trail, not here —
    // it has not reached the agent yet. The moment the server flips it to
    // `injected` (or converts it to text at run end) the row re-renders as a
    // trail message in this same feed.
    if (display.isSteeringQueued) {
      continue;
    }
    final day = DateTime(
      display.createdAt.year,
      display.createdAt.month,
      display.createdAt.day,
    );
    final isFirst = out.isEmpty;
    if (lastDay == null || day != lastDay) {
      if (!(isFirst && suppressOldestSeparator)) {
        out.add(_DayItem(day));
      }
      lastDay = day;
      prevSender = null;
    }

    // Insert exactly one unread divider before the first unread agent message.
    if (!dividerInserted && isUnread(display)) {
      out.add(_UnreadItem(count: unreadCount > 0 ? unreadCount : null));
      dividerInserted = true;
    }

    final collapse =
        prevSender != null &&
        prevSender.senderId == display.senderId &&
        prevSender.senderType == display.senderType &&
        !display.isSystem &&
        !prevSender.isSystem &&
        display.createdAt.difference(prevSender.createdAt).inMinutes.abs() < 5;

    out.add(_MessageItem(display, collapseHeader: collapse));
    prevSender = display;
  }
  return out;
}

const double _bottomThreshold = kFollowPinThreshold;
const double _loadMoreThreshold = 400;

/// How many rows the feed will ever measure for real (see
/// [_IdlePrecalculationPolicy]). Rows beyond it keep their estimate until they
/// are built.
const int kFeedPrecalcRowBudget = 24;

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
  final _scrollController = ScrollController();
  final _follow = FollowState();
  final _rowKeys = <String, GlobalKey>{};

  /// Drives [SuperListView] extent queries and offscreen-row reveals
  /// ([ListController.jumpToItem]) so a deep anchor target can be built before
  /// [Scrollable.ensureVisible] positions it.
  final _listController = ListController();

  /// Refines row extents once the feed is idle, bounded to
  /// [kFeedPrecalcRowBudget] rows. Armed by [_deferPrecalculation].
  final _precalcPolicy = _IdlePrecalculationPolicy();

  /// Re-arms [_precalcPolicy] once nothing has moved for
  /// [_precalcIdleDelay].
  Timer? _precalcTimer;

  /// The current display rows (ascending, oldest→newest), mirrored from the
  /// last build so the anchor path can map a message id to its reverse
  /// [SuperListView] index without the build closure in scope.
  List<_FeedItem> _items = const [];

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

  /// Estimated extent of the row at reverse [index], for rows the list has not
  /// laid out yet. See [estimateMessageRowExtent].
  double _estimateRowExtent(int? index, double crossAxisExtent) {
    if (index == null) {
      return kUnknownRowExtent;
    }
    // Reverse mapping, mirroring the itemBuilder. The load-more spinner sits at
    // `items.length` and has no item behind it.
    final i = _items.length - 1 - index;
    if (i < 0 || i >= _items.length) {
      return kUnknownRowExtent;
    }
    final item = _items[i];
    if (item is! _MessageItem) {
      return kSeparatorRowExtent;
    }
    // The row's content is centred in a document column inside the list's own
    // horizontal padding.
    final columnWidth = math.min(
      conversationColumnWidth,
      math.max(160.0, crossAxisExtent - 32),
    );
    return estimateMessageRowExtent(
      item.message,
      collapseHeader: item.collapseHeader,
      columnWidth: columnWidth,
    );
  }

  /// The reverse [SuperListView] index of [messageId] in the current window, or
  /// null if it isn't a rendered row. Mirrors the itemBuilder's reverse mapping
  /// (`items[items.length - 1 - index]`).
  int? _superIndexOf(String messageId) {
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it is _MessageItem && it.message.id == messageId) {
        return _items.length - 1 - i;
      }
    }
    return null;
  }

  GlobalKey _ensureRowKey(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  /// Runs a programmatic scroll action with a reentrancy guard so the scroll
  /// listener's intent/edge logic ignores self-induced position changes.
  Future<T> _runProgrammatic<T>(Future<T> Function() task) async {
    _programmatic = true;
    try {
      return await task();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _programmatic = false;
      });
    }
  }

  bool _programmatic = false;

  /// Consumes a pending permalink target (`?m=<id>`) matching this space:
  /// scrolls to and anchors the message, then clears the one-shot. Reuses the
  /// [scrollToMessage] reach loop, so a target beyond the window is loaded.
  void _maybeConsumePendingFocus() {
    final pending = ref.read(pendingFocusMessageProvider);
    if (pending == null || pending.spaceId != widget.spaceId) {
      return;
    }
    // Claim the one-shot synchronously so a rebuild before the post-frame
    // callback runs doesn't re-trigger it. The provider itself can only be
    // cleared off-frame: this runs from [build] and writing to a provider
    // during a build throws.
    if (_consumedFocusMessageId == pending.messageId) {
      return;
    }
    _consumedFocusMessageId = pending.messageId;
    if (!_didInitialLanding) {
      _didInitialLanding = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Still ours? A second feed (another conversation of the same space,
      // a split view) may have consumed and re-targeted the one-shot in the
      // meantime; only clear what we claimed.
      if (ref.read(pendingFocusMessageProvider)?.messageId ==
          pending.messageId) {
        ref.read(pendingFocusMessageProvider.notifier).set(null);
      }
      // The claim only had to survive the rebuilds between here and the build
      // that made it; releasing it lets the same permalink be opened again
      // (tapping the same notification twice) instead of being swallowed.
      _consumedFocusMessageId = null;
      scrollToMessage(pending.messageId);
    });
  }

  /// Parks [messageId] near the top of the viewport in anchored mode, leaving
  /// the previous turn peeking ~[kPreviousTurnPeek] above. The anchor only
  /// applies while the row is currently mounted (in the window). [withPeek]
  /// disables the previous-turn peek when the target is the oldest message.
  Future<void> _anchorTo(
    String messageId, {
    required bool animate,
    bool withPeek = true,
  }) async {
    _follow.mode = FeedFollowMode.anchored;
    _follow.anchorMessageId = messageId;

    // `alignment: 0.0` lands the target's top at the viewport top in a reverse
    // list. Pushing the alignment down by a fraction leaves the previous
    // (older) turn peeking into the top of the viewport.
    double alignment = 0.0;
    if (withPeek && _scrollController.hasClients) {
      final vh = _scrollController.position.viewportDimension;
      if (vh > 0) {
        alignment = (kPreviousTurnPeek / vh).clamp(0.0, 0.9);
      }
    }

    // The whole reveal (optional jump-to-build + ensureVisible) runs under one
    // programmatic guard so none of it is mistaken for a user scroll and the
    // guard is reset exactly once, after the sequence settles.
    await _runProgrammatic(() async {
      // SuperListView unbuilds offscreen rows, so a deep target (permalink,
      // first-unread far up) has a null currentContext and ensureVisible can't
      // reach it. Jump the row into the built window first, then let it build.
      if (_rowKeys[messageId]?.currentContext == null &&
          _listController.isAttached &&
          _scrollController.hasClients) {
        final index = _superIndexOf(messageId);
        if (index != null) {
          _listController.jumpToItem(
            index: index,
            scrollController: _scrollController,
            // Center it to guarantee it lands inside the built/cache window;
            // ensureVisible below applies the exact peek alignment.
            alignment: 0.5,
          );
          await WidgetsBinding.instance.endOfFrame;
        }
      }

      if (!mounted) {
        return;
      }
      final ctx = _rowKeys[messageId]?.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      final duration = animate
          ? CcMotion.resolve(context, const Duration(milliseconds: 250))
          : Duration.zero;
      await Scrollable.ensureVisible(
        ctx,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: duration,
        curve: Curves.easeOut,
      );
    });
  }

  /// Shared scroll-to-message primitive (permalinks, open-at-first-unread,
  /// badge anchoring). Returns false if the message can't be reached.
  ///
  /// 1. If the target is in the current window, anchor it + highlight pulse.
  /// 2. Otherwise grow the window (with `loadingOlder` set so physics doesn't
  ///    fight the growth) until the id appears, then anchor. Caps at
  ///    [kSpaceFeedMaxWindow].
  Future<bool> scrollToMessage(String messageId) async {
    // Fast path: already a rendered row in the current window. `_anchorTo`
    // reveals it even if its widget is currently unbuilt (offscreen).
    if (_superIndexOf(messageId) != null) {
      await _anchorTo(messageId, animate: true);
      _highlight(messageId);
      return true;
    }

    // Verify the message exists and belongs to this space before growing.
    final repo = ref.read(messagingRepositoryProvider);
    final found = await repo.getMessageById(
      ref.requireWorkspaceId(),
      messageId,
    );
    if (!mounted) {
      return false;
    }
    if (found == null || found.spaceId != widget.spaceId) {
      return false;
    }

    _follow.loadingOlder = true;
    try {
      final windowProvider = spaceFeedWindowProvider(widget.conversationId);
      while (ref.read(windowProvider) < kSpaceFeedMaxWindow) {
        ref.read(windowProvider.notifier).loadMore();
        final next = await ref.read(
          spaceFeedWindowedProvider((
            spaceId: widget.spaceId,
            conversationId: widget.conversationId,
          )).future,
        );
        if (!mounted) {
          return false;
        }
        if (next.messages.any((m) => m.id == messageId)) {
          // Let the build mirror the grown window into `_items` (and hence
          // `_superIndexOf`) before anchoring.
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) {
            return false;
          }
          await _anchorTo(messageId, animate: true);
          _highlight(messageId);
          return true;
        }
      }
    } finally {
      if (mounted) {
        _follow.loadingOlder = false;
      }
    }
    return false;
  }

  /// The in-flight highlight-pulse timer, so a dispose (or a second jump
  /// before the first pulse ends) cancels it rather than leaving it to fire
  /// into a disposed State. The `mounted` guard below made it benign, not
  /// absent — an unreferenced pending timer keeps this State reachable.
  Timer? _highlightTimer;

  void _highlight(String messageId) {
    if (!mounted) {
      return;
    }
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      _highlightTimer = null;
      if (mounted && _highlightedMessageId == messageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  /// Stamp the user's read cursor for this space (debounced) — called when
  /// pinned to the live edge so messages read down to the bottom are marked
  /// seen. Debounced so a burst of streaming flushes coalesces into one write.
  void _stampCursor() {
    final newest = _lastNewestId;
    if (newest == null || newest == _lastStampedNewestId) {
      return;
    }
    _lastStampedNewestId = newest;
    _cursorDebounce?.cancel();
    _cursorDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) {
        return;
      }
      // Read the workspace from the provider, not `context`: this runs in a
      // debounced callback and `GoRouterState.of(context)` throws outright when
      // there is no router above — which is also what made this branch
      // untestable without pumping a full router.
      ref
          .read(spaceReadRepositoryProvider)
          .markSpaceRead(
            ref.requireWorkspaceId(),
            widget.spaceId,
            ref.read(currentUserIdProvider) ?? '',
          );
    });
  }

  /// Advances the divider cutoff to [seenAt] — an arrival the reader witnessed.
  /// A null frontier stays null: a never-opened space shows no divider at all,
  /// and inventing one here would start drawing it.
  ///
  /// Rebuilds when the cutoff actually moves: the divider is derived from it in
  /// [build], so advancing it silently would leave a stale "New · n" on screen
  /// until some unrelated emission happened to repaint the feed.
  void _advanceReadFrontier(DateTime seenAt) {
    final current = _readFrontier;
    if (current == null || !seenAt.isAfter(current)) {
      return;
    }
    if (!mounted) {
      _readFrontier = seenAt;
      return;
    }
    setState(() => _readFrontier = seenAt);
  }

  /// Whether the viewport is sitting on the live edge right now, independent of
  /// [FollowState.mode]. A permalink open parks the reader in `anchored` mode,
  /// and a space whose content fits the viewport never fires [_onScroll] to
  /// re-engage following — so mode alone reports a reader who is plainly looking
  /// at the newest turn as "away".
  bool get _isAtLiveEdge =>
      _scrollController.hasClients &&
      _scrollController.position.pixels <= _bottomThreshold;

  /// Re-engages following (pinned to the live edge) and clears the away-count.
  ///
  /// Reaching the live edge means everything currently in the space has been
  /// seen, so the divider cutoff advances too — otherwise scrolling back down
  /// cleared the sidebar dot but left "New · n" drawn above messages the reader
  /// had just read.
  void _reengageFollowing() {
    _follow.mode = FeedFollowMode.following;
    _follow.anchorMessageId = null;
    if (_newWhileAway != 0) {
      setState(() => _newWhileAway = 0);
    }
    final seen = _lastNewestAt;
    if (seen != null) {
      _advanceReadFrontier(seen);
    }
    _stampCursor();
  }

  /// Lands the viewport on the live edge with no animation and resumes
  /// following. This is where both opening a chat and returning to one after a
  /// hidden spell end up: the newest message is on screen and a streaming turn
  /// below keeps being followed instead of compensated.
  ///
  /// In a reverse list offset 0 *is* the bottom, so a fresh mount is already
  /// there — the jump only matters when a live position is being reset (reveal).
  /// Read state is deliberately untouched: the unread divider keeps marking
  /// where the reader left off, up in the scrollback.
  void _landOnLiveEdge() {
    _follow.mode = FeedFollowMode.following;
    _follow.anchorMessageId = null;
    if (_scrollController.hasClients &&
        _scrollController.position.pixels != 0) {
      // Guarded so the scroll listener doesn't read the reset as reader intent.
      _runProgrammatic(() async => _scrollController.jumpTo(0));
    }
    // Nothing is below the fold any more, so the jump-to-latest affordance and
    // its missed-turn count are stale. [_onScroll] can't clear them: it ignores
    // programmatic movement and a space that fits the viewport never scrolls.
    if (_newWhileAway != 0 || _showJumpControl) {
      setState(() {
        _newWhileAway = 0;
        _showJumpControl = false;
      });
    }
  }

  /// Handles window changes after the first emission: anchors the user's just
  /// sent turn near the top and counts agent arrivals that happen while the
  /// reader is away from the live edge.
  void _onWindowChanged(({List<Message> messages, bool hasMore})? next) {
    final msgs = next?.messages ?? const [];
    // Fresh rows to build; anything measured off the back of this emission
    // would compete with them for the frame.
    _deferPrecalculation();
    _maybeAnnounce(msgs);
    if (msgs.isEmpty) {
      return;
    }
    // This emission is the FIRST after a hidden spell, so whatever it carries
    // arrived while the reader was away even though they are "present" again by
    // the time it lands. Without the flag the branches below would advance the
    // frontier straight past the whole nap (and stamp the cursor), silently
    // marking unseen turns as read. Repositioning is not this listener's job:
    // reveal lands on the live edge from [build], which does not depend on a
    // fresh window arriving at all.
    final afterReveal = _pendingRevealReconcile;
    _pendingRevealReconcile = false;
    final newest = msgs.last;
    final prevId = _lastNewestId;
    _lastNewestId = newest.id;
    _lastNewestAt = newest.createdAt;
    if (prevId == null || newest.id == prevId) {
      return;
    }
    if (newest.isUser) {
      // The user just sent: they're engaged. Park their turn near the top so
      // the agent's answer streams into the space below.
      _newWhileAway = 0;
      _watchingOwnTurn = true;
      _advanceReadFrontier(newest.createdAt);
      _anchorTo(newest.id, animate: true);
    } else if (!afterReveal) {
      if (_follow.mode == FeedFollowMode.following ||
          _watchingOwnTurn ||
          _isAtLiveEdge) {
        // Present and watching — pinned to the live edge (by follow mode or by
        // simply sitting on it, which is where a short space always is), or
        // parked on the turn they just sent with the answer arriving below it.
        // This is read, not new: don't draw a divider over it, don't count it as
        // missed and do advance the server cursor so the sidebar stops flagging
        // the space the reader is sitting in.
        _advanceReadFrontier(newest.createdAt);
        _stampCursor();
      } else {
        // An agent message arrived while the reader is reading history / an
        // anchor: count it as "new while away" so the jump-to-latest badge shows
        // what they've missed below the fold.
        setState(() => _newWhileAway += 1);
      }
    }
    // Else: this landed during the nap the reader just came back from. They are
    // sitting on the live edge looking at it, so it is not "missed below the
    // fold" — but the frontier stays put, so the divider still marks it as new.
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _programmatic) {
      return;
    }
    // Reading is the worst moment to measure: the rows scrolling in are being
    // built for real already.
    _deferPrecalculation();
    final pos = _scrollController.position;
    // Re-engage following when the reader scrolls back to the live edge.
    if (pos.pixels <= _bottomThreshold &&
        _follow.mode != FeedFollowMode.following) {
      _reengageFollowing();
    }

    final showControl = pos.pixels > _bottomThreshold;
    if (showControl != _showJumpControl) {
      setState(() => _showJumpControl = showControl);
    }

    // Load older messages as the user nears the top (high-offset end in a
    // reverse list). Flag the load so the follow physics does NOT compensate
    // for that top-end growth. Only when a load can actually happen —
    // otherwise `loadingOlder` sticks (nothing grows the item count to reset
    // it) and silently disables streaming compensation.
    if (_hasMore &&
        ref.read(spaceFeedWindowProvider(widget.conversationId)) <
            kSpaceFeedMaxWindow &&
        pos.maxScrollExtent - pos.pixels < _loadMoreThreshold) {
      _follow.loadingOlder = true;
      ref
          .read(spaceFeedWindowProvider(widget.conversationId).notifier)
          .loadMore();
    }
  }

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
    // Only an agent turn can stream; the registry knows if it's active.
    return registry.isActive(newestId) &&
        _scrollController.hasClients &&
        _scrollController.position.pixels > kFollowPinThreshold;
  }

  void _jumpToLatest() {
    if (!_scrollController.hasClients) {
      return;
    }
    _runProgrammicJump();
    _reengageFollowing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        setState(() => _showJumpControl = false);
      }
    });
  }

  void _runProgrammicJump() {
    _runProgrammatic(
      () => _scrollController.animateTo(
        0,
        duration: CcMotion.resolve(context, const Duration(milliseconds: 300)),
        curve: Curves.easeOut,
      ),
    );
  }

  /// Paced live-region announcements (principle 15): announce "Agent
  /// responding" once when a live agent turn starts and the final answer once
  /// when it completes — never per token. No-ops where the registry is inert
  /// (web), since nothing publishes active streams there.
  void _maybeAnnounce(List<Message> messages) {
    final newest = messages.isNotEmpty ? messages.last : null;
    if (newest == null || newest.isUser) {
      _newestWasStreaming = false;
      return;
    }
    final registry = ref.read(activeStreamRegistryProvider);
    final streaming = registry.isActive(newest.id);
    if (streaming && _announcedStartFor != newest.id) {
      _announcedStartFor = newest.id;
      _announcedDoneFor = null;
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).agentResponding,
        TextDirection.ltr,
      );
    } else if (!streaming &&
        _newestWasStreaming &&
        _announcedDoneFor != newest.id) {
      _announcedDoneFor = newest.id;
      final answer = newest.content.trim();
      final preview = answer.isEmpty
          ? AppLocalizations.of(context).agentFinished
          : (answer.length > 160 ? '${answer.substring(0, 160)}…' : answer);
      SemanticsService.sendAnnouncement(
        View.of(context),
        preview,
        TextDirection.ltr,
      );
    }
    _newestWasStreaming = streaming;
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

    return Builder(
      builder: (context) {
        final tokens = context.designSystem ?? DesignSystemTokens.light();
        final messages = window.messages;
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.messageSquare,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noMessagesYet,
                  style: CcTypography.title.copyWith(color: tokens.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sendFirstMessage,
                  style: CcTypography.body.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Snapshot the read cursor once it emits (null = never opened, still a
        // valid snapshot). Watched so the feed rebuilds when the value lands and
        // snapshotted exactly once so the divider logic is stable against later
        // re-stamps. Gated on the snapshot flag (and visibility) so the
        // subscription is dropped as soon as the one-shot is taken.
        if (isVisible && !_cursorSnapshotTaken) {
          final liveCursorAsync = ref.watch(
            spaceUserLastReadAtProvider(widget.spaceId),
          );
          if (liveCursorAsync.hasValue) {
            _readFrontier = liveCursorAsync.value;
            _cursorSnapshotTaken = true;
          }
        }

        // First non-empty emission (after the cursor snapshot is in): settle on
        // the live edge. A reverse list mounts at offset 0 (the newest message),
        // so this normalizes follow state rather than scrolling — but it also
        // catches the case where the window grew before the first frame settled.
        // Done here (not initState) because the window is async-empty at mount.
        if (messages.isNotEmpty &&
            _cursorSnapshotTaken &&
            !_didInitialLanding) {
          _didInitialLanding = true;
          _lastNewestId = messages.last.id;
          _lastNewestAt = messages.last.createdAt;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _landOnLiveEdge();
            }
          });
        }

        final items = _buildFeedItems(
          messages,
          // Suppress the oldest day separator while more history exists, since
          // earlier same-day messages may sit beyond the window.
          suppressOldestSeparator: window.hasMore,
          readFrontier: _readFrontier,
        );
        // Mirror for the anchor path's id→index mapping (_superIndexOf).
        _items = items;

        // Consume a one-shot permalink deep link (notification tap, copied
        // link, search jump). Done here, once rows exist, rather than beside
        // the window watch above: that build can still be the spinner one and
        // consuming there sends a target that IS in the window down the
        // grow-the-window path because `_superIndexOf` has nothing to match.
        if (isVisible) {
          _maybeConsumePendingFocus();
        }

        // Prune row keys to the current window so the map can't grow unbounded
        // across a long session.
        final keep = messages.map((m) => m.id).toSet();
        _rowKeys.removeWhere((k, _) => !keep.contains(k));

        // Older messages have finished loading once the item count grows;
        // re-enable bottom-growth compensation on the next frame.
        if (items.length != _lastItemCount) {
          if (items.length > _lastItemCount && _follow.loadingOlder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _follow.loadingOlder = false;
            });
          }
          _lastItemCount = items.length;
        }

        final platformPhysics = ScrollConfiguration.of(
          context,
        ).getScrollPhysics(context);

        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            // Every non-programmatic movement of the feed's own position marks
            // the user as actively scrolling, which suppresses the follow
            // physics' growth compensation (wheel/trackpad scrolls are
            // invisible to `isScrolling`/`velocity`, so this notification is
            // the only reliable signal on desktop).
            if (n.depth == 0 && !_programmatic) {
              _follow.noteUserScroll();
            }
            return false;
          },
          child: NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              // Any user-driven scroll is intent to stop following — except our
              // own animateTo/ensureVisible, which never emit this notification.
              if (n.direction != ScrollDirection.idle) {
                // Deliberate movement also ends the send-and-watch grace, so a
                // turn that lands after the reader has gone browsing counts as
                // missed again. Returning to the live edge re-engages following
                // (and re-arms advancing) via [_reengageFollowing].
                _watchingOwnTurn = false;
                if (_follow.mode == FeedFollowMode.following) {
                  _follow.mode = FeedFollowMode.free;
                }
              }
              return false;
            },
            child: Listener(
              onPointerDown: (_) {
                // Pointer-down covers interactions that don't move the scroll
                // (text selection, link taps, tool-row expansion) — all intent.
                if (_follow.mode == FeedFollowMode.following) {
                  _follow.mode = FeedFollowMode.free;
                }
              },
              child: Stack(
                children: [
                  // A single feed-wide SelectionArea owns text selection for
                  // every bubble (CcSelectionScope tells CcMarkdown to
                  // render plain, non-selectable text). This replaces one
                  // heavyweight SelectableRegion PER message with exactly one for
                  // the whole feed — the dominant per-message scroll cost.
                  SelectionArea(
                    child: CcSelectionScope(
                      child: SuperListView.builder(
                        controller: _scrollController,
                        listController: _listController,
                        // Refine real extents once the feed is idle, so the
                        // scroll extent settles and the scrollbar thumb stops
                        // resizing — but never while there is something better
                        // to do with the frame, and never for the whole window.
                        extentPrecalculationPolicy: _precalcPolicy,
                        // Until a row is measured or built, its height comes
                        // from its own content rather than the package's flat
                        // 100px-per-row default.
                        extentEstimation: _estimateRowExtent,
                        // During a fast fling, don't build the offscreen cache-area
                        // rows every frame — defer them until the scroll settles.
                        // Bubble rows are expensive (markdown parse + highlight), so
                        // this is the difference between a smooth fling and jank.
                        delayPopulatingCacheArea: true,
                        reverse: true,
                        physics: ReverseFollowPhysics(
                          state: _follow,
                        ).applyTo(platformPhysics),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        // +1 for the load-more row at the oldest (top) end.
                        itemCount: items.length + (window.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Reverse mapping: index 0 = newest (bottom).
                          if (window.hasMore && index == items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CcSpinner()),
                            );
                          }
                          final item = items[items.length - 1 - index];
                          final Widget content;
                          GlobalKey? rowKey;
                          if (item is _DayItem) {
                            content = DaySeparator(day: item.day);
                          } else if (item is _UnreadItem) {
                            content = UnreadDivider(count: item.count);
                          } else {
                            final m = item as _MessageItem;
                            rowKey = _ensureRowKey(m.message.id);
                            final bubble = SpaceMessageBubble(
                              message: m.message,
                              collapseHeader: m.collapseHeader,
                              onStartThread: widget.onStartThread == null
                                  ? null
                                  : () => widget.onStartThread!(m.message),
                              onOpenThread: widget.onOpenThread,
                            );
                            content = m.message.id == _highlightedMessageId
                                ? _Highlight(child: bubble)
                                : bubble;
                          }
                          // Center the conversation in a ~760px document column on
                          // wide panes (layout-only wrapper; reverse-list physics
                          // unaffected).
                          Widget row = Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: conversationColumnWidth,
                              ),
                              child: content,
                            ),
                          );
                          if (rowKey != null) {
                            row = KeyedSubtree(key: rowKey, child: row);
                          }
                          return row;
                        },
                      ),
                    ),
                  ),
                  if (_showJumpControl)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: JumpToLatest(
                        onTap: _jumpToLatest,
                        isStreaming: _isLiveBelow,
                        newCount: _newWhileAway,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Precalculation policy that measures rows only while the feed is idle, and
/// only up to [kFeedPrecalcRowBudget] of them.
///
/// **Precalculating an extent builds the row.** SuperListView measures by
/// building the item off-screen, laying it out and throwing it away
/// (`measureExtentForItem`), so for this feed one measurement is a whole
/// [SpaceMessageBubble]: a markdown parse, the syntax-highlighted diffs a file
/// edit opens by default — and, for the lite list rows the wire ships without
/// their transcript, a `messaging.getMessageById` round trip apiece. Measuring
/// the window unconditionally therefore costs exactly what rendering the entire
/// conversation costs, which is the thing the windowed lazy list exists to
/// avoid: opening a long space spent seconds building sixty turns nobody was
/// looking at, and fired one transcript fetch per turn to do it.
///
/// So measurement is deferred out of the open (and out of every window growth
/// and scroll — see [_SpaceMessageFeedState._deferPrecalculation]) and bounded.
/// The budget is what buys back the original intent — a stable scrollbar thumb
/// and a growth delta the follow physics can trust — for the rows around the
/// viewport, where it is felt, without paying it for scrollback nobody has
/// reached. Beyond the budget rows keep [estimateMessageRowExtent], which is
/// content-derived rather than the package's flat 100px, and every row corrects
/// itself the moment it is genuinely built.
class _IdlePrecalculationPolicy extends ExtentPrecalculationPolicy {
  bool _armed = false;

  /// Allows measurement again. Re-runs layout when this flips it back on: a
  /// policy that returned false is not consulted again until it says so.
  void arm() {
    if (_armed) {
      return;
    }
    _armed = true;
    valueDidChange();
  }

  /// Suspends measurement. Deliberately silent — the next layout pass asks the
  /// policy again anyway, and notifying here would mark the list dirty on every
  /// scroll tick.
  void disarm() => _armed = false;

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) {
    if (!_armed || context.numberOfItemsWithEstimatedExtent == 0) {
      return false;
    }
    final measured =
        context.numberOfItems - context.numberOfItemsWithEstimatedExtent;
    return measured < kFeedPrecalcRowBudget;
  }
}

/// Accent flash wrapper for the permalink-scroll highlight pulse.
class _Highlight extends StatefulWidget {
  const _Highlight({required this.child});

  final Widget child;

  @override
  State<_Highlight> createState() => _HighlightState();
}

class _HighlightState extends State<_Highlight>
    with SingleTickerProviderStateMixin {
  static const _pulse = Duration(milliseconds: 1200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    // The reduced-motion check is an inherited lookup (CcTheme / MediaQuery),
    // so it can only run here — reading it in initState throws.
    _controller
      ..duration = CcMotion.resolve(context, _pulse)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Fade an accentSoft wash in then out over the pulse window.
        final t = _controller.value;
        final alpha = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.accentSoft.withValues(alpha: alpha),
            borderRadius: AppRadii.brMd,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
