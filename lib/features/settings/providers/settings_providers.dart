
import 'dart:async';

import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/domain/entities/acp_model.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/domain/repositories/adapter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that resolves the list of models for a given `adapterId`.
final adapterModelsProvider = FutureProvider.family<List<AcpModel>, String?>((
  ref,
  adapterId,
) async {
  if (adapterId == null || adapterId.isEmpty) {
    return const [];
  }
  final detected = ref.read(detectedAdaptersProvider);
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

