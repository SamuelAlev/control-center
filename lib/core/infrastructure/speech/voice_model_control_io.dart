// Desktop (VM) binding for the voice-model control surface.
//
// The desktop owns its on-device speech-to-text model, so the control + status
// adapt the existing in-process lifecycle notifier (`voiceModelStateProvider`)
// — no RPC. This keeps the desktop's behaviour identical to the old
// `VoiceSection` while letting ONE section compile on both platforms via the
// seam. Live download/extract progress flows through because the status
// provider WATCHES the notifier's state (carrying the `phase` so the section can
// distinguish downloading from extracting).
library;

import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps the desktop [VoiceModelStatus] to the platform-neutral status.
ModelLifecycleStatus _mapStatus(VoiceModelStatus s) => switch (s) {
  VoiceModelStatus.unknown => ModelLifecycleStatus.unknown,
  VoiceModelStatus.notInstalled => ModelLifecycleStatus.notInstalled,
  VoiceModelStatus.downloading => ModelLifecycleStatus.downloading,
  VoiceModelStatus.installed => ModelLifecycleStatus.installed,
  VoiceModelStatus.error => ModelLifecycleStatus.error,
};

/// Projects the notifier's [VoiceModelState] to a [ModelStatusSnapshot].
ModelStatusSnapshot _snapshot(VoiceModelState state) => ModelStatusSnapshot(
  status: _mapStatus(state.status),
  progress: state.progress,
  phase: state.phase,
  error: state.error,
);

/// Desktop-backed [SelectableModelControl]: drives the in-process voice-model
/// lifecycle notifier directly, including the ASR model SELECTION (the in-
/// process registry the desktop section reads), so a connected web/remote
/// client gets the same model picker the desktop has.
class DesktopVoiceModelControl implements SelectableModelControl {
  /// Creates a control over the given [ref].
  DesktopVoiceModelControl(this._ref);

  final Ref _ref;

  VoiceModelStateNotifier get _notifier =>
      _ref.read(voiceModelStateProvider.notifier);

  @override
  Future<ModelStatusSnapshot> status() async =>
      _snapshot(_ref.read(voiceModelStateProvider));

  @override
  Stream<ModelStatusSnapshot> watch() {
    // Project the in-process lifecycle notifier's state changes onto the
    // platform-neutral snapshot stream, so a web/remote client connected to this
    // desktop GUI host sees live download/extract progress over `models.watch*`
    // (the desktop's own section watches the notifier directly).
    late final StreamController<ModelStatusSnapshot> controller;
    ProviderSubscription<VoiceModelState>? sub;
    controller = StreamController<ModelStatusSnapshot>(
      onListen: () {
        sub = _ref.listen<VoiceModelState>(
          voiceModelStateProvider,
          (_, next) {
            if (!controller.isClosed) {
              controller.add(_snapshot(next));
            }
          },
          fireImmediately: true,
        );
      },
      onCancel: () {
        sub?.close();
        sub = null;
        return controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> install() async {
    // Non-blocking: kick the in-process download off and return immediately
    // (the notifier flips to `downloading` synchronously). Callers watch
    // progress via [watch] / the notifier-backed status provider.
    unawaited(_notifier.installIfNeeded());
  }

  @override
  Future<void> cancel() async => _notifier.cancel();

  @override
  Future<void> uninstall() => _notifier.uninstall();

  @override
  Future<ModelCatalog> catalog() async => ModelCatalog(
    selectedId: _ref.read(selectedVoiceModelProvider),
    models: [
      for (final m in VoiceModelInfo.all)
        ModelChoice(id: m.id, displayName: m.displayName),
    ],
  );

  @override
  Future<ModelStatusSnapshot> select(String modelId) async {
    // Switching the persisted selection rebuilds [voiceModelStateProvider]
    // (it watches [selectedVoiceModelProvider]), which re-probes the newly-
    // selected model's install state. The re-probed status flows to a watcher
    // via [watch]; return the current snapshot synchronously.
    _ref.read(selectedVoiceModelProvider.notifier).select(modelId);
    return _snapshot(_ref.read(voiceModelStateProvider));
  }
}

/// The voice-model control the settings section drives. On desktop this is the
/// in-process control adapter over the existing lifecycle notifier.
final voiceModelControlProvider = Provider<ModelControl>(
  DesktopVoiceModelControl.new,
);

/// The current voice-model snapshot, as a resolved `AsyncData`. Never `null` on
/// desktop (it always hosts its own model). Watches `voiceModelStateProvider` so
/// the section reflects live download/extract progress.
///
/// This is a synchronous `Provider<AsyncValue<…>>` (not a `FutureProvider`) so
/// the desktop section renders the status on the FIRST frame — identical to the
/// old `VoiceSection` (no loading flicker). The web variant is a real
/// `FutureProvider`; both yield the same `AsyncValue<ModelStatusSnapshot?>` when
/// watched, so the single section reads them identically.
final voiceModelStatusSnapshotProvider =
    Provider<AsyncValue<ModelStatusSnapshot?>>((ref) {
      return AsyncData(_snapshot(ref.watch(voiceModelStateProvider)));
    });
