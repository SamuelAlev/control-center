part of 'message_feed.dart';

extension _ScrollingMethods on _SpaceMessageFeedState {
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
        _set(() => _newWhileAway += 1);
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
      _set(() => _showJumpControl = showControl);
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

  void _jumpToLatest() {
    if (!_scrollController.hasClients) {
      return;
    }
    _runProgrammicJump();
    _reengageFollowing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _set(() => _showJumpControl = false);
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
    _set(() => _readFrontier = seenAt);
  }

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
      _set(() => _newWhileAway = 0);
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
      _set(() {
        _newWhileAway = 0;
        _showJumpControl = false;
      });
    }
  }

  void _highlight(String messageId) {
    if (!mounted) {
      return;
    }
      _set(() => _highlightedMessageId = messageId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      _highlightTimer = null;
      if (mounted && _highlightedMessageId == messageId) {
        _set(() => _highlightedMessageId = null);
      }
    });
  }
}
