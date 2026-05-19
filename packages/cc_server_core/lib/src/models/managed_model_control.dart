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

/// Severity of a [ManagedModelControl] diagnostic, so the host can route each
/// kind to the right lane.
enum ModelLogLevel {
  /// A headline lifecycle event: a download starting, its progress and its
  /// completion.
  ///
  /// These fire ONLY when real work happens (a model that is already on disk
  /// logs nothing), so a host is meant to surface them at its DEFAULT verbosity
  /// rather than behind a debug flag. A fresh server spends its first minutes
  /// fetching multi-hundred-megabyte models over the network; with nothing on
  /// the log for that stretch a slow link and a hung boot look identical.
  notice,

  /// The install failed or was interrupted.
  warning,
}

/// Builds a [ManagedModelControl] `description` from a model's display name and
/// its approximate download size, e.g. `'all-MiniLM-L6-v2 (384-d), ~90 MB'`.
///
/// The size is the point: it is what turns "this is taking a while" into an
/// expectation the reader can check against their link.
String modelDescription(String displayName, int approxBytes) =>
    '$displayName, ~${(approxBytes / (1024 * 1024)).round()} MB';

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
  /// [runUninstall] removes it.
  ///
  /// [onLog] receives the install lifecycle — see [ModelLogLevel]. [description]
  /// names what is being fetched (e.g. `'all-MiniLM-L6-v2, ~90 MB'`) and is
  /// quoted in the download-started line, so the log says which asset the wait
  /// is for and roughly how long it should take.
  ManagedModelControl({
    required Future<bool> Function() probeInstalled,
    required ModelInstallRunner runInstall,
    required Future<void> Function() runUninstall,
    String? description,
    void Function(ModelLogLevel level, String message)? onLog,
  }) : _probeInstalled = probeInstalled,
       _runInstall = runInstall,
       _runUninstall = runUninstall,
       _description = description,
       _onLog = onLog;

  final Future<bool> Function() _probeInstalled;
  final ModelInstallRunner _runInstall;
  final Future<void> Function() _runUninstall;
  final String? _description;
  final void Function(ModelLogLevel level, String message)? _onLog;

  /// Last progress decile and phase already logged, so a transfer that ticks
  /// thousands of times reports roughly ten lines. Reset per install run.
  int _loggedTenths = -1;
  String? _loggedPhase;

  final StreamController<ModelStatusSnapshot> _events =
      StreamController<ModelStatusSnapshot>.broadcast();

  ModelStatusSnapshot _current = const ModelStatusSnapshot(
    status: ModelLifecycleStatus.unknown,
  );

  /// The token of the in-flight install (null when idle). Identity-compared in
  /// the driver so a superseded/cancelled run's late callbacks are ignored.
  CancelToken? _cancelToken;

  /// Completer for the in-flight disk probe. Concurrent [status]/[watch]
  /// callers await the same future so they never observe the construction-time
  /// `unknown` snapshot while the probe is still running.
  Completer<void>? _probeDone;

  void _set(ModelStatusSnapshot snapshot) {
    _current = snapshot;
    if (!_events.isClosed) {
      _events.add(snapshot);
    }
  }

  /// Probes disk once to resolve the initial `installed`/`notInstalled` state.
  /// A no-op once an install has started (so a stale probe never clobbers a
  /// live download). Concurrent callers share the in-flight future so a
  /// [watch] that races construction still waits for the real snapshot.
  Future<void> _ensureProbed() async {
    final inFlight = _probeDone;
    if (inFlight != null) {
      return inFlight.future;
    }
    final done = Completer<void>();
    _probeDone = done;
    if (_current.status == ModelLifecycleStatus.downloading) {
      done.complete();
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
    } finally {
      if (!done.isCompleted) {
        done.complete();
      }
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
    _loggedTenths = -1;
    _loggedPhase = null;
    _set(
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.downloading,
        progress: 0,
        phase: 'downloading',
      ),
    );
    _onLog?.call(
      ModelLogLevel.notice,
      _description == null ? 'downloading…' : 'downloading $_description…',
    );
    // Fire-and-forget: the transfer runs on the server; the client watches
    // [watch] for progress. install() returns as soon as the download starts.
    unawaited(_drive(cancelToken));
  }

  /// Reports a progress tick, at most once per 10% and once per phase change.
  ///
  /// The raw dio callback fires per chunk — thousands of times for a
  /// multi-hundred-megabyte model — so it is unusable as a log line, while
  /// logging nothing leaves the whole transfer invisible. Deciles keep the
  /// transfer legible in ~10 lines. The terminal `ready` tick is skipped
  /// because [_drive] logs completion with a duration right after it.
  void _logProgress(double progress, String phase) {
    final log = _onLog;
    if (log == null || phase == 'ready') {
      return;
    }
    final clamped = progress.clamp(0.0, 1.0);
    final tenths = (clamped * 10).floor();
    // The opening tick is what the download-started line already said. Claim
    // its decile on the way out so the next chunk does not report "1%"; a LATER
    // phase resetting to 0% is news and still gets through (its phase differs).
    if (clamped == 0 && _loggedTenths < 0) {
      _loggedPhase = phase;
      _loggedTenths = 0;
      return;
    }
    if (phase == _loggedPhase && tenths <= _loggedTenths) {
      return;
    }
    _loggedPhase = phase;
    _loggedTenths = tenths;
    log(ModelLogLevel.notice, '$phase ${(clamped * 100).round()}%');
  }

  Future<void> _drive(CancelToken cancelToken) async {
    final startedAt = DateTime.now();
    String elapsed() {
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      return '${(ms / 1000).toStringAsFixed(1)}s';
    }

    try {
      await _runInstall(
        cancelToken: cancelToken,
        onProgress: (progress, phase) {
          // Drop late callbacks from a cancelled / superseded run.
          if (!identical(_cancelToken, cancelToken)) {
            return;
          }
          _logProgress(progress, phase);
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
      _onLog?.call(ModelLogLevel.notice, 'installed in ${elapsed()}');
      _set(
        const ModelStatusSnapshot(
          status: ModelLifecycleStatus.installed,
          progress: 1,
          phase: 'ready',
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _onLog?.call(
          ModelLogLevel.notice,
          'download cancelled after ${elapsed()}',
        );
        _set(
          const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled),
        );
        return;
      }
      _onLog?.call(
        ModelLogLevel.warning,
        'install failed after ${elapsed()}: ${e.message ?? e}',
      );
      _set(
        ModelStatusSnapshot(
          status: ModelLifecycleStatus.error,
          error: e.message ?? e.toString(),
        ),
      );
    } catch (e) {
      _onLog?.call(
        ModelLogLevel.warning,
        'install failed after ${elapsed()}: $e',
      );
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
