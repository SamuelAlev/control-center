import 'dart:async';

import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';

/// Per-thread (DM/channel/conversation) sandbox handle registry.
///
/// One sandbox session per `sessionId` — typically the channel or
/// conversation id. Reused by:
///   * `SandboxedAgentDispatchAdapter` when launching an agent run
///   * `TerminalPanel` when the user runs ad-hoc commands in the drawer
///
/// Sharing the same handle means the agent and the user see the same
/// filesystem state — what the agent writes, the terminal can read.
class SandboxSessionManager {
  /// Creates a [SandboxSessionManager] backed by the given [sandbox] port.
  SandboxSessionManager(this._sandbox);

  final SandboxPort _sandbox;
  final Map<String, SandboxHandle> _handles = {};
  final Map<String, Future<SandboxHandle>> _inflight = {};

  /// Returns the existing handle for [sessionId] or launches a new sandbox
  /// using [spec]. Concurrent callers share the same in-flight launch.
  Future<SandboxHandle> ensure(String sessionId, SandboxSpec spec) async {
    final existing = _handles[sessionId];
    if (existing != null) {
      final alive = await _sandbox.isAlive(existing);
      if (alive) {
        return existing;
      }
    }
    final inflight = _inflight[sessionId];
    if (inflight != null) {
      return inflight;
    }
    final launch = _sandbox.launch(spec);
    _inflight[sessionId] = launch;
    try {
      final handle = await launch;
      _handles[sessionId] = handle;
      return handle;
    } finally {
      unawaited(_inflight.remove(sessionId));
    }
  }

  /// Reads the current handle for [sessionId] without launching one.
  SandboxHandle? peek(String sessionId) => _handles[sessionId];

  /// Tears down a single session.
  Future<void> destroy(String sessionId) async {
    final handle = _handles.remove(sessionId);
    if (handle != null) {
      await _sandbox.destroy(handle);
    }
  }

  /// Tears down every active session.
  Future<void> destroyAll() async {
    final ids = List<String>.from(_handles.keys);
    for (final id in ids) {
      await destroy(id);
    }
  }

  /// Returns the underlying sandbox port (so consumers can call `exec` /
  /// `events` directly against a handle).
  SandboxPort get sandbox => _sandbox;
}
