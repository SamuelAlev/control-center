import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider-governance repository (PRD 05), over RPC on both desktop and web —
/// the host (in-process on desktop, remote on web) owns the `provider_policies`
/// table.
final providerPolicyRepositoryProvider = Provider<ProviderPolicyRepository>(
  (ref) => RpcProviderPolicyRepository(ref.watch(rpcClientProvider)),
);

/// The active workspace's provider-governance statements (live).
final workspaceProviderPoliciesProvider =
    StreamProvider<List<WorkspaceProviderPolicy>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const []);
      }
      return ref
          .watch(providerPolicyRepositoryProvider)
          .watchForWorkspace(workspaceId);
    });

/// The active workspace's policy engine, consumed by the catalog's finalize to
/// drop denied providers. Null when there is no active workspace (no policy to
/// apply → the catalog stays fully populated).
final workspaceProviderPolicyEngineProvider =
    FutureProvider<ProviderPolicyEngine?>((ref) async {
      final policies = await ref.watch(
        workspaceProviderPoliciesProvider.future,
      );
      if (policies.isEmpty) {
        return null;
      }
      return ProviderPolicyEngine.fromStatements(
        policies.map((p) => p.statement),
      );
    });

/// Upserts a governance statement for the active workspace.
Future<void> upsertProviderPolicy(
  WidgetRef ref,
  String id,
  PolicyStatement statement,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref
      .read(providerPolicyRepositoryProvider)
      .upsert(workspaceId, id, statement);
}

/// Deletes a governance statement for the active workspace.
Future<void> deleteProviderPolicy(WidgetRef ref, String id) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  await ref.read(providerPolicyRepositoryProvider).delete(workspaceId, id);
}
