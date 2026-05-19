import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

/// Lifecycle status of a managed background process.
enum BackgroundProcessStatus {
  /// Spawned, waiting on the readiness probe (if any).
  starting,

  /// Running (no probe, or probe not yet satisfied).
  running,

  /// Probe satisfied — the process is accepting work.
  ready,

  /// Exited on its own.
  exited,

  /// Failed to spawn or crashed.
  failed,

  /// Being torn down.
  stopping,

  /// Stopped by the agent / on session exit.
  stopped;

  /// The wire string.
  String get wire => name;
}

/// A readiness probe: the process is "ready" when its combined stdout/stderr
/// matches [pattern] OR a TCP connection to [port] succeeds, whichever first,
/// within [timeout].
class ReadyProbe {
  /// Creates a [ReadyProbe].
  const ReadyProbe({
    this.pattern,
    this.port,
    this.timeout = const Duration(seconds: 30),
  });

  /// Parses a probe from MCP tool args (`{pattern?, port?, timeout_ms?}`).
  static ReadyProbe? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final pattern = raw['pattern'] as String?;
    final port = (raw['port'] as num?)?.toInt();
    if (pattern == null && port == null) {
      return null;
    }
    final timeoutMs = (raw['timeout_ms'] as num?)?.toInt();
    return ReadyProbe(
      pattern: pattern,
      port: port,
      timeout: timeoutMs != null && timeoutMs > 0
          ? Duration(milliseconds: timeoutMs)
          : const Duration(seconds: 30),
    );
  }

  /// Regex matched against the accumulated output.
  final String? pattern;

  /// TCP port whose first successful connection marks readiness.
  final int? port;

  /// How long to wait before giving up on readiness.
  final Duration timeout;
}

/// An immutable snapshot of a managed process.
class BackgroundProcessInfo {
  /// Creates a [BackgroundProcessInfo].
  const BackgroundProcessInfo({
    required this.id,
    required this.command,
    required this.cwd,
    required this.status,
    required this.ready,
    this.pid,
    this.description,
    this.exitCode,
    required this.startedAt,
  });

  /// Stable handle id (`bgp-<uuid>`).
  final String id;

  /// The full command line.
  final String command;

  /// Working directory.
  final String cwd;

  /// Current status.
  final BackgroundProcessStatus status;

  /// Whether the readiness probe has been satisfied.
  final bool ready;

  /// OS process id, once spawned.
  final int? pid;

  /// Short label for the UI.
  final String? description;

  /// Exit code, once the process has exited.
  final int? exitCode;

  /// When the process was started.
  final DateTime startedAt;

  /// The wire map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'command': command,
    'cwd': cwd,
    'status': status.wire,
    'ready': ready,
    if (pid != null) 'pid': pid,
    if (description != null) 'description': description,
    if (exitCode != null) 'exit_code': exitCode,
    'started_at': startedAt.toIso8601String(),
  };
}

/// Raised when a background-process operation is rejected (e.g. sandbox gate).
class BackgroundProcessException implements Exception {
  /// Creates a [BackgroundProcessException].
  const BackgroundProcessException(this.message);

  /// The reason.
  final String message;

  @override
  String toString() => 'BackgroundProcessException: $message';
}

class _ManagedProcess {
  _ManagedProcess({
    required this.id,
    required this.command,
    required this.cwd,
    required this.process,
    required this.startedAt,
    this.description,
  });

  final String id;
  final String command;
  final String cwd;
  final Process process;
  final DateTime startedAt;
  final String? description;

  BackgroundProcessStatus status = BackgroundProcessStatus.starting;
  bool ready = false;
  int? exitCode;
  final StringBuffer output = StringBuffer();
  RegExp? pattern;
  Timer? probeTimer;
  // Cancelled in BackgroundProcessManager._terminate (a different scope than
  // where they're assigned), so the lint's same-scope heuristic misfires.
  // ignore: cancel_subscriptions
  StreamSubscription<String>? stdoutSub;
  // ignore: cancel_subscriptions
  StreamSubscription<String>? stderrSub;

  BackgroundProcessInfo toInfo() => BackgroundProcessInfo(
    id: id,
    command: command,
    cwd: cwd,
    status: status,
    ready: ready,
    pid: process.pid,
    description: description,
    exitCode: exitCode,
    startedAt: startedAt,
  );
}

/// Starts and supervises long-running child processes (dev servers, watchers,
/// log tails) on behalf of an agent (PRD 01 feature 8).
///
/// * `start / list / status / logs / stop / restart` operations.
/// * Optional readiness probe (regex-on-output or TCP-port-accept).
/// * Output kept in a [maxOutputBytes] ring buffer.
/// * All processes auto-stopped on [dispose] (session exit) — no leaks.
/// * Sandbox-gated: `start`/`restart` throw while `sandboxed` returns true.
class BackgroundProcessManager {
  /// Creates a [BackgroundProcessManager].
  ///
  /// [sandboxed] is consulted on every `start`/`restart`; when it returns true
  /// those operations are refused (spawning escapes the sandbox). [runDir], when
  /// set, is the default working directory for spawned processes.
  BackgroundProcessManager({
    bool Function()? sandboxed,
    this.runDir,
    this.maxOutputBytes = 200 * 1024,
  }) : _sandboxed = sandboxed ?? (() => false);

  final bool Function() _sandboxed;

  /// Default working directory for spawned processes.
  final String? runDir;

  /// Ring-buffer cap for captured output.
  final int maxOutputBytes;

  final _processes = <String, _ManagedProcess>{};
  final _uuid = const Uuid();

  /// Snapshots of all known processes.
  List<BackgroundProcessInfo> list() =>
      _processes.values.map((p) => p.toInfo()).toList();

  /// Snapshot of one process, or null if unknown.
  BackgroundProcessInfo? status(String id) => _processes[id]?.toInfo();

  /// The captured output of [id], optionally only the last [tailLines] lines.
  String? logs(String id, {int? tailLines}) {
    final managed = _processes[id];
    if (managed == null) {
      return null;
    }
    final text = managed.output.toString();
    if (tailLines == null) {
      return text;
    }
    final lines = const LineSplitter().convert(text);
    final start = lines.length > tailLines ? lines.length - tailLines : 0;
    return lines.sublist(start).join('\n');
  }

  /// Starts a process running [command] (a shell command line). Resolves once
  /// the process is spawned; if [ready] is set, also waits for the probe (up to
  /// the probe timeout) before returning the snapshot.
  Future<BackgroundProcessInfo> start({
    required String command,
    String? cwd,
    String? description,
    ReadyProbe? ready,
  }) async {
    if (_sandboxed()) {
      throw const BackgroundProcessException(
        'background processes are unavailable while the sandbox is enabled',
      );
    }
    final workdir = cwd ?? runDir ?? Directory.current.path;
    final shell = Platform.isWindows ? 'cmd' : '/bin/sh';
    final shellArgs = Platform.isWindows
        ? ['/c', command]
        : ['-c', command];

    final Process process;
    try {
      process = await Process.start(
        shell,
        shellArgs,
        workingDirectory: workdir,
        environment: {'TERM': 'dumb'},
        includeParentEnvironment: true,
      );
    } on ProcessException catch (e) {
      throw BackgroundProcessException('failed to start: ${e.message}');
    }

    final managed = _ManagedProcess(
      id: 'bgp-${_uuid.v4()}',
      command: command,
      cwd: workdir,
      process: process,
      startedAt: DateTime.now(),
      description: description,
    );
    if (ready?.pattern != null) {
      managed.pattern = RegExp(ready!.pattern!);
    }
    managed.status = BackgroundProcessStatus.running;
    _processes[managed.id] = managed;

    final readyCompleter = Completer<void>();

    void appendOutput(String chunk) {
      managed.output.write(chunk);
      _clampOutput(managed);
      if (!managed.ready &&
          managed.pattern != null &&
          managed.pattern!.hasMatch(managed.output.toString())) {
        _markReady(managed, readyCompleter);
      }
    }

    managed.stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen(appendOutput, onError: (_) {});
    managed.stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(appendOutput, onError: (_) {});

    unawaited(
      process.exitCode.then((code) {
        managed
          ..exitCode = code
          ..status = code == 0
              ? BackgroundProcessStatus.exited
              : BackgroundProcessStatus.failed;
        managed.probeTimer?.cancel();
        if (!readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      }).catchError((_) {}),
    );

    if (ready != null) {
      managed.probeTimer = Timer(ready.timeout, () {
        if (!readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      });
      if (ready.port != null) {
        unawaited(_pollPort(managed, ready.port!, readyCompleter));
      }
      await readyCompleter.future;
    }
    return managed.toInfo();
  }

  Future<void> _pollPort(
    _ManagedProcess managed,
    int port,
    Completer<void> readyCompleter,
  ) async {
    while (!readyCompleter.isCompleted &&
        managed.status != BackgroundProcessStatus.exited &&
        managed.status != BackgroundProcessStatus.failed) {
      if (await _portAccepts(port)) {
        _markReady(managed, readyCompleter);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<bool> _portAccepts(int port) async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 500),
      );
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  void _markReady(_ManagedProcess managed, Completer<void> readyCompleter) {
    managed
      ..ready = true
      ..status = BackgroundProcessStatus.ready;
    managed.probeTimer?.cancel();
    if (!readyCompleter.isCompleted) {
      readyCompleter.complete();
    }
  }

  /// Stops process [id] (SIGTERM, then SIGKILL after a grace period), best-effort
  /// killing the descendant tree. Returns the final snapshot, or null if unknown.
  Future<BackgroundProcessInfo?> stop(String id) async {
    final managed = _processes[id];
    if (managed == null) {
      return null;
    }
    managed.status = BackgroundProcessStatus.stopping;
    await _terminate(managed);
    managed.status = BackgroundProcessStatus.stopped;
    return managed.toInfo();
  }

  /// Restarts process [id] with the same command/cwd/description.
  Future<BackgroundProcessInfo?> restart(String id, {ReadyProbe? ready}) async {
    final managed = _processes[id];
    if (managed == null) {
      return null;
    }
    if (_sandboxed()) {
      throw const BackgroundProcessException(
        'background processes are unavailable while the sandbox is enabled',
      );
    }
    await _terminate(managed);
    _processes.remove(id);
    return start(
      command: managed.command,
      cwd: managed.cwd,
      description: managed.description,
      ready: ready,
    );
  }

  Future<void> _terminate(_ManagedProcess managed) async {
    managed.probeTimer?.cancel();
    await managed.stdoutSub?.cancel();
    await managed.stderrSub?.cancel();
    final pid = managed.process.pid;
    // Best-effort: reap the direct child tree on POSIX before SIGTERM.
    if (!Platform.isWindows) {
      try {
        await Process.run('pkill', ['-TERM', '-P', '$pid']);
      } on Object {
        // pkill unavailable — fall through to the direct kill.
      }
    }
    managed.process.kill();
    try {
      await managed.process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      managed.process.kill(ProcessSignal.sigkill);
    }
  }

  void _clampOutput(_ManagedProcess managed) {
    if (managed.output.length <= maxOutputBytes) {
      return;
    }
    final text = managed.output.toString();
    final trimmed = text.substring(text.length - maxOutputBytes);
    managed.output
      ..clear()
      ..write(trimmed);
  }

  /// Stops and forgets every managed process. Call on session exit.
  Future<void> dispose() async {
    final all = _processes.values.toList();
    _processes.clear();
    await Future.wait(all.map(_terminate));
  }
}
