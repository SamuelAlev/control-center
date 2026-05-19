/// A live, server-hosted code-server (VS Code in the browser) process opened
/// against one conversation's isolated copy-on-write worktree.
///
/// code-server runs **on the server** (`cc_server`) — never on a client — and
/// binds loopback only. A client reaches it through the authenticated
/// `/proxy/vscode/<sessionId>/` reverse proxy (the thin-client invariant), or —
/// on a loopback-local desktop/Linux — directly on `127.0.0.1:<port>`.
///
/// [sessionId] is a **capability**: it is minted only over the PSK-authenticated
/// RPC socket (`codeServer.open`), bound server-side to `(workspaceId,
/// deviceId)` with a TTL, and handed only to the authorized client. The reverse
/// proxy re-checks ownership on every request and rejects unknown / expired /
/// foreign sessions with 403 (loud deny). It must be high-entropy and
/// unguessable; never derived from public inputs.
class CodeServerSession {
  /// Creates a [CodeServerSession].
  const CodeServerSession({
    required this.sessionId,
    required this.workspaceId,
    required this.port,
    required this.folderPath,
    required this.deviceId,
    required this.expiresAt,
    required this.status,
  });

  /// High-entropy, unguessable capability token. Authorizes the holder to reach
  /// this session's code-server through `/proxy/vscode/<sessionId>/`. Serves as
  /// the map key in the host's session table.
  final String sessionId;

  /// The owning workspace (never null — the isolation boundary). Every proxy
  /// request re-checks this against the connected device's bound workspace.
  final String workspaceId;

  /// The ephemeral loopback TCP port code-server bound (`127.0.0.1:<port>`).
  /// Parsed from code-server's startup stdout.
  final int port;

  /// The absolute path of the conversation's isolated CoW worktree code-server
  /// opened as its `--folder` (so user edits land beside agent edits).
  final String folderPath;

  /// The paired-device id of the client that minted this session. The proxy
  /// re-checks that an incoming request's connected device matches this (or its
  /// workspace), so a capability leaked to a foreign device still cannot proxy.
  final String deviceId;

  /// When this session's capability expires. The proxy rejects requests for an
  /// expired session with 403; the host reaps it on the idle-GC sweep.
  final DateTime expiresAt;

  /// Host-side readiness, so the client can render the right surface
  /// (spinner while installing, guidance card when unavailable).
  final CodeServerStatus status;
}

/// A "open this file as its own app tab" request that originated INSIDE the
/// embedded editor. The bundled bridge extension (running in code-server's
/// server-side extension host) detects when the user navigates the editor to a
/// different file (a cmd-click "go to definition", an Explorer open, …), reports
/// it to `cc_server`, and pins the editor window back on its entry file — so the
/// app shell owns the tabs instead of the embedded editor silently swapping the
/// file under a now-stale app-tab title.
///
/// [path] is RELATIVE to the conversation worktree (the same shape the Explorer
/// file-click uses), so the client can open a fresh code-server tab for it with
/// the workspace's existing `(channelId, repoId)` context.
class CodeServerOpenRequest {
  /// Creates a [CodeServerOpenRequest].
  const CodeServerOpenRequest({
    required this.workspaceId,
    required this.channelId,
    required this.repoId,
    required this.path,
    this.line,
  });

  /// The owning workspace (the isolation boundary — the watch stream filters on
  /// it so a client only ever sees its own workspace's requests).
  final String workspaceId;

  /// The conversation whose worktree the editor is open on. The client scopes
  /// its subscription to this so the request lands in the right IDE surface.
  final String channelId;

  /// The repo whose worktree hosts the file (may be empty when the session was
  /// opened letting the server pick the conversation's first linked worktree).
  final String repoId;

  /// The file to open, RELATIVE to the worktree root.
  final String path;

  /// The 0-based line the editor was navigated to (a go-to-definition target),
  /// or null when unknown. Best-effort — the client may ignore it.
  final int? line;
}

/// A "this file's unsaved (dirty) state changed" report that originated INSIDE
/// the embedded editor. The bundled bridge extension watches the code-server
/// workspace's text documents and reports each dirty↔clean transition to
/// `cc_server`, which fans it out on `CodeServerPort.watchDirtyState` so the app
/// shell can render (or clear) the per-tab unsaved-changes dot — code-server
/// owns the buffer, so the app can only learn its dirty state by being told.
///
/// [path] is RELATIVE to the conversation worktree (matching
/// [CodeServerOpenRequest.path]) so the client can key it to the right app tab.
class CodeServerDirtyEvent {
  /// Creates a [CodeServerDirtyEvent].
  const CodeServerDirtyEvent({
    required this.workspaceId,
    required this.channelId,
    required this.repoId,
    required this.path,
    required this.dirty,
  });

  /// The owning workspace (the isolation boundary — the watch stream filters on
  /// it so a client only ever sees its own workspace's reports).
  final String workspaceId;

  /// The conversation whose worktree the editor is open on. The client scopes
  /// its subscription to this so the report lands in the right IDE surface.
  final String channelId;

  /// The repo whose worktree hosts the file (may be empty when the session was
  /// opened letting the server pick the conversation's first linked worktree).
  final String repoId;

  /// The file whose dirty state changed, RELATIVE to the worktree root.
  final String path;

  /// True when the file now has unsaved changes; false when it became clean
  /// (saved / reverted / closed without changes).
  final bool dirty;
}

/// Host-side readiness of a code-server install, surfaced to the client so it
/// can show the right UI (spinner vs guidance card vs the editor).
enum CodeServerStatus {
  /// code-server is installed and a session was spawned successfully.
  ready,

  /// code-server is being downloaded / installed; retry shortly.
  installing,

  /// code-server could not be found or installed on this host; the client
  /// should show guidance (install instructions) rather than spin forever.
  unavailable,
}
