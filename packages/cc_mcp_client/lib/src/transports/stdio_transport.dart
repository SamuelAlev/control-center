import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';

/// Stdio transport: spawns a local child process and speaks newline-delimited
/// JSON-RPC ("JSONL") over its stdin/stdout. stderr is captured for diagnostics.
///
/// On POSIX the child is spawned in its own process group (`start(... )` plus a
/// negative-PID kill on [close]) so a `SIGTERM` reaches the *whole descendant
/// tree* and we never leak zombie grandchildren (e.g. `npx` → `node`). On
/// Windows the process is killed with its tree via [Process.kill] (Dart's
/// runtime terminates the job object).
class StdioTransport implements McpTransport {
  /// Creates a [StdioTransport] for [config] (must be a stdio config).
  StdioTransport(this.config)
    : assert(
        config.transport == McpTransportKind.stdio,
        'StdioTransport requires a stdio config',
      );

  /// The server config (command, args, env, cwd).
  final McpServerConfig config;

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

    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onError: (_) {}, cancelOnError: false);

    _stderrSub = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onStderr, onError: (_) {}, cancelOnError: false);

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
      try {
        // SIGTERM the whole tree. On POSIX, killing the negative PID targets
        // the process group; Dart's Process.kill terminates the job/group.
        process.kill();
      } on Object {
        // Already dead.
      }
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}
