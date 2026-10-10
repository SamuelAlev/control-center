part of 'message_feed.dart';

/// The inner build tree for [SpaceMessageFeed]: item list, scroll listeners,
/// empty state and the jump-to-latest overlay.
extension _BuildMethods on _SpaceMessageFeedState {
  Widget _buildFeedBody(
    BuildContext context, {
    required ({List<Message> messages, bool hasMore}) window,
    required bool isVisible,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
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

        if (isVisible && !_cursorSnapshotTaken) {
          final liveCursorAsync = ref.watch(
            spaceUserLastReadAtProvider(widget.spaceId),
          );
          if (liveCursorAsync.hasValue) {
            _readFrontier = liveCursorAsync.value;
            _cursorSnapshotTaken = true;
          }
        }

        if (messages.isNotEmpty &&
            _cursorSnapshotTaken &&
            !_didInitialLanding) {
          _didInitialLanding = true;
          _lastNewestId = messages.last.id;
          _lastNewestAt = messages.last.createdAt;
          // Opening the conversation lands on its newest message, which reads
          // it: the stamp clears its notifications from the bell. The divider
          // keeps the snapshot taken above, so it still marks what was new.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _landOnLiveEdge();
              _stampCursor();
            }
          });
        }

        final items = buildFeedItems(
          messages,
          suppressOldestSeparator: window.hasMore,
          readFrontier: _readFrontier,
        );
        final previousItems = _items;
        _items = items;
        _shiftExtentsForNewRows(previousItems, items);

        if (isVisible) {
          _maybeConsumePendingFocus();
        }

        final keep = messages.map((m) => m.id).toSet();
        _rowKeys.removeWhere((k, _) => !keep.contains(k));
        _keptRows.removeWhere((k, _) => !keep.contains(k));

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
            if (n.depth == 0 && !_programmatic) {
              _follow.noteUserScroll();
            }
            return false;
          },
          child: NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              if (n.direction != ScrollDirection.idle) {
                if (_follow.mode == FeedFollowMode.following) {
                  _follow.mode = FeedFollowMode.free;
                }
              }
              return false;
            },
            child: Listener(
              onPointerDown: (_) {
                if (_follow.mode == FeedFollowMode.following) {
                  _follow.mode = FeedFollowMode.free;
                }
              },
              child: Stack(
                children: [
                  SelectionArea(
                    child: CcSelectionScope(
                      child: SuperListView.builder(
                        controller: _scrollController,
                        listController: _listController,
                        extentPrecalculationPolicy: _precalcPolicy,
                        extentEstimation: _estimateRowExtent,
                        delayPopulatingCacheArea: true,
                        reverse: true,
                        physics: ReverseFollowPhysics(
                          state: _follow,
                        ).applyTo(platformPhysics),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: items.length + (window.hasMore ? 1 : 0),
                        itemBuilder: (context, index) =>
                            _buildItem(context, index, items, window, theme),
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

  /// Tells the list about rows that landed at the newest end since the last
  /// build.
  ///
  /// The list caches measured extents by index, and in a reverse list the
  /// newest row is index 0 — so an arrival shifts every row up one index and,
  /// unannounced, each inherits its neighbour's extent. The resulting layout
  /// error is invisible on the live edge but nudges a reader browsing history
  /// by the height difference on every turn that lands below the fold.
  ///
  /// Runs after [_items] is updated: the list estimates the new rows' extents
  /// through [_estimateRowExtent], which reads it.
  void _shiftExtentsForNewRows(List<FeedItem> before, List<FeedItem> items) {
    final previous = before.isEmpty ? null : before.last;
    if (previous is! MessageItem ||
        !_listController.isAttached ||
        _listController.isLocked) {
      return;
    }
    final at = items.lastIndexWhere(
      (it) => it is MessageItem && it.message.id == previous.message.id,
    );
    if (at < 0) {
      return;
    }
    for (var i = at + 1; i < items.length; i++) {
      _listController.addItem(0);
    }
  }

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
      final highlighted = m.message.id == _highlightedMessageId;
      final openThread = widget.onOpenThread;
      final startThread = widget.onStartThread;
      final kept = _keptRows[m.message.id];
      if (kept != null &&
          kept.message == m.message &&
          kept.collapseHeader == m.collapseHeader &&
          kept.highlighted == highlighted &&
          (kept.onOpenThread == null) == (openThread == null) &&
          (kept.onStartThread == null) == (startThread == null)) {
        content = kept.child;
      } else {
        final bubble = SpaceMessageBubble(
          message: m.message,
          collapseHeader: m.collapseHeader,
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
