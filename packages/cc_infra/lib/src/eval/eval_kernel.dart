import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/eval/kernel_runners.dart';
import 'package:cc_infra/src/eval/magics_transform.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Which interpreter a kernel runs.
enum KernelLanguage {
  /// CPython, via `python3 -u`.
  python,

  /// Node, via `node`.
  javascript;

  /// The runner source written into the working directory.
  String get runnerSource =>
      this == KernelLanguage.python ? pythonKernelRunner : jsKernelRunner;

  /// The file the runner is written to.
  String get runnerFileName =>
      this == KernelLanguage.python ? '.cc_kernel.py' : '.cc_kernel.js';

  /// Rewrites the notebook idioms people type into plain source.
  String transform(String source) => this == KernelLanguage.python
      ? transformPythonMagics(source)
      : transformJsMagics(source);
}

/// One thing a cell produced.
sealed class KernelOutput {
  const KernelOutput();
}

/// Text the cell printed.
class KernelText extends KernelOutput {
  /// Creates a [KernelText].
  const KernelText(this.text, {this.isError = false});

  /// The text.
  final String text;

  /// Whether it went to stderr.
  final bool isError;
}

/// The cell's trailing expression, echoed the way a notebook does.
class KernelResult extends KernelOutput {
  /// Creates a [KernelResult].
  const KernelResult(this.text);

  /// The repr.
  final String text;
}

/// An image the cell produced — a chart, typically.
class KernelImage extends KernelOutput {
  /// Creates a [KernelImage].
  const KernelImage({required this.mediaType, required this.base64Data});

  /// `image/png`, `text/html`, …
  final String mediaType;

  /// The payload, base64 for binary types.
  final String base64Data;
}

/// What one cell produced in total.
class KernelRunOutcome {
  /// Creates a [KernelRunOutcome].
  const KernelRunOutcome({
    required this.outputs,
    this.error,
    this.timedOut = false,
  });

  /// Everything the cell emitted, in order.
  final List<KernelOutput> outputs;

  /// The traceback, when it raised.
  final String? error;

  /// Whether the inactivity budget expired.
  final bool timedOut;

  /// Whether it completed cleanly.
  bool get isError => error != null || timedOut;
}

/// Runs one of the agent's tools on behalf of code inside a cell.
typedef KernelToolBridge =
    Future<({String content, bool isError})> Function(
      String name,
      Map<String, dynamic> arguments,
    );

/// How a kernel process is started. Host or enclosure.
abstract interface class KernelLauncher {
  /// Writes [contents] to [relativePath] in the kernel's working directory.
  Future<void> writeFile(String relativePath, String contents);

  /// Starts the interpreter on [runnerPath] with piped stdio.
  Future<Process> start(KernelLanguage language, String runnerPath);
}

/// Runs the kernel as a child process of the server.
///
/// The plain path, used when no enclosure is available. The enclosure launcher
/// is the one that matters for an untrusted repo — see `RigKernelLauncher` —
/// but they speak the same NDJSON, so nothing above this line knows which one
/// it got.
class HostKernelLauncher implements KernelLauncher {
  /// Creates a [HostKernelLauncher] rooted at [workingDirectory].
  const HostKernelLauncher({
    required this.workingDirectory,
    this.pythonExecutable,
    this.nodeExecutable,
  });

  /// Where cells run.
  final String workingDirectory;

  /// Override for the Python interpreter.
  final String? pythonExecutable;

  /// Override for node.
  final String? nodeExecutable;

  @override
  Future<void> writeFile(String relativePath, String contents) async {
    final file = File(p.join(workingDirectory, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  @override
  Future<Process> start(KernelLanguage language, String runnerPath) {
    // A checkout's own venv is the interpreter its dependencies are installed
    // against; a `$PATH` python is a different environment, and a cell that
    // cannot import the package the repo depends on reads as broken code.
    final python =
        pythonExecutable ??
        _firstExisting([
          p.join(workingDirectory, '.venv', 'bin', 'python3'),
          p.join(workingDirectory, 'venv', 'bin', 'python3'),
        ]) ??
        'python3';
    return switch (language) {
      KernelLanguage.python => Process.start(
        python,
        // Unbuffered: the whole value of streaming a cell's output is losing
        // it to a 4KB buffer that only flushes when the cell ends.
        ['-u', runnerPath],
        workingDirectory: workingDirectory,
        includeParentEnvironment: true,
      ),
      KernelLanguage.javascript => Process.start(
        nodeExecutable ?? 'node',
        [runnerPath],
        workingDirectory: workingDirectory,
        includeParentEnvironment: true,
      ),
    };
  }

  static String? _firstExisting(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }
}

/// Resolves the launcher for one conversation, when the kernel is first used.
///
/// Async and deferred so the "where does this run" decision — the enclosure
/// when the conversation has one, the host otherwise — stays in the
/// composition root and is made at the moment a cell is actually run, not at
/// the moment the tool surface is assembled.
typedef KernelLauncherResolver = Future<KernelLauncher> Function();

/// Defers to a [KernelLauncherResolver] on first use.
class LazyKernelLauncher implements KernelLauncher {
  /// Creates a [LazyKernelLauncher] over a resolver.
  LazyKernelLauncher(this._resolve);

  final KernelLauncherResolver _resolve;
  Future<KernelLauncher>? _resolved;

  Future<KernelLauncher> get _launcher => _resolved ??= _resolve();

  @override
  Future<void> writeFile(String relativePath, String contents) async =>
      (await _launcher).writeFile(relativePath, contents);

  @override
  Future<Process> start(KernelLanguage language, String runnerPath) async =>
      (await _launcher).start(language, runnerPath);
}

/// A live interpreter that keeps its variables between calls.
///
/// **What persistence buys.** Loading a dataframe costs seconds and a hundred
/// megabytes; charting it costs milliseconds. A one-shot `bash python -c` pays
/// the load on every question, so an agent exploring data asks fewer questions
/// than it should. Here the second cell starts where the first stopped.
///
/// **The timeout is an INACTIVITY budget, and it pauses during a bridged
/// call.** A cell that fans out to `task` and waits four minutes for subagents
/// is not a hung cell — but a wall-clock timeout cannot tell the difference and
/// kills it mid-fanout, losing the whole kernel's state. So the budget is
/// suspended while a bridged call is outstanding and resumes when it returns.
/// That is a bug you only find in production.
class EvalKernel {
  /// Creates an [EvalKernel].
  EvalKernel({
    required this.language,
    required KernelLauncher launcher,
    KernelToolBridge? bridge,
    this.inactivityTimeout = const Duration(minutes: 5),
    this.maxOutputChars = 100000,
  }) : _launcher = launcher,
       _bridge = bridge;

  /// Which interpreter.
  final KernelLanguage language;

  /// How long a cell may go without producing anything.
  final Duration inactivityTimeout;

  /// Cap on a single cell's text output.
  final int maxOutputChars;

  final KernelLauncher _launcher;
  final KernelToolBridge? _bridge;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final _stderrLog = <String>[];
  final _ready = Completer<String>();
  int _nextId = 1;

  _Cell? _cell;
  bool _disposed = false;

  /// Whether the interpreter is running.
  bool get isRunning => _process != null && !_disposed;

  /// The interpreter version, once it has announced itself.
  Future<String> get version => _ready.future;

  /// Recent interpreter stderr, for diagnosing a kernel that will not start.
  List<String> get stderrLog => List.unmodifiable(_stderrLog);

  /// Starts the interpreter, writing the runner first.
  Future<void> start() async {
    if (_process != null) {
      return;
    }
    // A fresh interpreter clears a previous `dispose` — the eval tool's
    // `reset` flow is exactly that: dispose, then `run` starts a new one.
    _disposed = false;
    await _launcher.writeFile(language.runnerFileName, language.runnerSource);
    final process = await _launcher.start(language, language.runnerFileName);
    _process = process;
    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine);
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (_stderrLog.length >= 100) {
            _stderrLog.removeAt(0);
          }
          _stderrLog.add(line);
        });
    unawaited(
      process.exitCode.then((code) {
        // A `reset` kills this interpreter and starts a replacement; when the
        // old exit code lands after the new process is already installed, it
        // must not tear the replacement down (null its handle, fail its cell).
        if (!identical(process, _process)) {
          return;
        }
        _process = null;
        _cell?.failHard('the kernel exited with code $code');
        if (!_ready.isCompleted) {
          _ready.completeError(
            StateError(
              'the ${language.name} kernel exited before it was ready'
              '${_stderrLog.isEmpty ? '' : ': ${_stderrLog.last}'}',
            ),
          );
        }
      }),
    );
    // A kernel that never announces itself is one whose interpreter is
    // missing; surfacing that as a start failure beats a first cell that
    // times out with no explanation.
    await _ready.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw StateError(
        'the ${language.name} interpreter did not start'
        '${_stderrLog.isEmpty ? '' : ': ${_stderrLog.last}'}',
      ),
    );
  }

  /// Runs [source] and returns everything it produced.
  Future<KernelRunOutcome> run(String source) async {
    if (_cell != null) {
      throw StateError('a cell is already running in this kernel');
    }
    await start();
    final process = _process;
    if (process == null) {
      throw StateError('the kernel is not running');
    }

    final cell = _Cell(
      id: _nextId++,
      timeout: inactivityTimeout,
      maxOutputChars: maxOutputChars,
    );
    _cell = cell;
    try {
      process.stdin.writeln(
        jsonEncode({
          'type': 'exec',
          'id': cell.id,
          'code': language.transform(source),
        }),
      );
      return await cell.completed.future;
    } finally {
      cell.dispose();
      _cell = null;
    }
  }

  /// Interrupts the running cell without killing the kernel.
  ///
  /// `SIGINT` rather than a kill, because the point is to lose the CELL and
  /// keep every variable the session has built up. The runner ignores it
  /// between requests, so a cancel that arrives late cannot take the kernel
  /// down.
  void interrupt() {
    final process = _process;
    if (process == null) {
      return;
    }
    process.kill(ProcessSignal.sigint);
  }

  /// Stops the interpreter and forgets its state.
  ///
  /// Not final: the eval tool's `reset` disposes and then starts a fresh
  /// interpreter on this same kernel, and a later `dispose` must still be able
  /// to kill THAT one.
  Future<void> dispose() async {
    final process = _process;
    if (_disposed && process == null) {
      return;
    }
    _disposed = true;
    _process = null;
    _cell?.failHard('the kernel was shut down');
    try {
      process?.stdin.writeln(jsonEncode({'type': 'shutdown'}));
    } on Object {
      // Already gone.
    }
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    process?.kill();
  }

  void _onLine(String line) {
    if (line.isEmpty) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      // A runner that printed something outside the protocol: treat it as the
      // cell's output rather than dropping it, since that is usually a
      // library writing straight to fd 1.
      _cell?.add(KernelText(line));
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    switch (decoded['type']) {
      case 'ready':
        if (!_ready.isCompleted) {
          _ready.complete('${decoded['version']}');
        }
      case 'started':
        _cell?.touch();
      case 'stdout':
        _cell?.add(KernelText('${decoded['text']}'));
      case 'stderr':
        _cell?.add(KernelText('${decoded['text']}', isError: true));
      case 'result':
        _cell?.add(KernelResult('${decoded['text']}'));
      case 'display':
        _cell?.add(
          KernelImage(
            mediaType: '${decoded['mime']}',
            base64Data: '${decoded['data']}',
          ),
        );
      case 'bridge_call':
        _onBridgeCall(decoded);
      case 'error':
        _cell?.finish(error: '${decoded['text']}');
      case 'done':
        _cell?.finish();
    }
  }

  void _onBridgeCall(Map<String, dynamic> message) {
    final cell = _cell;
    final process = _process;
    final bridge = _bridge;
    if (cell == null || process == null) {
      return;
    }
    if (bridge == null) {
      process.stdin.writeln(
        jsonEncode({
          'is_error': true,
          'content': 'no tool bridge is wired for this kernel',
        }),
      );
      return;
    }
    // The budget is suspended for exactly as long as the tool takes. Without
    // this a cell that fans out to subagents is killed mid-fanout.
    cell.pauseTimeout();
    unawaited(() async {
      ({String content, bool isError}) reply;
      try {
        reply = await bridge(
          '${message['name']}',
          (message['arguments'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      } on Object catch (e) {
        reply = (content: '$e', isError: true);
      }
      cell.resumeTimeout();
      try {
        process.stdin.writeln(
          jsonEncode({'content': reply.content, 'is_error': reply.isError}),
        );
      } on Object catch (e) {
        CcInfraLog.warning('kernel bridge reply failed: $e');
      }
    }());
  }
}

/// The state of one in-flight cell.
class _Cell {
  _Cell({
    required this.id,
    required this.timeout,
    required this.maxOutputChars,
  }) {
    _arm();
  }

  final int id;
  final Duration timeout;
  final int maxOutputChars;
  final completed = Completer<KernelRunOutcome>();
  final outputs = <KernelOutput>[];

  Timer? _timer;
  var _chars = 0;
  var _truncated = false;
  var _paused = false;

  void _arm() {
    _timer?.cancel();
    _timer = Timer(timeout, () {
      if (!completed.isCompleted) {
        completed.complete(
          KernelRunOutcome(outputs: List.of(outputs), timedOut: true),
        );
      }
    });
  }

  void touch() {
    if (!_paused) {
      _arm();
    }
  }

  void pauseTimeout() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resumeTimeout() {
    _paused = false;
    if (!completed.isCompleted) {
      _arm();
    }
  }

  void add(KernelOutput output) {
    touch();
    if (output is KernelText) {
      // Bounded: a cell in a print loop would otherwise fill the context
      // window the tool result lands in.
      if (_chars >= maxOutputChars) {
        if (!_truncated) {
          _truncated = true;
          outputs.add(const KernelText('\n… output truncated\n'));
        }
        return;
      }
      _chars += output.text.length;
    }
    outputs.add(output);
  }

  void finish({String? error}) {
    _timer?.cancel();
    if (!completed.isCompleted) {
      completed.complete(
        KernelRunOutcome(outputs: List.of(outputs), error: error),
      );
    }
  }

  void failHard(String message) {
    _timer?.cancel();
    if (!completed.isCompleted) {
      completed.complete(
        KernelRunOutcome(outputs: List.of(outputs), error: message),
      );
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
