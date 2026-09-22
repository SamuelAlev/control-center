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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _landOnLiveEdge();
            }
          });
        }

        final items = buildFeedItems(
          messages,
          suppressOldestSeparator: window.hasMore,
          readFrontier: _readFrontier,
        );
        _items = items;

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
                _watchingOwnTurn = false;
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

  Widget _buildItem(
    BuildContext context,
    int index,
    List<FeedItem> items,
    ({List<Message> messages, bool hasMore}) window,
    ThemeData theme,
  ) {
    if (window.hasMore && index == items.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CcSpinner()),
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
          identical(kept.onOpenThread, openThread) &&
          (kept.onStartThread == null) == (startThread == null)) {
        content = kept.child;
      } else {
        final bubble = SpaceMessageBubble(
          message: m.message,
          collapseHeader: m.collapseHeader,
          onStartThread: startThread == null
              ? null
              : () => widget.onStartThread!(m.message),
          onOpenThread: openThread,
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
