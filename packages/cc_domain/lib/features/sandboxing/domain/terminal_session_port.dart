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
  ///
  /// A session with an owner (see [OwnedTerminalSessionPort]) is left running:
  /// this is what closing a tab sends, and closing the tab of a supervised
  /// process must not stop it.
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

/// A session started through [OwnedTerminalSessionPort.spawnOwned].
class OwnedTerminalSession {
  /// Creates an [OwnedTerminalSession].
  const OwnedTerminalSession({
    required this.sessionId,
    required this.pid,
    required this.exitCode,
  });

  /// Opaque session id, usable with every [TerminalSessionPort] call.
  final String sessionId;

  /// The OS pid of the command. A PTY child leads its own session, so this is
  /// also its process group.
  final int pid;

  /// Completes when the command exits: its code, or `-signal` if killed.
  final Future<int> exitCode;
}

/// Terminal sessions that belong to a server-side owner rather than a tab.
///
/// The owner tag (`environment:<id>/<component>`) makes the session run a given
/// command instead of the login shell and survive its tab: only [killOwned],
/// holding the same tag, ends it. Tabs can still open, read and type into it
/// through [TerminalSessionPort].
abstract interface class OwnedTerminalSessionPort {
  /// Runs [executable] in a new PTY owned by [owner], on the host.
  ///
  /// [onOutput] sees every byte from the first one, which a subscriber to
  /// [TerminalSessionPort.output] can't promise.
  Future<OwnedTerminalSession> spawnOwned({
    required String workspaceId,
    required String owner,
    required String executable,
    required String cwd,
    List<String> arguments = const [],
    Map<String, String> environment = const {},
    String? spaceId,
    int rows = 30,
    int cols = 120,
    void Function(List<int> bytes)? onOutput,
  });

  /// Ends [sessionId]. Throws on a workspace or owner mismatch. Idempotent.
  Future<void> killOwned({
    required String workspaceId,
    required String sessionId,
    required String owner,
  });

  /// The owner of [sessionId], or null for an unowned or unknown session.
  String? ownerOf(String sessionId);

  /// The live sessions of [workspaceId] whose owner starts with [ownerPrefix].
  List<String> sessionsOwnedBy({
    required String workspaceId,
    required String ownerPrefix,
  });
}
