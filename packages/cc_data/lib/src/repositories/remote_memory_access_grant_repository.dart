import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates memory access grants over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `memory_access_grant.*` ops + the
/// `memory_access_grant.watchByWorkspace` subscription in the host catalog.
class RemoteMemoryAccessGrantRepository {
  /// Creates a [RemoteMemoryAccessGrantRepository] over [_client].
  RemoteMemoryAccessGrantRepository(this._client);

  final RemoteRpcClient _client;

  /// All access grants in the bound workspace.
  Future<List<MemoryAccessGrantDto>> getByWorkspace() async {
    final data = await _client.call('memory_access_grant.getByWorkspace', const {});
    return _grants(data);
  }

  /// Inserts or updates [grant] (the host owns persistence).
  Future<void> upsert(MemoryAccessGrantDto grant) =>
      _client.call('memory_access_grant.upsert', {'grant': grant.toJson()});

  /// Inserts or updates [grants] in a batch.
  Future<void> upsertAll(List<MemoryAccessGrantDto> grants) =>
      _client.call('memory_access_grant.upsertAll', {
        'grants': grants.map((g) => g.toJson()).toList(),
      });

  /// Live access grants in the bound workspace — a fresh snapshot on every
  /// change.
  Stream<List<MemoryAccessGrantDto>> watch() =>
      _client.subscribe('memory_access_grant.watchByWorkspace', const {}).map(_grants);

  List<MemoryAccessGrantDto> _grants(Map<String, dynamic> data) =>
      ((data['grants'] as List?) ?? const [])
          .whereType<Map>()
          .map((g) => MemoryAccessGrantDto.fromJson(g.cast<String, dynamic>()))
          .toList();
}
