// Desktop (VM) binding for the diarization-model control surface.
//
// The desktop owns its on-device speaker-diarization model, so the control +
// status adapt the existing in-process lifecycle notifier
// (`diarizationModelStateProvider`) — no RPC. This keeps the desktop's
// behaviour identical to the old `DiarizationSection` while letting ONE section
// compile on both platforms via the seam. Live download progress flows through
// because the status provider WATCHES the notifier's state.
library;

import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps the desktop [DiarizationModelStatus] to the platform-neutral status.
ModelLifecycleStatus _mapStatus(DiarizationModelStatus s) => switch (s) {
  DiarizationModelStatus.unknown => ModelLifecycleStatus.unknown,
  DiarizationModelStatus.notInstalled => ModelLifecycleStatus.notInstalled,
  DiarizationModelStatus.downloading => ModelLifecycleStatus.downloading,
  DiarizationModelStatus.installed => ModelLifecycleStatus.installed,
  DiarizationModelStatus.error => ModelLifecycleStatus.error,
};

/// Projects the notifier's [DiarizationModelState] to a [ModelStatusSnapshot].
ModelStatusSnapshot _snapshot(DiarizationModelState state) =>
    ModelStatusSnapshot(
      status: _mapStatus(state.status),
      progress: state.progress,
      phase: state.phase,
      error: state.error,
    );

/// Desktop-backed [ModelControl]: drives the in-process diarization-model
/// lifecycle notifier directly.
class DesktopDiarizationModelControl implements ModelControl {
  /// Creates a control over the given [ref].
  DesktopDiarizationModelControl(this._ref);

  final Ref _ref;

  DiarizationModelStateNotifier get _notifier =>
      _ref.read(diarizationModelStateProvider.notifier);

  @override
  Future<ModelStatusSnapshot> status() async =>
      _snapshot(_ref.read(diarizationModelStateProvider));

  @override
  Stream<ModelStatusSnapshot> watch() {
    // Project the in-process lifecycle notifier's state changes onto the
    // platform-neutral snapshot stream, so a web/remote client connected to this
    // desktop GUI host sees live download/extract progress over `models.watch*`
    // (the desktop's own section watches the notifier directly).
    late final StreamController<ModelStatusSnapshot> controller;
    ProviderSubscription<DiarizationModelState>? sub;
    controller = StreamController<ModelStatusSnapshot>(
      onListen: () {
        sub = _ref.listen<DiarizationModelState>(
          diarizationModelStateProvider,
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
    // Non-blocking: kick the in-process download off and return immediately.
    // Callers watch progress via [watch] / the notifier-backed status provider.
    unawaited(_notifier.installIfNeeded());
  }

  @override
  Future<void> cancel() async => _notifier.cancel();

  @override
  Future<void> uninstall() => _notifier.uninstall();
}

/// The diarization-model control the settings section drives. On desktop this is
/// the in-process control adapter over the existing lifecycle notifier.
final diarizationModelControlProvider = Provider<ModelControl>(
  DesktopDiarizationModelControl.new,
);

/// The current diarization-model snapshot, as a resolved `AsyncData`. Never
/// `null` on desktop (it always hosts its own model). Watches
/// `diarizationModelStateProvider` so the section reflects live download
/// progress.
///
/// This is a synchronous `Provider<AsyncValue<…>>` (not a `FutureProvider`) so
/// the desktop section renders the status on the FIRST frame — identical to the
/// old `DiarizationSection` (no loading flicker). The web variant is a real
/// `FutureProvider`; both yield the same `AsyncValue<ModelStatusSnapshot?>` when
/// watched, so the single section reads them identically.
final diarizationModelStatusSnapshotProvider =
    Provider<AsyncValue<ModelStatusSnapshot?>>((ref) {
      return AsyncData(_snapshot(ref.watch(diarizationModelStateProvider)));
    });
