part of 'message_feed.dart';

/// Builds one reverse-list row without rebuilding unchanged bubble widgets.
extension _FeedRowMethods on _SpaceMessageFeedState {
  Widget _buildRow(BuildContext context, int index, List<FeedRow> rows) {
    if (index == rows.length) {
      // The history above the live window, while its outline loads.
      return const KeyedSubtree(
        key: ValueKey<String>(_AnchorMethods.loadMoreRowKey),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CcSpinner()),
        ),
      );
    }
    final row = rows[rows.length - 1 - index];
    final Widget content;
    String? firstId;
    switch (row) {
      case ItemRow(:final item):
        switch (item) {
          case DayItem():
            content = DaySeparator(day: item.day);
          case UnreadItem():
            content = UnreadDivider(count: item.count);
          case MessageItem():
            firstId = item.message.id;
            content = _messageContent(item);
        }
      case TurnHeadRow(:final item):
        firstId = item.message.id;
        content = _highlightTurnRow(
          item,
          TurnHeadRowView(row: row, turn: _turns[item.message.id]!),
        );
      case TurnPartRow(:final item):
        content = _highlightTurnRow(
          item,
          TurnPartRowView(row: row, turn: _turns[item.message.id]!),
        );
      case TurnFootRow(:final item):
        final startThread = widget.onStartThread;
        content = _highlightTurnRow(
          item,
          TurnFootRowView(
            row: row,
            turn: _turns[item.message.id]!,
            onStartThread: startThread == null
                ? null
                : () => widget.onStartThread!(item.message),
            onOpenThread: widget.onOpenThread == null ? null : _openThread,
          ),
        );
      case PlaceholderRow(:final entry):
        firstId = entry.id;
        content = FeedPlaceholderRow(
          height: _placeholderExtent(index),
          alignEnd: entry.senderType == SenderType.user,
        );
    }
    // One retained layer per row. Scrolling then composites the cached
    // raster instead of re-recording every markdown/text bubble on the
    // way past.
    Widget out = RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: conversationColumnWidth),
          child: content,
        ),
      ),
    );
    // The first row of a message carries the key [Scrollable.ensureVisible]
    // reveals it by; the row key lets the list find a row's element again
    // when rows land around it (`findChildIndexCallback`).
    if (firstId != null) {
      out = KeyedSubtree(key: _ensureRowKey(firstId), child: out);
    }
    return KeyedSubtree(key: ValueKey<String>(row.key), child: out);
  }

  /// A stand-in takes exactly the extent the list reserved for its slot, so
  /// building it never moves anything.
  double _placeholderExtent(int index) {
    if (_listController.isAttached && index < _listController.numberOfItems) {
      final (extent, _) = _listController.extentForIndex(index);
      if (extent > 0) {
        return extent;
      }
    }
    return _estimateRowExtent(
      index,
      _geometry.crossAxisExtent ?? conversationColumnWidth,
    );
  }

  bool _isHighlighted(MessageItem m) =>
      _highlightedMessageId != null &&
      (m.message.id == _highlightedMessageId ||
          m.inlineMessages.any((s) => s.id == _highlightedMessageId));

  Widget _highlightTurnRow(MessageItem item, Widget row) =>
      _isHighlighted(item) ? Highlight(child: row) : row;

  /// A message rendered whole, reusing the widget instance while nothing it
  /// depends on changed.
  Widget _messageContent(MessageItem m) {
    final highlighted = _isHighlighted(m);
    final openThread = widget.onOpenThread;
    final startThread = widget.onStartThread;
    final kept = _keptRows[m.message.id];
    if (kept != null &&
        kept.message == m.message &&
        kept.collapseHeader == m.collapseHeader &&
        listEquals(kept.inlineMessages, m.inlineMessages) &&
        kept.canRetry == m.canRetry &&
        kept.highlighted == highlighted &&
        (kept.onOpenThread == null) == (openThread == null) &&
        (kept.onStartThread == null) == (startThread == null)) {
      return kept.child;
    }
    final bubble = SpaceMessageBubble(
      message: m.message,
      collapseHeader: m.collapseHeader,
      inlineMessages: m.inlineMessages,
      canRetry: m.canRetry,
      onStartThread: startThread == null
          ? null
          : () => widget.onStartThread!(m.message),
      // Parents rebuild with a fresh closure on every layout build, so
      // rows call through the State instead of capturing the instance.
      onOpenThread: openThread == null ? null : _openThread,
    );
    final content = highlighted ? Highlight(child: bubble) : bubble;
    _keptRows[m.message.id] = _KeptFeedRow(
      message: m.message,
      collapseHeader: m.collapseHeader,
      inlineMessages: m.inlineMessages,
      canRetry: m.canRetry,
      highlighted: highlighted,
      onOpenThread: openThread,
      onStartThread: startThread,
      child: content,
    );
    return content;
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
    required this.inlineMessages,
    required this.canRetry,
    required this.highlighted,
    required this.onOpenThread,
    required this.onStartThread,
    required this.child,
  });

  final Message message;
  final bool collapseHeader;
  final List<Message> inlineMessages;
  final bool canRetry;
  final bool highlighted;
  final void Function(String threadId)? onOpenThread;
  final void Function(Message message)? onStartThread;
  final Widget child;
}
