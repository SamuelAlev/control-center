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
            conversationLastReadProvider((
              spaceId: widget.spaceId,
              conversationId: widget.conversationId,
            )),
          );
          if (liveCursorAsync.hasValue) {
            _readFrontier = liveCursorAsync.value?.at;
            _cursorSnapshotTaken = true;
          }
        }

        if (messages.isNotEmpty &&
            _cursorSnapshotTaken &&
            !_didInitialLanding) {
          _didInitialLanding = true;
          _lastNewest = messages.last;
          // Opening the conversation lands on its newest message, which reads
          // it: the stamp clears its notifications from the bell. The divider
          // keeps the snapshot taken above, so it still marks what was new.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _wasVisible) {
              _landOnLiveEdge();
              _stampCursor();
            }
          });
        }

        // The whole conversation: the live window, the history range loaded
        // around the reader, and stand-ins sized from the outline for the
        // rest (see `composeFeedTimeline`).
        final outline = window.hasMore ? _outline : null;
        final timeline = composeFeedTimeline(
          live: messages,
          liveHasMore: window.hasMore,
          outline: outline,
          range: _range,
        );
        if (timeline.outlineStale) {
          _refreshOutline(messages.first.id);
        }
        // Until the outline arrives the history above the window is not
        // known yet: a spinner holds its place.
        final showMore = window.hasMore && outline == null && !_outlineFailed;
        final unreadId = firstUnreadId(timeline.spans, _readFrontier);
        final spanItems = [
          for (final span in timeline.spans)
            if (span is LoadedSpan)
              buildFeedItems(
                span.messages,
                suppressOldestSeparator: span.afterGap,
                readFrontier:
                    unreadId != null &&
                        span.messages.any((m) => m.id == unreadId)
                    ? _readFrontier
                    : null,
                allowRetry: span.reachesNewest,
              )
            else
              const <FeedItem>[],
        ];
        _codeFont = ref.watch(codeFontFamilyProvider);
        _measurer = FeedTextMeasurer.of(context, codeFontFamily: _codeFont);
        _syncTurns([for (final items in spanItems) ...items]);
        final rows = <FeedRow>[];
        for (var i = 0; i < timeline.spans.length; i++) {
          switch (timeline.spans[i]) {
            case StandInSpan(:final entries):
              rows.addAll(entries.map(PlaceholderRow.new));
            case LoadedSpan():
              rows.addAll(
                expandFeedRows(spanItems[i], transcriptOf: _transcriptOf),
              );
          }
        }
        _rows = rows;
        final previousSlots = _slotKeysByIndex;
        _mirrorRowKeys(rows, hasMore: showMore);
        // The list caches extents by index; tell it which rows landed, left
        // or were replaced so every other row keeps its own extent. Runs
        // after [_rows] is updated: the list estimates the new rows through
        // [_estimateRowExtent], which reads it.
        syncListExtents(_listController, previousSlots, _slotKeysByIndex);

        final toolFocus = ref.watch(pendingFocusToolCallProvider);
        if (isVisible) {
          _maybeConsumePendingFocus(historyPending: showMore);
          _maybeConsumePendingToolFocus(toolFocus);
        }

        final keep = {for (final row in rows) ?messageIdOfRowKey(row.key)};
        _rowKeys.removeWhere((k, _) => !keep.contains(k));
        _keptRows.removeWhere((k, _) => !keep.contains(k));
        if (outline != null) {
          _scheduleRecenter();
        }

        _armAnchorCapture();

        final platformPhysics = ScrollConfiguration.of(
          context,
        ).getScrollPhysics(context);

        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            if (n.depth == 0) {
              _armAnchorCapture();
              _syncJumpControl();
            }
            return false;
          },
          child: NotificationListener<ScrollUpdateNotification>(
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
                          physics: AnchorFollowPhysics(
                            state: _follow,
                          ).applyTo(platformPhysics),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: rows.length + (showMore ? 1 : 0),
                          findChildIndexCallback: _findRowIndex,
                          itemBuilder: (context, index) =>
                              _buildRow(context, index, rows),
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
          ),
        );
      },
    );
  }
}
