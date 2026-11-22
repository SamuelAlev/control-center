part of 'dispatch_session.dart';

/// The harness loops of a run that are parked, and what the silence watchdog
/// and a compaction need to know about them.
final class _RunParks {
  /// The parked loops (the main loop, `main`, and each subagent's, by its
  /// run id), parked on work they are owed, such as a live background command
  /// ([LoopPark]). A parked loop makes no model call and prints nothing, by
  /// design, so the silence watchdog skips while any loop is parked.
  final Set<String> loops = {};

  /// When the last park ended: like a resolved human wait, the end of a park
  /// gives the agent a full silence window again.
  DateTime? lastEndedAt;

  /// See [DispatchSessionPark.stillInFlightLines].
  InFlightLines? inFlightLines;

  /// See [DispatchSessionPark.silenceCheckEvery].
  Duration checkEvery = DispatchSession.silenceCheckInterval;

  /// See [DispatchSessionPark.compacting].
  bool compacting = false;

  /// See [DispatchSessionPark.lastCompactionEndedAt].
  DateTime? compactionEndedAt;

  void noteCompacting({required bool started}) {
    if (started) {
      compacting = true;
    } else if (compacting) {
      compacting = false;
      compactionEndedAt = clock.now();
    }
  }

  void note(String loop, {required bool parked}) {
    if (parked) {
      loops.add(loop);
    } else if (loops.remove(loop)) {
      lastEndedAt = clock.now();
    }
  }

  /// The silence watchdog's activity marks: [output] and [humanWaitEnd]
  /// (the session's own), then the end of the last park.
  List<DateTime?> marks(DateTime? output, DateTime? humanWaitEnd) => [
    output,
    humanWaitEnd,
    lastEndedAt,
  ];

  void clear() {
    loops.clear();
    lastEndedAt = null;
    compacting = false;
    compactionEndedAt = null;
  }
}

/// A run's parked harness loops, the "Still in flight" lines and the silence
/// watchdog's test seams.
extension DispatchSessionPark on DispatchSession {
  /// Whether a harness loop of this run is parked: waiting, with no model
  /// call, for a background command (or another [WouldStopPark]) to finish.
  /// The run's activity is "waiting", not "silent".
  bool get parked => _parks.loops.isNotEmpty;

  /// Whether the main harness loop is writing a compaction summary now
  /// ([LoopCompacting]): `agent_activity` reports the run as compacting.
  bool get compacting => _parks.compacting;

  /// When the main loop's last compaction summary ended, or null.
  DateTime? get lastCompactionEndedAt => _parks.compactionEndedAt;

  /// Extra lines for the "Still in flight" block the harness loop writes
  /// after each compaction ([LoopCompactionConfig.inFlightLines]): the goal,
  /// wakes, asks and stored keys. Set by whoever owns that state before the
  /// run starts; null adds none.
  InFlightLines? get stillInFlightLines => _parks.inFlightLines;
  set stillInFlightLines(InFlightLines? lines) => _parks.inFlightLines = lines;

  /// A Claude Code session compacted its context: the server writes the
  /// "Still in flight" block as the conversation's row, for the next turn.
  /// Best effort: a failed write leaves the earlier block in place.
  void _noteClaudeCompacted() {
    final write = deps.stillInFlight.claudeCompacted;
    final (ws, space, agent, conversation) =
        (workspaceId, spaceId, agentId, conversationId);
    if (write == null ||
        ws == null ||
        space == null ||
        agent == null ||
        conversation == null) {
      return;
    }
    unawaited(
      write(
        workspaceId: ws,
        spaceId: space,
        agentId: agent,
        conversationId: conversation,
      ).catchError((Object e) {
        CcInfraLog.warning('[claude] still-in-flight block not written: $e');
      }),
    );
  }

  /// Whether this run's harness got `repl`, so a refresh call in the block
  /// is written as a script call. False before the harness assembled its
  /// tools, and for a run that is not a built-in harness run.
  Future<bool> get runsScripts async {
    final setup = _codeModeScriptsSetup;
    return setup != null && (await setup).executions != null;
  }

  /// How often this session's silence watchdog checks:
  /// [DispatchSession.silenceCheckInterval] in production. Tests shorten it
  /// and move `clock` (package:clock) to cover a long silence in
  /// milliseconds.
  @visibleForTesting
  Duration get silenceCheckEvery => _parks.checkEvery;
  @visibleForTesting
  set silenceCheckEvery(Duration every) => _parks.checkEvery = every;

  /// Starts the silence watchdog as the CLI lanes do once their process is
  /// up; the built-in harness lane starts none.
  @visibleForTesting
  void startSilenceWatchdog() => _startSilenceWatchdog();

  /// Records a harness loop's [LoopPark]: [loop] names the loop (`main` or a
  /// subagent's run id).
  void _noteLoopPark(String loop, {required bool parked}) =>
      _parks.note(loop, parked: parked);

  /// Records the main loop's [LoopCompacting].
  void _noteCompacting({required bool started}) =>
      _parks.noteCompacting(started: started);
}
