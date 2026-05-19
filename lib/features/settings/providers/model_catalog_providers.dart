import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/provider_policy_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The finalized model catalog (PRD 05): models.dev providers/models with
/// provider enablement resolved and the active workspace's governance policy
/// applied (denied providers removed). Used by the model picker — denied
/// providers are absent (unselectable). Rebuilds when the policy changes.
final modelCatalogProvider = FutureProvider<ModelCatalog>((ref) async {
  final service = ref.watch(modelCatalogServiceProvider);
  final policy = await ref.watch(workspaceProviderPolicyEngineProvider.future);
  return service.catalog(policy: policy);
});

/// The catalog with enablement resolved but NO governance policy applied — the
/// full provider list, used by the governance browser so a denied provider
/// stays visible (and re-allowable). The picker uses [modelCatalogProvider].
final rawModelCatalogProvider = FutureProvider<ModelCatalog>((ref) {
  return ref.watch(modelCatalogServiceProvider).catalog();
});

/// Forces a models.dev re-sync (the "sync now" control), then refreshes the
/// catalog providers.
Future<void> refreshModelCatalog(WidgetRef ref) async {
  await ref.read(modelCatalogServiceProvider).refresh(force: true);
  ref
    ..invalidate(modelCatalogProvider)
    ..invalidate(rawModelCatalogProvider);
}
