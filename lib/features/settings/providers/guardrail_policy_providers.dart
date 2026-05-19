import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action-guardrail policy repository (PRD 24), over RPC on both desktop and
/// web — the host (in-process on desktop, remote on web) owns the
/// `action_policy_rules` table.
final actionPolicyRepositoryProvider = Provider<ActionPolicyRepository>(
  (ref) => RpcActionPolicyRepository(ref.watch(rpcClientProvider)),
);

/// The active workspace's guardrail rules (live). The matrix's effective-
/// decision cells and the what-if probe resolve this list CLIENT-SIDE with a
/// [const PolicyResolver] — no server compute.
final workspaceActionPoliciesProvider = StreamProvider<List<ActionPolicyRule>>((
  ref,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  return ref.watch(actionPolicyRepositoryProvider).watchRules(workspaceId);
});

/// A stable rule id per (scope, class|command) so re-editing a cell overwrites
/// the same row rather than minting a fresh UUID each time. Scoped by workspace
/// so the key is unique across workspaces (the server still forces the row's
/// workspace to the session workspace).
String stableActionPolicyRuleId({
  required String workspaceId,
  required ActionScopeType scopeType,
  required String scopeId,
  ActionClass? actionClass,
  String? commandPrefix,
}) {
  final key = actionClass != null
      ? 'class:${actionClass.wire}'
      : 'cmd:${commandPrefix ?? ''}';
  return 'ap_${workspaceId}_${scopeType.wire}_${scopeId}_$key';
}

/// Upserts a guardrail rule for the active workspace.
Future<void> upsertActionPolicyRule(
  WidgetRef ref,
  ActionPolicyRule rule,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref.read(actionPolicyRepositoryProvider).upsertRule(rule);
}

/// Deletes a guardrail rule (clear-to-inherited) for the active workspace.
Future<void> deleteActionPolicyRule(WidgetRef ref, String id) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref.read(actionPolicyRepositoryProvider).deleteRule(workspaceId, id);
}
