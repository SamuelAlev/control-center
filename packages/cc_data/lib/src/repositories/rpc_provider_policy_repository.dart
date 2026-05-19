import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ProviderPolicyRepository] backed by the RPC client — the thin-client data
/// path for PRD 05 provider governance.
///
/// Mirrors the host's `provider_policy.*` ops + the
/// `provider_policy.watchForWorkspace` subscription, mapping [ProviderPolicyDto]
/// to [WorkspaceProviderPolicy]. The host owns persistence and is STATELESS —
/// it holds no session workspace — so every call names the `workspaceId` the
/// interface threads rather than leaning on the client's ambient active
/// workspace, which follows the route and is absent before one is open.
class RpcProviderPolicyRepository implements ProviderPolicyRepository {
  /// Creates an [RpcProviderPolicyRepository] over [_client].
  RpcProviderPolicyRepository(this._client);

  final RemoteRpcClient _client;

  static WorkspaceProviderPolicy _fromDto(ProviderPolicyDto d) =>
      WorkspaceProviderPolicy(
        id: d.id,
        statement: PolicyStatement(
          action: d.action,
          resource: d.resource,
          effect: PolicyEffect.fromRaw(d.effect),
          layer: _policyLayerByName[d.layer] ?? PolicyLayer.workspace,
        ),
      );

  List<WorkspaceProviderPolicy> _parse(Map<String, dynamic> data) =>
      ((data['policies'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (p) =>
                _fromDto(ProviderPolicyDto.fromJson(p.cast<String, dynamic>())),
          )
          .toList();

  @override
  Future<List<WorkspaceProviderPolicy>> listForWorkspace(
    String workspaceId,
  ) async {
    final data = await _client.call('provider_policy.listForWorkspace', {
      'workspace_id': workspaceId,
    });
    return _parse(data);
  }

  @override
  Stream<List<WorkspaceProviderPolicy>> watchForWorkspace(String workspaceId) =>
      // Explicit `workspace_id` rather than the client's ambient active
      // workspace, which flips on a switch independently of the workspace this
      // keyed caller is asking about.
      _client
          .subscribe('provider_policy.watchForWorkspace', {
            'workspace_id': workspaceId,
          })
          .map(_parse);

  @override
  Future<void> upsert(
    String workspaceId,
    String id,
    PolicyStatement statement,
  ) => _client.call('provider_policy.upsert', {
    'policy': ProviderPolicyDto(
      id: id,
      workspaceId: workspaceId,
      action: statement.action,
      resource: statement.resource,
      effect: statement.effect.id,
      layer: statement.layer.name,
    ).toJson(),
  });

  @override
  Future<void> delete(String workspaceId, String id) => _client.call(
    'provider_policy.delete',
    {'workspace_id': workspaceId, 'id': id},
  );

  @override
  Future<ProviderPolicyEngine> engineFor(String workspaceId) async {
    final policies = await listForWorkspace(workspaceId);
    return ProviderPolicyEngine.fromStatements(
      policies.map((p) => p.statement),
    );
  }
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, PolicyLayer> _policyLayerByName = PolicyLayer.values
    .asNameMap();
