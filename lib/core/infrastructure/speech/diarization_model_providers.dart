import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle status of the on-disk speaker-diarization models.
enum DiarizationModelStatus {
  /// Filesystem hasn't been checked yet.
  unknown,

  /// Models are not present and download has not started.
  notInstalled,

  /// Models are currently downloading / extracting.
  downloading,

  /// Models are installed and ready for use.
  installed,

  /// Last install attempt failed; see [DiarizationModelState.error].
  error,
}

/// Immutable snapshot of the diarization-model lifecycle.
class DiarizationModelState {
  /// Creates a [DiarizationModelState].
  const DiarizationModelState({
    this.status = DiarizationModelStatus.unknown,
    this.progress = 0.0,
    this.phase,
    this.paths,
    this.error,
  });

  /// Current lifecycle status.
  final DiarizationModelStatus status;

  /// Download / extraction progress in [0, 1].
  final double progress;

  /// Sub-phase, e.g. `downloading`, `extracting`, `ready`.
  final String? phase;

  /// Resolved paths when [status] is [DiarizationModelStatus.installed].
  final DiarizationModelPaths? paths;

  /// Last error message, if any.
  final String? error;

  /// Returns a copy with the given overrides.
  DiarizationModelState copyWith({
    DiarizationModelStatus? status,
    double? progress,
    String? phase,
    DiarizationModelPaths? paths,
    String? error,
    bool clearError = false,
    bool clearPhase = false,
  }) {
    return DiarizationModelState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      phase: clearPhase ? null : (phase ?? this.phase),
      paths: paths ?? this.paths,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// True when both models are installed and [paths] are resolved.
  bool get isInstalled =>
      status == DiarizationModelStatus.installed && paths != null;
}

/// Owns the diarization-model lifecycle. Probes the filesystem on init and
/// surfaces download progress to the UI. Mirrors `EmbeddingModelStateNotifier`.
class DiarizationModelStateNotifier extends Notifier<DiarizationModelState> {
  DiarizationModelManager get _manager =>
      ref.read(diarizationModelManagerProvider);
  CancelToken? _cancelToken;

  @override
  DiarizationModelState build() {
    Future.microtask(_probeOnce);
    return const DiarizationModelState();
  }

  Future<void> _probeOnce() async {
    try {
      final paths = await _manager.resolve();
      if (paths != null) {
        state = state.copyWith(
          status: DiarizationModelStatus.installed,
          progress: 1,
          phase: 'ready',
          paths: paths,
          clearError: true,
        );
      } else {
        state = state.copyWith(status: DiarizationModelStatus.notInstalled);
      }
    } catch (e, st) {
      AppLog.e('DiarizationModelState', 'probe failed: $e', e, st);
      state = state.copyWith(
        status: DiarizationModelStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Begin downloading + extracting the diarization models.
  Future<void> installIfNeeded() async {
    if (state.status == DiarizationModelStatus.downloading ||
        state.status == DiarizationModelStatus.installed) {
      return;
    }
    _cancelToken = CancelToken();
    state = state.copyWith(
      status: DiarizationModelStatus.downloading,
      progress: 0,
      phase: 'downloading',
      clearError: true,
    );
    try {
      final paths = await _manager.install(
        cancelToken: _cancelToken,
        onProgress: (progress, phase) {
          state = state.copyWith(progress: progress, phase: phase);
        },
      );
      state = state.copyWith(
        status: DiarizationModelStatus.installed,
        progress: 1,
        phase: 'ready',
        paths: paths,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = state.copyWith(
          status: DiarizationModelStatus.notInstalled,
          progress: 0,
          clearPhase: true,
        );
        return;
      }
      state = state.copyWith(
        status: DiarizationModelStatus.error,
        error: e.message ?? e.toString(),
      );
    } catch (e, st) {
      AppLog.e('DiarizationModelState', 'install failed: $e', e, st);
      state = state.copyWith(
        status: DiarizationModelStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Cancel an in-flight download.
  void cancel() {
    _cancelToken?.cancel('User cancelled diarization model download.');
  }

  /// Remove the installed models.
  Future<void> uninstall() async {
    await _manager.uninstall();
    state = state.copyWith(
      status: DiarizationModelStatus.notInstalled,
      progress: 0,
      clearPhase: true,
      clearError: true,
    );
  }
}

/// Provider exposing the on-disk [DiarizationModelManager].
final diarizationModelManagerProvider =
    Provider<DiarizationModelManager>((ref) {
  return DiarizationModelManager(paths: appCcPaths);
});

/// Provider exposing the [DiarizationModelState].
final diarizationModelStateProvider =
    NotifierProvider<DiarizationModelStateNotifier, DiarizationModelState>(
  DiarizationModelStateNotifier.new,
);
