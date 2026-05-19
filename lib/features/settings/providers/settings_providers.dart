import 'dart:async';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that resolves the list of models for a given `adapterId`.
///
/// The built-in harness adapter is special-cased: its models are served live by
/// the providers the user is logged into (via `providers.listModels`), not by
/// probing a CLI. Every other adapter resolves via the ACP model repository.
final adapterModelsProvider = FutureProvider.family<List<AcpModel>, String?>((
  ref,
  adapterId,
) async {
  if (adapterId == null || adapterId.isEmpty) {
    return const [];
  }
  final detected = ref.read(detectedAdaptersProvider);
  final adapter = detected
      .where((d) => d.adapter.id == adapterId)
      .map((d) => d.adapter)
      .firstOrNull;
  if (adapter?.transport == AdapterTransport.harness) {
    final models = await ref.watch(harnessModelsProvider.future);
    // models.dev metadata (context window) for models whose live endpoint
    // doesn't report one — enrichment only, never a source of model ids.
    ModelCatalog catalog;
    try {
      catalog = await ref.watch(rawModelCatalogProvider.future);
    } on Object {
      catalog = ModelCatalog.empty;
    }
    return [
      for (final m in models)
        AcpModel(
          id: m.id,
          name: m.displayName ?? m.id,
          contextWindow:
              m.contextWindow ?? catalog.resolve(m.id)?.limits.context,
        ),
    ];
  }
  final cliPath = detected
      .where((d) => d.adapter.id == adapterId)
      .map((d) => d.path)
      .firstOrNull;
  return ref
      .read(acpModelRepositoryProvider)
      .listModels(adapterId, cliPath: cliPath);
});

/// Provider that watches the detection status of all predefined adapter CLIs.
final detectedAdaptersProvider =
    NotifierProvider<AdapterDetectionNotifier, List<DetectedAdapter>>(
      AdapterDetectionNotifier.new,
    );

/// The adapters actually installed, and the ONLY set a picker may offer.
///
/// Detection runs on the SERVER host for every client tier —
/// `buildAdapterRepository` binds `RpcAdapterRepository` on desktop and web
/// alike — so "installed" is one fact about one machine, not a per-device
/// guess. That is what makes filtering safe: offering an undetected runner
/// used to be justified as "it might exist on the machine that will run it",
/// but there is only one such machine and it has already answered.
///
/// Choosing a runner that is not installed cannot succeed; it produces a
/// dispatch that fails later, far from the dropdown that allowed it. Settings →
/// Adapters is the surface that lists undetected runners, because that is where
/// finding out what to install is the point.
final availableAdaptersProvider = Provider<List<Adapter>>((ref) {
  return [
    for (final d in ref.watch(detectedAdaptersProvider))
      if (d.isFound) d.adapter,
  ];
});

/// Whether adapter detection has not finished. An empty [availableAdaptersProvider]
/// means "none installed" only once this is false — until then it means "not
/// answered yet", and the two deserve different UI.
final adapterDetectionPendingProvider = Provider<bool>((ref) {
  return ref
      .watch(detectedAdaptersProvider)
      .any((d) => d.status == DetectionStatus.checking);
});

/// Adapter detection notifier.
class AdapterDetectionNotifier extends Notifier<List<DetectedAdapter>> {
  @override
  List<DetectedAdapter> build() {
    _startDetection();
    return predefinedAdapters.map((a) {
      return DetectedAdapter(adapter: a, status: DetectionStatus.checking);
    }).toList();
  }

  Future<void> _startDetection() async {
    final repository = ref.read(adapterRepositoryProvider);
    for (final adapter in predefinedAdapters) {
      unawaited(_detect(repository, adapter));
    }
  }

  Future<void> _detect(AdapterRepository repository, Adapter adapter) async {
    final result = await repository.detectOne(adapter);
    final index = state.indexWhere((d) => d.adapter.id == adapter.id);
    if (index == -1) {
      return;
    }

    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) result else state[i],
    ];
  }

  /// Refresh.
  Future<void> refresh() async {
    state = predefinedAdapters.map((a) {
      return DetectedAdapter(adapter: a, status: DetectionStatus.checking);
    }).toList();
    await _startDetection();
  }
}
