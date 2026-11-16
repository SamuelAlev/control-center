part of 'message_feed.dart';

/// History beyond the live window, after Delta's: the feed lays out every
/// message of the conversation (stand-ins sized from the outline for the ones
/// not loaded) and loads a range of messages around wherever the reader is.
/// Scrolling, dragging the scrollbar and opening a permalink all just move
/// that range.
extension _HistoryMethods on _SpaceMessageFeedState {
  /// Rows either side of the viewport checked for stand-ins: the range moves
  /// a little before the reader reaches unloaded history.
  static const int _recenterReach = 12;

  /// Re-centers the history range shortly, coalescing a scroll's ticks.
  void _scheduleRecenter() {
    if (_recenterTimer != null || _outline == null) {
      return;
    }
    _recenterTimer = Timer(const Duration(milliseconds: 120), () {
      _recenterTimer = null;
      if (mounted) {
        _recenterRange();
      }
    });
  }

  /// Points the history range at the message in the middle of the viewport
  /// when stand-ins are on screen or about to be.
  void _recenterRange() {
    if (!_listController.isAttached || _rows.isEmpty) {
      return;
    }
    final visible = _listController.visibleRange;
    if (visible == null) {
      return;
    }
    final (first, last) = visible;
    final from = math.max(0, first - _recenterReach);
    final to = math.min(_rows.length - 1, last + _recenterReach);
    var standIn = false;
    for (var index = from; index <= to; index++) {
      if (_rows[_rows.length - 1 - index] is PlaceholderRow) {
        standIn = true;
        break;
      }
    }
    if (!standIn) {
      return;
    }
    final anchorId = _messageIdNear((first + last) ~/ 2);
    if (anchorId == null || anchorId == _rangeAnchorId) {
      return;
    }
    _set(() => _rangeAnchorId = anchorId);
  }

  /// The message of the row at list [index], or of the nearest row that has
  /// one (separators and the unread divider do not).
  String? _messageIdNear(int index) {
    for (var d = 0; d < _rows.length; d++) {
      for (final i in [index - d, index + d]) {
        if (i < 0 || i >= _rows.length) {
          continue;
        }
        final id = messageIdOfRowKey(_rows[_rows.length - 1 - i].key);
        if (id != null) {
          return id;
        }
      }
    }
    return null;
  }

  /// Drops the history range: the reader is back at the live edge, and the
  /// history above turns back into stand-ins (off screen, above the reader).
  void _releaseRange() {
    _recenterTimer?.cancel();
    _recenterTimer = null;
    if (_rangeAnchorId == null && _range == null) {
      return;
    }
    _set(() {
      _rangeAnchorId = null;
      _range = null;
    });
  }

  /// The range's anchor could not be loaded (deleted or reverted since the
  /// outline was read): drop the range and refresh the outline.
  void _onRangeFailed(String anchorId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _rangeAnchorId != anchorId) {
        return;
      }
      _set(() {
        _rangeAnchorId = null;
        _range = null;
      });
      ref.invalidate(conversationOutlineProvider(_feedRef));
    });
  }

  /// Refetches the outline once for the live window starting at
  /// [oldestLiveId]: it is out of step with the loaded messages.
  void _refreshOutline(String oldestLiveId) {
    if (_outlineRefreshedFor == oldestLiveId) {
      return;
    }
    _outlineRefreshedFor = oldestLiveId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(conversationOutlineProvider(_feedRef));
      }
    });
  }

  ConversationRef get _feedRef =>
      (spaceId: widget.spaceId, conversationId: widget.conversationId);

  /// Brings [messageId], a message the feed shows only as a stand-in, into
  /// view: jumps to the stand-in, loads the range around it, then settles on
  /// the loaded message. Returns false if the range cannot be loaded.
  Future<bool> _revealStandIn(String messageId) async {
    _set(() => _rangeAnchorId = messageId);
    await _anchorTo(messageId, animate: false);
    if (!mounted) {
      return false;
    }
    // The build after the anchor change watches the range; read it once it
    // does, so the read does not create (and drop) a second subscription.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return false;
    }
    try {
      await ref.read(
        spaceFeedRangeProvider((
          spaceId: widget.spaceId,
          conversationId: widget.conversationId,
          anchorId: messageId,
        )).future,
      );
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
    await _anchorTo(messageId, animate: true);
    return true;
  }
}
