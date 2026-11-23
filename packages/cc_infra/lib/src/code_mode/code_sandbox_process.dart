import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_runner_live_availability.dart';
import 'package:cc_infra/src/code_mode/code_runner_self_test.dart';
import 'package:cc_infra/src/code_mode/host_path_scrub.dart';
import 'package:cc_infra/src/code_mode/runner_frames.dart';
import 'package:cc_infra/src/code_mode/runner_json.dart';
import 'package:cc_infra/src/code_mode/runner_start_frames.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/child_process.dart';

/// Runs scripts in `cc_codemode` processes: one process per script, spoken to
/// in newline-delimited JSON over its stdio (the protocol in
/// `packages/cc_natives/native/codemode/README.md`).
///
/// The runner is the sandbox, and this class is the part that must never
/// trust it. Every frame it writes is hostile input: a frame over 8 MiB, bytes
/// that are not UTF-8 JSON, JSON nested deeper than the runner itself could
/// write, an unknown frame type, a field of the wrong type, a call id that
/// repeats or skips, more calls than the runner was allowed, a call name or
/// arguments over their cap, output past its caps, an image that is not what
/// it claims, a store frame the runner should itself have refused or store
/// traffic past what the runner allows, or anything after `done` ends the
/// script as [CodeExecutionStatus.sandboxError] and kills the process at
/// once. So does a runner that stops reading what the host sends it. A throw
/// while the host handles a frame is treated the same way, so nothing a
/// runner writes can escape this class or leave a session without an
/// outcome. The host also never sends the runner a frame the runner would
/// reject, so a script cannot be ended by a tool result it was handed.
///
/// What the runner reports about itself (`done.stats`: CPU time, peak heap,
/// call and output counts) is recorded as reported. Nothing enforces a limit
/// or bills anyone on it; the host's own counts do that.
///
/// The wall-clock deadline is enforced here, by killing the process, so it
/// holds whatever the interpreter does. It pauses while the script waits on a
/// person ([CodeSandboxSession.holdDeadline]).
///
/// The process is started directly with an empty environment, not inside the
/// run's agent sandbox: the runner confines itself before it reads anything,
/// and proves it in its first frame. A runner that reports less than full
/// lockdown is killed before it sees the script.
class CodeSandboxProcess implements CodeSandboxPort {
  /// Uses the runner at [executable], an absolute path (see
  /// `BundledCodeRunner.locate`).
  CodeSandboxProcess({
    required this.executable,
    this.handshakeTimeout = const Duration(seconds: 10),
    this.selfTestTimeout = const Duration(seconds: 30),
    this.exitGrace = const Duration(seconds: 2),
    this.retestInterval = const Duration(minutes: 1),
  });

  /// The protocol version this host speaks; a runner of another one is
  /// refused at its self-test (`--version`) and at every handshake.
  static const int protocolVersion = 2;

  /// Host calls (`searchTools`, `describeTool`, `describeNamespace`,
  /// `models.*`) a script may make on top of its nested tool calls.
  ///
  /// The runner counts both kinds against one `max_calls`, so that number is
  /// [CodeModeLimits.maxNestedCalls] plus this allowance. The execution
  /// service enforces the tool-call cap itself and tells the script so;
  /// the runner's count is the second line of defence. The execution
  /// service bounds lookups itself, before any work
  /// ([CodeModeLimits.maxLookups], [CodeModeLimits.maxLookupMs] and the
  /// argument sizes), since it answers them on the isolate that serves
  /// every workspace; this count bounds the frames a runner may send.
  static const int hostCallAllowance = 1000;

  /// How much of the runner's stderr is kept, from the end.
  static const int stderrCaptureBytes = 64 * 1024;

  /// How much of the runner's stderr reaches a result and a record, from the
  /// end, in characters, after control and bidirectional characters are
  /// replaced: the runner chooses it, so it is kept short.
  static const int stderrTailChars = 300;

  /// Bytes written to the runner's stdin that it has not read yet. A runner
  /// that stops reading would otherwise make the server hold every reply;
  /// past this budget it is ended as a protocol violation.
  static const int stdinBacklogBudgetBytes = 64 * 1024 * 1024;

  /// The deepest JSON nesting a runner frame can have: a value the runner
  /// parsed (serde_json, [kRunnerMaxJsonDepth]) inside the frame object and
  /// one field. Anything deeper did not come from an honest runner, and is
  /// refused before the host walks it.
  static const int maxFrameDepth = kRunnerMaxJsonDepth + 2;

  /// Slack on the runner's stored-value total. The runner measures values
  /// the way Dart's encoder writes them, so an honest runner never comes
  /// near it; it is a margin, and past it the session is a violation.
  static const int storeTotalSlackBytes = 64 * 1024;

  /// Unanswered call arguments the host holds before it stops reading
  /// stdout until replies drain, weighed by the heap they take decoded
  /// ([JsonShape.weight]), not by their JSON. A script cannot make the
  /// server hold more than this, plus the one call that crosses it, in
  /// arguments it has not answered yet.
  static const int pendingArgumentBudgetBytes = 64 * 1024 * 1024;

  /// The heap an admitted call's arguments can take decoded, about 7.5 MiB:
  /// the [JsonShape.weight] of [CodeModeLimits.maxCallArgumentBytes] (and
  /// the measuring slack) holding [CodeModeLimits.maxCallArgumentItems]
  /// objects. A call holding more values is refused to the script, as an
  /// ordinary error for that call, before its arguments are decoded.
  static const int maxCallWeightBytes =
      (CodeModeLimits.maxCallArgumentBytes + argumentMeasureSlackBytes) *
          5 ~/
          2 +
      CodeModeLimits.maxCallArgumentItems * JsonShape.objectCost;

  /// The heap a frame may take decoded, beyond the arguments of a call
  /// refused for [CodeModeLimits.maxCallArgumentItems] and a return value
  /// that would take more, which is kept as text. Every frame an
  /// honest runner writes fits: a stored value (256 KiB of `{}`) about
  /// 28 MiB, a text or return value of the whole frame cap about 25 MiB. A frame over it was not written by an honest
  /// runner and ends the session before the host decodes it, so decoding
  /// takes at most this much at a time, one frame at a time per isolate.
  static const int maxFrameWeightBytes = 32 * 1024 * 1024;

  /// Slack when re-measuring a call's arguments. The runner measures them
  /// the way Dart's encoder writes them, so an honest runner never comes
  /// near it; it is a margin, and past it the session is a violation.
  static const int argumentMeasureSlackBytes = 4096;

  /// The absolute path of `cc_codemode`.
  final String executable;

  /// How long the runner has to write its `ready` frame.
  final Duration handshakeTimeout;

  /// How long `--self-test` may take.
  final Duration selfTestTimeout;

  /// How long a runner has to exit after `done` before it is killed.
  final Duration exitGrace;

  /// The least time between two re-runs of the self-test after launch
  /// failures ([availability]).
  final Duration retestInterval;

  late final CodeRunnerLiveAvailability _health = CodeRunnerLiveAvailability(
    selfTest: _runSelfTest,
    retestInterval: retestInterval,
  );
  final Set<_RunnerSession> _live = {};
  bool _disposed = false;

  /// Runner processes that have been started and have not exited yet.
  int get liveProcessCount => _live.length;

  /// Whether scripts can run on this host, live: the boot [selfTest]'s
  /// result, turned off by a failed re-run of the self-test after a launch
  /// failure and on again by a later one that passes
  /// ([CodeRunnerLiveAvailability]). A read while off may start that re-run.
  @override
  CodeRunnerAvailability get availability => _health.current;

  /// Fires once per change of [availability] after boot, with the new
  /// answer.
  Stream<CodeRunnerAvailability> get changes => _health.changes;

  /// Self-tests re-run after boot so far.
  int get retests => _health.retests;

  /// Waits for a self-test re-run in flight, if any. For tests.
  Future<void> get retestDone => _health.retestDone;

  /// The `init.limits` object for [limits], as the runner reads it.
  ///
  /// `max_output_chars` is set from [CodeModeLimits.interpreterOutputBytes]:
  /// the runner counts characters (Unicode scalar values), and a character
  /// cap equal to the byte figure bounds the output to at most four times
  /// that many bytes, which the item cap and the frame cap bound further.
  /// [storeWritable] false gives a zero store budget, so `store()` throws in
  /// the script.
  static Map<String, int> runnerLimits(
    CodeModeLimits limits, {
    required int returnBudgetChars,
    bool storeWritable = true,
  }) => {
    'wall_ms': limits.wallClockMs,
    'cpu_ms': limits.cpuMs,
    'heap_bytes': limits.heapBytes,
    'stack_bytes': CodeModeLimits.stackBytes,
    'max_calls': limits.maxNestedCalls + hostCallAllowance,
    'max_call_args_bytes': CodeModeLimits.maxCallArgumentBytes,
    'max_output_chars': CodeModeLimits.interpreterOutputBytes,
    'max_output_items': CodeModeLimits.interpreterOutputItems,
    'return_budget_chars': returnBudgetChars,
    'store_value_bytes': storeWritable ? CodeModeLimits.maxStoreValueBytes : 0,
    'store_total_bytes': storeWritable ? CodeModeLimits.maxStoreTotalBytes : 0,
  };

  /// The boot self-test. Once [availability] has turned off after a
  /// launch failure, it stays off: this returns it without running.
  @override
  Future<CodeRunnerAvailability> selfTest() => _health.boot();

  // Both run, the protocol first: the self-test decides which reason a
  // runner that fails both is given ([runCodeRunnerSelfTest]).
  Future<CodeRunnerAvailability> _runSelfTest() async => runCodeRunnerSelfTest(
    () => _spawn(const ['--self-test']),
    timeout: selfTestTimeout,
    exitGrace: exitGrace,
    detailChars: stderrTailChars,
    protocolProblem: await checkCodeRunnerProtocol(
      () => _spawn(const ['--version']),
      expected: protocolVersion,
      timeout: selfTestTimeout,
    ),
  );

  Future<Process> _spawn(List<String> arguments) => ChildProcess.start(
    executable,
    arguments,
    workingDirectory: runnerWorkingDirectory(executable),
    inheritBase: false,
    // Windows processes cannot start without SystemRoot; the runner's
    // launcher passes only that (and SystemDrive, windir, and LOCALAPPDATA
    // from the user's profile, which Windows needs to place an AppContainer
    // child's TEMP) to its child.
    inherit: [if (Platform.isWindows) 'SYSTEMROOT'],
    environment: const {'PATH': ''},
  );

  @override
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  }) async {
    if (_disposed) {
      throw const CodeSandboxStartException(
        'The code mode runner host has shut down.',
      );
    }
    if (cancel.isCancelled) {
      throw const CodeSandboxStartException(
        'The script was cancelled before its runner started.',
        errorKind: 'cancelled',
      );
    }
    // Encoded before the spawn: frames that cannot be sent spawn nothing.
    final frames = RunnerStartFrames.encode(request);
    final Process process;
    try {
      process = await _spawn(const []);
    } on Object catch (e) {
      // The error names the runner's path: it goes to the log only.
      _health.launchFailed('it could not be started: $e');
      throw const CodeSandboxStartException(
        'The code mode runner could not be started on this server; the '
        'server log has the reason.',
      );
    }
    final session = _RunnerSession(this, process, request, frames);
    _live.add(session);
    unawaited(session.outcome.whenComplete(() => _live.remove(session)));
    if (_disposed) {
      session.kill(_EndReason.disposed);
    }
    await session.connect(handshakeTimeout, cancel);
    return session;
  }

  /// Kills every live runner and waits for their outcomes. A session whose
  /// process does not report its exit is ended without it after the exit
  /// grace, so this always returns.
  @override
  Future<void> dispose() async {
    _disposed = true;
    _health.close();
    final live = _live.toList();
    for (final session in live) {
      session.kill(_EndReason.disposed);
    }
    await Future.wait([for (final s in live) s.outcome]).timeout(
      exitGrace + _drainGrace,
      onTimeout: () {
        for (final session in live) {
          session.abandon();
        }
        return const [];
      },
    );
  }

  /// How long the host keeps reading a runner's stdout after it exited.
  static const Duration _drainGrace = Duration(seconds: 2);
}

// Signal numbers of the runner's kernel backstops, per platform.
final int _sigsys = ProcessSignal.sigsys.signalNumber;
final int _sigabrt = ProcessSignal.sigabrt.signalNumber;
final int _sigxcpu = ProcessSignal.sigxcpu.signalNumber;

/// Why the host ended a runner, when it did.
enum _EndReason {
  deadline,
  cancelled,
  violation,
  disposed,
  handshake,
  unresponsive,
}

class _RunnerSession implements CodeSandboxSession {
  _RunnerSession(this._host, this._process, this._request, this._frames)
    : _maxCallFrames =
          _request.limits.maxNestedCalls + CodeSandboxProcess.hostCallAllowance,
      _deadline = PausableDeadline(
        Duration(milliseconds: _request.limits.wallClockMs),
      ) {
    _deadline.onExpire = _expire;
    _splitter = RunnerFrameSplitter(
      CodeModeLimits.maxFrameBytes,
      onFrame: _onFrameBytes,
      onOversize: () => _violate(
        'frame_too_large',
        'The runner wrote a frame over '
            '${CodeModeLimits.maxFrameBytes ~/ (1024 * 1024)} MiB.',
      ),
    );
    unawaited(_process.stdin.done.catchError((Object _) {}));
    _stdoutSub = _process.stdout.listen(
      (chunk) {
        if (!_stopReading) {
          _splitter.add(chunk);
        }
      },
      onError: (Object e) {
        // The error can name a host path: it goes to the log only.
        CcInfraLog.warning(
          'code mode: reading a runner failed: ${oneLogLine('$e')}',
        );
        _violate('protocol', 'Reading the runner failed.');
      },
      onDone: _completeStdout,
      cancelOnError: true,
    );
    _stderrDone = _process.stderr
        .forEach(_stderr.add)
        .catchError((Object _) {});
    unawaited(_process.exitCode.then(_onExit));
  }

  final CodeSandboxProcess _host;
  final Process _process;
  final CodeSandboxStart _request;
  final RunnerStartFrames _frames;
  late final ScriptLines _scriptLines = ScriptLines(_request.code);
  final int _maxCallFrames;
  final PausableDeadline _deadline;
  late final RunnerFrameSplitter _splitter;
  late final StreamSubscription<List<int>> _stdoutSub;
  final BoundedCapture _stderr = BoundedCapture(
    CodeSandboxProcess.stderrCaptureBytes,
  );
  final StreamController<CodeSandboxEvent> _events = StreamController();
  final Completer<CodeSandboxOutcome> _outcome = Completer();
  final Completer<Map<String, dynamic>> _ready = Completer();
  final Completer<void> _stdoutDone = Completer();

  /// Completes when the runner's stderr is read to its end: what it wrote
  /// just before it exited can still be in the pipe when the exit arrives.
  late final Future<void> _stderrDone;

  CodeRunnerHandshake? _handshake;
  bool _running = false;
  bool _stopReading = false;
  bool _stdinClosed = false;
  _EndReason? _endReason;
  String? _violationKind;
  String? _violationDetail;
  Map<String, dynamic>? _done;

  /// A return value with more values than a script receives decoded, as
  /// the runner wrote it; shown instead of the `value` decoded from `done`.
  String? _rawReturnValue;
  int? _exitCode;
  int _lastCallId = 0;
  int _callFrames = 0;
  final Map<int, int> _pending = {};
  int _pendingWeight = 0;
  bool _pausedForBackpressure = false;

  /// Frames read in the same chunk as the call that filled the pending
  /// budget: they wait here, undecoded, until replies drain it, so no frame
  /// is decoded past the budget.
  final Queue<Uint8List> _deferred = Queue();
  int _outputChars = 0;
  int _outputItems = 0;
  int _storeFrames = 0;

  /// Stored-value bytes by key, as the runner counts them against its
  /// `store_total_bytes`: the values loaded at init, then each write.
  late final Map<String, int> _storeSizes = {..._frames.storeSizes};
  late int _storeTotal = _frames.storeTotal;
  final Queue<Uint8List> _stdinQueue = Queue();
  int _stdinBacklog = 0;
  bool _flushing = false;
  int _creditedMs = 0;
  Timer? _killTimer;
  Timer? _exitTimer;
  bool _finalizing = false;

  @override
  CodeRunnerHandshake get handshake => _handshake!;

  @override
  Stream<CodeSandboxEvent> get events => _events.stream;

  @override
  Future<CodeSandboxOutcome> get outcome => _outcome.future;

  bool get _ended => _endReason != null || _done != null;

  // ---------------------------------------------------------------------
  // Handshake

  Future<void> connect(Duration timeout, CancellationToken cancel) async {
    final failed = Completer<CodeSandboxStartException>();
    void fail(CodeSandboxStartException e) {
      if (!failed.isCompleted) {
        failed.complete(e);
      }
    }

    final timer = Timer(
      timeout,
      () => fail(
        CodeSandboxStartException(
          'The code mode runner did not report ready within '
          '${timeout.inSeconds} s.',
        ),
      ),
    );
    unawaited(
      cancel.whenCancelled.then(
        (_) => fail(
          const CodeSandboxStartException(
            'The script was cancelled before its runner started.',
            errorKind: 'cancelled',
          ),
        ),
      ),
    );
    unawaited(
      _outcome.future.then((o) {
        if (!failed.isCompleted && !_ready.isCompleted && !cancel.isCancelled) {
          // Exited before it was ready, its script not yet sent.
          _host._health.launchFailed(
            o.detail ?? 'it exited before it was ready',
          );
        }
        fail(
          CodeSandboxStartException(
            o.detail ?? 'The code mode runner exited before it was ready.',
            errorKind: switch (o.errorKind) {
              'lockdown' => 'lockdown',
              'protocol' || 'frame_too_large' => 'protocol',
              _ => 'start',
            },
          ),
        );
      }),
    );
    final result = await Future.any<Object>([_ready.future, failed.future]);
    timer.cancel();
    if (result is CodeSandboxStartException) {
      await _abortStart();
      throw result;
    }
    final ready = result as Map<String, dynamic>;
    final protocol = ready['protocol'];
    final engine = ready['engine'];
    final lockdown = ready['lockdown'];
    if (protocol is! int || engine is! String || lockdown is! Map) {
      _host._health.launchFailed('it sent a malformed ready frame');
      await _abortStart();
      throw const CodeSandboxStartException(
        'The code mode runner sent a malformed ready frame.',
        errorKind: 'protocol',
      );
    }
    if (protocol != CodeSandboxProcess.protocolVersion) {
      _host._health.launchFailed('it speaks protocol $protocol');
      await _abortStart();
      throw CodeSandboxStartException(
        'The code mode runner speaks protocol $protocol; this server speaks '
        '${CodeSandboxProcess.protocolVersion}. Reinstall the application or '
        'server bundle.',
        errorKind: 'protocol',
      );
    }
    final report = CodeRunnerLockdown.fromJson(
      lockdown.cast<String, dynamic>(),
    );
    if (!report.isFull) {
      _host._health.launchFailed(
        'it did not lock itself down fully (level ${report.level})',
      );
      await _abortStart();
      final failedControls = report.details['failed'];
      throw CodeSandboxStartException(
        'The code mode runner did not lock itself down fully on this host '
        '(level ${report.level}'
        '${failedControls is List && failedControls.isNotEmpty ? '; not applied: ${failedControls.join(', ')}' : ''}'
        '). No script was sent to it.',
        errorKind: 'lockdown',
      );
    }
    _handshake = CodeRunnerHandshake(
      protocol: protocol,
      engine: engine,
      lockdown: report,
    );
    _begin();
  }

  Future<void> _abortStart() async {
    kill(_EndReason.handshake);
    await _outcome.future;
  }

  void _begin() {
    _running = true;
    _write(_frames.init);
    _write(_frames.exec);
    _deadline.start();
  }

  // ---------------------------------------------------------------------
  // Frames from the runner

  void _onFrameBytes(Uint8List bytes) {
    if (_stopReading) {
      return;
    }
    if (_pausedForBackpressure) {
      _deferred.add(bytes);
      return;
    }
    _handleFrameBytes(bytes);
  }

  void _handleFrameBytes(Uint8List bytes) {
    // The frame is weighed before it is decoded: one MiB of `{}` takes
    // about 82 MiB once decoded. A call whose arguments hold more than
    // [CodeModeLimits.maxCallArgumentItems] values is decoded without
    // them and refused to the script; any other frame heavier than an
    // honest runner writes ends the session.
    // Only the members the host reads here are kept by the scan.
    final scan = scanJsonFrame(bytes, keep: const {'type', 'args', 'value'});
    // Dart decodes iteratively, but much of what handles a value afterwards
    // recurses; a frame deeper than any the runner can write is refused
    // before anything walks it, or decodes it.
    if (scan.depth > CodeSandboxProcess.maxFrameDepth) {
      _violate(
        'protocol',
        'The runner wrote a frame nested more than '
            '${CodeSandboxProcess.maxFrameDepth} levels deep.',
      );
      return;
    }
    final type = scan.valueOf('type');
    final argsShape = type == 'call' ? scan.shapeOf('args') : null;
    final refused =
        argsShape != null &&
        argsShape.items > CodeModeLimits.maxCallArgumentItems;
    // A script's return value is structured JSON of up to the frame cap,
    // and the host only shows it as text: one that would take more than a
    // frame may take decoded is kept as the text the runner wrote,
    // undecoded.
    final valueShape = type == 'done' ? scan.shapeOf('value') : null;
    final rawValue =
        valueShape != null &&
            scan.shape.weight > CodeSandboxProcess.maxFrameWeightBytes
        ? utf8.decode(scan.bytesOf('value')!, allowMalformed: true)
        : null;
    final stripped = refused ? 'args' : (rawValue != null ? 'value' : null);
    final rest = switch (stripped) {
      'args' => scan.shape.without(argsShape!),
      'value' => scan.shape.without(valueShape!),
      _ => scan.shape,
    };
    if (rest.weight > CodeSandboxProcess.maxFrameWeightBytes) {
      _violate(
        'protocol',
        'The runner wrote a frame that would take about '
            '${rest.weight ~/ (1024 * 1024)} MiB once decoded; the cap is '
            '${CodeSandboxProcess.maxFrameWeightBytes ~/ (1024 * 1024)} MiB.',
      );
      return;
    }
    final Object? decoded;
    try {
      decoded = utf8JsonDecoder.convert(
        stripped == null ? bytes : scan.withEmptyObjectFor(stripped),
      );
    } on FormatException {
      _violate('protocol', 'The runner wrote a line that is not UTF-8 JSON.');
      return;
    }
    try {
      _onFrame(decoded, argsShape, refused: refused, rawValue: rawValue);
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: handling a runner frame failed', e, st);
      _violate(
        'protocol',
        'The host could not handle a frame the runner wrote '
            '(${e.runtimeType}).',
      );
    }
  }

  void _onFrame(
    Object? decoded,
    JsonShape? argsShape, {
    required bool refused,
    String? rawValue,
  }) {
    if (decoded is! Map<String, dynamic>) {
      _violate('protocol', 'The runner wrote a frame that is not an object.');
      return;
    }
    final type = decoded['type'];
    if (_done != null) {
      _violate('protocol', 'The runner wrote a frame after done.');
      return;
    }
    if (_handshake == null && !_running) {
      if (type == 'ready' && !_ready.isCompleted) {
        _ready.complete(decoded);
        return;
      }
      _violate('protocol', 'The runner wrote "$type" before ready.');
      return;
    }
    switch (type) {
      case 'call':
        _onCall(decoded, argsShape, refused: refused);
      case 'output':
        _onOutput(decoded);
      case 'store':
        _onStore(decoded);
      case 'done':
        _rawReturnValue = rawValue;
        _onDone(decoded);
      default:
        _violate('protocol', 'The runner wrote an unknown frame type: $type.');
    }
  }

  void _onCall(
    Map<String, dynamic> frame,
    JsonShape? argsShape, {
    required bool refused,
  }) {
    final id = frame['id'];
    final rawTarget = frame['target'];
    final target = rawTarget is String
        ? CodeSandboxCallTarget.tryParse(rawTarget)
        : null;
    final name = frame['name'];
    final args = frame['args'];
    if (id is! int ||
        target == null ||
        name is! String ||
        name.isEmpty ||
        args is! Map<String, dynamic> ||
        argsShape == null) {
      _violate('protocol', 'The runner wrote a malformed call frame.');
      return;
    }
    // A call site is optional; one that is present must name a character of
    // the script, like every other field the runner writes must be what the
    // protocol says.
    final ScriptCallSite? site;
    try {
      site = frame.containsKey('at') ? _scriptLines.siteOf(frame['at']) : null;
    } on FormatException catch (e) {
      _violate(
        'protocol',
        'The runner wrote a malformed call site (${e.message}).',
      );
      return;
    }
    if (utf8Length(name) > CodeModeLimits.maxCallNameBytes) {
      _violate(
        'protocol',
        'The runner sent a call name over '
            '${CodeModeLimits.maxCallNameBytes} bytes.',
      );
      return;
    }
    if (id != _lastCallId + 1) {
      _violate(
        'protocol',
        id <= _lastCallId
            ? 'The runner reused call id $id.'
            : 'The runner skipped from call id $_lastCallId to $id.',
      );
      return;
    }
    _lastCallId = id;
    _callFrames++;
    if (_callFrames > _maxCallFrames) {
      _violate(
        'call_cap',
        'The runner sent more than the $_maxCallFrames calls it was allowed.',
      );
      return;
    }
    // A refused call's arguments were never decoded, so their text is
    // measured as it came; an honest runner writes it without spaces.
    final size = refused
        ? argsShape.bytes
        : utf8.encode(jsonEncode(args)).length;
    if (size >
        CodeModeLimits.maxCallArgumentBytes +
            CodeSandboxProcess.argumentMeasureSlackBytes) {
      _violate(
        'protocol',
        'The runner sent call arguments of $size bytes; the cap is '
            '${CodeModeLimits.maxCallArgumentBytes}.',
      );
      return;
    }
    if (refused) {
      _pending[id] = 0;
      reply(
        CodeSandboxReply(
          id: '$id',
          ok: false,
          payload: {
            'message':
                'The arguments to $name hold ${argsShape.items} values; a '
                'call takes at most ${CodeModeLimits.maxCallArgumentItems} '
                '(objects, arrays, members and other values together). Split '
                'the data across calls, or pass bulk data as one string where '
                'the tool takes text.',
            'status': NestedCallStatus.invalidArgs.wire,
          },
        ),
      );
      return;
    }
    final weight = argsShape.weight;
    _pending[id] = weight;
    _pendingWeight += weight;
    if (_pendingWeight > CodeSandboxProcess.pendingArgumentBudgetBytes &&
        !_pausedForBackpressure) {
      _pausedForBackpressure = true;
      // Already paused when this frame came out of the deferred queue.
      if (!_stdoutSub.isPaused) {
        _stdoutSub.pause();
      }
    }
    _events.add(
      CodeSandboxCall(
        id: '$id',
        target: target,
        name: name,
        arguments: args,
        site: site,
      ),
    );
  }

  void _onOutput(Map<String, dynamic> frame) {
    final ScriptOutputItem item;
    final int chars;
    switch (frame['kind']) {
      case 'text':
        final text = frame['text'];
        if (text is! String) {
          _violate('protocol', 'The runner wrote a malformed text output.');
          return;
        }
        item = ScriptTextOutput(text);
        chars = text.runes.length;
      case 'log':
        final text = frame['text'];
        final level = ScriptConsoleLevel.tryParse(
          frame['level'] is String ? frame['level'] as String : null,
        );
        if (text is! String || level == null) {
          _violate('protocol', 'The runner wrote a malformed log output.');
          return;
        }
        item = ScriptConsoleOutput(level: level, text: text);
        chars = text.runes.length;
      case 'image':
        final image = frame['image'];
        if (image is! Map ||
            image['type'] != 'image' ||
            image['mediaType'] is! String ||
            image['data'] is! String) {
          _violate('protocol', 'The runner wrote a malformed image output.');
          return;
        }
        final mediaType = image['mediaType'] as String;
        final data = image['data'] as String;
        final problem = imageProblem(mediaType, data);
        if (problem != null) {
          _violate('protocol', 'The runner wrote an image that $problem.');
          return;
        }
        item = ScriptImageOutput(mediaType: mediaType, data: data);
        chars = data.length;
      default:
        _violate('protocol', 'The runner wrote an unknown output kind.');
        return;
    }
    _outputChars += chars;
    _outputItems++;
    // The runner may write the frame that crosses its own cap before it
    // writes done(output_exceeded), so the host allows one more frame's
    // worth before it calls the runner a liar.
    if (_outputChars >
            CodeModeLimits.interpreterOutputBytes +
                CodeModeLimits.maxFrameBytes ||
        _outputItems > CodeModeLimits.interpreterOutputItems + 1) {
      _violate('output', 'The runner wrote more output than it was allowed.');
      return;
    }
    _events.add(CodeSandboxOutput(item));
  }

  /// A store frame mirrors what the runner enforces before it writes one:
  /// a session given a zero budget stores and deletes nothing, a key is at
  /// most [CodeModeLimits.maxStoreKeyBytes], a value at most
  /// [CodeModeLimits.maxStoreValueBytes], the values together at most
  /// [CodeModeLimits.maxStoreTotalBytes], and a script makes at most
  /// [CodeModeLimits.maxStoreFrames] store operations. A frame past any of
  /// them came from a runner that broke its own rules.
  void _onStore(Map<String, dynamic> frame) {
    final key = frame['key'];
    if (key is! String) {
      _violate('protocol', 'The runner wrote a malformed store frame.');
      return;
    }
    if (!_request.storeWritable) {
      _violate(
        'protocol',
        'The runner wrote a store frame in a session that may not store.',
      );
      return;
    }
    if (++_storeFrames > CodeModeLimits.maxStoreFrames) {
      _violate(
        'store_overrun',
        'The runner sent more than ${CodeModeLimits.maxStoreFrames} store '
            'operations.',
      );
      return;
    }
    final keyBytes = utf8Length(key);
    if (keyBytes > CodeModeLimits.maxStoreKeyBytes) {
      _violate(
        'protocol',
        'The runner sent a store key of $keyBytes bytes; the cap is '
            '${CodeModeLimits.maxStoreKeyBytes}.',
      );
      return;
    }
    if (frame['delete'] == true) {
      _storeTotal -= _storeSizes.remove(key) ?? 0;
      _events.add(CodeSandboxStoreWrite(key: key));
      return;
    }
    if (!frame.containsKey('value')) {
      _violate('protocol', 'The runner wrote a store frame with no value.');
      return;
    }
    final valueJson = jsonEncode(frame['value']);
    // storedValueBytes(frame['value']), without encoding it twice.
    final size = utf8Length(valueJson);
    if (size >
        CodeModeLimits.maxStoreValueBytes +
            CodeSandboxProcess.argumentMeasureSlackBytes) {
      _violate(
        'protocol',
        'The runner sent a stored value of $size bytes; the cap is '
            '${CodeModeLimits.maxStoreValueBytes}.',
      );
      return;
    }
    final total = _storeTotal - (_storeSizes[key] ?? 0) + size;
    if (total >
        CodeModeLimits.maxStoreTotalBytes +
            CodeSandboxProcess.storeTotalSlackBytes) {
      _violate(
        'store_overrun',
        'The runner stored values totalling $total bytes; the cap is '
            '${CodeModeLimits.maxStoreTotalBytes}.',
      );
      return;
    }
    _storeSizes[key] = size;
    _storeTotal = total;
    _events.add(CodeSandboxStoreWrite(key: key, valueJson: valueJson));
  }

  void _onDone(Map<String, dynamic> frame) {
    final ok = frame['ok'];
    final stats = frame['stats'];
    if (ok is! bool || (stats != null && stats is! Map)) {
      _violate('protocol', 'The runner wrote a malformed done frame.');
      return;
    }
    if (stats is Map) {
      for (final key in const [
        'cpu_ms',
        'peak_heap_bytes',
        'calls',
        'output_chars',
      ]) {
        final v = stats[key];
        if (v is! int || v < 0) {
          _violate('protocol', 'The runner wrote malformed done stats.');
          return;
        }
      }
    }
    if (!ok) {
      final error = frame['error'];
      if (error is! Map ||
          error['kind'] is! String ||
          _errorKinds[error['kind']] == null ||
          (error['name'] != null && error['name'] is! String) ||
          (error['message'] != null && error['message'] is! String) ||
          (error['stack'] != null && error['stack'] is! String) ||
          (error['line'] != null && error['line'] is! int) ||
          (error['column'] != null && error['column'] is! int)) {
        _violate('protocol', 'The runner wrote a malformed done error.');
        return;
      }
    }
    _done = frame;
    _deadline.stop();
    _closeStdin();
    _exitTimer = Timer(_host.exitGrace, () {
      _process.kill(ProcessSignal.sigkill);
    });
  }

  static const Map<String, (CodeExecutionStatus, String)> _errorKinds = {
    'script_error': (CodeExecutionStatus.failed, 'script_error'),
    'cpu_exceeded': (CodeExecutionStatus.timedOut, 'cpu'),
    'memory_exceeded': (CodeExecutionStatus.memoryExceeded, 'heap'),
    'output_exceeded': (CodeExecutionStatus.outputExceeded, 'output'),
    'stalled': (CodeExecutionStatus.failed, 'stalled'),
    'cancelled': (CodeExecutionStatus.cancelled, 'cancelled'),
    'internal': (CodeExecutionStatus.sandboxError, 'internal'),
  };

  // ---------------------------------------------------------------------
  // Host to runner

  @override
  void reply(CodeSandboxReply reply) {
    if (_ended || !_running) {
      return;
    }
    final id = int.tryParse(reply.id);
    if (id == null || !_pending.containsKey(id)) {
      return;
    }
    _pendingWeight -= _pending.remove(id)!;
    final credit = _deadline.heldMs - _creditedMs;
    _creditedMs += credit;
    _write(_resultFrame(id, reply, credit));
    if (_pausedForBackpressure &&
        _pendingWeight <= CodeSandboxProcess.pendingArgumentBudgetBytes) {
      // Frames read before the pause go first, in order, until one fills
      // the budget again; only then does reading resume.
      _pausedForBackpressure = false;
      while (_deferred.isNotEmpty && !_pausedForBackpressure && !_stopReading) {
        _handleFrameBytes(_deferred.removeFirst());
      }
      if (!_pausedForBackpressure && !_stopReading) {
        _stdoutSub.resume();
      }
    }
  }

  /// The `result` frame for [reply], replaced by a failure the runner
  /// accepts when the payload cannot cross: not JSON, nested deeper than the
  /// runner parses, or over the frame cap.
  static String _resultFrame(int id, CodeSandboxReply reply, int creditMs) {
    String frame(bool ok, Object? payload) {
      final encoded = tryJsonEncode({
        'type': 'result',
        'id': id,
        'ok': ok,
        'payload': payload,
        if (creditMs > 0) 'credit_ms': creditMs,
      });
      return encoded ?? '';
    }

    Object? errorPayload(Object? raw) {
      if (raw is Map && raw['message'] is String) {
        return {
          'message': raw['message'],
          if (raw['status'] is String) 'status': raw['status'],
        };
      }
      return {'message': raw is String && raw.isNotEmpty ? raw : 'Failed.'};
    }

    // A value already encoded was checked when its call settled (JSON, its
    // depth and its size): it goes into the frame as it is.
    final json = reply.payloadJson;
    if (json != null && json.length <= CodeModeLimits.maxNestedResultBytes) {
      return '{"type":"result","id":$id,"ok":true,"payload":'
          '${utf8.decode(json)}'
          '${creditMs > 0 ? ',"credit_ms":$creditMs' : ''}}';
    }
    final payload = reply.ok ? reply.payload : errorPayload(reply.payload);
    String? problem;
    // The frame adds two levels (the frame object and, for errors, the
    // payload object is already counted), so the payload keeps headroom.
    if (jsonDepth(payload) > kRunnerMaxJsonDepth - 2) {
      problem =
          'The result is nested more than ${kRunnerMaxJsonDepth - 2} levels '
          'deep, which a script cannot receive.';
    } else {
      final text = frame(reply.ok, payload);
      if (text.isEmpty) {
        problem = 'The result is not JSON, so a script cannot receive it.';
      } else if (utf8.encode(text).length > CodeModeLimits.maxFrameBytes) {
        problem =
            'The result is over ${CodeModeLimits.maxFrameBytes ~/ (1024 * 1024)} '
            'MiB, which a script cannot receive. Narrow the request.';
      } else {
        return text;
      }
    }
    return frame(false, {'message': problem, 'status': 'failed'});
  }

  /// Queues [frame] for the runner. What the runner has not read yet is
  /// counted from the moment it is queued until the pipe accepted it
  /// (`flush`), so a runner that stops reading is caught once
  /// [CodeSandboxProcess.stdinBacklogBudgetBytes] are waiting, not when the
  /// server runs out of memory.
  void _write(String frame) {
    if (_stdinClosed) {
      return;
    }
    final bytes = utf8.encode('$frame\n');
    if (_stdinBacklog + bytes.length >
        CodeSandboxProcess.stdinBacklogBudgetBytes) {
      _violate(
        'stdin_stalled',
        'The runner stopped reading: '
            '${_stdinBacklog ~/ (1024 * 1024)} MiB sent to it were still '
            'unread.',
      );
      return;
    }
    _stdinBacklog += bytes.length;
    _stdinQueue.add(bytes);
    if (!_flushing) {
      unawaited(_drainStdin());
    }
  }

  /// Hands queued frames to the pipe one batch at a time, waiting for each
  /// batch to be accepted. `IOSink.add` may not be called while a flush is
  /// pending, so frames queue here meanwhile.
  Future<void> _drainStdin() async {
    _flushing = true;
    try {
      while (_stdinQueue.isNotEmpty && !_stdinClosed) {
        final batch = BytesBuilder(copy: false);
        while (_stdinQueue.isNotEmpty) {
          batch.add(_stdinQueue.removeFirst());
        }
        final size = batch.length;
        _process.stdin.add(batch.takeBytes());
        await _process.stdin.flush();
        _stdinBacklog -= size;
      }
    } on Object {
      // The runner is gone; its exit decides the outcome.
    } finally {
      _flushing = false;
      if (_stdinClosed) {
        _closeSink();
      }
    }
  }

  void _closeStdin() {
    if (_stdinClosed) {
      return;
    }
    _stdinClosed = true;
    _stdinQueue.clear();
    if (!_flushing) {
      _closeSink();
    }
    // Otherwise _drainStdin closes the sink when its flush ends; a killed
    // runner ends it with an error.
  }

  void _closeSink() {
    try {
      unawaited(_process.stdin.close().catchError((Object _) {}));
    } on Object {
      // Already closed, or bound to a flush that a dead pipe will end.
    }
  }

  @override
  CodeSandboxDeadlineHold holdDeadline() {
    _deadline.hold();
    return PausableDeadlineHold(_deadline);
  }

  @override
  void cancel() {
    if (_ended) {
      return;
    }
    _endReason = _EndReason.cancelled;
    _stopGracefully();
  }

  @override
  bool get ended => _ended || _outcome.isCompleted;

  @override
  void terminate() {
    if (_outcome.isCompleted) {
      return;
    }
    kill(_EndReason.unresponsive);
    Timer(_host.exitGrace + CodeSandboxProcess._drainGrace, abandon);
  }

  /// Ends the session without waiting for its process to report its exit:
  /// for a process that was killed and still has not exited.
  void abandon() {
    if (_outcome.isCompleted) {
      return;
    }
    _endReason ??= _EndReason.unresponsive;
    _completeStdout();
    unawaited(_finalize());
  }

  void _expire() {
    if (_ended) {
      return;
    }
    _endReason = _EndReason.deadline;
    _stopGracefully();
  }

  /// Asks the runner to stop, then kills it after the grace period. Output
  /// and calls it writes in between are still read.
  void _stopGracefully() {
    _deadline.stop();
    _write('{"type":"cancel"}');
    _killTimer ??= Timer(
      const Duration(milliseconds: CodeModeLimits.cancelKillGraceMs),
      () => _process.kill(ProcessSignal.sigkill),
    );
  }

  /// Kills the runner at once for [reason].
  void kill(_EndReason reason) {
    _endReason ??= reason;
    _deadline.stop();
    _stopReading = true;
    _closeStdin();
    _process.kill(ProcessSignal.sigkill);
  }

  void _violate(String kind, String detail) {
    if (_endReason != null) {
      return;
    }
    _violationKind = kind;
    _violationDetail = detail;
    kill(_EndReason.violation);
    unawaited(_stdoutSub.cancel());
    _completeStdout();
  }

  void _completeStdout() {
    if (!_stdoutDone.isCompleted) {
      _stdoutDone.complete();
    }
  }

  // ---------------------------------------------------------------------
  // Exit

  Future<void> _onExit(int code) async {
    _exitCode = code;
    _deadline.stop();
    // Frames and stderr written just before the exit are still in their
    // pipes. Give the readers a moment to drain them, then stop listening
    // whatever happens.
    await Future.wait([
      _stdoutDone.future,
      _stderrDone,
    ]).timeout(CodeSandboxProcess._drainGrace, onTimeout: () => const []);
    await _finalize();
  }

  /// Completes the outcome exactly once, whatever happens on the way: a
  /// throw while it is built ends the script as a sandbox error rather than
  /// leaving the session, its slot and its run waiting forever.
  Future<void> _finalize() async {
    if (_finalizing) {
      return;
    }
    _finalizing = true;
    CodeSandboxOutcome? outcome;
    try {
      _killTimer?.cancel();
      _exitTimer?.cancel();
      _deadline.stop();
      _stopReading = true;
      _closeStdin();
      unawaited(_stdoutSub.cancel().catchError((Object _) {}));
      // Not awaited: a stream nobody listened to (a failed handshake) never
      // reports its close as delivered.
      unawaited(_events.close().catchError((Object _) {}));
      outcome = _buildOutcome();
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: reading a runner outcome failed', e, st);
    } finally {
      if (!_outcome.isCompleted) {
        _outcome.complete(
          outcome ??
              CodeSandboxOutcome(
                status: CodeExecutionStatus.sandboxError,
                errorKind: CodeExecutionErrorKind.hostError,
                detail:
                    'The host could not read how the script ended, so it was '
                    'stopped.',
              ),
        );
      }
    }
  }

  CodeSandboxOutcome _buildOutcome() {
    final done = _done;
    final stats = done?['stats'];
    final sandboxStats = stats is Map
        ? CodeSandboxStats(
            cpuMs: stats['cpu_ms'] as int,
            peakHeapBytes: stats['peak_heap_bytes'] as int,
            calls: stats['calls'] as int,
            outputBytes: stats['output_chars'] as int,
          )
        : null;
    final wallSeconds = (_request.limits.wallClockMs / 1000).toStringAsFixed(
      _request.limits.wallClockMs % 1000 == 0 ? 0 : 1,
    );
    switch (_endReason) {
      case _EndReason.violation:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.sandboxError,
          errorKind: _violationKind,
          detail:
              'The script runner broke the protocol and was stopped: '
              '$_violationDetail',
          stats: sandboxStats,
        );
      case _EndReason.deadline:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.timedOut,
          errorKind: 'deadline',
          detail:
              'The script ran past its $wallSeconds s wall-clock limit and '
              'was stopped. Time spent waiting for a person is not counted.',
          stats: sandboxStats,
        );
      case _EndReason.cancelled:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.cancelled,
          errorKind: 'cancelled',
          detail: 'The script was cancelled.',
          stats: sandboxStats,
        );
      case _EndReason.disposed:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.cancelled,
          errorKind: 'shutdown',
          detail: 'The server shut down while the script was running.',
          stats: sandboxStats,
        );
      case _EndReason.handshake:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.sandboxError,
          errorKind: 'start',
          detail: 'The script runner was stopped before the script started.',
        );
      case _EndReason.unresponsive:
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.sandboxError,
          errorKind: CodeExecutionErrorKind.unresponsive,
          detail:
              'The script runner did not report how the script ended and was '
              'stopped.',
          stats: sandboxStats,
        );
      case null:
        break;
    }
    if (done == null) {
      return CodeSandboxOutcome(
        status: CodeExecutionStatus.sandboxError,
        errorKind: switch (_exitCode) {
          3 => 'lockdown',
          4 => CodeExecutionErrorKind.internal,
          _ => 'exited',
        },
        detail: _exitDetail(_exitCode),
      );
    }
    if (done['ok'] == true) {
      if (_exitCode != 0) {
        return CodeSandboxOutcome(
          status: CodeExecutionStatus.sandboxError,
          errorKind: 'exited',
          detail: _exitDetail(_exitCode),
          stats: sandboxStats,
        );
      }
      return CodeSandboxOutcome(
        status: CodeExecutionStatus.completed,
        returnValue: switch (_rawReturnValue) {
          final raw? => ScriptTextOutput(raw),
          _ when done.containsKey('value') =>
            ScriptOutputItem.value(done['value']) as ScriptTextOutput,
          _ => null,
        },
        stats: sandboxStats,
      );
    }
    final error = (done['error'] as Map).cast<String, dynamic>();
    // `kind` alone decides the status; the name, message and stack are the
    // script's (capped by ScriptError.fromJson) and only ever displayed.
    final (status, kind) = _errorKinds[error['kind']]!;
    final scriptError = ScriptError.fromJson(error);
    return CodeSandboxOutcome(
      status: status,
      error: status == CodeExecutionStatus.failed ? scriptError : null,
      errorKind: kind,
      detail: switch (kind) {
        'cpu' =>
          'The script used its ${_request.limits.cpuMs ~/ 1000} s of '
              'interpreter CPU time.',
        'heap' =>
          'The script used its '
              '${_request.limits.heapBytes ~/ (1024 * 1024)} MiB of memory.',
        'output' =>
          'The script wrote more output than the interpreter keeps '
              '(${scriptError.message}).',
        'stalled' =>
          'The script awaited a promise that nothing could settle: no tool '
              'call, timer or other work was pending.',
        'internal' => oneLineLabel(
          _withoutHostPaths(
            oneLogLine(
              'The script runner failed: ${scriptError.name}: '
              '${scriptError.message}',
            ),
          ),
          CodeSandboxProcess.stderrTailChars,
        ),
        _ => null,
      },
      stats: sandboxStats,
    );
  }

  /// [text] with the runner's path, its directory and every other host
  /// path replaced: what the runner writes reaches the model.
  String _withoutHostPaths(String text) => scrubHostPaths(
    text,
    knownPaths: [_host.executable, File(_host.executable).parent.path],
  );

  /// The end of the runner's stderr, safe to show: each line made a log
  /// line ([oneLogLine]: invisible characters dropped, secrets redacted,
  /// control and bidirectional characters replaced), then host paths
  /// replaced; lines joined with ` | `, at most
  /// [CodeSandboxProcess.stderrTailChars] characters from the end.
  String _stderrTail() {
    final lines = utf8
        .decode(_stderr.bytes(), allowMalformed: true)
        .split('\n')
        .map((l) => _withoutHostPaths(oneLogLine(l)).trim())
        .where((l) => l.isNotEmpty)
        .toList();
    var tail = lines.join(' | ').replaceAll(RegExp(r'\s+'), ' ');
    final runes = tail.runes.toList();
    const max = CodeSandboxProcess.stderrTailChars;
    if (runes.length > max) {
      tail = '…${String.fromCharCodes(runes.sublist(runes.length - max + 1))}';
    }
    return tail;
  }

  String _exitDetail(int? code) {
    final said = _stderrTail();
    final tail = said.isEmpty ? '' : ' Runner said: $said';
    // The runner's exit codes and the signals its kernel backstops send
    // (cc_codemode's README, "Exit codes").
    final what = switch (code) {
      0 => 'The script runner exited without finishing the script.',
      1 => 'The script runner reported a protocol violation by the host.',
      2 => 'The script runner was started with arguments it does not accept.',
      3 => 'The script runner could not lock itself down fully.',
      4 =>
        'The script runner failed internally, or could not set up its '
            'interpreter.',
      5 => 'The script runner lost its input before the script finished.',
      null => 'The script runner exited.',
      _ when code == -_sigsys =>
        'The script runner was stopped by its lockdown for a system call it '
            'may not make (SIGSYS).',
      _ when code == -_sigabrt =>
        'The script runner aborted: it ran out of memory outside the '
            "script's heap, or its interpreter failed an internal check "
            '(SIGABRT).',
      _ when code == -_sigxcpu || code == -ProcessSignal.sigkill.signalNumber =>
        'The script runner was killed (signal ${-code}): it used up its CPU '
            'time, or the host stopped it.',
      _ when code < 0 => 'The script runner was killed by signal ${-code}.',
      _ => 'The script runner exited with code $code.',
    };
    return '$what$tail';
  }
}

/// The working directory every runner process starts in, whatever the
/// server's own: `/` on macOS and Linux, so it names no directory of the
/// server's; on Windows the directory of the runner's own executable, the
/// one place its container is certain to be allowed to open (not yet run
/// on a Windows host).
String runnerWorkingDirectory(String executable) =>
    Platform.isWindows ? File(executable).parent.path : '/';
