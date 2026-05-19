import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates memory domains over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `memory_domain.*` ops + `memory_domain.watchForWorkspace`
/// subscription in the host catalog.
class RemoteMemoryDomainRepository {
  /// Creates a [RemoteMemoryDomainRepository] over [_client].
  RemoteMemoryDomainRepository(this._client);

  final RemoteRpcClient _client;

  /// All domains in the bound workspace.
  Future<List<MemoryDomainDto>> getByWorkspace() async {
    final data = await _client.call('memory_domain.getByWorkspace', const {});
    return _domains(data);
  }

  /// The domain named [name] in the bound workspace, or null.
  Future<MemoryDomainDto?> findByName(String name) async {
    final data = await _client.call('memory_domain.findByName', {'name': name});
    final domain = data['domain'];
    return domain is Map
        ? MemoryDomainDto.fromJson(domain.cast<String, dynamic>())
        : null;
  }

  /// Inserts or updates [domain] (the host owns persistence).
  Future<void> upsert(MemoryDomainDto domain) =>
      _client.call('memory_domain.upsert', {'domain': domain.toJson()});

  /// Live domains in the bound workspace — a fresh snapshot on every change.
  Stream<List<MemoryDomainDto>> watch() => _client
      .subscribe('memory_domain.watchForWorkspace', const {})
      .map(_domains);

  List<MemoryDomainDto> _domains(Map<String, dynamic> data) =>
      ((data['domains'] as List?) ?? const [])
          .whereType<Map>()
          .map((d) => MemoryDomainDto.fromJson(d.cast<String, dynamic>()))
          .toList();
}
