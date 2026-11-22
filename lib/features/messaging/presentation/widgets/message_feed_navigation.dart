part of 'message_feed.dart';

/// Scroll-to-message, anchoring, permalink consumption and related helpers
/// for [SpaceMessageFeed].
extension _NavigationMethods on _SpaceMessageFeedState {
  /// The reverse [SuperListView] index of [messageId]'s top row (a steering
  /// message or answered question resolves to its turn; a message not loaded
  /// resolves to its stand-in), or null if the feed does not list it. Mirrors
  /// the itemBuilder's reverse mapping (`rows[rows.length - 1 - index]`).
  int? _superIndexOf(String messageId) {
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row is PlaceholderRow && row.entry.id == messageId) {
        return _rows.length - 1 - i;
      }
      final item = switch (row) {
        ItemRow(:final item) => item is MessageItem ? item : null,
        TurnHeadRow(:final item) => item,
        _ => null,
      };
      if (item != null &&
          (item.message.id == messageId ||
              item.inlineMessages.any((m) => m.id == messageId))) {
        return _rows.length - 1 - i;
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

  /// Consumes a pending permalink target (`?m=<id>`) matching this space:
  /// scrolls to and anchors the message, then clears the one-shot. A target
  /// in history is reached through its stand-in, so with history beyond the
  /// live window this waits for the outline ([historyPending]).
  void _maybeConsumePendingFocus({required bool historyPending}) {
    final pending = ref.read(pendingFocusMessageProvider);
    if (pending == null ||
        pending.spaceId != widget.spaceId ||
        historyPending) {
      return;
    }
    if (_claims.message == pending.messageId) {
      return;
    }
    _claims.message = pending.messageId;
    if (!_didInitialLanding) {
      _didInitialLanding = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(pendingFocusMessageProvider)?.messageId ==
          pending.messageId) {
        ref.read(pendingFocusMessageProvider.notifier).set(null);
      }
      _claims.message = null;
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
    final index = _superIndexOf(messageId);
    final rowId = index == null
        ? messageId
        : messageIdOfRowKey(_rows[_rows.length - 1 - index].key) ?? messageId;
    _follow.mode = FeedFollowMode.anchored;

    double alignment = 0.0;
    if (withPeek && _scrollController.hasClients) {
      final vh = _scrollController.position.viewportDimension;
      if (vh > 0) {
        alignment = (kPreviousTurnPeek / vh).clamp(0.0, 0.9);
      }
    }

    await _runProgrammatic(() async {
      if (_rowKeys[rowId]?.currentContext == null &&
          _listController.isAttached &&
          _scrollController.hasClients) {
        final index = _superIndexOf(messageId);
        if (index != null) {
          _listController.jumpToItem(
            index: index,
            scrollController: _scrollController,
            alignment: 0.5,
          );
          await WidgetsBinding.instance.endOfFrame;
        }
      }

      if (!mounted) {
        return;
      }
      final ctx = _rowKeys[rowId]?.currentContext;
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
  /// 1. A loaded message: anchor it + highlight pulse.
  /// 2. A stand-in (history not loaded): jump to it, load the range around
  ///    it, then anchor + highlight.
  /// 3. Not listed at all: the outline may predate the message; confirm it
  ///    belongs here, refresh the outline once, and try again.
  Future<bool> scrollToMessage(String messageId) async {
    var index = _superIndexOf(messageId);
    if (index == null) {
      final Message? found;
      try {
        found = await ref
            .read(messagingRepositoryProvider)
            .getMessageById(ref.requireWorkspaceId(), messageId);
      } on Object {
        return false;
      }
      if (!mounted ||
          found == null ||
          found.spaceId != widget.spaceId ||
          found.conversationId != widget.conversationId) {
        return false;
      }
      ref.invalidate(conversationOutlineProvider(_feedRef));
      try {
        await ref.read(conversationOutlineProvider(_feedRef).future);
      } on Object {
        return false;
      }
      if (!mounted) {
        return false;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return false;
      }
      index = _superIndexOf(messageId);
      if (index == null) {
        return false;
      }
    }
    if (_rows[_rows.length - 1 - index] is PlaceholderRow) {
      if (!await _revealStandIn(messageId)) {
        return false;
      }
    } else {
      await _anchorTo(messageId, animate: true);
    }
    if (!mounted) {
      return false;
    }
    _highlight(messageId);
    return true;
  }

  /// Consumes a pending "show this tool call" target meant for this
  /// conversation: scrolls its transcript row into view and flashes it, then
  /// clears the one-shot.
  void _maybeConsumePendingToolFocus(PendingToolCallFocus? pending) {
    if (pending == null || pending.spaceId != widget.spaceId) {
      return;
    }
    final conversationId = pending.conversationId;
    if (conversationId != null &&
        conversationId.isNotEmpty &&
        conversationId != widget.conversationId) {
      return;
    }
    if (_claims.toolCall == pending.toolCallId) {
      return;
    }
    _claims.toolCall = pending.toolCallId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(pendingFocusToolCallProvider) == pending) {
        ref.read(pendingFocusToolCallProvider.notifier).set(null);
      }
      _claims.toolCall = null;
      unawaited(_scrollToToolCall(pending.toolCallId));
    });
  }

  /// Brings the transcript row showing the call [toolCallId] into view (a
  /// script's calls show in its row) and flashes it. False when no row of the
  /// loaded window shows it.
  Future<bool> _scrollToToolCall(String toolCallId) async {
    final at = latestRowShowingToolCall(_rows, toolCallId);
    if (at < 0) {
      return false;
    }
    final key = _rows[at].key;
    final index = _rows.length - 1 - at;
    _follow.mode = FeedFollowMode.anchored;
    await _runProgrammatic(() async {
      if (_listController.isAttached && _scrollController.hasClients) {
        _listController.jumpToItem(
          index: index,
          scrollController: _scrollController,
          alignment: 0.5,
        );
        await WidgetsBinding.instance.endOfFrame;
      }
    });
    if (!mounted) {
      return false;
    }
    _set(() => _highlightedRowKey = key);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      _highlightTimer = null;
      if (mounted && _highlightedRowKey == key) {
        _set(() => _highlightedRowKey = null);
      }
    });
    return true;
  }
}

/// Focus targets a feed has already claimed, so each one-shot is acted on
/// exactly once even though the provider write that clears it is deferred out
/// of `build`.
class _FocusClaims {
  /// A permalink target (`?m=<id>`).
  String? message;

  /// A "show this tool call" target.
  String? toolCall;
}
