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

  /// Resolves PR #[prNumber]'s channel worktree on the server (creating +
  /// provisioning it if needed — the SAME worktree the in-app workbench edits,
  /// not a separate checkout) and opens it in the editor [editorId] on the host's
  /// display.
  Future<void> openPrInEditor({
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    required String editorId,
    String? repoId,
    String title = '',
  }) async {
    await _client.call('ide.openPrInEditor', {
      'repo_full_name': repoFullName,
      'pr_number': prNumber,
      'pr_external_id': prExternalId,
      'editor_id': editorId,
      'repo_id': ?repoId,
      if (title.isNotEmpty) 'title': title,
    });
  }

  /// Resolves PR #[prNumber]'s channel worktree on the server (creating +
  /// provisioning it if needed) and returns its absolute path WITHOUT launching
  /// an editor — so a GUI-attached client (the native desktop app) can open the
  /// path in a LOCAL editor itself. This is the SAME worktree the workbench
  /// edits; there is no separate `pr_worktrees/` checkout.
  Future<String> ensureWorktree({
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String? repoId,
    String title = '',
  }) async {
    final data = await _client.call('ide.ensureWorktree', {
      'repo_full_name': repoFullName,
      'pr_number': prNumber,
      'pr_external_id': prExternalId,
      'repo_id': ?repoId,
      if (title.isNotEmpty) 'title': title,
    });
    return data['path'] as String;
  }

  IdeEditor _editor(Map<String, dynamic> w) => IdeEditor(
    id: w['id'] as String? ?? '',
    displayName: w['display_name'] as String? ?? '',
    installed: w['installed'] as bool? ?? false,
  );
}
