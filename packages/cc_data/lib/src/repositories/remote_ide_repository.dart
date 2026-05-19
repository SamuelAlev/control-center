import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Drives the server host's editor / IDE capabilities over the RPC client.
///
/// Editors and PR worktrees live on the SERVER's machine (the desktop
/// in-process host, or a desktop-hosted server). Mirrors the
/// `ide.detectEditors` + `ide.openPrInEditor` ops in the host catalog. A
/// headless server registers neither op, so [detectEditors] returns an empty
/// list there and the open-in-IDE button hides itself — exactly like the
/// desktop button on an unsupported platform.
class RemoteIdeRepository {
  /// Creates a [RemoteIdeRepository] over [_client].
  RemoteIdeRepository(this._client);

  final RemoteRpcClient _client;

  /// The editors the server host can launch, each flagged installed. Returns an
  /// empty list when the host exposes no editor capability (a headless server).
  Future<List<IdeEditor>> detectEditors() async {
    try {
      final data = await _client.call('ide.detectEditors', const {});
      return ((data['editors'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => _editor(e.cast<String, dynamic>()))
          .toList();
    } on RemoteRpcException catch (e) {
      // Absent on a headless host (default-deny → opUnknown): treat as "no
      // editors available" rather than surfacing an error to the UI.
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  /// Materializes PR #[prNumber]'s head branch into a copy-on-write worktree on
  /// the server and opens it in the editor [editorId]. The session's bound
  /// workspace owns the ephemeral worktree.
  Future<void> openPrInEditor({
    required RepoDto repo,
    required int prNumber,
    required String prHeadRef,
    required String editorId,
  }) async {
    await _client.call('ide.openPrInEditor', {
      'repo': repo.toJson(),
      'pr_number': prNumber,
      'pr_head_ref': prHeadRef,
      'editor_id': editorId,
    });
  }

  /// Materializes PR #[prNumber]'s head branch into a worktree on the server and
  /// returns its absolute path WITHOUT launching an editor — so a GUI-attached
  /// client (the native desktop app) can open the path in a LOCAL editor itself.
  /// The session's bound workspace owns the ephemeral worktree. Served even by a
  /// headless host (unlike [openPrInEditor], which needs an editor launcher).
  Future<String> ensureWorktree({
    required RepoDto repo,
    required int prNumber,
    required String prHeadRef,
  }) async {
    final data = await _client.call('ide.ensureWorktree', {
      'repo': repo.toJson(),
      'pr_number': prNumber,
      'pr_head_ref': prHeadRef,
    });
    return data['path'] as String;
  }

  IdeEditor _editor(Map<String, dynamic> w) => IdeEditor(
    id: w['id'] as String? ?? '',
    displayName: w['display_name'] as String? ?? '',
    installed: w['installed'] as bool? ?? false,
  );
}
