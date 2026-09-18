part of 'space_screen.dart';

extension _SpaceFollow on _SpaceScreenState {
  void _releaseFollowing() {
    if (_follow.mode == FollowMode.following) {
      _follow.mode = FollowMode.free;
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _programmatic) return;
    final pos = _scroll.position;
    if (pos.pixels <= kFollowPinThreshold &&
        _follow.mode != FollowMode.following) {
      _reengageFollowing();
    }
    final show = pos.pixels > kFollowPinThreshold;
    if (show != _showJump) _set(() => _showJump = show);
  }

  void _reengageFollowing() {
    _follow.mode = FollowMode.following;
    _follow.anchorMessageId = null;
    if (_newWhileAway != 0) _set(() => _newWhileAway = 0);
  }

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

  Future<void> _anchorTo(String messageId, {required bool animate}) async {
    _follow.mode = FollowMode.anchored;
    _follow.anchorMessageId = messageId;
    final ctx = _rowKeys[messageId]?.currentContext;
    if (ctx == null) return;
    double alignment = 0.0;
    if (_scroll.hasClients) {
      final vh = _scroll.position.viewportDimension;
      if (vh > 0) alignment = (64 / vh).clamp(0.0, 0.9);
    }
    await _runProgrammatic(
      () => Scrollable.ensureVisible(
        ctx,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: animate
            ? CcMotion.resolve(context, const Duration(milliseconds: 250))
            : Duration.zero,
        curve: Curves.easeOut,
      ),
    );
  }

  void _landOnLiveEdge() {
    _follow.mode = FollowMode.following;
    _follow.anchorMessageId = null;
    if (_scroll.hasClients && _scroll.position.pixels != 0) {
      _runProgrammatic(() async => _scroll.jumpTo(0));
    }
    if (_newWhileAway != 0 || _showJump) {
      _set(() {
        _newWhileAway = 0;
        _showJump = false;
      });
    }
  }

  void _maybeAnnounce(List<MessageDto> messages) {
    final newest = messages.isNotEmpty ? messages.last : null;
    if (newest == null || newest.senderType == 'user') {
      _newestWasStreaming = false;
      return;
    }
    final meta = newest.metadata is Map ? newest.metadata as Map : null;
    final segments = decodeTranscript(meta?['segments']);
    final isAgentTurn = segments.isNotEmpty;
    final streaming =
        isAgentTurn && ((meta?['streamComplete'] as bool?) != true);
    if (streaming && _announcedStartFor != newest.id) {
      _announcedStartFor = newest.id;
      _announcedDoneFor = null;
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).agentResponding,
        Directionality.of(context),
      );
    } else if (!streaming &&
        _newestWasStreaming &&
        _announcedDoneFor != newest.id) {
      _announcedDoneFor = newest.id;
      final answer = newest.content.trim();
      final preview = answer.isEmpty
          ? AppLocalizations.of(context).agentFinished
          : (answer.length > 160 ? '${answer.substring(0, 160)}…' : answer);
      SemanticsService.sendAnnouncement(
        View.of(context),
        preview,
        Directionality.of(context),
      );
    }
    _newestWasStreaming = streaming;
  }

  void _onMessagesChanged(List<MessageDto> messages) {
    _maybeAnnounce(messages);
    if (messages.isEmpty) return;
    final newest = messages.last;
    final prevId = _lastNewestId;
    _lastNewestId = newest.id;
    if (!_didInitialLanding) {
      _didInitialLanding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _landOnLiveEdge();
      });
      return;
    }
    if (prevId == null || newest.id == prevId) return;
    if (newest.senderType == 'user') {
      _newWhileAway = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _anchorTo(newest.id, animate: true);
      });
    } else if (_follow.mode != FollowMode.following) {
      _set(() => _newWhileAway += 1);
    }
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _runProgrammatic(
      () => _scroll.animateTo(
        0,
        duration: CcMotion.resolve(context, const Duration(milliseconds: 300)),
        curve: Curves.easeOut,
      ),
    );
    _reengageFollowing();
  }
  Widget _activeBanner(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accentSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(AppIcons.loader, size: 14, color: t.accent),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).agentWorking,
              style: TextStyle(fontSize: 13, color: t.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
