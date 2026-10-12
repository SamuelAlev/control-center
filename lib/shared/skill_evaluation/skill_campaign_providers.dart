import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typed campaign access through the application's connected RPC transport.
final skillCampaignClientProvider = Provider<RpcEvalsClient>(
  (ref) => RpcEvalsClient(ref.watch(rpcClientProvider)),
);

/// Always scope subscriptions by explicit workspace; no active-workspace capture.
final skillCampaignsProvider = StreamProvider.autoDispose
    .family<List<SkillCampaignView>, ({String workspaceId, String? skillKey})>(
      (ref, scope) => ref
          .watch(skillCampaignClientProvider)
          .watchCampaignsForSkill(scope.workspaceId, skillKey: scope.skillKey),
    );

/// Live, nullable campaign state; deletion is not an empty successful report.
final skillCampaignProvider = StreamProvider.autoDispose
    .family<SkillCampaignView?, ({String workspaceId, String campaignId})>(
      (ref, scope) => ref
          .watch(skillCampaignClientProvider)
          .watchCampaign(scope.workspaceId, scope.campaignId),
    );

/// Workspace-authorized corpus inventory and executor capability limits.
final skillCorporaProvider = FutureProvider.autoDispose
    .family<SkillCorporaView, String>(
      (ref, workspaceId) =>
          ref.watch(skillCampaignClientProvider).skillCorpora(workspaceId),
    );

/// Explicit opt-in revision policy for a workspace-scoped skill identity.
final skillCampaignPolicyProvider = FutureProvider.autoDispose
    .family<SkillCampaignPolicyView?, ({String workspaceId, String skillKey})>(
      (ref, scope) => ref
          .watch(skillCampaignClientProvider)
          .skillPolicy(scope.workspaceId, scope.skillKey),
    );

/// Refreshes attempt metadata as persisted progress or lifecycle state changes.
final skillAttemptsProvider = FutureProvider.autoDispose
    .family<List<SkillAttemptView>, ({String workspaceId, String campaignId})>((
      ref,
      scope,
    ) {
      ref.watch(
        skillCampaignProvider(scope).select(
          (value) => (
            value.asData?.value?.completedAttempts,
            value.asData?.value?.status,
          ),
        ),
      );
      return ref
          .watch(skillCampaignClientProvider)
          .listAttempts(scope.workspaceId, scope.campaignId);
    });
