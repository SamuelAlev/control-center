import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates memory facts over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `memory_fact.*` ops + `memory_fact.watchForWorkspace`
/// subscription in the host catalog.
class RemoteMemoryFactRepository {
  /// Creates a [RemoteMemoryFactRepository] over [_client].
  RemoteMemoryFactRepository(this._client);

  final RemoteRpcClient _client;

  /// All facts in the bound workspace.
  Future<List<MemoryFactDto>> getByWorkspace() async {
    final data = await _client.call('memory_fact.getByWorkspace', const {});
    return _facts(data);
  }

  /// A single fact by id (scoped to the bound workspace server-side), or null.
  Future<MemoryFactDto?> getById(String id) async {
    final data = await _client.call('memory_fact.getById', {'fact_id': id});
    final fact = data['fact'];
    return fact is Map
        ? MemoryFactDto.fromJson(fact.cast<String, dynamic>())
        : null;
  }

  /// Active (not superseded) facts for [topic] in the bound workspace.
  Future<List<MemoryFactDto>> getActiveByTopic(String topic) async {
    final data = await _client.call('memory_fact.getActiveByTopic', {
      'topic': topic,
    });
    return _facts(data);
  }

  /// Facts authored by [agentId] in the bound workspace.
  Future<List<MemoryFactDto>> getByAuthor(String agentId) async {
    final data = await _client.call('memory_fact.getByAuthor', {
      'agent_id': agentId,
    });
    return _facts(data);
  }

  /// FTS5 search for [query] in the bound workspace. (Hybrid vector search is
  /// host-only; the thin client cannot ship a query embedding.)
  Future<List<MemoryFactDto>> search(String query) async {
    final data = await _client.call('memory_fact.search', {'query': query});
    return _facts(data);
  }

  /// Inserts or updates [fact] (the host owns persistence + embedding).
  Future<void> upsert(MemoryFactDto fact) =>
      _client.call('memory_fact.upsert', {'fact': fact.toJson()});

  /// Deletes the fact [factId].
  Future<void> delete(String factId) =>
      _client.call('memory_fact.delete', {'fact_id': factId});

  /// Live facts in the bound workspace — a fresh snapshot on every change.
  Stream<List<MemoryFactDto>> watch() =>
      _client.subscribe('memory_fact.watchForWorkspace', const {}).map(_facts);

  List<MemoryFactDto> _facts(Map<String, dynamic> data) =>
      ((data['facts'] as List?) ?? const [])
          .whereType<Map>()
          .map((f) => MemoryFactDto.fromJson(f.cast<String, dynamic>()))
          .toList();
}
