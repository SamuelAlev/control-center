import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AcpModelRepository] backed by the RPC client — the thin-client data path.
///
/// The models an adapter advertises are resolved on the SERVER's machine (the
/// host owns the adapter CLIs / the curated per-adapter list), so the thin
/// client lists them over the host's `acp.listModels` op. A host that wires no
/// ACP model source leaves the op absent (default-deny → `opUnknown`); the
/// client degrades to an empty list rather than surfacing an error.
class RpcAcpModelRepository implements AcpModelRepository {
  /// Creates an [RpcAcpModelRepository] over [_client].
  RpcAcpModelRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<AcpModel>> listModels(String adapterId, {String? cliPath}) async {
    try {
      final data = await _client.call('acp.listModels', {
        'adapter_id': adapterId,
        if (cliPath != null && cliPath.isNotEmpty) 'cli_path': cliPath,
      });
      return ((data['models'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map(AcpModel.fromJson)
          .where((m) => m.id.isNotEmpty)
          .toList();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }
}
