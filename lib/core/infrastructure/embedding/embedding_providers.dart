import 'package:control_center/core/infrastructure/embedding/embedding_model_manager.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle status of the local embedding model.
enum EmbeddingModelStatus {
  /// Filesystem hasn't been checked yet.
  unknown,
  /// Model is not present and download has not started.
  notInstalled,
  /// Model is currently downloading.
  downloading,
  /// Model is installed and ready for use.
  installed,
  /// Last install attempt failed; see [EmbeddingModelState.error].
  error,
}

/// Immutable snapshot of the embedding model lifecycle.
class EmbeddingModelState {
  /// Creates an [EmbeddingModelState].
  const EmbeddingModelState({
    this.status = EmbeddingModelStatus.unknown,
    this.progress = 0.0,
    this.phase,
    this.error,
  });

  /// Current lifecycle status.
  final EmbeddingModelStatus status;

  /// Download progress in [0, 1].
  final double progress;

  /// Sub-phase, e.g. `downloading`, `ready`.
  final String? phase;

  /// Last error message, if any.
  final String? error;

  /// Returns a copy with the given overrides.
  EmbeddingModelState copyWith({
    EmbeddingModelStatus? status,
    double? progress,
    String? phase,
    String? error,
    bool clearError = false,
    bool clearPhase = false,
  }) {
    return EmbeddingModelState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      phase: clearPhase ? null : (phase ?? this.phase),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the embedding-model lifecycle. Probes the filesystem on init,
/// surfaces download progress to the UI, and forwards the resolved paths
/// to [EmbeddingService] once install completes.
class EmbeddingModelStateNotifier extends Notifier<EmbeddingModelState> {
  EmbeddingModelManager get _manager => ref.read(embeddingModelManagerProvider);
  CancelToken? _cancelToken;

  @override
  EmbeddingModelState build() {
    Future.microtask(_probeOnce);
    return const EmbeddingModelState();
  }

  Future<void> _probeOnce() async {
    try {
      final paths = await _manager.resolve();
      if (paths != null) {
        ref.read(embeddingServiceProvider).updatePaths(paths);
        state = state.copyWith(
          status: EmbeddingModelStatus.installed,
          progress: 1,
          phase: 'ready',
          clearError: true,
        );
      } else {
        state = state.copyWith(status: EmbeddingModelStatus.notInstalled);
      }
    } catch (e, st) {
      AppLog.e('EmbeddingModelState', 'probe failed: $e', e, st);
      state = state.copyWith(
        status: EmbeddingModelStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Begin downloading and loading the embedding model.
  Future<void> installIfNeeded() async {
    if (state.status == EmbeddingModelStatus.downloading) {
      return;
    }
    _cancelToken = CancelToken();
    state = state.copyWith(
      status: EmbeddingModelStatus.downloading,
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
      ref.read(embeddingServiceProvider).updatePaths(paths);
      state = state.copyWith(
        status: EmbeddingModelStatus.installed,
        progress: 1,
        phase: 'ready',
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = state.copyWith(
          status: EmbeddingModelStatus.notInstalled,
          progress: 0,
          clearPhase: true,
        );
        return;
      }
      state = state.copyWith(
        status: EmbeddingModelStatus.error,
        error: e.message ?? e.toString(),
      );
    } catch (e, st) {
      AppLog.e('EmbeddingModelState', 'install failed: $e', e, st);
      state = state.copyWith(
        status: EmbeddingModelStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Cancel an in-flight download.
  void cancel() {
    _cancelToken?.cancel('User cancelled embedding model download.');
  }

  /// Remove the installed model and clear the embedding service.
  Future<void> uninstall() async {
    await _manager.uninstall();
    ref.read(embeddingServiceProvider).updatePaths(null);
    state = state.copyWith(
      status: EmbeddingModelStatus.notInstalled,
      progress: 0,
      clearPhase: true,
      clearError: true,
    );
  }
}

/// Provider exposing the on-disk [EmbeddingModelManager].
final embeddingModelManagerProvider = Provider<EmbeddingModelManager>((ref) {
  return EmbeddingModelManager();
});

/// Provider exposing the on-device [EmbeddingService].
final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  final manager = ref.watch(embeddingModelManagerProvider);
  return EmbeddingService(modelInfo: manager.model);
});

/// Provider exposing the [EmbeddingModelState].
final embeddingModelStateProvider =
    NotifierProvider<EmbeddingModelStateNotifier, EmbeddingModelState>(
  EmbeddingModelStateNotifier.new,
);
