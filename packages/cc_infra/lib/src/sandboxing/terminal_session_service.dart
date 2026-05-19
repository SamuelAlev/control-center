import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_natives/cc_natives.dart' show Pty;

/// Session-id prefix that keeps a terminal's sandbox session distinct from the
/// agent's sandbox session in the same conversation. Mirrors the desktop copy
/// in `lib/features/sandboxing/data/services/sandbox_terminal_pty.dart`; the two
/// stay in sync until the thin-client flip (Phase 5) deletes the desktop one.
const String terminalSandboxSessionPrefix = 'term-';

/// The sandbox profile a terminal session runs under. The terminal is the
/// user's playground (capability gating only applies to the agent dispatcher):
/// home is writable, secret paths (`~/.ssh`, `~/.aws`, …) are read-denied,
/// network is open. Kept identical to the desktop copy.
SandboxConfig terminalSandboxConfig({
  required String sessionId,
  required String cwd,
}) {
  final home = Platform.environment['HOME'] ?? '';
  return SandboxConfig(
    sessionId: '$terminalSandboxSessionPrefix$sessionId',
    network: const NetworkConfig(),
    filesystem: FilesystemConfig(
      denyRead: [
        if (home.isNotEmpty) ...[
          '$home/.ssh',
          '$home/.aws',
          '$home/.gnupg',
          '$home/.config/gh',
          '$home/Library/Keychains',
        ],
      ],
      allowWrite: [
        cwd,
        if (home.isNotEmpty) home,
        '/tmp',
      ],
    ),
    skipMandatoryHomeRcDenies: true,
  );
}

/// Boots an interactive terminal PTY (on `libccpty`) under the given [backend]:
///  * none   → host shell directly,
///  * native → `sandbox-exec`/`bwrap`-wrapped shell via [manager].
Future<Pty> _startTerminalPty({
  required SandboxManager manager,
  required SandboxBackend backend,
  required String sessionId,
  required String cwd,
  required int rows,
  required int cols,
  void Function(String notice)? onNotice,
}) async {
  if (backend == SandboxBackend.none) {
    return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
  }
  final shell = Platform.isMacOS ? '/bin/zsh' : '/bin/bash';
  final config = terminalSandboxConfig(sessionId: sessionId, cwd: cwd);
  try {
    final wrap = await manager.wrap(
      config: config,
      argv: [shell, '-il'],
      workingDirectory: cwd,
    );
    final env = <String, String>{
      if (Platform.environment['HOME'] != null)
        'HOME': Platform.environment['HOME']!,
      if (Platform.environment['PATH'] != null)
        'PATH': Platform.environment['PATH']!,
      if (Platform.environment['TERM'] != null)
        'TERM': Platform.environment['TERM']!,
      ...wrap.environment,
    };
    return Pty.start(
      wrap.executable,
      arguments: wrap.argv,
      environment: env,
      workingDirectory: cwd,
      rows: rows,
      columns: cols,
    );
  } on UnsupportedError catch (e) {
    onNotice?.call('[!] $e — running on the host without a sandbox.');
    return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
  }
}

Future<Pty> _startHostShellPty({
  required int rows,
  required int cols,
  required String cwd,
}) async {
  return Pty.start(
    Platform.isWindows ? 'cmd.exe' : '/bin/zsh',
    arguments: const ['-il'],
    workingDirectory: cwd,
    rows: rows,
    columns: cols,
  );
}

class _Session {
  _Session({
    required this.workspaceId,
    required this.sandboxSessionId,
    required this.pty,
  }) {
    _ptyOut = pty.output.listen(
      _output.add,
      onDone: () {
        if (!_output.isClosed) {
          unawaited(_output.close());
        }
      },
    );
  }

  final String workspaceId;
  final String sandboxSessionId;
  final Pty pty;

  final StreamController<List<int>> _output =
      StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _ptyOut;

  Stream<List<int>> get output => _output.stream;

  Future<void> dispose() async {
    await _ptyOut?.cancel();
    _ptyOut = null;
    try {
      pty.kill();
    } catch (_) {}
    if (!_output.isClosed) {
      await _output.close();
    }
  }
}

/// Pure-Dart [TerminalSessionPort] for the headless `cc_server`: owns `libccpty`
/// PTYs and exposes them over the `terminal.*` RPC ops so a connected web/thin
/// client runs a REAL terminal on the server host. The Flutter-free sibling of
/// the desktop `DesktopTerminalSessionPort` (which takes a Riverpod `Ref`); this
/// takes its deps directly so it links into the `dart build cli` binary.
///
/// Every [output]/[write]/[resize]/[kill] validates the session's owning
/// `workspaceId` before touching the PTY — a connected client physically cannot
/// drive another workspace's terminal (the workspace-isolation invariant).
class TerminalSessionService implements TerminalSessionPort {
  /// Creates the service over a [manager] (sandbox lifecycle), a [filesystem]
  /// (working-dir resolution) and a [defaultBackend] used when the client does
  /// not name one (the headless server defaults to the host shell).
  TerminalSessionService({
    required SandboxManager manager,
    required WorkspaceFilesystemPort filesystem,
    SandboxBackend defaultBackend = SandboxBackend.none,
  })  : _manager = manager,
        _fs = filesystem,
        _defaultBackend = defaultBackend;

  final SandboxManager _manager;
  final WorkspaceFilesystemPort _fs;
  final SandboxBackend _defaultBackend;

  final Map<String, _Session> _sessions = {};
  int _counter = 0;

  void _assertOwned(_Session? session, String workspaceId) {
    if (session != null && session.workspaceId != workspaceId) {
      // Deny loudly — never silently no-op (hides the bug) nor proceed (leaks).
      throw StateError('Terminal session belongs to a different workspace');
    }
  }

  @override
  Future<String> spawn({
    required String workspaceId,
    required int rows,
    required int cols,
    String? channelId,
    String? cwd,
    String? backend,
  }) async {
    final String workingDir;
    if (cwd != null && cwd.isNotEmpty) {
      workingDir = cwd;
    } else if (channelId != null && channelId.isNotEmpty) {
      workingDir = await _fs.ensureConversationDir(workspaceId, channelId);
    } else {
      await _fs.ensureWorkspaceDirs(workspaceId);
      workingDir = await _fs.workspaceDir(workspaceId);
    }

    final resolvedBackend = backend == null
        ? _defaultBackend
        : (SandboxBackend.values.asNameMap()[backend] ?? _defaultBackend);

    final sessionId = 'tty${++_counter}-${channelId ?? workspaceId}';
    final pty = await _startTerminalPty(
      manager: _manager,
      backend: resolvedBackend,
      sessionId: sessionId,
      cwd: workingDir,
      rows: rows,
      cols: cols,
    );
    _sessions[sessionId] = _Session(
      workspaceId: workspaceId,
      sandboxSessionId: '$terminalSandboxSessionPrefix$sessionId',
      pty: pty,
    );
    return sessionId;
  }

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String sessionId,
  }) {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Terminal session not found: $sessionId');
    }
    _assertOwned(session, workspaceId);
    return session.output;
  }

  @override
  Future<void> write({
    required String workspaceId,
    required String sessionId,
    required List<int> data,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    session?.pty.write(Uint8List.fromList(data));
  }

  @override
  Future<void> resize({
    required String workspaceId,
    required String sessionId,
    required int rows,
    required int cols,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    session?.pty.resize(rows, cols);
  }

  @override
  Future<void> kill({
    required String workspaceId,
    required String sessionId,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    if (session == null) {
      return;
    }
    _sessions.remove(sessionId);
    await session.dispose();
    try {
      await _manager.disposeSession(session.sandboxSessionId);
    } catch (_) {}
  }

  /// Tears down every live session (host shutdown).
  Future<void> disposeAll() async {
    final sessions = _sessions.values.toList();
    _sessions.clear();
    for (final s in sessions) {
      await s.dispose();
      try {
        await _manager.disposeSession(s.sandboxSessionId);
      } catch (_) {}
    }
  }
}
