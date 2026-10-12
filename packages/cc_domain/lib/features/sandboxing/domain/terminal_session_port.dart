/// Platform-neutral control surface for server-hosted interactive terminal
/// sessions (a PTY running a shell inside the agent's sandbox).
/// The pure-Dart server owns the native PTY through `cc_natives` and the sandbox
/// manager. Desktop and web clients drive those sessions through the
/// `terminal.*` RPC ops and `terminal.output` subscription; clients never spawn
/// a PTY themselves.
/// Sessions are WORKSPACE-SCOPED: `spawn` records the owning workspace and the
/// host validates ownership on every `output`/`write`/`resize`/`kill` before
/// touching a session, so one workspace can never read or drive another's
/// terminal (the workspace-isolation invariant).
library;

import 'package:cc_domain/features/sandboxing/domain/terminal_command_buffer.dart';

/// Owns server-side PTY terminal sessions and exposes their lifecycle for the
/// `terminal.*` RPC surface.
abstract interface class TerminalSessionPort {
  /// Spawns a new sandboxed shell PTY for [workspaceId] and returns its opaque
  /// session id. [spaceId] (when given) scopes the on-disk working directory
  /// to the conversation; [cwd] overrides the resolved directory; [backend]
  /// (a `SandboxBackend` name) pins the sandbox backend, defaulting to the
  /// host's active backend. [rows]/[cols] set the initial PTY size.
  Future<String> spawn({
    required String workspaceId,
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
    String? actingUserId,
  });

  /// The raw PTY output byte stream for [sessionId], owned by [workspaceId].
  /// The stream closes when the shell process exits. Throws if the session does
  /// not exist or belongs to another workspace.
  Stream<List<int>> output({
    required String workspaceId,
    required String sessionId,
  });

  /// The session's foreground-process title stream: the name of the command
  /// currently running in [sessionId]'s PTY (`'pnpm dev serve'`), or `''` when
  /// the shell sits at its prompt. Emits the current title immediately on
  /// listen, then on every foreground change — the ghostty/VS Code fallback
  /// for shells that never retitle via OSC 0/2. Hosts that cannot inspect the
  /// PTY's foreground process emit nothing. Throws if the session does not
  /// exist or belongs to another workspace.
  Stream<String> titles({
    required String workspaceId,
    required String sessionId,
  });

  /// Writes [data] (already-decoded bytes) to [sessionId]'s PTY stdin. A no-op
  /// when the session is gone. Throws on a cross-workspace mismatch.
  ///
  /// The result says whether this chunk *submitted* a command (Enter). Typing
  /// without sending does nothing the audit trail should record; the
  /// reconstructed line rides on [TerminalWriteResult.command] so the trail
  /// can name what ran rather than the bare carriage return.
  Future<TerminalWriteResult> write({
    required String workspaceId,
    required String sessionId,
    required List<int> data,
  });

  /// Resizes [sessionId]'s PTY to [rows]×[cols]. A no-op when the session is
  /// gone. Throws on a cross-workspace mismatch.
  Future<void> resize({
    required String workspaceId,
    required String sessionId,
    required int rows,
    required int cols,
  });

  /// Kills [sessionId]'s shell and releases its sandbox resources. Idempotent.
  /// Throws on a cross-workspace mismatch.
  Future<void> kill({required String workspaceId, required String sessionId});

  /// The `SandboxBackend` name [sessionId] actually runs under, or null when
  /// the session is unknown.
  ///
  /// The client shows this as a badge. It matters because the backend a
  /// session ASKED for and the one it GOT can differ (an unspecified default
  /// can step down when a host has no rig service), and a terminal that says
  /// "enclosed VM" while running on the host would be the worst possible
  /// label.
  String? backendOf(String sessionId);
}
