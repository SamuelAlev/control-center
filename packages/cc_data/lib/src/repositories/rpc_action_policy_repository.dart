import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [ActionPolicyRepository] backed by the RPC client — the thin-client data
/// path for PRD 24 agent-permission guardrails.
///
/// Mirrors the host's `action_policy.*` ops + the
/// `action_policy.watchForWorkspace` subscription, round-tripping an
/// [ActionPolicyRule] through [ActionPolicyRuleDto]. The host owns persistence
/// and is STATELESS — it holds no session workspace — so every call names the
/// `workspaceId` the interface threads. Leaning on the client's ambient active
/// workspace instead would follow the route rather than the workspace a keyed
/// caller asked about and would carry nothing at all before one is open.
class RpcActionPolicyRepository implements ActionPolicyRepository {
  /// Creates an [RpcActionPolicyRepository] over [_client].
  RpcActionPolicyRepository(this._client);

  final RemoteRpcClient _client;

  List<ActionPolicyRule> _parse(Map<String, dynamic> data) =>
      ((data['rules'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (r) => ActionPolicyRuleDto.fromJson(
              r.cast<String, dynamic>(),
            ).toEntity(now: DateTime.now()),
          )
          .toList();

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final data = await _client.call('action_policy.list', {
      'workspace_id': workspaceId,
    });
    return _parse(data);
  }

  @override
  // [workspaceId] rides in the args instead of leaning on the client's ambient
  // active-workspace injection: the ambient id follows the route and flips on a
  // switch, independently of the workspace a keyed caller is asking about.
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) => _client
      .subscribe('action_policy.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(_parse);

  @override
  Future<void> upsertRule(ActionPolicyRule rule) => _client.call(
    'action_policy.upsert',
    {'rule': ActionPolicyRuleDto.fromEntity(rule).toJson()},
  );

  @override
  Future<void> deleteRule(String workspaceId, String id) => _client.call(
    'action_policy.delete',
    {'workspace_id': workspaceId, 'id': id},
  );

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async {
    final all = await rules(workspaceId);
    return all
        .where((r) => r.scopeType == scopeType && r.scopeId == scopeId)
        .toList();
  }

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async {
    final all = await rules(workspaceId);
    for (final r in all) {
      if (r.id == id) {
        return r;
      }
    }
    return null;
  }
}
