part of 'message_feed.dart';

/// The scroll anchor: which row the reader is looking at, by key, captured
/// after each frame and resolved back to a position by [AnchorFollowPhysics].
extension _AnchorMethods on _SpaceMessageFeedState {
  /// Key of the load-older row that sits past the oldest message.
  static const String loadMoreRowKey = 'more';

  /// Mirrors the row keys of [rows] in list index order (reverse: index 0 is
  /// the newest row).
  void _mirrorRowKeys(List<FeedRow> rows, {required bool hasMore}) {
    final keys = <String>[
      for (var i = rows.length - 1; i >= 0; i--) rows[i].key,
      if (hasMore) loadMoreRowKey,
    ];
    _rowKeysByIndex = keys;
    _indexByRowKey = {for (var i = 0; i < keys.length; i++) keys[i]: i};
    // What the list's extents are synced by: a stand-in and the message that
    // replaces it share a row key but not a height, so the swap re-estimates
    // the slot instead of carrying the stand-in's extent over as measured.
    _slotKeysByIndex = [
      for (var i = rows.length - 1; i >= 0; i--)
        switch (rows[i]) {
          PlaceholderRow(:final key) => '$key~',
          final row => row.key,
        },
      if (hasMore) loadMoreRowKey,
    ];
    // Stand-ins have no revision: their height is never recorded.
    _revisionByRowKey = {
      for (final row in rows)
        if (row is! PlaceholderRow) row.key: _rowRevision(row),
    };
  }

  /// Finds a row's current index from its key, so the list keeps a row's
  /// element (and the state under it, such as a streaming answer's renderer)
  /// when rows land before it.
  int? _findRowIndex(Key key) =>
      key is ValueKey<String> ? _indexByRowKey[key.value] : null;

  String? _rowKeyAt(int index) => index >= 0 && index < _rowKeysByIndex.length
      ? _rowKeysByIndex[index]
      : null;

  /// Where the row named [rowKey] ends right now (its top edge, in list
  /// coordinates), or null when it is not laid out. Called by the physics in
  /// the middle of layout, so it reads only the sliver's bookkeeping.
  ///
  /// A message changes shape when its turn starts being laid out row by row
  /// (its transcript became known) or stops (it went back to one row): the
  /// anchored key is then gone, and the message's top row stands in. Its top
  /// edge is the message's top edge either way, so the reader does not move.
  double? _probeAnchor(String rowKey) {
    var index = _indexByRowKey[rowKey];
    if (index == null) {
      final messageId = messageIdOfRowKey(rowKey);
      if (messageId != null) {
        index =
            _indexByRowKey[turnRowKey(messageId, 'h')] ??
            _indexByRowKey['m:$messageId'];
      }
    }
    if (index == null) {
      return null;
    }
    return _geometry.placementOf(index)?.trailingEdge;
  }

  /// Schedules one anchor capture after the next frame. Called on every
  /// scroll, build and metrics change; coalesces to one capture per frame.
  void _armAnchorCapture() {
    if (_anchorCaptureArmed) {
      return;
    }
    _anchorCaptureArmed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _anchorCaptureArmed = false;
      if (mounted) {
        _captureAnchor();
      }
    });
  }

  /// Records the row under the viewport's top edge and where it is.
  ///
  /// Captured whatever the follow mode: when the reader leaves the live edge
  /// the anchor from the frame before is already in place.
  void _captureAnchor() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    _geometry.attach(position.context.notificationContext);
    final anchor = _geometry.anchorAtTop(position, _rowKeyAt);
    if (anchor != null) {
      _follow.anchor = anchor;
    }
    _recordLaidOutHeights();
  }

  /// Remembers the extent of every row laid out this frame.
  void _recordLaidOutHeights() {
    final width = _geometry.crossAxisExtent;
    if (width == null) {
      return;
    }
    for (final placement in _geometry.placements()) {
      final key = _rowKeyAt(placement.index);
      final revision = key == null ? null : _revisionByRowKey[key];
      if (key == null || revision == null) {
        continue;
      }
      _heights.recordMeasured(
        key,
        placement.trailingEdge - placement.leadingEdge,
        width: width,
        revision: revision,
      );
    }
  }
}
