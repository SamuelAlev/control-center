import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usage/cost repository (PRD 05, feature #12), over RPC on both targets.
final usageRepositoryProvider = Provider<RpcUsageRepository>(
  (ref) => RpcUsageRepository(ref.watch(rpcClientProvider)),
);

/// Spend over the last 7 days for the active workspace (the usage dashboard).
///
/// Watches [activeWorkspaceIdProvider] so it re-fetches on a workspace switch —
/// the server scopes the summary to the bound workspace, so without this the
/// card would keep showing the previous workspace's spend.
final weeklyCostSummaryProvider = FutureProvider<CostSummary>((ref) {
  ref.watch(activeWorkspaceIdProvider);
  return ref.watch(usageRepositoryProvider).costSummary(windowDays: 7);
});
