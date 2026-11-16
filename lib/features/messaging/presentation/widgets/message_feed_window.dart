part of 'message_feed.dart';

/// What the feed shows: the live window (frozen while the pane is hidden),
/// and the history beyond it.
extension _WindowMethods on _SpaceMessageFeedState {
  /// Whether a live agent turn is streaming below the fold — drives the
  /// jump-to-latest "streaming" indicator.
  bool get _isLiveBelow {
    final newestId = _lastNewest?.id;
    if (newestId == null) {
      return false;
    }
    final registry = ref.read(activeStreamRegistryProvider);
    return registry.isActive(newestId) &&
        _scrollController.hasClients &&
        _scrollController.position.pixels > kFollowPinThreshold;
  }

  Widget _buildFeed(BuildContext context) {
    // Hidden-pane freeze. When this feed sits in a hidden IndexedStack tab,
    // Visibility.of reports false (and registers a dependency, so build
    // re-runs when the tab flips). While hidden we drop every live
    // watch/listen — Riverpod recomputes the dependency set per build, the
    // autoDispose providers lose their last listener, the RPC subscriptions
    // unsubscribe and server work for this space stops — and render the
    // frozen snapshots instead. The tree stays mounted with identical
    // content, so the ScrollController offset, FollowState, _didInitialLanding,
    // and _rowKeys all survive the nap.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      // Reveal: navigating back to this chat lands on the live edge, so the
      // surviving offset from before the nap is reset — instantly, next frame,
      // no animation. Done here rather than off a window emission because a
      // short nap may not produce one (the provider is still warm) and the
      // reader must land at the bottom either way. Landing there is reading
      // it, so acknowledge again even if the newest message kept its id: its
      // completion notification may have arrived while this pane was hidden.
      _pendingRevealReconcile = true;
      _lastStampedNewestId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _wasVisible) {
          _landOnLiveEdge();
          _stampCursor();
        }
      });
    } else if (!isVisible && _wasVisible) {
      _cursorDebounce?.cancel();
    }
    _wasVisible = isVisible;

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final ({List<Message> messages, bool hasMore}) window;
    final feedRef = (
      spaceId: widget.spaceId,
      conversationId: widget.conversationId,
    );
    if (isVisible) {
      // Live turn relay: folds `messaging.watchSpaceTurns` into the
      // active-stream registry the agent bubbles render from. Watched here so
      // the subscription lives exactly as long as the feed is on screen.
      ref.watch(spaceTurnRelayProvider(widget.spaceId));
      final windowAsync = ref.watch(spaceFeedWindowedProvider(feedRef));
      ref.listen(spaceFeedWindowedProvider(feedRef), (_, next) {
        _onWindowChanged(next.value);
      });

      // Read the last value rather than `.when` so a reload (window growth
      // from loadMore, a streaming DB flush, or the re-subscribe after a
      // hidden spell) never replaces the list with a spinner — which would
      // destroy the ScrollController and snap the reverse list back to the
      // bottom. Until the first fresh emission after a reveal, the frozen
      // snapshot keeps rendering.
      final fresh = windowAsync.value ?? _frozenWindow;
      if (fresh == null) {
        if (windowAsync.hasError) {
          return Center(child: Text(failureMessage(l10n, windowAsync.error!)));
        }
        return const Center(child: CcSpinner());
      }
      window = fresh;
      _frozenWindow = fresh;
      // History beyond the live window: its outline, and the range loaded
      // around where the reader is. Only needed when there is history.
      if (fresh.hasMore) {
        final outlineAsync = ref.watch(conversationOutlineProvider(feedRef));
        if (outlineAsync.value case final outline?) {
          _outline = outline;
        }
        _outlineFailed = outlineAsync.hasError && _outline == null;
        final anchorId = _rangeAnchorId;
        if (anchorId != null) {
          final rangeAsync = ref.watch(
            spaceFeedRangeProvider((
              spaceId: widget.spaceId,
              conversationId: widget.conversationId,
              anchorId: anchorId,
            )),
          );
          if (rangeAsync.value case final range?) {
            _range = range.messages;
          } else if (rangeAsync.hasError) {
            _onRangeFailed(anchorId);
          }
        }
      }
    } else {
      final frozen = _frozenWindow;
      if (frozen == null) {
        // Hidden before anything ever emitted: nothing to freeze. The live
        // watches (and the spinner-to-content transition) resume on reveal.
        return const Center(child: CcSpinner());
      }
      window = frozen;
    }

    return _buildFeedBody(
      context,
      window: window,
      isVisible: isVisible,
      theme: theme,
      l10n: l10n,
    );
  }
}
