import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
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

  List<ActionPolicyRule> _parse(Map<String, dynamic> data, String workspaceId) {
    final rows = data['rules'];
    if (rows is! List) {
      throw const FormatException('Missing action policy rules');
    }
    return [for (final value in rows) _rule(value, workspaceId)];
  }

  ActionPolicyRule _rule(Object? value, String workspaceId) {
    if (value is! Map) {
      throw const FormatException('Invalid action policy rule');
    }
    final json = value.cast<String, dynamic>();
    if (json['workspace_id'] != workspaceId ||
        json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        !ActionScopeType.values.any((s) => s.wire == json['scope_type']) ||
        json['scope_id'] is! String ||
        (json['scope_type'] == ActionScopeType.workspace.wire
            ? json['scope_id'] != ''
            : (json['scope_id'] as String).isEmpty) ||
        !ActionDecision.values.any((d) => d.wire == json['decision']) ||
        ((json['action_class'] == null) == (json['command_prefix'] == null)) ||
        (json['action_class'] != null &&
            (json['action_class'] is! String ||
                ActionClass.fromWire(json['action_class'] as String) ==
                    null)) ||
        (json['command_prefix'] != null &&
            (json['command_prefix'] is! String ||
                (json['command_prefix'] as String).isEmpty))) {
      throw const FormatException('Invalid action policy rule');
    }
    return ActionPolicyRuleDto.fromJson(json).toEntity(now: DateTime.now());
  }

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final data = await _client.call('action_policy.list', {
      'workspace_id': workspaceId,
    });
    return _parse(data, workspaceId);
  }

  @override
  // [workspaceId] rides in the args instead of leaning on the client's ambient
  // active-workspace injection: the ambient id follows the route and flips on a
  // switch, independently of the workspace a keyed caller is asking about.
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) => _client
      .subscribe('action_policy.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map((data) => _parse(data, workspaceId));

  @override
  Future<void> upsertRule(ActionPolicyRule rule) =>
      _client.call('action_policy.upsert', {
        'workspace_id': rule.workspaceId,
        'rule': ActionPolicyRuleDto.fromEntity(rule).toJson(),
      });

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
