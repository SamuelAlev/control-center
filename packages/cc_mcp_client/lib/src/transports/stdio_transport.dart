import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/process/terminate_process_tree.dart';
import 'package:cc_mcp_client/src/transports/bounded_lines.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';

/// Stdio transport: spawns a local child process and speaks newline-delimited
/// JSON-RPC ("JSONL") over its stdin/stdout. stderr is captured for diagnostics.
///
/// [close] tears the child down through [terminateProcessTree]: reap the
/// descendants, SIGTERM, 3s grace, SIGKILL. That ladder is load-bearing here —
/// an `npx`-style wrapper exits on SIGTERM and would otherwise orphan its
/// `node` grandchild (holding the pipe and any port it bound), and a child that
/// ignores SIGTERM would survive `close()` entirely.
///
/// (This doc used to claim the child was spawned in its own process group and
/// killed by negative PID. It never was: `Process.start` has no process-group
/// option and `Process.kill` cannot target a negative pid — the implementation
/// was a single bare SIGTERM to the direct child.)
class StdioTransport implements McpTransport {
  /// Creates a [StdioTransport] for [config] (must be a stdio config).
  StdioTransport(this.config) {
    // Thrown, not asserted: `assert` is stripped in release, so in the shipped
    // server binary a misrouted config would have started a subprocess and
    // spoken the wrong protocol at it.
    if (config.transport != McpTransportKind.stdio) {
      throw ArgumentError('StdioTransport requires a stdio config');
    }
  }

  /// The server config (command, args, env, cwd).
  final McpServerConfig config;

  /// Cap on one unterminated JSONL line (1 MiB). A frame bigger than this is
  /// not a frame this client can use — it is a runaway writer.
  static const int _maxLineChars = 1 << 20;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _done = Completer<void>();
  final _stderrTail = <String>[];
  bool _closed = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Future<void> get done => _done.future;

  /// The last few stderr lines, for surfacing why a server failed to start.
  String get stderrTail => _stderrTail.join('\n');

  @override
  Future<void> start() async {
    final command = config.command;
    if (command == null || command.trim().isEmpty) {
      throw const McpTransportException('stdio server has no command');
    }
    final environment = <String, String>{...config.env};
    try {
      _process = await Process.start(
        command,
        config.args,
        workingDirectory: config.cwd,
        environment: environment.isEmpty ? null : environment,
        // POSIX: own process group so a tree-kill reaches grandchildren.
        // Windows: Dart kills the job object, so no flag is needed.
        runInShell: false,
      );
    } on ProcessException catch (e) {
      throw McpTransportException(
        'failed to spawn "$command": ${e.message}',
        cause: e,
      );
    }

    // Bounded, malformed-tolerant line splitting: a server that never emits a
    // newline must not grow the client's heap without limit, and one bad byte
    // must not kill the stream (see `boundedLines`).
    _stdoutSub = boundedLines(
      _process!.stdout,
      onOverflow: (chars) =>
          _onStderr('[transport] dropped an oversized stdout line ($chars '
              'chars, cap $_maxLineChars)'),
    ).listen(_onLine, onError: (_) {}, cancelOnError: false);

    _stderrSub = boundedLines(
      _process!.stderr,
    ).listen(_onStderr, onError: (_) {}, cancelOnError: false);

    // The process exiting is a hard close.
    unawaited(
      _process!.exitCode.then((_) => _handleClose()).catchError((_) {}),
    );
  }

  void _onLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        _incoming.add(decoded);
      }
    } on FormatException {
      // Non-JSON line on stdout (some servers log to stdout). Ignore.
    }
  }

  void _onStderr(String line) {
    _stderrTail.add(line);
    if (_stderrTail.length > 50) {
      _stderrTail.removeAt(0);
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final process = _process;
    if (process == null || _closed) {
      throw const McpTransportException('stdio transport is not open');
    }
    final frame = jsonEncode(message);
    try {
      process.stdin.add(utf8.encode('$frame\n'));
      await process.stdin.flush();
    } on Object catch (e) {
      // Broken pipe — the child died between our liveness check and the write.
      throw McpTransportException('stdio write failed', cause: e);
    }
  }

  void _handleClose() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final process = _process;
    _process = null;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    if (process != null) {
      await terminateProcessTree(process);
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}
