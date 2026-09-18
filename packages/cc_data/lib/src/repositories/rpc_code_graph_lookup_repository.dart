import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_lookup_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// RPC-backed [CodeGraphLookupPort] over `codeGraph.symbolLookup`.
class RpcCodeGraphLookupRepository implements CodeGraphLookupPort {
  /// Creates an [RpcCodeGraphLookupRepository] over the given RPC client.
  RpcCodeGraphLookupRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<CodeGraphLookupResult> lookup({
    required String workspaceId,
    required String repoId,
    required String name,
    String? spaceId,
  }) async {
    final data = await _client.call('codeGraph.symbolLookup', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
      'name': name,
      'space_id': ?spaceId,
    });
    return CodeGraphLookupResult(
      fromBasePartition: data['from_base'] as bool? ?? true,
      definitions: _candidates(data['definitions']),
    );
  }

  List<CodeGraphLookupCandidate> _candidates(
    Object? raw, {
    bool nested = false,
  }) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map)
          _candidate(item.cast<String, dynamic>(), nested: nested),
    ];
  }

  CodeGraphLookupCandidate _candidate(
    Map<String, dynamic> w, {
    bool nested = false,
  }) {
    final kind =
        CodeSymbolKind.tryParse(w['kind'] as String?) ?? CodeSymbolKind.function;
    return CodeGraphLookupCandidate(
      id: w['id'] as String? ?? '',
      name: w['name'] as String? ?? '',
      qualifiedName: w['qualified_name'] as String? ?? '',
      kind: kind,
      filePath: w['file_path'] as String? ?? '',
      startLine: (w['start_line'] as num?)?.toInt() ?? 0,
      endLine: (w['end_line'] as num?)?.toInt() ?? 0,
      parentName: w['parent_name'] as String?,
      signature: w['signature'] as String? ?? '',
      callerCount: (w['caller_count'] as num?)?.toInt() ?? 0,
      implementors: nested
          ? const []
          : _candidates(w['implementors'], nested: true),
    );
  }
}
