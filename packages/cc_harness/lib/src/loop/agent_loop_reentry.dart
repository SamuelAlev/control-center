part of 'agent_loop_runner.dart';

/// The calls one model-issued call made through its reentry: the bounded
/// digest for its result block, and for the checklist at most one call, the
/// last checklist write in call order, reduced to what the checklist reads
/// ([ChecklistSupervisor.retainedWrite]).
class _NestedRecord {
  const _NestedRecord(this.digest, this.calls);

  static const _NestedRecord none = _NestedRecord([], []);

  final List<HarnessNestedToolCall> digest;
  final List<_ObservedCall> calls;
}

/// A bounded FIFO of slots. A waiter whose token is cancelled leaves the
/// queue at once, so cancelling a parent settles its queued calls too.
class _Lane {
  _Lane(this.limit);

  final int limit;
  var _active = 0;
  final Queue<Completer<bool>> _waiting = Queue<Completer<bool>>();

  /// Takes a slot; false when [token] was cancelled first.
  Future<bool> acquire(CancellationToken token) {
    if (token.isCancelled) {
      return Future<bool>.value(false);
    }
    if (_active < limit && _waiting.isEmpty) {
      _active++;
      return Future<bool>.value(true);
    }
    final waiter = Completer<bool>();
    _waiting.add(waiter);
    unawaited(
      token.whenCancelled.then((_) {
        if (!waiter.isCompleted && _waiting.remove(waiter)) {
          waiter.complete(false);
        }
      }),
    );
    return waiter.future;
  }

  /// Hands the slot to the next waiter, or frees it.
  void release() {
    while (_waiting.isNotEmpty) {
      final next = _waiting.removeFirst();
      if (!next.isCompleted) {
        next.complete(true);
        return;
      }
    }
    _active--;
  }
}

/// A deadline that stops counting while it is paused: a tool waiting on a
/// person is not running late. Pauses nest; the clock runs again when the
/// last one ends.
class _PausableDeadline {
  _PausableDeadline(this.limit, this._onExpire);

  final Duration limit;
  final void Function() _onExpire;
  final Stopwatch _running = Stopwatch();
  Timer? _timer;
  var _pauses = 0;
  var _started = false;
  var _done = false;

  void start() {
    if (_started || _done) {
      return;
    }
    _started = true;
    _arm();
  }

  void pause() {
    if (_done) {
      return;
    }
    _pauses++;
    if (_pauses == 1) {
      _running.stop();
      _timer?.cancel();
      _timer = null;
    }
  }

  void resume() {
    if (_done || _pauses == 0) {
      return;
    }
    _pauses--;
    _arm();
  }

  void _arm() {
    if (!_started || _pauses > 0 || _done) {
      return;
    }
    _running.start();
    final remaining = limit - _running.elapsed;
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (_done || _pauses > 0) {
        return;
      }
      _done = true;
      _onExpire();
    });
  }

  void dispose() {
    _done = true;
    _timer?.cancel();
  }
}

/// The loop's [ToolReentry] for one model-issued call.
///
/// Settles with its parent: [close] runs when the parent's execution ends (on
/// every path), cancels whatever is still in flight or queued, and makes any
/// later call settle as cancelled without emitting anything.
class _LoopReentry implements ToolReentry {
  _LoopReentry(
    this.s, {
    required this.parentToolUseId,
    required this.parentToken,
    required this.parentDeadline,
    required void Function(AgentLoopEvent event) emit,
  }) : _emitSink = emit;

  final _RunState s;
  final String parentToolUseId;
  final CancellationToken parentToken;
  final _PausableDeadline? parentDeadline;
  final void Function(AgentLoopEvent event) _emitSink;
  final CancellationTokenSource _settled = CancellationTokenSource();
  late final _Lane _parallel = _Lane(
    max(1, s.config.tools.maxParallelNestedCalls),
  );
  var _next = 0;

  /// Per call, in call order: what the digest keeps of it (null while the
  /// call runs). Bounded in total, whatever the number of calls: a name is
  /// kept while the names kept so far fit [harnessNestedCallDigestBytes] and
  /// its identifying arguments while those fit it too; past that a call keeps
  /// [_unkept] (it would not reach the digest, which stops at the first name
  /// that does not fit), so no call's arguments outlive it here.
  final List<HarnessNestedToolCall?> _records = [];
  var _namesKept = 0;
  var _argsKept = 0;

  /// What a call keeps once the digest's room is used up.
  static const HarnessNestedToolCall _unkept = HarnessNestedToolCall(name: '');

  /// The last checklist write in call order, reduced, and its call's slot.
  ({int slot, _ObservedCall call})? _checklistWrite;

  @override
  Map<String, HarnessTool> get callable => s.catalog.callable;

  /// The record of every call made so far, the digest bounded to
  /// [harnessNestedCallDigestBytes] in call order.
  ///
  /// Every call keeps its name while names fit, because how many calls ran
  /// and which tools they were is the evidence a summary needs most; the
  /// identifying arguments then fill what room is left, earliest call first.
  _NestedRecord get record {
    final entries = [for (final e in _records) ?e];
    final write = _checklistWrite?.call;
    if (entries.isEmpty && write == null) {
      return _NestedRecord.none;
    }
    final names = <HarnessNestedToolCall>[];
    var room = harnessNestedCallDigestBytes;
    for (final e in entries) {
      if (identical(e, _unkept)) {
        break;
      }
      final name = HarnessNestedToolCall(name: e.name, isError: e.isError);
      final c = _cost(name);
      if (c > room) {
        break;
      }
      room -= c;
      names.add(name);
    }
    final digest = [...names];
    for (var i = 0; i < digest.length; i++) {
      final full = entries[i];
      if (full.args.isEmpty) {
        continue;
      }
      final extra = _cost(full) - _cost(digest[i]);
      if (extra <= room) {
        room -= extra;
        digest[i] = full;
      }
    }
    return _NestedRecord(List.unmodifiable(digest), [?write]);
  }

  static int _cost(HarnessNestedToolCall c) => jsonEncode(c.toJson()).length;

  void close() => _settled.cancel('The tool that made this call finished.');

  void _emit(AgentLoopEvent event) {
    if (!_settled.isCancelled) {
      _emitSink(event);
    }
  }

  @override
  Future<ToolReentryOutcome> call(
    String name,
    Object? args, {
    CancellationToken? cancel,
    Duration? timeout,
    PersonWaitListener? onPersonWait,
    void Function(ToolGateVerdict verdict)? onToolStarted,
    ({int line, int column})? site,
  }) async {
    final id = '$parentToolUseId/${++_next}';
    final slot = _records.length;
    _records.add(null);
    final clock = Stopwatch()..start();
    ToolReentryOutcome outcome(_Gated gated) => ToolReentryOutcome(
      toolName: name,
      toolCallId: id,
      parentToolUseId: parentToolUseId,
      result: gated.result,
      status: gated.status,
      gate: gated.gate,
      duration: clock.elapsed,
      personWait: gated.personWait,
      stillRunning: gated.stillRunning,
    );
    final cancelledBeforeStart = _Gated(
      HarnessToolResult.error(
        'Cancelled before the tool could run.',
      ).withOutcome(ToolOutcome.cancelled),
      ToolReentryStatus.cancelled,
    );
    if (_settled.isCancelled) {
      // The parent already settled: its events are closed, and a call now
      // would run work nobody waits for.
      return outcome(cancelledBeforeStart);
    }
    final token = CancellationToken.any([parentToken, _settled.token, ?cancel]);
    Map<String, dynamic>? map;
    String? argsError;
    if (args is Map<String, dynamic>) {
      map = args;
    } else if (args is Map && args.keys.every((k) => k is String)) {
      map = args.cast<String, dynamic>();
    } else {
      argsError =
          'Tool arguments must be a JSON object, got '
          '${args == null ? 'null' : args.runtimeType}.';
    }
    final tool = map == null ? null : callable[name];
    final _Lane? lane;
    if (tool == null) {
      lane = null;
    } else if (s.batchingAllowed &&
        _isParallelSafe(tool) &&
        !tool.waitsOnPerson) {
      lane = _parallel;
    } else {
      // Effectful, gated or waiting on a person: one at a time across the
      // run, in call order, so a person faces one card or form at a time.
      lane = s.serialLane;
    }
    final startArgs = map ?? const <String, dynamic>{};
    if (lane != null && !await lane.acquire(token)) {
      _emit(
        LoopToolCallStart(
          toolName: name,
          toolUseId: id,
          args: startArgs,
          parentToolUseId: parentToolUseId,
          callSite: site,
        ),
      );
      _emit(
        LoopToolCallResult(
          toolName: name,
          toolUseId: id,
          result: cancelledBeforeStart.result,
          parentToolUseId: parentToolUseId,
        ),
      );
      _keep(slot, name, map, isError: true);
      return outcome(cancelledBeforeStart);
    }
    _Gated gated;
    try {
      _emit(
        LoopToolCallStart(
          toolName: name,
          toolUseId: id,
          args: startArgs,
          parentToolUseId: parentToolUseId,
          callSite: site,
        ),
      );
      final loopTimeout = s.config.tools.toolTimeout;
      gated = await s.gate.run(
        name: name,
        args: startArgs,
        argsError: argsError,
        toolCallId: id,
        parentToolUseId: parentToolUseId,
        context: s.ctx.withCancel(token),
        timeout: tool != null && tool.waitsOnPerson
            ? loopTimeout
            : _earlier(timeout, loopTimeout),
        waits: _PersonWaits(parentDeadline, onPersonWait),
        onToolStarted: onToolStarted,
      );
    } on Object catch (e) {
      gated = _Gated(
        HarnessToolResult.error('Tool "$name" failed: $e'),
        ToolReentryStatus.failed,
      );
    } finally {
      lane?.release();
    }
    _keep(slot, name, map, isError: gated.result.isError);
    if (gated.notice case final notice?) {
      _emit(LoopNotice(notice));
    }
    _emit(
      LoopToolCallResult(
        toolName: name,
        toolUseId: id,
        result: gated.result,
        parentToolUseId: parentToolUseId,
      ),
    );
    return outcome(gated);
  }

  /// Records call [slot] within the bounds of [_records]: never its
  /// arguments themselves, only their identifying part while it fits and, for
  /// a checklist write, what the checklist reads of it.
  void _keep(
    int slot,
    String name,
    Map<String, dynamic>? args, {
    required bool isError,
  }) {
    if (args != null) {
      if (s.guards.checklist?.retainedWrite(name, args) case final write?) {
        if (_checklistWrite == null || _checklistWrite!.slot < slot) {
          _checklistWrite = (slot: slot, call: (name: name, args: write));
        }
      }
    }
    final bare = HarnessNestedToolCall(name: name, isError: isError);
    final nameCost = _cost(bare);
    if (_namesKept + nameCost > harnessNestedCallDigestBytes) {
      _records[slot] = _unkept;
      return;
    }
    _namesKept += nameCost;
    final identifying = args == null
        ? const <String, Object?>{}
        : identifyingToolArgs(args);
    if (identifying.isEmpty) {
      _records[slot] = bare;
      return;
    }
    final full = HarnessNestedToolCall(
      name: name,
      args: identifying,
      isError: isError,
    );
    final extra = _cost(full) - nameCost;
    if (_argsKept + extra > harnessNestedCallDigestBytes) {
      _records[slot] = bare;
      return;
    }
    _argsKept += extra;
    _records[slot] = full;
  }

  static Duration? _earlier(Duration? a, Duration? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a < b ? a : b;
  }
}
