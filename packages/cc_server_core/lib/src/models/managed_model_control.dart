import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:dio/dio.dart';

/// Signature of an on-disk model manager's `install` method
/// (`VoiceModelManager` / `DiarizationModelManager` / `EmbeddingModelManager`
/// all expose this exact shape). The return value is discarded — the control
/// reports lifecycle via [ModelStatusSnapshot]s, not the manager's resolved
/// paths.
typedef ModelInstallRunner =
    Future<void> Function({
      void Function(double progress, String phase)? onProgress,
      CancelToken? cancelToken,
    });

/// A server-side [ModelControl] that drives one on-disk model manager directly
/// (no Riverpod), so a headless `cc_server` can HOST the download + unarchive a
/// thin client triggers over the `models.*` RPC ops.
///
/// This is the server counterpart to lib's `Desktop*ModelControl` adapters: the
/// desktop projects an in-process Riverpod controller's state onto the same
/// [ModelControl] surface, whereas this owns the lifecycle state itself.
///
/// Key behaviour the thin-client download experience depends on:
/// * [install] is NON-BLOCKING — it flips the state to `downloading` and kicks
///   the transfer off in the background, returning immediately. The
///   `models.install*` op therefore returns a `downloading` snapshot in
///   milliseconds instead of holding the RPC call open for the whole multi-
///   hundred-MB transfer (which would time out).
/// * [watch] streams a fresh snapshot on every progress tick + status
///   transition, so the client animates a live progress bar via the
///   `models.watch*` subscription while the SERVER does the work.
///
/// The three managers differ only in their `resolve()` return type, so this is
/// parameterized by closures rather than coupled to a concrete manager.
class ManagedModelControl implements ModelControl {
  /// Creates a control backed by a model manager.
  ///
  /// [probeInstalled] reports whether the model is already present on disk
  /// (typically `manager.resolve() != null`); [runInstall] downloads + unpacks
  /// it (streaming progress through `onProgress`, honouring `cancelToken`);
  /// [runUninstall] removes it. [onLog] receives install-failure diagnostics.
  ManagedModelControl({
    required Future<bool> Function() probeInstalled,
    required ModelInstallRunner runInstall,
    required Future<void> Function() runUninstall,
    void Function(String message)? onLog,
  })  : _probeInstalled = probeInstalled,
        _runInstall = runInstall,
        _runUninstall = runUninstall,
        _onLog = onLog;

  final Future<bool> Function() _probeInstalled;
  final ModelInstallRunner _runInstall;
  final Future<void> Function() _runUninstall;
  final void Function(String message)? _onLog;

  final StreamController<ModelStatusSnapshot> _events =
      StreamController<ModelStatusSnapshot>.broadcast();

  ModelStatusSnapshot _current = const ModelStatusSnapshot(
    status: ModelLifecycleStatus.unknown,
  );

  /// The token of the in-flight install (null when idle). Identity-compared in
  /// the driver so a superseded/cancelled run's late callbacks are ignored.
  CancelToken? _cancelToken;
  bool _probed = false;

  void _set(ModelStatusSnapshot snapshot) {
    _current = snapshot;
    if (!_events.isClosed) {
      _events.add(snapshot);
    }
  }

  /// Probes disk once to resolve the initial `installed`/`notInstalled` state.
  /// A no-op once an install has started (so a stale probe never clobbers a
  /// live download).
  Future<void> _ensureProbed() async {
    if (_probed) {
      return;
    }
    _probed = true;
    if (_current.status == ModelLifecycleStatus.downloading) {
      return;
    }
    try {
      final installed = await _probeInstalled();
      _set(
        ModelStatusSnapshot(
          status: installed
              ? ModelLifecycleStatus.installed
              : ModelLifecycleStatus.notInstalled,
          progress: installed ? 1 : 0,
          phase: installed ? 'ready' : null,
        ),
      );
    } catch (e) {
      _set(
        ModelStatusSnapshot(
          status: ModelLifecycleStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<ModelStatusSnapshot> status() async {
    await _ensureProbed();
    return _current;
  }

  @override
  Stream<ModelStatusSnapshot> watch() async* {
    await _ensureProbed();
    // Replay the current snapshot so a fresh subscriber renders immediately,
    // then forward every subsequent transition.
    yield _current;
    yield* _events.stream;
  }

  @override
  Future<void> install() async {
    await _ensureProbed();
    if (_current.status == ModelLifecycleStatus.installed ||
        _current.status == ModelLifecycleStatus.downloading) {
      return;
    }
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    _set(
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.downloading,
        progress: 0,
        phase: 'downloading',
      ),
    );
    // Fire-and-forget: the transfer runs on the server; the client watches
    // [watch] for progress. install() returns as soon as the download starts.
    unawaited(_drive(cancelToken));
  }

  Future<void> _drive(CancelToken cancelToken) async {
    try {
      await _runInstall(
        cancelToken: cancelToken,
        onProgress: (progress, phase) {
          // Drop late callbacks from a cancelled / superseded run.
          if (!identical(_cancelToken, cancelToken)) {
            return;
          }
          _set(
            ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: progress,
              phase: phase,
            ),
          );
        },
      );
      if (!identical(_cancelToken, cancelToken)) {
        return;
      }
      _set(
        const ModelStatusSnapshot(
          status: ModelLifecycleStatus.installed,
          progress: 1,
          phase: 'ready',
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _set(
          const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled),
        );
        return;
      }
      _onLog?.call('model install failed: ${e.message ?? e}');
      _set(
        ModelStatusSnapshot(
          status: ModelLifecycleStatus.error,
          error: e.message ?? e.toString(),
        ),
      );
    } catch (e) {
      _onLog?.call('model install failed: $e');
      _set(
        ModelStatusSnapshot(
          status: ModelLifecycleStatus.error,
          error: e.toString(),
        ),
      );
    } finally {
      if (identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
      }
    }
  }

  @override
  Future<void> cancel() async {
    _cancelToken?.cancel('cancelled by client');
    _cancelToken = null;
  }

  @override
  Future<void> uninstall() async {
    _cancelToken?.cancel('superseded by uninstall');
    _cancelToken = null;
    await _runUninstall();
    _set(const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled));
  }

  /// Cancels any in-flight download and closes the progress stream. Call on
  /// server shutdown.
  Future<void> dispose() async {
    _cancelToken?.cancel('disposed');
    _cancelToken = null;
    await _events.close();
  }
}
