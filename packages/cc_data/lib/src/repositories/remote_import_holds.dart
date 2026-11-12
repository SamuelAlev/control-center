import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [ImportHoldReview] over RPC: `workspace.importHolds.list` and
/// `workspace.importHolds.resolve`.
///
/// Both name their workspace explicitly: the Backups page reviews holds of
/// whichever workspace was restored, rarely the one being viewed.
class RemoteImportHolds implements ImportHoldReview {
  /// Creates the adapter over [_client].
  const RemoteImportHolds(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<ImportHoldView>> list(String workspaceId) async {
    final data = await _client.call('workspace.importHolds.list', {
      'workspace_id': workspaceId,
    });
    return decodeRows(
      [
        for (final raw in (data['holds'] as List?) ?? const [])
          if (raw is Map) raw.cast<String, dynamic>(),
      ],
      importHoldFromWire,
      what: 'import hold',
    );
  }

  @override
  Future<bool> resolve({
    required String workspaceId,
    required String holdId,
    required bool accept,
  }) async {
    final data = await _client.call('workspace.importHolds.resolve', {
      'workspace_id': workspaceId,
      'hold_id': holdId,
      'accept': accept,
    });
    return data['applied'] == true;
  }
}

/// One `workspace.importHolds.list` entry. Throws [ArgumentError] or
/// [FormatException] for an entry that cannot be one (no id, no kind, no
/// timestamp), which [decodeRows] drops.
ImportHoldView importHoldFromWire(Map<String, dynamic> wire) {
  final payload = wire['payload'];
  final importedAt = wire['imported_at'];
  if (importedAt is! String) {
    throw const FormatException('import hold without imported_at');
  }
  return ImportHoldView(
    id: wire['id'] as String? ?? '',
    wireKind: wire['kind'] as String? ?? '',
    payload: payload is Map ? payload.cast<String, Object?>() : const {},
    importedAt: DateTime.parse(importedAt),
    sourceInstallId: wire['source_install_id'] as String? ?? '',
  );
}
