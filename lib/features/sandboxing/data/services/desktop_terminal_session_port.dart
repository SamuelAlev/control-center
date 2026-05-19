import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:control_center/di/server_providers.dart'
    show workspaceFilesystemPortProvider;
import 'package:control_center/features/sandboxing/data/services/sandbox_terminal_pty.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers_server.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One live server-side terminal session: a `flutter_pty` shell whose output is
/// fanned out to any number of RPC subscribers via a broadcast controller, plus
/// the owning workspace + sandbox session id for cleanup and isolation checks.
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

  /// The PTY output byte stream (broadcast — many RPC subscribers can attach).
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

/// Desktop-backed [TerminalSessionPort]: owns the in-process `flutter_pty` PTYs
/// the same way the local terminal panel does, exposed over RPC so a connected
/// web / thin client can run a REAL terminal on this host.
///
/// Sessions live in [_sessions] keyed by an opaque id; each carries its owning
/// `workspaceId`, so every [output]/[write]/[resize]/[kill] validates ownership
/// before touching the PTY — a connected client physically cannot drive another
/// workspace's terminal (the workspace-isolation invariant). The desktop wires
/// this at the in-process-host call site; a pure-Dart headless server (no
/// `flutter_pty`) leaves the port null and the `terminal.*` ops are absent.
///
/// The control plane is server-side only: it reads the same providers the
/// in-process RPC host uses (`sandboxManagerProvider`,
/// `activeSandboxBackendProvider`, `workspaceFilesystemPortProvider`), so it
/// never touches an RPC-flipped public provider and stays out of the rpcClient
/// cycle.
class DesktopTerminalSessionPort implements TerminalSessionPort {
  /// Creates a port over the given [ref].
  DesktopTerminalSessionPort(this._ref);

  final Ref _ref;

  final Map<String, _Session> _sessions = {};
  int _counter = 0;

  SandboxManager get _manager => _ref.read(sandboxManagerProvider);
  WorkspaceFilesystemPort get _fs => _ref.read(workspaceFilesystemPortProvider);

  void _assertOwned(_Session? session, String workspaceId) {
    if (session != null && session.workspaceId != workspaceId) {
      // Deny loudly — never silently no-op (hides the bug) nor proceed (leaks).
      throw const WorkspaceMismatchException(
        'Terminal session belongs to a different workspace',
      );
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
    // Resolve the working directory: an explicit override, else the
    // conversation dir (scoped by channel), else the workspace dir.
    final String workingDir;
    if (cwd != null && cwd.isNotEmpty) {
      workingDir = cwd;
    } else if (channelId != null && channelId.isNotEmpty) {
      workingDir = await _fs.ensureConversationDir(workspaceId, channelId);
    } else {
      await _fs.ensureWorkspaceDirs(workspaceId);
      workingDir = await _fs.workspaceDir(workspaceId);
    }

    final active = _ref.read(activeSandboxBackendProvider);
    final resolvedBackend = backend == null
        ? active
        : (SandboxBackend.values.asNameMap()[backend] ?? active);

    final sessionId = 'tty${++_counter}-${channelId ?? workspaceId}';
    final pty = await startSandboxTerminalPty(
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
    // Resolve ownership eagerly (throws on a foreign session) so the
    // subscription surfaces the error immediately rather than streaming.
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
    // A late write to an exited session is a harmless no-op.
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
    // Drop the per-session sandbox bridge files / Seatbelt profiles too.
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
