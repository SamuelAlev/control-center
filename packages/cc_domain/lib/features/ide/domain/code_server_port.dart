/// Platform-neutral control surface for server-hosted code-server (VS Code in
/// the browser) sessions.
/// code-server runs on the **server** (`cc_server`), bound to loopback and
/// opening the conversation's isolated copy-on-write worktree as its folder.
/// A client reaches code-server only through its authenticated encrypted
/// resource tunnel and a device-bound proxy capability. The shared process has
/// a separate internal bridge id for extension-host reports and commands.
/// Sessions remain workspace-scoped: foreign conversation worktrees are never
/// resolved from another workspace's identifiers.
library;

import 'package:cc_domain/features/ide/domain/code_server_session.dart';

/// Owns server-side code-server processes and exposes their lifecycle for the
/// `codeServer.*` RPC surface + the `/proxy/vscode/` reverse proxy.
abstract interface class CodeServerPort {
  /// Ensures a code-server session exists for `(workspaceId, spaceId,
  /// repoId)` — reusing a running instance keyed by the conversation's
  /// worktree, or spawning one bound loopback on an ephemeral port with its
  /// `--folder` set to the worktree path.
  /// [deviceId] is the paired-device id of the minting client; the returned
  /// [CodeServerSession.sessionId] is a high-entropy capability bound to it.
  /// [path], when given, deep-links the file code-server opens first. Returns
  /// the live session (its `status` reports install/readiness). Throws on a
  /// cross-workspace mismatch or when the worktree cannot be resolved (never
  /// falls back to the raw checkout).
  /// [autoSave] is the client's editor auto-save preference — the VS Code
  /// `files.autoSave` value (`'off'`, `'afterDelay'`, `'onFocusChange'`,
  /// `'onWindowChange'`) — seeded into the session's `settings.json` so the
  /// embedded editor honours it. Defaults to `'afterDelay'`.
  Future<CodeServerSession> ensureSession({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String deviceId,
    String? path,
    String autoSave = 'afterDelay',
  });

  /// Releases one device-owned reference to [sessionId]. Closing the last
  /// reference revokes that device's capability but does not terminate a shared
  /// process while another device still has live references. Idempotent for an
  /// already-closed capability; rejects a live capability owned by another
  /// device or workspace.
  Future<void> closeSession({
    required String workspaceId,
    required String sessionId,
    required String deviceId,
  });

  /// Resolves a live public capability to the owning device and shared process.
  /// Unknown, closed and expired bindings return null. The proxy must compare
  /// [CodeServerSession.deviceId] against its authenticated device on every
  /// request; neither the process id nor the extension bridge id is a client
  /// proxy capability.
  CodeServerSession? lookup(String sessionId);

  /// True only for a live process addressed by its server-only bridge id with
  /// at least one unexpired client binding. The private loopback listener calls
  /// this before accepting extension reports and reverse command SSE.
  bool lookupBridge(String instanceId);

  /// Streams "open this file as its own app tab" requests reported by the
  /// bundled bridge extension running inside the embedded editors, scoped to
  /// [workspaceId] (the isolation boundary). The client subscribes (further
  /// filtered to its conversation) and opens a fresh editor tab per request, so
  /// navigating the editor to another file spawns an app tab instead of silently
  /// swapping the file under the current tab.
  Stream<CodeServerOpenRequest> watchOpenRequests(String workspaceId);

  /// Records a server-side bridge-extension report addressed by the internal
  /// process id [sessionId]. Private loopback authorization is mandatory before
  /// invocation. Out-of-worktree paths and dead instances are ignored. [line]
  /// is the best-effort go-to target; [windowId] is the reporting window's
  /// bridge id, passed through to the client.
  void reportOpen({
    required String sessionId,
    required String absPath,
    int? line,
    String? windowId,
  });

  /// Streams "this file's unsaved (dirty) state changed" reports from the bridge
  /// extension, scoped to [workspaceId] (the isolation boundary). The client
  /// subscribes (filtered to its conversation) and toggles the per-tab
  /// unsaved-changes dot.
  Stream<CodeServerDirtyEvent> watchDirtyState(String workspaceId);

  /// Records the extension's dirty-state report for [absPath] via its internal
  /// process id [sessionId]. The private listener authorizes this id before
  /// invocation; dead instances and out-of-worktree paths are ignored.
  void reportDirty({
    required String sessionId,
    required String absPath,
    required bool dirty,
  });

  /// Asks the embedded editor to save the (dirty) worktree-relative [path] to
  /// disk. Resolves the conversation's running code-server, pushes a `save`
  /// command onto its reverse [commandStream] (consumed by the bridge
  /// extension) and completes true once the extension acks by reporting the
  /// file clean (or false on timeout / no running session). Throws on a
  /// cross-workspace mismatch or unresolvable worktree.
  ///
  /// This is the ONLY way the app can persist code-server's in-memory edits —
  /// `cc_server` cannot see the unsaved buffer, so it must ask the editor.
  Future<bool> saveFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String path,
  });

  /// Asks the embedded editor window [windowId] (its bridge id) to show the
  /// worktree-relative [path], revealing the 1-based [line] when given. One
  /// window serves every app tab of a worktree, so switching tabs switches the
  /// file it shows instead of booting a window per tab. Pushes an `open`
  /// command onto the running code-server's [commandStream]; only the bridge
  /// with that id acts on it. Returns false when no code-server is running for
  /// the worktree or [path] escapes it. Throws on a cross-workspace mismatch.
  Future<bool> openFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String windowId,
    required String path,
    int? line,
  });

  /// Closes the worktree-relative [path] in every editor window of the
  /// worktree, after its app tab closed. With [revert] the unsaved buffer is
  /// discarded first (the close prompt's "Don't save"); without it a dirty
  /// buffer is left open rather than lost. Returns false when no code-server
  /// is running for the worktree or [path] escapes it. Throws on a
  /// cross-workspace mismatch.
  Future<bool> closeFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String path,
    bool revert = false,
  });

  /// Reverse command stream for an internal process id [sessionId], served
  /// only on the private listener's `/__cc_commands__` SSE endpoint. Empty for
  /// an unknown or unreferenced process.
  Stream<Map<String, Object?>> commandStream(String sessionId);
}
