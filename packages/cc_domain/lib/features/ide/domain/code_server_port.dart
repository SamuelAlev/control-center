/// Platform-neutral control surface for server-hosted code-server (VS Code in
/// the browser) sessions.
///
/// code-server runs on the **server** (`cc_server`) — never on a client — bound
/// loopback only, opening the conversation's isolated copy-on-write worktree as
/// its folder. A connected client reaches it through the authenticated
/// `/proxy/vscode/<sessionId>/` reverse proxy; a loopback-local desktop/Linux
/// may hit `127.0.0.1:<port>` directly. The thin-client invariant holds: every
/// client talks to the same server.
///
/// Sessions are **WORKSPACE-SCOPED**: `ensureSession` records the owning
/// workspace, and the host validates ownership on every `closeSession` /
/// `lookup` before touching a session, so one workspace can never reach
/// another's code-server (the workspace-isolation invariant). The worktree is
/// resolved strictly from the caller's workspace; a foreign `channel_id` /
/// `repo_id` yields no worktree → no session.
library;

import 'package:cc_domain/features/ide/domain/code_server_session.dart';

/// Owns server-side code-server processes and exposes their lifecycle for the
/// `codeServer.*` RPC surface + the `/proxy/vscode/` reverse proxy.
abstract interface class CodeServerPort {
  /// Ensures a code-server session exists for `(workspaceId, channelId,
  /// repoId)` — reusing a running instance keyed by the conversation's
  /// worktree, or spawning one bound loopback on an ephemeral port with its
  /// `--folder` set to the worktree path.
  ///
  /// [deviceId] is the paired-device id of the minting client; the returned
  /// [CodeServerSession.sessionId] is a high-entropy capability bound to it.
  /// [path], when given, deep-links the file code-server opens first. Returns
  /// the live session (its `status` reports install/readiness). Throws on a
  /// cross-workspace mismatch or when the worktree cannot be resolved (never
  /// falls back to the raw checkout).
  ///
  /// [autoSave] is the client's editor auto-save preference — the VS Code
  /// `files.autoSave` value (`'off'`, `'afterDelay'`, `'onFocusChange'`,
  /// `'onWindowChange'`) — seeded into the session's `settings.json` so the
  /// embedded editor honours it. Defaults to `'afterDelay'`.
  Future<CodeServerSession> ensureSession({
    required String workspaceId,
    required String channelId,
    required String repoId,
    required String deviceId,
    String? path,
    String autoSave = 'afterDelay',
  });

  /// Releases one reference to [sessionId]; the host ref-counts shared
  /// instances and idle-GCs the process when the last reference closes.
  /// Idempotent. Throws on a cross-workspace mismatch.
  Future<void> closeSession({
    required String workspaceId,
    required String sessionId,
  });

  /// Looks up a live session by its capability [sessionId] — used by the
  /// `/proxy/vscode/` reverse proxy to authorize each request (unknown /
  /// expired / foreign-workspace → null → 403). Returns null when no such live,
  /// unexpired session exists.
  CodeServerSession? lookup(String sessionId);

  /// Streams "open this file as its own app tab" requests reported by the
  /// bundled bridge extension running inside the embedded editors, scoped to
  /// [workspaceId] (the isolation boundary). The client subscribes (further
  /// filtered to its conversation) and opens a fresh editor tab per request, so
  /// navigating the editor to another file spawns an app tab instead of silently
  /// swapping the file under the current tab.
  Stream<CodeServerOpenRequest> watchOpenRequests(String workspaceId);

  /// Records a bridge-extension report that a new file became active inside the
  /// code-server addressed by capability [sessionId]; validates the session and,
  /// when the file resolves inside its worktree, fans a [CodeServerOpenRequest]
  /// out on [watchOpenRequests]. An unknown/expired [sessionId] or an
  /// out-of-worktree [absPath] is ignored (never throws — it is called from the
  /// proxy's report endpoint). [line] is the best-effort go-to target.
  void reportOpen({
    required String sessionId,
    required String absPath,
    int? line,
  });

  /// Streams "this file's unsaved (dirty) state changed" reports from the bridge
  /// extension, scoped to [workspaceId] (the isolation boundary). The client
  /// subscribes (filtered to its conversation) and toggles the per-tab
  /// unsaved-changes dot.
  Stream<CodeServerDirtyEvent> watchDirtyState(String workspaceId);

  /// Records a bridge-extension report that the dirty state of [absPath] changed
  /// inside the code-server addressed by capability [sessionId]. Validates the
  /// session and, when the file resolves inside its worktree, fans a
  /// [CodeServerDirtyEvent] out on [watchDirtyState]. Unknown/expired
  /// [sessionId] or an out-of-worktree [absPath] is ignored (never throws — it
  /// is called from the proxy's report endpoint).
  void reportDirty({
    required String sessionId,
    required String absPath,
    required bool dirty,
  });

  /// Asks the embedded editor to save the (dirty) worktree-relative [path] to
  /// disk. Resolves the conversation's running code-server, pushes a `save`
  /// command onto its reverse [commandStream] (consumed by the bridge
  /// extension), and completes true once the extension acks by reporting the
  /// file clean (or false on timeout / no running session). Throws on a
  /// cross-workspace mismatch or unresolvable worktree.
  ///
  /// This is the ONLY way the app can persist code-server's in-memory edits —
  /// `cc_server` cannot see the unsaved buffer, so it must ask the editor.
  Future<bool> saveFile({
    required String workspaceId,
    required String channelId,
    required String repoId,
    required String path,
  });

  /// The reverse command stream for the session addressed by capability
  /// [sessionId] — a sequence of `{cmd, …}` maps (e.g. `{cmd:'save', path}`) the
  /// proxy relays to the bridge extension over the `/__cc_commands__` SSE
  /// endpoint. Empty (never emits) for an unknown/expired session.
  Stream<Map<String, Object?>> commandStream(String sessionId);
}
