// Desktop (VM) binding for the embedding-model control surface.
//
// The desktop owns its on-device embedding model, so the control + status
// adapt the existing in-process lifecycle controller (`embeddingModelState
// Provider`) — no RPC. This keeps the desktop's behaviour identical to the old
// `EmbeddingSection` while letting ONE section compile on both platforms via the
// seam. Live download progress flows through because the status provider WATCHES
// the controller's state (it rebuilds on every progress tick).
library;

import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps the desktop [EmbeddingModelStatus] to the platform-neutral status.
ModelLifecycleStatus _mapStatus(EmbeddingModelStatus s) => switch (s) {
  EmbeddingModelStatus.unknown => ModelLifecycleStatus.unknown,
  EmbeddingModelStatus.notInstalled => ModelLifecycleStatus.notInstalled,
  EmbeddingModelStatus.downloading => ModelLifecycleStatus.downloading,
  EmbeddingModelStatus.installed => ModelLifecycleStatus.installed,
  EmbeddingModelStatus.error => ModelLifecycleStatus.error,
};

/// Projects the controller's [EmbeddingModelState] to a [ModelStatusSnapshot].
ModelStatusSnapshot _snapshot(EmbeddingModelState state) => ModelStatusSnapshot(
  status: _mapStatus(state.status),
  progress: state.progress,
  phase: state.phase,
  error: state.error,
);

/// Desktop-backed [ModelControl]: drives the in-process embedding-model
/// lifecycle controller directly.
class DesktopEmbeddingModelControl implements ModelControl {
  /// Creates a control over the given [ref].
  DesktopEmbeddingModelControl(this._ref);

  final Ref _ref;

  EmbeddingModelController get _notifier =>
      _ref.read(embeddingModelStateProvider.notifier);

  @override
  Future<ModelStatusSnapshot> status() async =>
      _snapshot(_ref.read(embeddingModelStateProvider));

  @override
  Stream<ModelStatusSnapshot> watch() {
    // Project the in-process lifecycle controller's state changes onto the
    // platform-neutral snapshot stream, so a web/remote client connected to this
    // desktop GUI host sees live download progress over `models.watch*` (the
    // desktop's own section watches the controller directly).
    late final StreamController<ModelStatusSnapshot> controller;
    ProviderSubscription<EmbeddingModelState>? sub;
    controller = StreamController<ModelStatusSnapshot>(
      onListen: () {
        sub = _ref.listen<EmbeddingModelState>(
          embeddingModelStateProvider,
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
    // Callers watch progress via [watch] / the controller-backed status provider.
    unawaited(_notifier.installIfNeeded());
  }

  @override
  Future<void> cancel() async => _notifier.cancel();

  @override
  Future<void> uninstall() => _notifier.uninstall();
}

/// The embedding-model control the settings section drives. On desktop this is
/// the in-process control adapter over the existing lifecycle controller.
final embeddingModelControlProvider = Provider<ModelControl>(
  DesktopEmbeddingModelControl.new,
);

/// The current embedding-model snapshot, as a resolved `AsyncData`. Never
/// `null` on desktop (it always hosts its own model). Watches
/// `embeddingModelStateProvider` so the section reflects live download progress.
///
/// This is a synchronous `Provider<AsyncValue<…>>` (not a `FutureProvider`) so
/// the desktop section renders the status on the FIRST frame — identical to the
/// old `EmbeddingSection` (no loading flicker). The web variant is a real
/// `FutureProvider`; both yield the same `AsyncValue<ModelStatusSnapshot?>` when
/// watched, so the single section reads them identically.
final embeddingModelStatusSnapshotProvider =
    Provider<AsyncValue<ModelStatusSnapshot?>>((ref) {
      return AsyncData(_snapshot(ref.watch(embeddingModelStateProvider)));
    });
