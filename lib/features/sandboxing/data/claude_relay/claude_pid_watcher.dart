import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Parsed contents of Claude Code's per-process session file at
/// `~/.claude/sessions/{pid}.json`.
class PidFileData {
  /// Creates [PidFileData].
  const PidFileData({
    required this.pid,
    required this.sessionId,
    required this.cwd,
    required this.kind,
    this.status,
    this.waitingFor,
    this.updatedAt,
  });

  /// Claude process id.
  final int pid;

  /// Session id (used as the transcript filename).
  final String sessionId;

  /// Working directory of the session.
  final String cwd;

  /// Session kind.
  final String kind;

  /// `busy` / `idle` / `waiting` / `unknown`.
  final String? status;

  /// What Claude is waiting for, when [status] is `waiting`.
  final String? waitingFor;

  /// Last-updated epoch millis, if present.
  final int? updatedAt;

  /// Parses [PidFileData] from a decoded JSON map, or returns `null` if the
  /// shape is unusable.
  static PidFileData? fromJson(Map<String, Object?> json) {
    final pid = json['pid'];
    final sessionId = json['sessionId'];
    if (pid is! int && pid is! num) {
      return null;
    }
    if (sessionId is! String) {
      return null;
    }
    return PidFileData(
      pid: (pid as num).toInt(),
      sessionId: sessionId,
      cwd: (json['cwd'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? '',
      status: json['status'] as String?,
      waitingFor: json['waitingFor'] as String?,
      updatedAt: json['updatedAt'] is num
          ? (json['updatedAt'] as num).toInt()
          : null,
    );
  }
}

bool _isSafeSessionId(String sessionId) {
  // Session IDs are used as filenames under ~/.claude/projects.
  return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(sessionId) &&
      !sessionId.contains('..');
}

/// Polls Claude Code's per-process session file for status and session
/// metadata. This is the same mechanism `claude ps` uses — no custom hooks.
///
/// Dart port of the upstream relay's `PidWatcher` (src/pid-watcher.ts). The `homeDir`
/// argument can be overridden in tests to isolate filesystem state.
class ClaudePidWatcher {
  /// Creates a [ClaudePidWatcher] for [pid].
  ClaudePidWatcher(
    this.pid,
    this.onStatusChange, {
    String? homeDir,
    this.pollInterval = const Duration(milliseconds: 500),
  }) : _homeDir = homeDir ?? _defaultHome() {
    _pidFilePath = p.join(_homeDir, '.claude', 'sessions', '$pid.json');
  }

  /// The Claude process id being watched.
  final int pid;

  /// Invoked when the status or wait-state changes.
  final void Function(String status, String? waitingFor, PidFileData data)
      onStatusChange;

  /// How often the session file is polled.
  final Duration pollInterval;

  final String _homeDir;
  late final String _pidFilePath;

  Timer? _timer;
  String? _lastStatus;
  String? _lastWaitingFor;

  static String _defaultHome() {
    return Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
  }

  /// Starts polling immediately, then on [pollInterval].
  void start() {
    _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  /// Stops any active polling.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns the current session id from the PID file, if it is safe to use
  /// as a filename.
  String? getSessionId() {
    final sessionId = _readPidFile()?.sessionId;
    return sessionId != null && _isSafeSessionId(sessionId) ? sessionId : null;
  }

  void _poll() {
    final data = _readPidFile();
    if (data == null) {
      return;
    }
    final status = data.status ?? 'unknown';
    final waitingFor = data.waitingFor;
    if (status != _lastStatus || waitingFor != _lastWaitingFor) {
      _lastStatus = status;
      _lastWaitingFor = waitingFor;
      onStatusChange(status, waitingFor, data);
    }
  }

  PidFileData? _readPidFile() {
    try {
      final raw = File(_pidFilePath).readAsStringSync();
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return PidFileData.fromJson(decoded.cast<String, Object?>());
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
