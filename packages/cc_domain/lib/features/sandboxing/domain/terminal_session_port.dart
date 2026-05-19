/// Platform-neutral control surface for server-hosted interactive terminal
/// sessions (a PTY running a shell inside the agent's sandbox).
///
/// On the desktop this is backed by an in-process implementation that owns
/// `flutter_pty` + the sandbox manager (the same stack the desktop terminal
/// panel used to drive directly); on the web / thin client the panel drives the
/// SERVER's sessions over the `terminal.*` RPC ops + the `terminal.output`
/// subscription. A PTY physically cannot run in a browser, so a web client only
/// has a real terminal when the connected server hosts these ops; a pure-Dart
/// headless server (which does not link `flutter_pty`) leaves the port null, the
/// ops are absent and the web panel renders an honest "terminal runs on the
/// server host" placeholder.
///
/// Sessions are WORKSPACE-SCOPED: `spawn` records the owning workspace and the
/// host validates ownership on every `output`/`write`/`resize`/`kill` before
/// touching a session, so one workspace can never read or drive another's
/// terminal (the workspace-isolation invariant).
library;

/// Owns server-side PTY terminal sessions and exposes their lifecycle for the
/// `terminal.*` RPC surface.
abstract interface class TerminalSessionPort {
  /// Spawns a new sandboxed shell PTY for [workspaceId] and returns its opaque
  /// session id. [channelId] (when given) scopes the on-disk working directory
  /// to the conversation; [cwd] overrides the resolved directory; [backend]
  /// (a `SandboxBackend` name) pins the sandbox backend, defaulting to the
  /// host's active backend. [rows]/[cols] set the initial PTY size.
  Future<String> spawn({
    required String workspaceId,
    required int rows,
    required int cols,
    String? channelId,
    String? cwd,
    String? backend,
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
  Future<void> write({
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
