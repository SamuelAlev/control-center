part of 'message_feed.dart';

/// Scroll-to-message, anchoring, permalink consumption and related helpers
/// for [SpaceMessageFeed].
extension _NavigationMethods on _SpaceMessageFeedState {
  /// Estimated extent of the row at reverse [index], for rows the list has not
  /// laid out yet. See [estimateMessageRowExtent].
  double _estimateRowExtent(int? index, double crossAxisExtent) {
    if (index == null) {
      return kUnknownRowExtent;
    }
    final i = _items.length - 1 - index;
    if (i < 0 || i >= _items.length) {
      return kUnknownRowExtent;
    }
    final item = _items[i];
    if (item is! MessageItem) {
      return kSeparatorRowExtent;
    }
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
      if (it is MessageItem && it.message.id == messageId) {
        return _items.length - 1 - i;
      }
    }
    return null;
  }

  GlobalKey _ensureRowKey(String id) =>
      _rowKeys.putIfAbsent(id, GlobalKey.new);

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
  /// scrolls to and anchors the message, then clears the one-shot. Reuses the
  /// [scrollToMessage] reach loop, so a target beyond the window is loaded.
  void _maybeConsumePendingFocus() {
    final pending = ref.read(pendingFocusMessageProvider);
    if (pending == null || pending.spaceId != widget.spaceId) {
      return;
    }
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
      if (ref.read(pendingFocusMessageProvider)?.messageId ==
          pending.messageId) {
        ref.read(pendingFocusMessageProvider.notifier).set(null);
      }
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

    double alignment = 0.0;
    if (withPeek && _scrollController.hasClients) {
      final vh = _scrollController.position.viewportDimension;
      if (vh > 0) {
        alignment = (kPreviousTurnPeek / vh).clamp(0.0, 0.9);
      }
    }

    await _runProgrammatic(() async {
      if (_rowKeys[messageId]?.currentContext == null &&
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
    if (_superIndexOf(messageId) != null) {
      await _anchorTo(messageId, animate: true);
      _highlight(messageId);
      return true;
    }

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
}
