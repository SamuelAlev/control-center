part of 'message_feed.dart';

/// The agent turns in the window: their shared per-turn state, and the
/// transcript each one is laid out from.
extension _TurnMethods on _SpaceMessageFeedState {
  /// Keeps one [FeedTurnState] per agent turn in [items]; drops the rest.
  ///
  /// Dropped states are disposed after the frame: the rows that listen to
  /// them are only replaced by this build.
  void _syncTurns(List<FeedItem> items) {
    final ids = <String>{
      for (final item in items)
        if (item is MessageItem && item.message.isAgentTurn) item.message.id,
    };
    final dropped = <FeedTurnState>[];
    _turns.removeWhere((id, turn) {
      if (ids.contains(id)) {
        return false;
      }
      turn.live.structure.removeListener(_onTurnStructure);
      dropped.add(turn);
      return true;
    });
    if (dropped.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final turn in dropped) {
          turn.dispose();
        }
      });
    }
    final registry = ref.read(activeStreamRegistryProvider);
    for (final id in ids) {
      _turns.putIfAbsent(id, () {
        final turn = FeedTurnState(registry, id);
        turn.live.structure.addListener(_onTurnStructure);
        return turn;
      });
    }
  }

  /// The transcript [item]'s turn is laid out from, or null to render it as
  /// one row. Also readies the turn's row renderer for this build.
  TurnTranscript? _transcriptOf(MessageItem item) {
    final turn = _turns[item.message.id];
    if (turn == null) {
      return null;
    }
    final message = item.message;
    // A turn that streamed here settles onto the relay's last snapshot. The
    // list row ships without segments, so confirm the finished transcript
    // with the server, as a single-row turn bubble does: the persisted one
    // can hold text the stream never delivered, and the snapshot would cut
    // the turn off until something else refetched it. One read per turn: it
    // stops once the transcript has arrived.
    final List<TranscriptSegment>? confirmed =
        turn.sawLive &&
            !turn.confirmed &&
            message.isStreamingComplete &&
            message.metadata?['segments_elided'] == true
        ? ref.watch(messageDetailProvider(message.id)).asData?.value?.transcript
        : null;
    final transcript = turn.transcriptFor(
      message,
      cached: () => _transcriptCache?.get(message.id),
      confirmed: confirmed,
    );
    if (transcript != null) {
      turn.rows.prepare(
        codeFont: _codeFont,
        isLive: transcript.isLive,
        segmentCount: transcript.segments.length,
      );
    }
    return transcript;
  }

  /// A live turn opened or closed a segment, or finished: its rows change.
  void _onTurnStructure() {
    if (mounted) {
      _set(() {});
    }
  }

  /// A transcript read landed. A turn in the window that was one row can now
  /// be laid out row by row. Deferred to a microtask: the read can land while
  /// the tree is building.
  void _onTranscriptPut(String messageId) {
    if (!_turns.containsKey(messageId)) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted) {
        _set(() {});
      }
    });
  }
}
