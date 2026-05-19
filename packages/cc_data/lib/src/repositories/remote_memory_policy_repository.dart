import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates memory policies over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `memory_policy.*` ops + `memory_policy.watchForWorkspace`
/// subscription in the host catalog.
class RemoteMemoryPolicyRepository {
  /// Creates a [RemoteMemoryPolicyRepository] over [_client].
  RemoteMemoryPolicyRepository(this._client);

  final RemoteRpcClient _client;

  /// All policies in the bound workspace.
  Future<List<MemoryPolicyDto>> getByWorkspace() async {
    final data = await _client.call('memory_policy.getByWorkspace', const {});
    return _policies(data);
  }

  /// A single policy by id (scoped to the bound workspace server-side), or null.
  Future<MemoryPolicyDto?> getById(String id) async {
    final data = await _client.call('memory_policy.getById', {'id': id});
    final policy = data['policy'];
    return policy is Map
        ? MemoryPolicyDto.fromJson(policy.cast<String, dynamic>())
        : null;
  }

  /// Active policies in the bound workspace, optionally filtered by [domain].
  Future<List<MemoryPolicyDto>> getActiveByWorkspace({String? domain}) async {
    final data = await _client.call('memory_policy.getActiveByWorkspace', {
      'domain': ?domain,
    });
    return _policies(data);
  }

  /// Inserts or updates [policy] (the host owns persistence).
  Future<void> upsert(MemoryPolicyDto policy) =>
      _client.call('memory_policy.upsert', {'policy': policy.toJson()});

  /// Deletes the policy [id].
  Future<void> delete(String id) =>
      _client.call('memory_policy.delete', {'id': id});

  /// Live policies in the bound workspace — a fresh snapshot on every change.
  Stream<List<MemoryPolicyDto>> watch() =>
      _client.subscribe('memory_policy.watchForWorkspace', const {}).map(_policies);

  List<MemoryPolicyDto> _policies(Map<String, dynamic> data) =>
      ((data['policies'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => MemoryPolicyDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
