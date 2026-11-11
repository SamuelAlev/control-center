import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';

/// One recorded decision about running programs from inside a worktree, as the
/// settings list renders it.
class SandboxExecGrantView {
  /// Creates a [SandboxExecGrantView].
  const SandboxExecGrantView({
    required this.id,
    required this.path,
    required this.allowed,
    required this.createdAt,
    this.createdBy,
  });

  /// Parses the `sandbox.listExecGrants` wire shape.
  factory SandboxExecGrantView.fromWire(Map<String, dynamic> json) =>
      SandboxExecGrantView(
        id: json['id'] as String? ?? '',
        path: json['path'] as String? ?? '',
        allowed: (json['decision'] as String?) == 'allow',
        createdBy: json['created_by'] as String?,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Row id, echoed back to revoke.
  final String id;

  /// The directory tree the decision covers.
  final String path;

  /// Whether programs under [path] may run.
  final bool allowed;

  /// Principal that answered, when the server recorded one.
  final String? createdBy;

  /// When the decision was made.
  final DateTime createdAt;
}

/// One page of `sandbox.listExecGrants`.
class SandboxExecGrantViewPage {
  /// Creates a [SandboxExecGrantViewPage].
  const SandboxExecGrantViewPage({required this.grants, required this.total});

  /// The rows on this page, newest first.
  final List<SandboxExecGrantView> grants;

  /// How many grants match the query across every page.
  final int total;
}

/// Reads and revokes sandbox exec grants over RPC.
///
/// There is deliberately no `grant` call: a decision is only ever created by
/// answering a confirmation the sandbox raised, so it is always attached to a
/// tree the operator was actually shown. A client able to mint one directly
/// would be a way to widen the sandbox with no prompt.
class RemoteSandboxExecGrantRepository {
  /// Creates a [RemoteSandboxExecGrantRepository] over [_client].
  RemoteSandboxExecGrantRepository(this._client);

  final RemoteRpcClient _client;

  /// One page of decisions in [workspaceId] whose path contains [query],
  /// newest first: [limit] rows from [offset], plus how many match in total.
  ///
  /// A server without the op (a demo) answers `opUnknown`, which reads as
  /// "no decisions" rather than an error, so the page renders its empty state
  /// instead of a red banner.
  Future<SandboxExecGrantViewPage> list(
    String workspaceId, {
    String query = '',
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final data = await _client.call('sandbox.listExecGrants', {
        'workspace_id': workspaceId,
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'offset': offset,
        'limit': limit,
      });
      final grants = [
        for (final g in (data['grants'] as List? ?? const []))
          if (g is Map)
            SandboxExecGrantView.fromWire(g.cast<String, dynamic>()),
      ];
      return SandboxExecGrantViewPage(
        grants: grants,
        total: (data['total'] as num).toInt(),
      );
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const SandboxExecGrantViewPage(grants: [], total: 0);
      }
      rethrow;
    }
  }

  /// Revokes [id], so the operator is asked again next time.
  Future<void> revoke(String workspaceId, String id) => _client.call(
    'sandbox.revokeExecGrant',
    {'workspace_id': workspaceId, 'id': id},
  );
}
