import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_state_bindings.dart';
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

/// Contract for the embedding-model lifecycle controller (probe / install /
/// cancel / uninstall), exposed so the desktop and web notifiers share a type.
abstract class EmbeddingModelController extends Notifier<EmbeddingModelState> {
  /// Begin downloading and loading the embedding model.
  Future<void> installIfNeeded();

  /// Cancel an in-flight download.
  void cancel();

  /// Remove the installed model and clear the embedding service.
  Future<void> uninstall();
}

/// Provider exposing the on-device [EmbeddingPort].
///
/// DECLARED here and RESOLVED through the embedding seam: the real cc_natives
/// `EmbeddingService` on the VM, an honest "not available on web" stub on web.
final embeddingServiceProvider = Provider<EmbeddingPort>(buildEmbeddingPort);

/// Provider exposing the [EmbeddingModelState] + its lifecycle controller.
///
/// On the VM the notifier probes the filesystem, downloads the model and
/// forwards the resolved paths to the embedding service; on web it reports a
/// permanent "desktop-only" state and its actions throw.
final embeddingModelStateProvider =
    NotifierProvider<EmbeddingModelController, EmbeddingModelState>(
  buildEmbeddingModelController,
);
