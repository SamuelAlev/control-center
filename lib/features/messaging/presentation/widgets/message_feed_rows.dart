part of 'message_feed.dart';

/// Builds one reverse-list row without rebuilding unchanged bubble widgets.
extension _FeedRowMethods on _SpaceMessageFeedState {
  Widget _buildItem(
    BuildContext context,
    int index,
    List<FeedItem> items,
    ({List<Message> messages, bool hasMore}) window,
    ThemeData theme,
  ) {
    if (window.hasMore && index == items.length) {
      // Past the window ceiling nothing can load, so a spinner there would
      // just animate (a ticker and a repaint per frame) for as long as the
      // reader sits at the top. Hold the row's place without it.
      final canLoad =
          ref.read(spaceFeedWindowProvider(widget.conversationId)) <
          kSpaceFeedMaxWindow;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: canLoad
            ? const Center(child: CcSpinner())
            : const SizedBox.shrink(),
      );
    }
    final item = items[items.length - 1 - index];
    final Widget content;
    GlobalKey? rowKey;
    if (item is DayItem) {
      content = DaySeparator(day: item.day);
    } else if (item is UnreadItem) {
      content = UnreadDivider(count: item.count);
    } else {
      final m = item as MessageItem;
      rowKey = _ensureRowKey(m.message.id);
      final highlighted =
          m.message.id == _highlightedMessageId ||
          m.inlineMessages.any((s) => s.id == _highlightedMessageId);
      final openThread = widget.onOpenThread;
      final startThread = widget.onStartThread;
      final kept = _keptRows[m.message.id];
      if (kept != null &&
          kept.message == m.message &&
          kept.collapseHeader == m.collapseHeader &&
          listEquals(kept.inlineMessages, m.inlineMessages) &&
          kept.highlighted == highlighted &&
          (kept.onOpenThread == null) == (openThread == null) &&
          (kept.onStartThread == null) == (startThread == null)) {
        content = kept.child;
      } else {
        final bubble = SpaceMessageBubble(
          message: m.message,
          collapseHeader: m.collapseHeader,
          inlineMessages: m.inlineMessages,
          onStartThread: startThread == null
              ? null
              : () => widget.onStartThread!(m.message),
          // Parents rebuild with a fresh closure on every layout build, so
          // rows call through the State instead of capturing the instance.
          onOpenThread: openThread == null ? null : _openThread,
        );
        content = highlighted ? Highlight(child: bubble) : bubble;
        _keptRows[m.message.id] = _KeptFeedRow(
          message: m.message,
          collapseHeader: m.collapseHeader,
          inlineMessages: m.inlineMessages,
          highlighted: highlighted,
          onOpenThread: openThread,
          onStartThread: startThread,
          child: content,
        );
      }
    }
    // One retained layer per row. Scrolling then composites the cached
    // raster instead of re-recording every markdown/text bubble on the
    // way past. The window is only a handful of rows, so the layer count
    // stays small.
    Widget row = RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: conversationColumnWidth),
          child: content,
        ),
      ),
    );
    if (rowKey != null) {
      row = KeyedSubtree(key: rowKey, child: row);
    }
    return row;
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
    required this.highlighted,
    required this.onOpenThread,
    required this.onStartThread,
    required this.child,
  });

  final Message message;
  final bool collapseHeader;
  final List<Message> inlineMessages;
  final bool highlighted;
  final void Function(String threadId)? onOpenThread;
  final void Function(Message message)? onStartThread;
  final Widget child;
}
