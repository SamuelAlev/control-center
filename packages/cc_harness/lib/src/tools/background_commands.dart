/// Background shell commands that live inside one run.
///
/// The harness `bash` tool can start a command with `run_in_background` and
/// return at once with a handle (`b1`, `b2`, …). The command keeps running
/// through the same runner, policy and sandbox as a foreground one, and its
/// output streams into this registry, where `read_output` pages it by the
/// command's output handle while it runs. When it exits, or its timeout kills
/// it, a notice goes to the run's aside lane and the full output is written to
/// the run's [ToolOutputStore].
///
/// A background command never outlives its run: the loop parks instead of
/// ending a turn while one is live, and kills every live command when the run
/// ends for any reason ([BackgroundCommandRegistry.killAll]).
library;

import 'dart:async';

import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/context/tool_call_form.dart';
import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_output_store.dart';
import 'package:cc_harness/src/context/wake_data.dart';
import 'package:cc_harness/src/tools/background_notify.dart';
import 'package:cc_harness/src/tools/command_runner.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// Where a background command is in its life.
enum BackgroundCommandStatus {
  /// Spawned and not yet finished.
  running,

  /// Exited on its own; [BackgroundCommand.exitCode] says how.
  exited,

  /// Killed by its own timeout.
  timedOut,

  /// Killed by `bash_kill` or because its run ended.
  killed,
}

/// Why a command was killed, when it was.
enum _KillReason { user, runEnded }

/// One background command of a run, readable while it runs.
///
/// Output is kept in memory with a bound: the first [headChars] characters
/// verbatim and a rolling tail of the rest up to [maxChars] in all, so a
/// command that floods its output cannot grow the server's memory without
/// limit. Reads name what was dropped.
class BackgroundCommand {
  BackgroundCommand._({
    required this.command,
    required this.timeout,
    required this.outputHandle,
    required this.scope,
    required this.clock,
    this.notify,
  });

  /// The command's `notify` matcher, or null when it was started without
  /// one.
  final BackgroundNotify? notify;

  /// Whether the command's exit notice reached the model (the loop drained it
  /// into the conversation). `bash_output` and `bash_kill` say so then, so the
  /// model does not act on the result twice.
  bool get noticeDelivered => _noticeDelivered;
  bool _noticeDelivered = false;

  /// Called when a `notify` line matched, so a parked run can wake.
  void Function()? _onNotifyLine;

  /// Characters kept verbatim from the start of the output.
  static const int headChars = 256 * 1024;

  /// Characters kept in all (head plus rolling tail).
  static const int maxChars = 2 * 1024 * 1024;

  /// The handle the model names (`b1`, `b2`, …). Set when the command is
  /// spawned.
  String get handle => _handle;
  String _handle = '';

  /// The command line, as the model wrote it.
  final String command;

  /// How long the command may run before it is killed.
  final Duration timeout;

  /// The `read_output` handle that pages this command's output, live while it
  /// runs and for the rest of the run after it ends.
  final String outputHandle;

  /// The run scope the output is stored under, when the run has one.
  final ToolOutputScope? scope;

  /// The registry's clock.
  final DateTime Function() clock;

  /// When the command was spawned.
  DateTime get startedAt => _startedAt;
  late DateTime _startedAt;

  /// The command's state.
  BackgroundCommandStatus get status => _status;
  BackgroundCommandStatus _status = BackgroundCommandStatus.running;

  /// Whether the command is still running.
  bool get isLive => _status == BackgroundCommandStatus.running;

  /// The exit code once it [BackgroundCommandStatus.exited] (also set for a
  /// killed command when the runner reported one).
  int? get exitCode => _exitCode;
  int? _exitCode;

  /// When it finished, or null while it runs.
  DateTime? get endedAt => _endedAt;
  DateTime? _endedAt;

  /// The durable handle of the full output written to the run's output store
  /// when the command finished, or null (still running, or not stored).
  String? get storedOutputHandle => _storedOutputHandle;
  String? _storedOutputHandle;

  /// How long it has run (until now, or until it ended).
  Duration get elapsed => (_endedAt ?? clock()).difference(_startedAt);

  final StringBuffer _head = StringBuffer();
  String _tail = '';
  final StringBuffer _pending = StringBuffer();
  int _total = 0;
  int _cursor = 0;

  final CancellationTokenSource _kill = CancellationTokenSource();
  _KillReason? _killReason;
  bool _timedOut = false;
  Timer? _timer;
  final Completer<void> _settled = Completer<void>();

  /// Completes once the command finished and its notice (if any) was sent.
  Future<void> get settled => _settled.future;

  /// Every character the command has written so far, including any the
  /// bound dropped.
  int get totalChars => _total;

  void _append(String chunk) {
    if (chunk.isEmpty) {
      return;
    }
    _total += chunk.length;
    if (notify?.add(chunk) ?? false) {
      _onNotifyLine?.call();
    }
    var rest = chunk;
    if (_head.length < headChars) {
      final room = headChars - _head.length;
      if (rest.length <= room) {
        _head.write(rest);
        return;
      }
      _head.write(rest.substring(0, room));
      rest = rest.substring(room);
    }
    _pending.write(rest);
    // Compact with slack, so a chatty command does not reslice per chunk.
    if (_pending.length > 64 * 1024) {
      _flushPending();
    }
  }

  void _flushPending() {
    if (_pending.isEmpty) {
      return;
    }
    final combined = '$_tail$_pending';
    _pending.clear();
    const tailCap = maxChars - headChars;
    _tail = combined.length > tailCap
        ? combined.substring(combined.length - tailCap)
        : combined;
  }

  /// Characters the bound dropped between the head and the tail.
  int get _dropped {
    _flushPending();
    return _total - _head.length - _tail.length;
  }

  /// The output as kept: verbatim when nothing was dropped, else the head, a
  /// marker naming how much was dropped, and the tail.
  String get output {
    final dropped = _dropped;
    if (dropped <= 0) {
      return '$_head$_tail';
    }
    return '$_head\n[… $dropped characters of output were not kept …]\n'
        '$_tail';
  }

  /// The last [chars] characters of the output.
  String tail(int chars) {
    final text = output;
    return text.length <= chars ? text : text.substring(text.length - chars);
  }

  /// The output written since the last call (the first call: since the
  /// start), naming any part the bound dropped.
  String takeNewOutput() {
    final dropped = _dropped;
    final from = _cursor;
    _cursor = _total;
    if (from >= _total) {
      return '';
    }
    final head = _head.toString();
    final tailStart = _total - _tail.length;
    if (from >= tailStart) {
      return _tail.substring(from - tailStart);
    }
    final buf = StringBuffer();
    if (from < head.length) {
      buf.write(head.substring(from));
    }
    if (dropped > 0) {
      final missed = from < head.length ? dropped : tailStart - from;
      buf.write('\n[… $missed characters of output were not kept …]\n');
    }
    buf.write(_tail);
    return buf.toString();
  }

  /// A bounded slice of [output] for `read_output`.
  ToolOutputChunk read({required int offsetChars, required int limitChars}) =>
      sliceStoredOutput(
        output,
        offsetChars: offsetChars,
        limitChars: limitChars,
        toolName: 'bash',
      );

  /// One line describing the state, for tool results: `b1 running for 3 min`,
  /// `b1 exited with code 0 after 12 s`, `b1 timed out after 10 min`.
  String get stateLine => switch (_status) {
    BackgroundCommandStatus.running =>
      '$handle running for ${formatBackgroundDuration(elapsed)}',
    BackgroundCommandStatus.exited =>
      '$handle exited with code $_exitCode after '
          '${formatBackgroundDuration(elapsed)}',
    BackgroundCommandStatus.timedOut =>
      '$handle timed out after ${formatBackgroundDuration(timeout)} and was '
          'killed',
    BackgroundCommandStatus.killed =>
      '$handle was killed after ${formatBackgroundDuration(elapsed)}',
  };
}

/// What [BackgroundCommandRegistry.start] did.
sealed class BackgroundStart {
  const BackgroundStart();
}

/// The command is running in the background.
final class BackgroundStarted extends BackgroundStart {
  /// Creates the "started" outcome.
  const BackgroundStarted(this.command);

  /// The command, with its handle.
  final BackgroundCommand command;
}

/// The command was not started: the registry refused it (four live, run
/// ended) before anything was asked or spawned.
final class BackgroundRefused extends BackgroundStart {
  /// Creates the "refused" outcome.
  const BackgroundRefused(this.message);

  /// Why, for the model.
  final String message;
}

/// The runner answered before the command was spawned: a policy or a person
/// refused it, or it could not be started.
final class BackgroundNotStarted extends BackgroundStart {
  /// Creates the "not started" outcome.
  const BackgroundNotStarted(this.result);

  /// The runner's result (denied, or a failure to start).
  final HarnessCommandResult result;
}

/// Starts a command through a runner, handing it the kill token and the
/// observer the registry listens with.
typedef BackgroundLaunch =
    Future<HarnessCommandResult> Function(
      CancellationToken kill,
      HarnessCommandObserver observer,
      int timeoutSeconds,
    );

/// The live background commands of ONE run.
///
/// Each run gets its own (the tool registry is built per run, nested runs
/// included), so a subagent's commands die with the subagent's run.
class BackgroundCommandRegistry {
  /// Creates an empty registry. [store] is where a finished command's full
  /// output is written so its handle outlives the run.
  BackgroundCommandRegistry({
    this.store,
    this.maxLive = maxLiveCommands,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Live background commands one run may have at once.
  static const int maxLiveCommands = 4;

  /// Default timeout of a background command, in seconds.
  static const int defaultTimeoutSeconds = 600;

  /// Longest timeout a background command may ask for, in seconds.
  static const int maxTimeoutSeconds = 3600;

  /// Output characters an exit notice carries.
  static const int noticeTailChars = 2000;

  /// Characters of the command line an exit notice carries.
  static const int noticeCommandChars = 200;

  /// Where a finished command's output is stored, when the run has a store.
  final ToolOutputStore? store;

  /// Live commands allowed at once.
  final int maxLive;

  final DateTime Function() _clock;

  /// How this run calls `bash_output` and `bash_kill`, for the texts that
  /// name them. Bound by the dispatch once the run's surface is built
  /// ([bindCallForms]); until then they are named in plain words.
  ToolCallForms get callForms => _callForms;
  ToolCallForms _callForms = plainToolForm;

  /// Sets [callForms] from the run's materialized surface.
  void bindCallForms(ToolCallForms forms) => _callForms = forms;

  /// Receives each exit notice: the text for the aside lane and the command's
  /// handle. Bound by the loop; a notice with no listener is dropped (the
  /// command's state stays readable through `bash_output`).
  void Function(String notice, String handle)? onNotice;

  /// Receives a `notify` delivery of a command that ended with matched lines
  /// still waiting (they go out just before its exit notice). Deliveries of a
  /// running command are taken at the turn boundary instead
  /// ([takeNotifyDeliveries]).
  void Function(String delivery, String handle)? onNotify;

  /// Called when a command starts or settles, so a host can refresh what it
  /// shows.
  void Function()? onChanged;

  final List<Completer<void>> _eventWaiters = [];

  final List<BackgroundCommand> _commands = [];
  int _starting = 0;
  int _seq = 0;
  bool _closed = false;
  final List<Completer<void>> _settleWaiters = [];

  /// Every command this run started, in start order.
  List<BackgroundCommand> get commands => List.unmodifiable(_commands);

  /// The commands still running.
  List<BackgroundCommand> get live => [
    for (final c in _commands)
      if (c.isLive) c,
  ];

  /// The commands whose end is not fully handled yet: still running, or
  /// exited with their exit notice not yet handed to [onNotice]. A run must
  /// not end while one is left, or that notice is lost.
  List<BackgroundCommand> get unsettled => [
    for (final c in _commands)
      if (!c._settled.isCompleted) c,
  ];

  /// Whether the run ended: nothing more may start.
  bool get closed => _closed;

  /// The command named [handle], or null.
  BackgroundCommand? byHandle(String handle) {
    for (final c in _commands) {
      if (c.handle == handle) {
        return c;
      }
    }
    return null;
  }

  /// The command whose [BackgroundCommand.outputHandle] is [outputHandle].
  BackgroundCommand? byOutputHandle(String outputHandle) {
    for (final c in _commands) {
      if (c.outputHandle == outputHandle) {
        return c;
      }
    }
    return null;
  }

  /// The handles of every command, for an unknown-handle message.
  String knownHandles() => _commands.isEmpty
      ? 'This run has started no background command.'
      : 'Known handles: ${_commands.map((c) => c.handle).join(', ')}.';

  /// Why a new command may not start now, or null when it may.
  String? startRefusal() {
    if (_closed) {
      return 'The run is ending; no background command can start.';
    }
    final running = live;
    if (running.length + _starting >= maxLive) {
      final names = running.map((c) => c.handle).join(', ');
      final kill = _callForms('bash_kill');
      return 'At most $maxLive background commands may run at once in a run, '
          'and ${running.length + _starting} are running'
          '${names.isEmpty ? '' : ' ($names)'}. Wait for one to finish, or '
          'stop one with `${toolCallText(kill, 'bash_kill', 'handle')}`'
          '${kill == ToolCallForm.script ? ' from a `repl` script' : ''}, '
          'then start this one.';
    }
    return null;
  }

  /// Starts [command] through [launch] and returns once it was spawned (or
  /// refused before that).
  ///
  /// [callCancel] is the starting call's token: when it fires before the
  /// command was spawned (the call was abandoned while a person was asked),
  /// the start is withdrawn. After the spawn only the command's own timeout,
  /// [kill] and [killAll] stop it.
  Future<BackgroundStart> start({
    required String command,
    required Duration timeout,
    required BackgroundLaunch launch,
    ToolOutputScope? scope,
    CancellationToken? callCancel,
    BackgroundNotify? notify,
  }) async {
    final refusal = startRefusal();
    if (refusal != null) {
      return BackgroundRefused(refusal);
    }
    final entry = BackgroundCommand._(
      command: command,
      timeout: timeout,
      outputHandle: newToolOutputHandle(),
      scope: scope,
      clock: _clock,
      notify: notify,
    ).._onNotifyLine = _signalEvent;
    _starting++;
    var spawned = false;
    final started = Completer<void>();
    unawaited(
      callCancel?.whenCancelled.then((_) {
        if (!spawned) {
          entry._kill.cancel(
            'The call that started the command was abandoned.',
          );
        }
      }),
    );
    final observer = HarnessCommandObserver(
      onStarted: () {
        if (!started.isCompleted) {
          started.complete();
        }
      },
      onOutput: entry._append,
      sweepAfterExit: true,
    );
    final Future<HarnessCommandResult> run;
    try {
      // The runner's own timeout is a backstop a little past the registry's,
      // which kills first and so knows the command timed out.
      run = launch(entry._kill.token, observer, timeout.inSeconds + 5);
    } on Object catch (e) {
      _starting--;
      return BackgroundNotStarted(
        HarnessCommandResult(
          exitCode: 1,
          stdout: '',
          stderr: 'Failed to start command: $e',
        ),
      );
    }
    final outcome = Completer<HarnessCommandResult>();
    unawaited(
      run.then(
        outcome.complete,
        onError: (Object e) => outcome.complete(
          HarnessCommandResult(
            exitCode: 1,
            stdout: '',
            stderr: 'Failed to run command: $e',
          ),
        ),
      ),
    );
    await Future.any<void>([started.future, outcome.future]);
    _starting--;
    if (!started.isCompleted) {
      return BackgroundNotStarted(await outcome.future);
    }
    spawned = true;
    entry
      .._handle = 'b${++_seq}'
      .._startedAt = _clock();
    _commands.add(entry);
    if (_closed) {
      // The run ended while the command was being approved: it dies now.
      entry._killReason = _KillReason.runEnded;
      entry._kill.cancel('The run ended.');
    } else {
      entry._timer = Timer(timeout, () {
        if (entry.isLive) {
          entry._timedOut = true;
          entry._kill.cancel('The command timed out.');
        }
      });
    }
    unawaited(outcome.future.then((result) => _settle(entry, result)));
    onChanged?.call();
    return BackgroundStarted(entry);
  }

  Future<void> _settle(BackgroundCommand c, HarnessCommandResult result) async {
    c._timer?.cancel();
    c._flushPending();
    c.notify?.flush();
    c
      .._endedAt = _clock()
      .._exitCode = result.exitCode;
    if (c._killReason != null) {
      c._status = BackgroundCommandStatus.killed;
    } else if (c._timedOut || result.timedOut) {
      c._status = BackgroundCommandStatus.timedOut;
    } else {
      c._status = BackgroundCommandStatus.exited;
    }
    try {
      if (c._killReason != _KillReason.runEnded) {
        await _storeOutput(c);
        if (_takeNotify(c) case final delivery?) {
          onNotify?.call(delivery, c.handle);
        }
        if (c._killReason == null) {
          onNotice?.call(exitNotice(c), c.handle);
        }
      }
    } on Object {
      // A store or listener failure must not leave the command unsettled.
    } finally {
      if (!c._settled.isCompleted) {
        c._settled.complete();
      }
      final waiters = List<Completer<void>>.of(_settleWaiters);
      _settleWaiters.clear();
      for (final w in waiters) {
        if (!w.isCompleted) {
          w.complete();
        }
      }
      _signalEvent();
      onChanged?.call();
    }
  }

  Future<void> _storeOutput(BackgroundCommand c) async {
    final store = this.store;
    final scope = c.scope;
    if (store == null || scope == null) {
      return;
    }
    final ref = await store.put(
      ToolOutputWrite(scope: scope, toolName: 'bash', content: c.output),
    );
    c._storedOutputHandle = ref?.handle;
  }

  /// The aside notice for a command that finished on its own or timed out.
  String exitNotice(BackgroundCommand c) {
    // The command line sits outside the envelope: one line, and nothing in
    // it reads as the envelope's tag.
    final oneLine = wakeDataOutsideLine(c.command);
    final shown = oneLine.length > noticeCommandChars
        ? '${oneLine.substring(0, noticeCommandChars)}…'
        : oneLine;
    final head = c.status == BackgroundCommandStatus.timedOut
        ? '[Background command ${c.handle} timed out after '
              '${formatBackgroundDuration(c.timeout)} and was killed]'
        : '[Background command ${c.handle} finished with exit code '
              '${c.exitCode} after ${formatBackgroundDuration(c.elapsed)}]';
    final tail = c.tail(noticeTailChars).trim();
    final handle = c.storedOutputHandle ?? c.outputHandle;
    final framed = tail.isEmpty ? head : '$head $wakeDataRule';
    // The output is the command's, so untrusted: it goes inside the data
    // envelope with a nonce of this notice's own, and nothing it holds can
    // close that envelope or pass for this notice's first line.
    return [
      framed,
      'Command: `$shown`',
      if (tail.isEmpty)
        'It wrote no output.'
      else ...[
        'Last ${tail.length < noticeTailChars ? 'output' : '$noticeTailChars characters of output'}:',
        wakeDataEnvelope(tail, nonce: newWakeDataNonce()),
      ],
      'Full output: read_output(handle: "$handle")',
    ].join('\n');
  }

  /// Records that the exit notice of [handle] reached the model.
  void markNoticeDelivered(String handle) {
    byHandle(handle)?._noticeDelivered = true;
  }

  /// The `notify` deliveries waiting, one per command with matched lines, for
  /// the run's aside lane at a turn boundary.
  List<BackgroundNotifyDelivery> takeNotifyDeliveries() => [
    for (final c in _commands)
      if (_takeNotify(c) case final text?) (handle: c.handle, text: text),
  ];

  String? _takeNotify(BackgroundCommand c) => c.notify?.takeDelivery(
    handle: c.handle,
    running: c.isLive,
    outputHandle: c.storedOutputHandle ?? c.outputHandle,
  );

  /// Whether a `notify` delivery is waiting.
  bool get hasNotifyPending => _commands.any(
    (c) => c.handle.isNotEmpty && (c.notify?.hasPending ?? false),
  );

  /// Completes when any command settles or a `notify` line matches, or at
  /// once when nothing is unsettled and no delivery waits.
  Future<void> whenAnyEvent() {
    // Unsettled, not live: a command that exited and is still storing its
    // output has an event (its settle) to come.
    if (unsettled.isEmpty || hasNotifyPending) {
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _eventWaiters.add(waiter);
    return waiter.future;
  }

  void _signalEvent() {
    final waiters = List<Completer<void>>.of(_eventWaiters);
    _eventWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.complete();
      }
    }
  }

  /// Completes when any command settles, or at once when none is live.
  Future<void> whenAnySettles() {
    if (live.isEmpty) {
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _settleWaiters.add(waiter);
    return waiter.future;
  }

  /// Kills the live command [handle] (the model's `bash_kill`) and waits up
  /// to [grace] for it to settle. Returns the command, or null when no such
  /// handle exists. A finished command is returned as it is.
  Future<BackgroundCommand?> kill(
    String handle, {
    Duration grace = const Duration(seconds: 5),
  }) async {
    final c = byHandle(handle);
    if (c == null) {
      return null;
    }
    if (c.isLive) {
      c._killReason ??= _KillReason.user;
      c._kill.cancel('Killed by bash_kill.');
      await c.settled.timeout(grace, onTimeout: () {});
    }
    return c;
  }

  /// Opens the registry for a run (again): a host that runs the loop more
  /// than once with the same tools gets a registry that accepts commands in
  /// each run. Commands of an earlier run are already dead ([killAll]).
  void reopen() {
    _closed = false;
  }

  /// Ends the registry with its run: nothing more may start, every live
  /// command is killed (no notices: the run is over), and the call waits up
  /// to [grace] for them to exit. A command that already exited is told the
  /// run ended too, so the runner can end what it left behind (a daemon it
  /// started, see [HarnessCommandObserver.sweepAfterExit]). Safe to call more
  /// than once.
  Future<void> killAll({Duration grace = const Duration(seconds: 3)}) async {
    _closed = true;
    final running = live;
    for (final c in running) {
      c._killReason ??= _KillReason.runEnded;
      c._kill.cancel('The run ended.');
    }
    for (final c in _commands) {
      if (!c.isLive && !c._kill.token.isCancelled) {
        c._kill.cancel('The run ended.');
      }
    }
    if (running.isEmpty) {
      return;
    }
    await Future.wait([
      for (final c in running) c.settled,
    ]).timeout(grace, onTimeout: () => const <void>[]);
  }
}

/// A tool that carries its run's [BackgroundCommandRegistry]: `bash`,
/// `bash_output`, `bash_kill`, `read_output`. The loop finds the run's
/// registry through them ([backgroundCommandsOf]).
abstract interface class BackgroundCommandTool {
  /// The run's background commands, or null when this tool was built without
  /// them (background commands are then unavailable).
  BackgroundCommandRegistry? get backgroundCommands;
}

/// The background-command registry carried by [tools], or null when none
/// carries one.
BackgroundCommandRegistry? backgroundCommandsOf(Iterable<HarnessTool> tools) {
  for (final tool in tools) {
    if (tool case final BackgroundCommandTool carrier) {
      final registry = carrier.backgroundCommands;
      if (registry != null) {
        return registry;
      }
    }
  }
  return null;
}

/// `45 s`, `6 min`, `1 h 5 min`.
String formatBackgroundDuration(Duration d) {
  if (d.inSeconds < 60) {
    return '${d.inSeconds < 0 ? 0 : d.inSeconds} s';
  }
  if (d.inMinutes < 60) {
    return '${d.inMinutes} min';
  }
  final minutes = d.inMinutes % 60;
  return '${d.inHours} h${minutes == 0 ? '' : ' $minutes min'}';
}
