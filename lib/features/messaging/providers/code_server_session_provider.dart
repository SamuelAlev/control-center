import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/providers/editor_preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolved code-server session for one conversation worktree, fetched from the
/// connected `cc_server` via the `codeServer.open` op. The server spawns (or
/// reuses) a loopback-bound code-server on the conversation's isolated CoW
/// worktree and returns an app-relative proxy URL plus its readiness.
///
/// `workspace_id` is NOT passed — the host binds the authoritative workspace
/// per session and validates session ownership server-side, so a client can
/// never touch another workspace's code-server. When the connected server does
/// NOT host these ops (no code-server capability wired), `build` throws a
/// [RemoteRpcException] with code `RpcErrorCodes.opUnknown`; the pane catches
/// it and renders an honest "code-server is unavailable on this server" card.
class CodeServerSessionRequest {
  /// Creates a [CodeServerSessionRequest].
  const CodeServerSessionRequest({
    required this.channelId,
    this.repoId,
    this.path,
    this.line,
  });

  /// The conversation whose isolated worktree code-server should open.
  final String channelId;

  /// The repo whose worktree to open (the conversation may hold several). Null
  /// lets the server pick the first linked worktree for the conversation.
  final String? repoId;

  /// Optional file to deep-link open first inside code-server.
  final String? path;

  /// Optional 1-based line to reveal in the deep-linked file (best-effort).
  final int? line;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeServerSessionRequest &&
          channelId == other.channelId &&
          repoId == other.repoId &&
          path == other.path &&
          line == other.line;

  @override
  int get hashCode => Object.hash(channelId, repoId, path, line);
}

/// The resolved code-server handle: the app-relative proxy URL, the loopback
/// direct URL (for an external-browser open on Linux) and readiness.
@immutable
class CodeServerSessionResult {
  /// Creates a [CodeServerSessionResult].
  const CodeServerSessionResult({
    required this.sessionId,
    required this.url,
    required this.directUrl,
    required this.status,
  });

  /// The capability token authorizing `/proxy/vscode/<sessionId>/`.
  final String sessionId;

  /// App-relative proxy URL (`/proxy/vscode/<sid>/`) — embeds inline on every
  /// tier; same-origin to the web bundle and to the desktop-served bundle.
  final String url;

  /// The loopback direct URL (`http://127.0.0.1:<port>/`) — for an
  /// external-browser open where a native webview is unavailable (Linux).
  final String directUrl;

  /// Server-side readiness (spinner while installing, card when unavailable).
  final CodeServerStatus status;
}

/// Resolves a code-server session for the given request over the connected server.
///
/// Falls back to [CodeServerStatus.unavailable] when the op is unknown (the
/// host doesn't run code-server) so the pane can render guidance instead of an
/// error trace.
final codeServerSessionProvider = FutureProvider.autoDispose
    .family<CodeServerSessionResult, CodeServerSessionRequest>((
      ref,
      request,
    ) async {
      final client = ref.watch(rpcClientProvider);
      // Push the editor auto-save preference on every open. Read (not watch): a
      // preference change must NOT re-resolve — and thus flash/reload — an already
      // open editor. The change still takes effect the next time any editor tab
      // opens, because the server rewrites settings.json on every open (reuse path
      // included) and VS Code hot-reloads it for the whole worktree's windows.
      final autoSave = ref.read(editorAutoSaveModeProvider).wireValue;
      final data = await client.call('codeServer.open', {
        'channel_id': request.channelId,
        if (request.repoId != null) 'repo_id': request.repoId!,
        if (request.path != null) 'path': request.path!,
        if (request.line != null && request.line! > 0) 'line': request.line!,
        'auto_save': autoSave,
      });
      final statusName = data['status'] as String? ?? 'ready';
      CodeServerStatus status;
      switch (statusName) {
        case 'installing':
          status = CodeServerStatus.installing;
          break;
        case 'unavailable':
          status = CodeServerStatus.unavailable;
          break;
        default:
          status = CodeServerStatus.ready;
      }
      return CodeServerSessionResult(
        sessionId: data['session_id'] as String? ?? '',
        url: data['url'] as String? ?? '',
        directUrl: data['direct_url'] as String? ?? '',
        status: status,
      );
    });

/// A server-pushed "open this file as a new app tab" request originating INSIDE
/// the embedded editor (the bundled bridge extension reports a file the user
/// navigated to). Carries a worktree-relative [path] and the `(repoId)` context.
@immutable
class CodeServerOpenEvent {
  /// Creates a [CodeServerOpenEvent].
  const CodeServerOpenEvent({
    required this.repoId,
    required this.path,
    this.line,
  });

  /// The repo whose worktree hosts the file (may be empty → server picks first).
  final String repoId;

  /// The file to open, RELATIVE to the worktree root.
  final String path;

  /// Best-effort 0-based go-to line, or null.
  final int? line;
}

/// Streams the embedded editor's in-editor open-file requests for the given
/// channel id (reported by the bridge extension via `codeServer.watchOpenRequests`). The
/// IDE layout listens and opens a fresh code-server tab per event, so navigating
/// the editor spawns an app tab instead of swapping the current tab's file.
///
/// On a server that doesn't host the op (no code-server), the subscription
/// errors — the layout's listener simply ignores the error state.
final codeServerOpenRequestsProvider = StreamProvider.autoDispose
    .family<CodeServerOpenEvent, String>((ref, channelId) {
      final client = ref.watch(rpcClientProvider);
      return client
          .subscribe('codeServer.watchOpenRequests', {'channel_id': channelId})
          .map(
            (m) => CodeServerOpenEvent(
              repoId: m['repo_id'] as String? ?? '',
              path: m['path'] as String? ?? '',
              line: (m['line'] as num?)?.toInt(),
            ),
          );
    });

/// A server-pushed "this file's unsaved (dirty) state changed" event from the
/// embedded editor's bridge extension. The IDE layout keys it to the matching
/// app tab (by `(repoId, path)`) to show/hide the unsaved-changes dot.
@immutable
class CodeServerDirtyEvent {
  /// Creates a [CodeServerDirtyEvent].
  const CodeServerDirtyEvent({
    required this.repoId,
    required this.path,
    required this.dirty,
  });

  /// The repo whose worktree hosts the file (may be empty → server picked first).
  final String repoId;

  /// The file whose dirty state changed, RELATIVE to the worktree root.
  final String path;

  /// True when the file now has unsaved changes; false when it became clean.
  final bool dirty;
}

/// Streams the embedded editor's per-file dirty-state changes for the given
/// channel (reported by the bridge extension via `codeServer.watchDirtyState`).
/// The IDE layout listens and toggles the matching tab's unsaved-changes dot.
///
/// On a server that doesn't host the op (no code-server), the subscription
/// errors — the layout's listener simply ignores the error state.
final codeServerDirtyStateProvider = StreamProvider.autoDispose
    .family<CodeServerDirtyEvent, String>((ref, channelId) {
      final client = ref.watch(rpcClientProvider);
      return client
          .subscribe('codeServer.watchDirtyState', {'channel_id': channelId})
          .map(
            (m) => CodeServerDirtyEvent(
              repoId: m['repo_id'] as String? ?? '',
              path: m['path'] as String? ?? '',
              dirty: m['dirty'] == true,
            ),
          );
    });

/// Asks the server to save a dirty worktree-relative [path] to disk by relaying
/// a save command to the embedded editor (the only holder of the unsaved
/// buffer). Backs the app's "Save" tab-close choice. Returns true when the
/// editor acked the save (or best-effort on timeout); false when there is no
/// running session or the op is unavailable.
Future<bool> saveCodeServerFile(
  RemoteRpcClient rpcClient, {
  required String channelId,
  String? repoId,
  required String path,
}) async {
  try {
    final data = await rpcClient.call('codeServer.saveFile', {
      'channel_id': channelId,
      if (repoId != null && repoId.isNotEmpty) 'repo_id': repoId,
      'path': path,
    });
    return data['saved'] == true;
  } catch (_) {
    // A server without code-server (opUnknown) or a transport hiccup — treat as
    // "couldn't save"; the caller decides whether to still close the tab.
    return false;
  }
}
