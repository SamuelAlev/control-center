part of 'dispatch_session.dart';

/// The run summary for a run a person stopped, whichever stop path ran: the
/// dispatch session's terminate and the dispatch service's run-row close.
const kRunStoppedByUserSummary = 'Stopped by user';

/// The run-log reason for runs still in flight when the server shut down.
const kRunStoppedByShutdownSummary = 'Stopped: the server shut down';

/// The fraction of [DispatchSession.costCapMicros], in tenths, at which a run
/// that can take input is told to wrap up (9 = 90%).
const kRunCostWrapUpTenths = 9;

/// The wrap-up note a run near its cost cap is given on a backend that takes
/// input mid-run. The same words the built-in harness loop steers with
/// (`AgentLoopGuards`' external budget pressure), so every backend tells the
/// agent the same thing.
const kRunCostWrapUpSteer =
    'You are approaching this run’s cost budget. Wrap up your work '
    'NOW: persist important notes, leave the worktree in a coherent '
    'state and deliver your result — a follow-up run continues '
    'from what you leave behind.';

/// How a run is ending, as the session decided it: the reason, the cost cap
/// and its wrap-up note, and the terminal write a shutdown waits for.
class _RunEnd {
  /// Why the run ended, once the session decided it (a stop, the watchdog,
  /// the cost cap, a usage limit). The first decision stands. Null leaves
  /// the reason to the run's outcome: `completed`, or `error` when it failed.
  RunEndReason? reason;

  /// The provider's reset time for a [RunEndReason.usageLimit] end.
  DateTime? limitResetsAt;

  /// The pending terminal write `_failRun` started, for a caller (a server
  /// shutdown) that must not return before it lands.
  Future<void>? failWrite;

  /// Whether the run's spend reached its cost cap. Set once by
  /// `_observeRunCost`; the backend that reported the spend stops the run.
  bool costCapReached = false;

  /// Whether the run crossed [kRunCostWrapUpTenths] of its cap and the
  /// wrap-up note is still to be delivered.
  bool wrapUpDue = false;

  /// Whether the wrap-up note was delivered (it is given once).
  bool wrapUpGiven = false;

  /// What the run spent, from the usage reports it emitted: the cost a run
  /// the session ends itself settles with (`_failRun`).
  final RunCostTally usage = RunCostTally();

  /// The built-in harness run's model-call accounting, once it started:
  /// `_failRun` waits for its writes (and its subagents') before it settles.
  HarnessRunAccounting? accounting;
}

extension _DispatchSessionRunEnd on DispatchSession {
  /// Why the run ended, once the session decided it ([_RunEnd.reason]).
  RunEndReason? get _endReason => _runEnd.reason;

  /// The provider's reset time for a [RunEndReason.usageLimit] end.
  DateTime? get _limitResetsAt => _runEnd.limitResetsAt;

  /// The pending terminal write `_failRun` started.
  Future<void>? get _failWrite => _runEnd.failWrite;
  set _failWrite(Future<void>? write) => _runEnd.failWrite = write;

  /// Whether the run's spend reached [DispatchSession.costCapMicros].
  bool get _costCapReached => _runEnd.costCapReached;

  /// The run's terminal event, carrying how it ended.
  DoneEvent get _doneEvent =>
      DoneEvent(endReason: _endReason, limitResetsAt: _limitResetsAt);

  /// A server shutdown's stamp: the run's row settles now as a server stop,
  /// rather than being found by the orphan reaper at the next boot (which
  /// settles it the same way if this write never lands).
  void _stampServerStop(String summary) {
    _markEndReason(RunEndReason.serverStopped);
    if (!emittedDone && !_abortStarted) {
      _failRun(summary, quiet: true);
    }
  }

  /// Records why the run is ending. The first reason wins: a person's stop
  /// that kills a process mid-cap-check is still a person's stop.
  void _markEndReason(RunEndReason reason, {DateTime? limitResetsAt}) {
    if (_runEnd.reason != null) {
      return;
    }
    _runEnd.reason = reason;
    if (reason == RunEndReason.usageLimit) {
      _runEnd.limitResetsAt = limitResetsAt;
    }
  }

  /// Checks the run's total spend so far, [spentMicros], against
  /// [DispatchSession.costCapMicros], for a backend whose own loop does not
  /// enforce the cap (Claude Code, ACP; the built-in harness checks it in
  /// its loop).
  ///
  /// Returns true the one time the cap is reached: the run's end reason
  /// becomes [RunEndReason.budget] and the caller stops the run. Crossing
  /// [kRunCostWrapUpTenths] of the cap makes [_takeCostWrapUp] return the
  /// wrap-up note once.
  bool _observeRunCost(int spentMicros) {
    final cap = costCapMicros;
    final end = _runEnd;
    if (cap == null || end.costCapReached) {
      return false;
    }
    if (spentMicros >= cap) {
      end.costCapReached = true;
      end.wrapUpDue = false;
      _markEndReason(RunEndReason.budget);
      addEvent(
        DebugEvent(
          content:
              '[sandbox] stopped: the run reached its cost cap '
              '(${_usd(spentMicros)} of ${_usd(cap)}).',
        ),
      );
      return true;
    }
    if (!end.wrapUpGiven && spentMicros * 10 >= cap * kRunCostWrapUpTenths) {
      end.wrapUpDue = true;
    }
    return false;
  }

  /// The wrap-up note, once, when the run crossed [kRunCostWrapUpTenths] of
  /// its cap; null otherwise.
  String? _takeCostWrapUp() {
    final end = _runEnd;
    if (!end.wrapUpDue || end.wrapUpGiven) {
      return null;
    }
    end.wrapUpDue = false;
    end.wrapUpGiven = true;
    return kRunCostWrapUpSteer;
  }

  /// Holds the run's spend, with the turn in flight estimated, against the
  /// cost cap. Called as each streamed model call grows.
  ///
  /// A goal segment is usually one turn, and Claude Code reports cost only
  /// with the turn's `result`, so the cap is compared on estimates too: the
  /// spend the results reported so far plus every call no `result` has
  /// reported yet (`ClaudeRunState.unreported`), each priced at its serving
  /// model's rates (the model catalog's, the same prices the built-in
  /// harness's accounting uses). Past [kRunCostWrapUpTenths] of the cap the
  /// running turn is steered to wrap up; at the cap it is interrupted, and
  /// the run ends with [RunEndReason.budget]. The settled cost is still the
  /// one the turn's `result` reports. A call whose model the catalog has no
  /// price for adds nothing here; its turn is checked on its result.
  void _observeClaudeRunningCost() {
    if (costCapMicros == null || _runEnd.costCapReached) {
      return;
    }
    final end = _runEnd;
    final spent =
        _claude.dispatchTotals.costMicros + _claude.unreported.pricedMicros;
    if (_observeRunCost(spent)) {
      unawaited(_interruptClaudeTurn());
      return;
    }
    final wrapUp = _takeCostWrapUp();
    if (wrapUp == null) {
      return;
    }
    if (_claude.stdin == null || _claude.heldLines != null) {
      // No lane into the running turn: the note waits for the next one.
      end
        ..wrapUpGiven = false
        ..wrapUpDue = true;
      return;
    }
    _claude.steered.add(wrapUp);
    _claude.stdin!.add(_claudeUserLine(wrapUp));
    addEvent(
      DebugEvent(
        content:
            '[claude] steered the running turn to wrap up: it is near its '
            'cost cap',
      ),
    );
  }

  /// [event], folded into the run's spend first when it is a usage report.
  AgentProcessEvent _withUsageCounted(AgentProcessEvent event) {
    if (event is UsageEvent) {
      _runEnd.usage.add(event);
    }
    return event;
  }

  static String _usd(int micros) =>
      'USD ${(micros / 1000000).toStringAsFixed(2)}';
}
