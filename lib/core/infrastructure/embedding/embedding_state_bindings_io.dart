// Desktop (VM) embedding model: the real cc_natives service + the
// download/probe lifecycle controller backed by the on-disk model manager.
library;

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/embedding/embedding_service.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the on-disk [EmbeddingModelManager], rooted at the device
/// app-support dir via the shared [appCcPaths] layout.
final _embeddingModelManagerProvider = Provider<EmbeddingModelManager>((ref) {
  return EmbeddingModelManager(paths: appCcPaths);
});

/// Provider exposing the on-device [EmbeddingService].
final _embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  final manager = ref.watch(_embeddingModelManagerProvider);
  return EmbeddingService(modelInfo: manager.model);
});

/// Desktop embedding port (cc_natives on-device inference).
EmbeddingPort buildEmbeddingPort(Ref ref) => ref.watch(_embeddingServiceProvider);

/// Desktop embedding-model lifecycle controller.
EmbeddingModelController buildEmbeddingModelController() =>
    _DesktopEmbeddingModelController();

/// Owns the embedding-model lifecycle. Probes the filesystem on init,
/// surfaces download progress to the UI, and forwards the resolved paths
/// to [EmbeddingService] once install completes.
class _DesktopEmbeddingModelController extends EmbeddingModelController {
  EmbeddingModelManager get _manager => ref.read(_embeddingModelManagerProvider);
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
        ref.read(_embeddingServiceProvider).updatePaths(paths);
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

  @override
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
      ref.read(_embeddingServiceProvider).updatePaths(paths);
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

  @override
  void cancel() {
    _cancelToken?.cancel('User cancelled embedding model download.');
  }

  @override
  Future<void> uninstall() async {
    await _manager.uninstall();
    ref.read(_embeddingServiceProvider).updatePaths(null);
    state = state.copyWith(
      status: EmbeddingModelStatus.notInstalled,
      progress: 0,
      clearPhase: true,
      clearError: true,
    );
  }
}
