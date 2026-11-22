import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_infra/src/eval/kernel_runners.dart';
import 'package:cc_infra/src/eval/magics_transform.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
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
    required this.restarted,
    this.error,
    this.timedOut = false,
  });

  /// Everything the cell emitted, in order. A cell that printed more than
  /// the kernel's `maxOutputChars` keeps its first three quarters and its
  /// last quarter, with one [KernelText] between them that says how many
  /// characters were dropped there.
  final List<KernelOutput> outputs;

  /// Whether this is the first cell since the interpreter died unasked (it
  /// exited or was killed between cells, not a `reset`) and was started
  /// again: every variable, import and loaded file of the session is gone.
  /// True for that one cell only.
  final bool restarted;

  /// The traceback, when it raised.
  final String? error;

  /// Whether the inactivity budget expired.
  final bool timedOut;

  /// Whether it completed cleanly.
  bool get isError => error != null || timedOut;
}

/// How a kernel process is started. Host or enclosure.
abstract interface class KernelLauncher {
  /// Writes [contents] to [relativePath] in the kernel's working directory.
  Future<void> writeFile(String relativePath, String contents);

  /// Starts the interpreter on [runnerPath] with piped stdio.
  Future<Process> start(KernelLanguage language, String runnerPath);
}

/// Runs the kernel on the server host, used when the conversation has no
/// enclosure (`RigKernelLauncher`). Both speak the same NDJSON, so nothing
/// above this line knows which one it got.
///
/// The interpreter starts through the run's [processes] launcher: inside the
/// run's sandbox when the server sandboxes agents.
class HostKernelLauncher implements KernelLauncher {
  /// Creates a [HostKernelLauncher] rooted at [workingDirectory].
  const HostKernelLauncher({
    required this.workingDirectory,
    required this.processes,
    this.pythonExecutable,
    this.nodeExecutable,
  });

  /// Where cells run.
  final String workingDirectory;

  /// Starts the interpreter.
  final ToolProcessLauncher processes;

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
    // The venv is the repository's program, so only a confined kernel uses it.
    final python =
        pythonExecutable ??
        (processes.confined
            ? _firstExisting([
                p.join(workingDirectory, '.venv', 'bin', 'python3'),
                p.join(workingDirectory, 'venv', 'bin', 'python3'),
              ])
            : null) ??
        'python3';
    return switch (language) {
      KernelLanguage.python => processes.start(
        python,
        // Unbuffered: the whole value of streaming a cell's output is losing
        // it to a 4KB buffer that only flushes when the cell ends.
        ['-u', runnerPath],
        workingDirectory: workingDirectory,
      ),
      KernelLanguage.javascript => processes.start(
        nodeExecutable ?? 'node',
        [runnerPath],
        workingDirectory: workingDirectory,
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
/// **The timeout is an INACTIVITY budget.** A cell that keeps producing
/// output keeps running; one that goes quiet for [inactivityTimeout] is left
/// running and reported, and the kernel keeps its state.
class EvalKernel {
  /// Creates an [EvalKernel].
  EvalKernel({
    required this.language,
    required this._launcher,
    this.inactivityTimeout = const Duration(minutes: 5),
    this.maxOutputChars = 100000,
  });

  /// Which interpreter.
  final KernelLanguage language;

  /// How long a cell may go without producing anything.
  final Duration inactivityTimeout;

  /// Cap on a single cell's text output.
  final int maxOutputChars;

  final KernelLauncher _launcher;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final _stderrLog = <String>[];
  final _ready = Completer<String>();
  int _nextId = 1;

  _Cell? _cell;
  bool _disposed = false;

  /// Whether the interpreter died unasked after it had run a cell, so the
  /// next cell starts in a fresh one ([KernelRunOutcome.restarted]).
  bool _lostState = false;

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
        // Unasked (a `dispose` nulls the handle first): what the cells built
        // is gone, and the next cell is told so once.
        _lostState = _nextId > 1;
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
    final restarted = _lostState;
    _lostState = false;

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
      final outcome = await cell.completed.future;
      return restarted
          ? KernelRunOutcome(
              outputs: outcome.outputs,
              restarted: true,
              error: outcome.error,
              timedOut: outcome.timedOut,
            )
          : outcome;
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
    // Asked for: the caller knows the state is gone.
    _lostState = false;
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
      case 'error':
        _cell?.finish(error: '${decoded['text']}');
      case 'done':
        _cell?.finish();
    }
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

  /// Characters the head keeps: three quarters of [maxOutputChars].
  late final int _headCap = maxOutputChars * 3 ~/ 4;

  /// Characters the rolling tail keeps: the last quarter.
  late final int _tailCap = maxOutputChars - _headCap;
  var _chars = 0;
  var _cut = false;
  final _tail = ListQueue<KernelOutput>();
  var _tailChars = 0;

  /// UTF-16 units of text (and result) output dropped from the tail.
  var _dropped = 0;

  /// Images dropped from the tail: they take no characters, so they are
  /// counted apart.
  var _droppedImages = 0;

  void _arm() {
    _timer?.cancel();
    _timer = Timer(timeout, () {
      if (!completed.isCompleted) {
        completed.complete(
          KernelRunOutcome(
            outputs: _assembled(),
            restarted: false,
            timedOut: true,
          ),
        );
      }
    });
  }

  void touch() => _arm();

  /// Adds [output]. Bounded: a cell in a print loop would otherwise fill the
  /// context window the tool result lands in. The first three quarters of
  /// [maxOutputChars] are kept as they came; past them a rolling tail keeps
  /// the last quarter, where a loop's end (and its error) usually is.
  void add(KernelOutput output) {
    touch();
    var rest = output;
    if (!_cut) {
      final size = _sizeOf(output);
      if (_chars + size <= _headCap) {
        _chars += size;
        outputs.add(output);
        return;
      }
      _cut = true;
      if (output is KernelText) {
        final at = safeCutBefore(output.text, _headCap - _chars);
        if (at > 0) {
          outputs.add(
            KernelText(output.text.substring(0, at), isError: output.isError),
          );
        }
        _chars += at;
        rest = KernelText(output.text.substring(at), isError: output.isError);
      }
    }
    _tail.add(rest);
    _tailChars += _sizeOf(rest);
    while (_tailChars > _tailCap && _tail.isNotEmpty) {
      final first = _tail.removeFirst();
      final size = _sizeOf(first);
      final over = _tailChars - _tailCap;
      if (first is KernelText && size > over) {
        final at = safeCutAfter(first.text, over);
        _tail.addFirst(
          KernelText(first.text.substring(at), isError: first.isError),
        );
        _tailChars -= at;
        _dropped += at;
      } else {
        _tailChars -= size;
        _dropped += size;
        if (first is KernelImage) {
          _droppedImages++;
        }
      }
    }
  }

  static int _sizeOf(KernelOutput o) => switch (o) {
    KernelText(:final text) => text.length,
    KernelResult(:final text) => text.length,
    KernelImage() => 0,
  };

  /// The head, what was dropped when anything was, and the tail.
  List<KernelOutput> _assembled() => [
    ...outputs,
    if (_dropped > 0 || _droppedImages > 0)
      KernelText(
        '\n… dropped here: ${[if (_dropped > 0) '$_dropped characters (UTF-16 units) of text', if (_droppedImages > 0) '$_droppedImages image${_droppedImages == 1 ? '' : 's'}'].join(' and ')}. The cell printed more than $maxOutputChars '
        'characters of text; its first $_headCap and last $_tailCap are '
        'kept …\n',
      ),
    ..._tail,
  ];

  void finish({String? error}) {
    _timer?.cancel();
    if (!completed.isCompleted) {
      completed.complete(
        KernelRunOutcome(outputs: _assembled(), restarted: false, error: error),
      );
    }
  }

  void failHard(String message) {
    _timer?.cancel();
    if (!completed.isCompleted) {
      completed.complete(
        KernelRunOutcome(
          outputs: _assembled(),
          restarted: false,
          error: message,
        ),
      );
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
